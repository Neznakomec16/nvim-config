-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- snacks.explorer: give untracked files their own colour.
--
-- snacks links GitStatusUntracked, GitStatusIgnored, PathIgnored and PathHidden
-- all to NonText (picker/config/highlights.lua:16,17,71,72), so a brand-new
-- untracked file is indistinguishable from a gitignored one or a dotfile — only
-- the right-hand column icon differs (`?` vs the crossed-eye). Recolour just
-- untracked; the other three are legitimately dim.
--
-- Linked to `Added` (green in tokyonight and defined by every mainstream
-- scheme, with an nvim default as fallback), so it follows colorscheme changes.
--
-- snacks registers its groups with `default = true` and re-applies them from its
-- own ColorScheme hook, and `nvim_set_hl` with `default = true` never overwrites
-- an existing group — so this wins regardless of hook order.
local function snacks_untracked_hl()
  vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { link = "Added" })
end

snacks_untracked_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("snacks_untracked_hl", { clear = true }),
  callback = snacks_untracked_hl,
})

-- snacks.explorer: re-read the tree and git status when nvim regains focus.
--
-- The explorer caches `git status` for 15 minutes (CACHE_TTL in
-- snacks/explorer/git.lua) and only invalidates it from a filesystem watcher on
-- *expanded* directories, a write to .git/index, a BufWritePost in its own
-- window, or an explicit reveal. A file that another process (an agent, a code
-- generator) drops into a collapsed folder therefore stays invisible for up to
-- 15 minutes. `Tree:refresh` clears the git cache for the root and drops
-- `expanded` on the subtree, so the next find re-lists from disk.
--
-- Cost: this re-scans every *open* directory on each FocusGained. Cheap for a
-- normal tree; if it ever drags, narrow it to the cwd's direct children.
-- Requires `focus-events on` under tmux (set in ~/.tmux.conf).
vim.api.nvim_create_autocmd("FocusGained", {
  group = vim.api.nvim_create_augroup("snacks_explorer_refocus", { clear = true }),
  callback = function()
    if not _G.Snacks then
      return
    end
    local picker = Snacks.picker.get({ source = "explorer" })[1]
    if not picker or picker.closed then
      return
    end
    require("snacks.explorer.tree"):refresh(picker:cwd())
    require("snacks.explorer.actions").update(picker, { refresh = true })
  end,
})

-- Keep buffers in sync with files edited outside nvim (agents, formatters,
-- git). LazyVim runs `checktime` only on FocusGained/TermClose/TermLeave, so
-- while sitting in a buffer (or a claudecode terminal) watching an agent work,
-- buffers go stale: LSP diagnostics point at old text, and the next auto-save
-- hits "file changed since read" — a blocking prompt that looks like a freeze.
-- Poll instead: `checktime` stats every listed buffer, cheap at 2s. Reloading
-- a buffer re-sends its content to LSP, so diagnostics follow automatically.
local checktime_timer = vim.uv.new_timer()
checktime_timer:start(
  2000,
  2000,
  vim.schedule_wrap(function()
    -- checktime is forbidden while the cmdline or a prompt is busy (E11/E565)
    if vim.fn.mode() == "c" or vim.fn.getcmdwintype() ~= "" then
      return
    end
    vim.cmd("silent! checktime")
  end)
)

-- Make external reloads visible instead of silent under-the-cursor swaps.
-- Also drop and re-request inlay hints: hints computed for the pre-reload
-- text keep their old coordinates, which renders them mid-word and crashes
-- the decoration provider (nvim_buf_set_extmark out of range) when the file
-- got shorter.
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = vim.api.nvim_create_augroup("external_reload_notify", { clear = true }),
  callback = function(ev)
    -- A deleted file never reconciles its timestamp, so the 2s checktime
    -- poll would re-fire this forever: warn once and go quiet until the
    -- file reappears (which clears the flag and resumes reload notices).
    if vim.v.fcs_reason == "deleted" then
      if not vim.b[ev.buf].usage_deleted_notified then
        vim.b[ev.buf].usage_deleted_notified = true
        vim.notify("File deleted on disk (buffer kept): " .. vim.fn.fnamemodify(ev.file, ":~:."), vim.log.levels.WARN)
      end
      return
    end
    vim.b[ev.buf].usage_deleted_notified = nil
    vim.notify("Reloaded from disk: " .. vim.fn.fnamemodify(ev.file, ":~:."), vim.log.levels.INFO)
    if vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }) then
      vim.lsp.inlay_hint.enable(false, { bufnr = ev.buf })
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end
      end)
    end
  end,
})

-- Close dap-view before persistence saves a session: a restored layout brings
-- back a dap-view window the plugin no longer tracks, and the next debug run
-- opens its own beside the zombie (dap-view #132 is the same class of issue).
vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceSavePre",
  group = vim.api.nvim_create_augroup("dapview_out_of_sessions", { clear = true }),
  callback = function()
    local ok, dapview = pcall(require, "dap-view")
    if ok then
      pcall(dapview.close, true)
    end
  end,
})

