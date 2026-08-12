return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      -- GitLens-style virtual text at the end of the cursor line
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 300,
        ignore_whitespace = false,
      },
      current_line_blame_formatter = "  <author>, <author_time:%d.%m.%Y> · <summary>",
    },
    keys = {
      { "<leader>uB", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Toggle Line Blame" },
    },
  },
}
