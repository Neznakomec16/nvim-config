-- pytest-language-server: goto definition / references / hover / completion
-- for pytest fixtures — the one gap basedpyright cannot cover (fixture wiring
-- is pytest runtime magic, not static imports). Runs alongside basedpyright;
-- it answers only fixture-related requests. Installed via
-- `uv tool install pytest-language-server` (~/.local/bin).
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pytest_language_server = {},
      },
    },
  },
}
