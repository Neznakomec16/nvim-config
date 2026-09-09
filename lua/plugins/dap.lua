local function terminate()
  require("dap").terminate()
end

-- Start an additional session (config picker) without touching the running
-- one — unlike plain continue, which resumes the current session.
local function new_session()
  require("dap").continue({ new = true })
end

-- Restart with the same configuration: restart the live session, or re-run
-- the last one if it has already exited.
local function restart()
  local dap = require("dap")
  if dap.session() then
    dap.restart()
  else
    dap.run_last()
  end
end

local function step_out()
  require("dap").step_out()
end

-- Window picker for dap's jump-to-stopped-line. dap-view pins its panes with
-- 'winfixbuf', and nvim-dap's default `uselast` strategy blindly calls
-- nvim_win_set_buf on the current/previous window — E1513 and a DAP error
-- popup whenever a stop event arrives while focus is in a dap-view pane.
-- Order: a window already showing the buffer; the focused window when it is a
-- regular one; the first regular window of the tab; a new split. A regular
-- window has no 'winfixbuf', an empty 'buftype' and is not floating.
local function jump_to_stopped_line(bufnr, line, column)
  local api = vim.api
  local function set_cursor(win)
    pcall(api.nvim_win_set_cursor, win, { line, math.max(column, 1) - 1 })
    api.nvim_win_call(win, function()
      vim.cmd("normal! zv")
    end)
  end
  local function regular(win)
    return not vim.wo[win].winfixbuf
      and vim.bo[api.nvim_win_get_buf(win)].buftype == ""
      and api.nvim_win_get_config(win).relative == ""
  end
  local wins = api.nvim_tabpage_list_wins(0)
  for _, win in ipairs(wins) do
    if api.nvim_win_get_buf(win) == bufnr then
      return set_cursor(win)
    end
  end
  local targets = vim.tbl_filter(regular, wins)
  local cur = api.nvim_get_current_win()
  local target = vim.tbl_contains(targets, cur) and cur or targets[1]
  if not target then
    vim.cmd("split")
    target = api.nvim_get_current_win()
  end
  api.nvim_win_set_buf(target, bufnr)
  set_cursor(target)
end

