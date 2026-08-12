return {
  {
    "akinsho/git-conflict.nvim",
    event = "VeryLazy",
    opts = {
      default_mappings = false,
      highlights = {
        incoming = "DiffAdd",
        current = "DiffText",
      },
    },
    keys = {
      { "]x", "<cmd>GitConflictNextConflict<cr>", desc = "Next git conflict" },
      { "[x", "<cmd>GitConflictPrevConflict<cr>", desc = "Prev git conflict" },
      { "co", "<cmd>GitConflictChooseOurs<cr>", desc = "Choose current (ours)" },
      { "ct", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose incoming (theirs)" },
      { "cb", "<cmd>GitConflictChooseBoth<cr>", desc = "Choose both" },
      { "c0", "<cmd>GitConflictChooseNone<cr>", desc = "Choose none" },
    },
  },
}