-- :LspMem — active LSP clients with per-server memory. :LspInfo shows clients,
-- roots and capabilities but never memory; this walks nvim's own process
-- subtree and sums RSS per server (mason's python-shim + node pairs count as
-- one). The sticky window refreshes itself every 2s while shown; a second
-- :LspMem (or <leader>un) dismisses it and stops the refresh.
local lspmem_timer ---@type uv.uv_timer_t?

local function lspmem_visible()
  for _, n in ipairs(Snacks.notifier.get_history()) do
    if n.id == "lspmem" and n.shown and not n.hidden then
      return true
    end
  end
  return false
end

local function lspmem_stop()
  if lspmem_timer then
    lspmem_timer:stop()
    lspmem_timer:close()
    lspmem_timer = nil
  end
end

local function lspmem_render()
  local procs, children = {}, {}
  for _, l in ipairs(vim.fn.systemlist("ps -axo pid=,ppid=,rss=,etime=,command=")) do
    local pid, ppid, rss, etime, cmd = l:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s+(%S+)%s+(.+)$")
    if pid then
      pid, ppid = tonumber(pid), tonumber(ppid)
      procs[pid] = { rss = tonumber(rss), etime = etime, cmd = cmd }
      children[ppid] = children[ppid] or {}
      table.insert(children[ppid], pid)
    end
  end
  local function subtree(pid, acc)
    acc = acc or {}
    table.insert(acc, pid)
    for _, ch in ipairs(children[pid] or {}) do
      subtree(ch, acc)
    end
    return acc
  end
  local mine = subtree(vim.uv.os_getpid())
  local claimed = {}
  local lines = {}
  for _, c in ipairs(vim.lsp.get_clients()) do
    local exe = c.config.cmd and type(c.config.cmd) == "table" and c.config.cmd[1] or "?"
    local needle = vim.fs.basename(exe)
    local total, main
    for _, pid in ipairs(mine) do
      local pr = procs[pid]
      if pr and not claimed[pid] and not main and pr.cmd:find(needle, 1, true) then
        main = pid
        for _, sp in ipairs(subtree(pid)) do
          claimed[sp] = true
          total = (total or 0) + (procs[sp] and procs[sp].rss or 0)
        end
      end
    end
    local bufs = vim.tbl_count(c.attached_buffers or {})
    -- last two path segments keep the root readable inside the notifier's
    -- width cap; the code span stops the markdown renderer from pairing
    -- stray ~ into strikethrough
    local root = "-"
    if c.root_dir then
      root = "…/" .. vim.fn.fnamemodify(c.root_dir, ":h:t") .. "/" .. vim.fn.fnamemodify(c.root_dir, ":t")
    end
    if #lines == 0 then
      lines[1] = string.format("%-24s %7s  %-11s %4s  %s", "client", "mem", "up", "bufs", "root")
    end
    lines[#lines + 1] = string.format(
      "%-24s %7s  %-11s %4d  `%s`",
      c.name,
      total and string.format("%.0fMB", total / 1024) or "n/a",
      main and (procs[main].etime or "?") or "-",
      bufs,
      root
    )
  end
  vim.notify(
    #lines > 0 and table.concat(lines, "\n") or "no active LSP clients",
    vim.log.levels.INFO,
    { title = "LSP memory", timeout = 0, id = "lspmem" }
  )
end

vim.api.nvim_create_user_command("LspMem", function()
  if lspmem_visible() then
    lspmem_stop()
    Snacks.notifier.hide("lspmem")
    return
  end
  lspmem_render()
  lspmem_stop()
  lspmem_timer = vim.uv.new_timer()
  lspmem_timer:start(
    2000,
    2000,
    vim.schedule_wrap(function()
      if not lspmem_visible() then
        lspmem_stop()
        return
      end
      lspmem_render()
    end)
  )
end, { desc = "Active LSP clients with memory usage" })

-- Keystroke usage log for habit coaching (lua/config/usage-log.lua) is OFF:
-- disabled 2026-09-18 while chasing input lag. Re-enable by restoring the
-- require("config.usage-log") line.

-- Dispose every overseer task before quitting. A session that exits with
-- live streaming tasks (docker compose, temporal, port-forwards) feeds an
-- endless redraw stream into the quit hooks' vim.wait and can livelock the
-- exit at 99% CPU (seen 2026-09-18). ExitPre runs before the plugins' own
-- VimLeavePre cleanup, so by the time they wait, nothing is streaming.
vim.api.nvim_create_autocmd("ExitPre", {
  group = vim.api.nvim_create_augroup("overseer_dispose_on_exit", { clear = true }),
  callback = function()
    local overseer = package.loaded["overseer"]
    if not overseer then
      return
    end
    for _, task in ipairs(overseer.list_tasks({})) do
      pcall(task.dispose, task, true)
    end
  end,
})
