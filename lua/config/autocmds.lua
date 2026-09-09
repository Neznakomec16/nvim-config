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
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = vim.api.nvim_create_augroup("external_reload_notify", { clear = true }),
  callback = function(ev)
    vim.notify("Reloaded from disk: " .. vim.fn.fnamemodify(ev.file, ":~:."), vim.log.levels.INFO)
  end,
})
