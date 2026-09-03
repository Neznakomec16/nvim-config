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
