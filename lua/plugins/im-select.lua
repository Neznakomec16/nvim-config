-- Keep the OS input source in sync with the editor mode: force English (ABC)
-- outside insert mode and on focus, restore the previous layout on
-- InsertEnter. Replaces keymap mirroring (langmap/langmapper): normal mode is
-- physically always English, so every plugin — including getchar()-based ones
-- like which-key — just works from the Russian layout.
-- Requires `macism` (brew install laishulu/homebrew/macism).
-- macism is macOS-only; on Linux, let the plugin auto-detect ibus/fcitx5/fcitx.
local opts = {}
if vim.fn.has("macunix") == 1 then
  opts = {
    default_command = "macism",
    default_im_select = "com.apple.keylayout.ABC",
  }
end

return {
  "keaising/im-select.nvim",
  event = "VeryLazy",
  opts = opts,
}
