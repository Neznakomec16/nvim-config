-- Palenight, via material.nvim's `palenight` style.
--
-- The original `drewtempelmeyer/palenight.vim` is a vimscript port that only
-- defines legacy highlight groups: no `@`-prefixed treesitter captures and no
-- LSP semantic tokens, so most of LazyVim's UI falls back to defaults. This
-- plugin ships the same palette (bg #292D3E, fg #A6ACCD) with full coverage.
return {
  {
    "marko-cerovac/material.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      -- Integrations are opt-in and resolved by filename under
      -- material/highlights/plugins/, so an unknown name only warns.
      -- Listed: every supported integration this config actually installs.
      -- snacks.nvim (picker/explorer/dashboard/indent) has no integration
      -- here and falls back to the standard groups.
      plugins = {
        "blink",
        "dap",
        "flash",
        "gitsigns",
        "mini",
        "neotest",
        "noice",
        "trouble",
        "which-key",
      },
    },
    config = function(_, opts)
      -- Read by the colorscheme at load time; must be set before setup().
      vim.g.material_style = "palenight"
      require("material").setup(opts)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "material" },
  },
}
