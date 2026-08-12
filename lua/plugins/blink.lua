return {
  {
    "saghen/blink.cmp",
    opts = {
      -- Blink disables itself in prompt buffers; the dap REPL is one, so
      -- allow it there explicitly to get debugpy-driven completion.
      enabled = function()
        return vim.bo.buftype ~= "prompt" or vim.bo.filetype == "dap-repl"
      end,
      -- Show the function signature with the current argument highlighted
      -- while typing inside the parentheses.
      signature = { enabled = true },
      fuzzy = {
        -- Default is { 'score', 'sort_text' }, which lets fuzzy score override the
        -- LSP server's own ranking. That let dunder methods (e.g. `__getattribute__`)
        -- outrank the actually relevant override candidate (e.g. `get_state`) even
        -- though basedpyright's sortText correctly ranked the real member first.
        sorts = {
          -- Comparing sortText across sources is meaningless, so pin snippets
          -- below every other source first; nil falls through to the next sort.
          function(a, b)
            local a_snip = a.source_id == "snippets"
            local b_snip = b.source_id == "snippets"
            if a_snip ~= b_snip then
              return b_snip
            end
          end,
          "sort_text",
          "score",
        },
      },
      sources = {
        -- In the dap REPL, complete via omnifunc, which nvim-dap wires to the
        -- debug adapter — attribute candidates come from the live objects.
        per_filetype = {
          ["dap-repl"] = { "omni" },
        },
        providers = {
          omni = {
            -- debugpy can only compute completions for a paused frame; while
            -- the debuggee is running every request fails with "Thread to get
            -- completions seems to have resumed already". Only query it when
            -- the session is actually stopped.
            enabled = function()
              if vim.bo.filetype ~= "dap-repl" then
                return true
              end
              local ok, dap = pcall(require, "dap")
              local session = ok and dap.session()
              return session ~= nil and session.stopped_thread_id ~= nil
            end,
          },
          snippets = {
            -- Snippets are meaningless after a trigger character like `.`:
            -- only object attributes/methods from the LSP are relevant there.
            should_show_items = function(ctx)
              return ctx.trigger.initial_kind ~= "trigger_character"
            end,
          },
        },
      },
    },
  },
}
