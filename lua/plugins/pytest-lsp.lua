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
        pytest_language_server = {
          -- Keep basedpyright the only inlay-hint provider on python buffers:
          -- with two providers nvim 0.12.5's inlay-hint renderer races doc
          -- edits and crashes the decoration provider with extmark
          -- out-of-range storms (neovim/neovim#36318, fix not released yet).
          -- This server is here for fixture navigation; its hints add nothing.
          on_init = function(client)
            client.server_capabilities.inlayHintProvider = nil
          end,
        },
      },
    },
  },
}
