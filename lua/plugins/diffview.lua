-- Side-by-side diffs and file history in real nvim buffers (motions, search
-- and LSP work, unlike lazygit's pager), plus a 3-way merge view with the
-- base revision when a conflict is heavier than git-conflict's inline picks.
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    opts = {},
    keys = {
      {
        "<leader>gv",
        function()
          if require("diffview.lib").get_current_view() then
            vim.cmd("DiffviewClose")
          else
            vim.cmd("DiffviewOpen")
          end
        end,
        desc = "Diff View (toggle)",
      },
      { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (Diffview)" },
      { "<leader>gV", ":'<,'>DiffviewFileHistory<cr>", mode = "x", desc = "Range History (Diffview)" },
    },
  },
}
