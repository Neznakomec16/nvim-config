-- marksman indexes every .md under its root and publishes diagnostics for all
-- of them, open or not; it has no option to turn that off (its full option
-- list: Tests/default.marksman.toml upstream). In a repo with ~15k markdown
-- files (submodules included) that is tens of thousands of diagnostics plus a
-- hidden buffer per file (the default handler bufadd()s every URI), and every
-- consumer that walks vim.diagnostic.get() pays for all of them: bufferline
-- does it on each tabline redraw, which took 0.5-1.9s per redraw.
--
-- Keep only diagnostics for files loaded in a buffer. Opening a file still
-- shows its diagnostics: marksman re-publishes a document's diagnostics when
-- it gets opened (`reopenedWithDiagnostics` in its Server.fs), and nvim
-- clears them when the buffer detaches.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          handlers = {
            ["textDocument/publishDiagnostics"] = function(err, result, ctx)
              if result and vim.fn.bufloaded(vim.uri_to_fname(result.uri)) == 0 then
                return
              end
              return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx)
            end,
          },
        },
      },
    },
  },
}