-- Multi-line input for the dap REPL. The REPL is a prompt buffer (dap-view
-- embeds nvim-dap's dap.repl), and Neovim hands a prompt callback only the
-- last line — so multi-line code cannot be typed at the prompt itself.
-- Instead the text goes through dap.repl.execute: debugpy evaluates a repl
-- expression with eval() and falls back to exec() on SyntaxError, so whole
-- statements (for/def/with) arrive intact.
local function send_to_repl(lines)
  local text = table.concat(lines, "\n")
  if text:match("%S") then
    require("dap").repl.execute(text)
  end
end

-- The visual selection, as lines. Yanking exits visual mode as a side effect,
-- which is what we want after sending.
local function visual_lines()
  vim.cmd('normal! "vy')
  return vim.split(vim.fn.getreg("v"), "\n")
end

-- A python scratch buffer in a small split below: <CR> in normal mode sends
-- the whole buffer and clears it, <CR> on a selection sends just that. The
-- buffer is kept (bufhidden=hide), so reopening restores unsent drafts.
local function repl_input()
  local buf = vim.fn.bufnr("dap-repl-input")
  if buf == -1 then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "dap-repl-input")
    vim.bo[buf].filetype = "python"
    vim.bo[buf].bufhidden = "hide"
    -- Completion from the paused frame, the same source the REPL uses.
    -- blink keys its sources on this flag (see plugins/blink.lua); the
    -- omnifunc is the manual <C-x><C-o> fallback.
    vim.b[buf].dap_repl_input = true
    vim.bo[buf].omnifunc = "v:lua.require'dap'.omnifunc"
    vim.keymap.set("n", "<CR>", function()
      send_to_repl(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    end, { buffer = buf, desc = "Send buffer to DAP REPL" })
    vim.keymap.set("x", "<CR>", function()
      send_to_repl(visual_lines())
    end, { buffer = buf, desc = "Send selection to DAP REPL" })
  end
  vim.cmd("belowright 8split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.cmd("startinsert")
end

return {
  -- Persist breakpoints to disk and restore them when a file is reopened.
  -- Breakpoints must be set through this plugin's API to be saved, hence
  -- the overridden mappings below.
  {
    "Weissle/persistent-breakpoints.nvim",
    event = "BufReadPost",
    opts = {
      load_breakpoints_event = { "BufReadPost" },
    },
  },
  -- Treesitter syntax highlighting inside the dap REPL. The dap_repl parser
  -- must be installed AFTER this plugin's setup registers it; on a fresh
  -- machine run:
  --   :lua require("nvim-dap-repl-highlights").setup()
  --   :lua require("nvim-treesitter").install({ "dap_repl" })
  {
    "LiadOz/nvim-dap-repl-highlights",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },
  -- Replaced by nvim-dap-view below. dap-ui spreads its elements over a left
  -- sidebar plus a bottom tray, so it competed for the left edge with the
  -- snacks explorer and for the bottom with the overseer task list — and which
  -- pane got squeezed depended on the order the panels happened to be opened
  -- in. It comes in as a dependency of the LazyVim dap.core extra; disabling it
  -- here also drops the dapui open/close listeners defined in its own config.
  { "rcarriga/nvim-dap-ui", enabled = false },
  {
    "igorlfs/nvim-dap-view",
    opts = {
      winbar = {
        sections = { "scopes", "watches", "threads", "breakpoints", "exceptions", "repl", "console", "sessions" },
        default_section = "scopes",
        -- Clickable play/step/terminate buttons in the winbar.
        controls = { enabled = true },
      },
      windows = {
        size = 0.3,
        position = "below",
        -- Keep the console (adapter stdout / server logs) as a winbar section
        -- of the single bottom window instead of a separate split: `hide` only
        -- suppresses the extra terminal *window*, the "console" section above
        -- still renders the terminal buffer — full editor width, which the old
        -- docked dap-ui console pane never had.
        terminal = { hide = true },
      },
      -- "open" = open on session start and never auto-close; the conditional
      -- close (only after a clean session) lives in the nvim-dap spec below,
      -- so a failed test keeps the view with its error output on screen.
      auto_toggle = "open",
    },
    -- stylua: ignore
    keys = {
      { "<F9>", "<cmd>DapViewToggle<cr>", desc = "Toggle DAP View" },
      { "<leader>du", "<cmd>DapViewToggle<cr>", desc = "Dap View" },
      -- With no argument and no range, both commands resolve the expression
      -- themselves: <cexpr> in normal mode, the selection in visual mode.
      { "<leader>de", "<cmd>DapViewHover<cr>", desc = "Eval", mode = { "n", "x" } },
      { "<leader>dW", "<cmd>DapViewWatch<cr>", desc = "Watch Expression", mode = { "n", "x" } },
      -- Jump straight to a section instead of cycling the winbar with ]v/[v.
      { "<leader>dL", "<cmd>DapViewJump console<cr>", desc = "Console (logs)" },
      { "<leader>dr", "<cmd>DapViewJump repl<cr>", desc = "REPL" },
      -- <CR> on a session in this view makes it the active one that
      -- stepping/continue operate on.
      { "<leader>ds", "<cmd>DapViewJump sessions<cr>", desc = "Sessions (switch)" },
    },
  },
  -- The REPL input buffer completes from the debug adapter, exactly like the
  -- REPL does. It has filetype python (for highlighting/indent), so blink's
  -- per_filetype cannot single it out: wrap the merged default source list
  -- and switch on the buffer flag set in repl_input() instead.
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      local defaults = opts.sources.default
      opts.sources.default = function()
        if vim.b.dap_repl_input then
          return { "omni" }
        end
        return type(defaults) == "function" and defaults() or defaults
      end
    end,
  },
  {
    "mfussenegger/nvim-dap",
    -- Runs after nvim-dap is on the rtp, before LazyVim's config — the same
    -- side-effect `opts` pattern LazyVim's own lang extras use for dap.
    opts = function()
      local dap = require("dap")
      dap.defaults.fallback.switchbuf = jump_to_stopped_line

      -- Close dap-view only after a clean session. dap-view's own auto-close
      -- fires on every termination, wiping the console/REPL exactly when a
      -- test failed and its traceback is worth reading; auto_toggle = "open"
      -- disables it, and these listeners re-add closing for clean exits only.
      -- Failure signals: a stop with reason "exception" (unhandled error) or
      -- a nonzero exit code (pytest exits 1 on failed tests without any
      -- exception stop, because pytest swallows assertion errors itself).
      local failed = {}
      dap.listeners.before.event_stopped["dapview_keep_on_failure"] = function(session, body)
        if body and body.reason == "exception" then
          failed[session.id] = true
        end
      end
      dap.listeners.before.event_exited["dapview_keep_on_failure"] = function(session, body)
        if body and (body.exitCode or 0) ~= 0 then
          failed[session.id] = true
        end
      end
      local function close_if_clean(session)
        local keep = failed[session.id]
        failed[session.id] = nil
        if not keep then
          vim.schedule(function()
            require("dap-view").close(true)
          end)
        end
      end
      dap.listeners.after.event_terminated["dapview_keep_on_failure"] = close_if_clean
      dap.listeners.after.disconnect["dapview_keep_on_failure"] = close_if_clean
    end,
    dependencies = {
      "Weissle/persistent-breakpoints.nvim",
      "LiadOz/nvim-dap-repl-highlights",
      -- Loaded with nvim-dap rather than lazily on its own keys, so its dap
      -- listeners are registered before the first session starts and
      -- auto_toggle can fire.
      "igorlfs/nvim-dap-view",
    },
    -- stylua: ignore
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Run/Continue" },
      { "<F8>", function() require("persistent-breakpoints.api").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<F10>", function() require("dap").step_over() end, desc = "Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Step Into" },
      -- Modified F-keys arrive in one of two encodings depending on how the
      -- terminal/tmux deliver them: the modern notation (<S-F5>) or the
      -- legacy high F-numbers (S-F5=F17, C-F5=F29, C-S-F5=F41, S-F11=F23).
      -- Map both so the flow survives any transport.
      { "<S-F5>", terminate, desc = "Terminate Debug Session" },
      { "<F17>", terminate, desc = "Terminate Debug Session" },
      { "<C-F5>", new_session, desc = "New Debug Session" },
      { "<F29>", new_session, desc = "New Debug Session" },
      { "<C-S-F5>", restart, desc = "Restart Debug Session" },
      { "<F41>", restart, desc = "Restart Debug Session" },
      { "<S-F11>", step_out, desc = "Step Out" },
      { "<F23>", step_out, desc = "Step Out" },
      -- Superseded by the dap-view sections (<leader>dr / <leader>ds above).
      -- Dropping LazyVim's versions here keeps the winning mapping from
      -- depending on which of the two plugin specs happens to load last.
      { "<leader>dr", false },
      { "<leader>ds", false },
      -- Re-route LazyVim's breakpoint mappings through the persistent API too.
      { "<leader>db", function() require("persistent-breakpoints.api").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dB", function() require("persistent-breakpoints.api").set_conditional_breakpoint() end, desc = "Breakpoint Condition" },
      { "<leader>dX", function() require("persistent-breakpoints.api").clear_all_breakpoints() end, desc = "Clear All Breakpoints" },
      -- Jump back to the line the debugger is stopped on (the active frame).
      { "<leader>df", function() require("dap").focus_frame() end, desc = "Focus stopped line" },
      -- Multi-line REPL input: a scratch split in normal mode, or send the
      -- selection of any buffer straight to the REPL.
      { "<leader>dR", repl_input, desc = "REPL multi-line input" },
      { "<leader>dR", function() send_to_repl(visual_lines()) end, mode = "x", desc = "Send selection to REPL" },
    },
  },
}
