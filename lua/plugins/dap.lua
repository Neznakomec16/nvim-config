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
      -- Open on session start, close when it exits. The terminal buffer of the
      -- last session survives, so reopening after a crash still shows its logs.
      auto_toggle = true,
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
  {
    "mfussenegger/nvim-dap",
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
    },
  },
}
