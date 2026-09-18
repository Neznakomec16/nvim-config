-- Live coach for navigation anti-patterns: nags about jjjj/hhhh sprees,
-- arrow keys and inefficient repeats the moment they happen, and keeps a
-- habit log (:Hardtime report). Complements the passive keystroke usage-log
-- (lua/config/usage-log.lua): this one corrects in the moment, the log feeds
-- the periodic review.
return {
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    event = "VeryLazy",
    opts = {
      -- hint, not block: show the better motion instead of refusing the key
      restriction_mode = "hint",
      disable_mouse = false,
      -- keep the coach out of panels and prompts
      disabled_filetypes = {
        "qf", "help", "lazy", "mason", "noice", "trouble",
        "snacks_dashboard", "snacks_picker_list", "snacks_picker_input", "snacks_terminal",
        "dap-view", "dap-view-term", "dap-repl", "dap-repl-input",
        "OverseerList", "gitcommit",
      },
    },
    keys = {
      { "<leader>uH", "<cmd>Hardtime toggle<cr>", desc = "Toggle Hardtime (nav coach)" },
    },
  },
}
