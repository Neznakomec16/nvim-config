-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Search buffer symbols, matching the `gs` binding used in Zed
vim.keymap.set("n", "gs", function()
  Snacks.picker.lsp_symbols({ filter = LazyVim.config.kind_filter })
end, { desc = "Search buffer symbols" })

vim.keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode" })

-- Override LazyVim's default <C-hjkl> window nav with vim-tmux-navigator's
-- versions (see plugins/tmux-navigator.lua) so the same keys also cross
-- into tmux panes when there's no more nvim split to move into.
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Go to Left Window" })
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Go to Lower Window" })
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Go to Upper Window" })
vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Go to Right Window" })

-- Copy current buffer's path to the system clipboard
vim.keymap.set("n", "<leader>fy", function()
  local path = vim.fn.expand("%")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy relative file path" })

vim.keymap.set("n", "<leader>fY", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy absolute file path" })

vim.keymap.set("n", "<leader>fl", function()
  local loc = vim.fn.expand("%") .. ":" .. vim.fn.line(".")
  vim.fn.setreg("+", loc)
  vim.notify("Copied: " .. loc)
end, { desc = "Copy file path with line number" })

-- Open the current file in the OS default app — a browser for .html. Built-in
-- `gx` only opens the URL or path under the cursor, never the buffer itself.
vim.keymap.set("n", "<leader>fo", function()
  local path = vim.fn.expand("%:p")
  if path == "" then
    vim.notify("Buffer has no file on disk", vim.log.levels.WARN)
    return
  end
  local ok, err = vim.ui.open(path)
  if not ok then
    vim.notify(err or "vim.ui.open failed", vim.log.levels.ERROR)
  else
    vim.notify("Opened: " .. vim.fn.expand("%:t"))
  end
end, { desc = "Open file in browser / default app" })

-- Fuzzy grep: unlike LazyVim's `<leader>/` (live grep, where every keystroke is
-- sent to rg as a regex), this dumps every line once and then fuzzy-matches it
-- in the picker — closer to `rg '' | fzf`. Inside any snacks picker, <C-g>
-- toggles live/fuzzy on the fly as well.
--
vim.keymap.set("n", "<leader>s/", function()
  Snacks.picker.grep({
    cwd = LazyVim.root(),
    live = false,
    search = "",
    need_search = false,
    title = "Fuzzy Grep (Root Dir)",
  })
end, { desc = "Fuzzy Grep (Root Dir)" })

-- Quick manual format on Option+F ("format"; <C-i> must stay jump-forward).
-- Alt chords are reliable here: alacritty.toml sets option_as_alt = "Both",
-- so Option+F always arrives as ESC-prefixed f, no keyboard protocol needed.
vim.keymap.set({ "n", "x" }, "<M-f>", function()
  LazyVim.format({ force = true })
end, { desc = "Format buffer/selection" })

-- Browser-style buffer lifecycle on Option/Alt chords. Portable encoding: Alt
-- arrives as an ESC-prefixed key on Linux terminals by default and on macOS
-- via alacritty's option_as_alt — no keyboard protocol involved.
-- <M-w> closes the buffer keeping the window layout; <M-T> (Option+Shift+T)
-- reopens the most recently closed file, like Ctrl+W / Ctrl+Shift+T in a browser.
local closed_files = {} ---@type string[]
vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("reopen_closed_buffer", { clear = true }),
  callback = function(ev)
    if not vim.api.nvim_buf_is_valid(ev.buf) or vim.bo[ev.buf].buftype ~= "" then
      return
    end
    local name = vim.api.nvim_buf_get_name(ev.buf)
    if name == "" or vim.fn.filereadable(name) ~= 1 then
      return
    end
    closed_files = vim.tbl_filter(function(f)
      return f ~= name
    end, closed_files)
    table.insert(closed_files, name)
    closed_files = vim.list_slice(closed_files, math.max(1, #closed_files - 20))
  end,
})
vim.keymap.set("n", "<M-w>", function()
  Snacks.bufdelete()
end, { desc = "Close buffer" })
vim.keymap.set("n", "<M-T>", function()
  local file = table.remove(closed_files)
  if file then
    vim.cmd.edit(vim.fn.fnameescape(file))
  else
    vim.notify("No recently closed buffers", vim.log.levels.INFO)
  end
end, { desc = "Reopen last closed buffer" })
