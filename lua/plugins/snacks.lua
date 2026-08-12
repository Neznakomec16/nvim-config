-- With ignored = true, fd/rg run with --no-ignore, so heavy gitignored dirs
-- (.venv, node_modules, caches) would flood the pickers; exclude them
-- explicitly. The explorer lists directories lazily, so there it is enough
-- to hide just the noise (.git, __pycache__) while keeping .venv visible.
local picker_exclude = {
  ".git",
  "__pycache__",
  ".venv",
  "node_modules",
  ".mypy_cache",
  ".ruff_cache",
  ".pytest_cache",
}

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            exclude = { ".git", "__pycache__" },
          },
          files = {
            hidden = true,
            ignored = true,
            exclude = picker_exclude,
          },
          grep = {
            hidden = true,
            ignored = true,
            exclude = picker_exclude,
          },
        },
      },
    },
  },
}
