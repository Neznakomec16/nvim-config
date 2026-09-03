-- tokyonight, `moon` style. tokyonight ships with LazyVim, so this only pins
-- the style and makes the choice persistent: the `<leader>uC` picker applies a
-- colorscheme for the session only and never writes config.
return {
  {
    "folke/tokyonight.nvim",
    opts = { style = "moon" },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "tokyonight-moon" },
  },
}
