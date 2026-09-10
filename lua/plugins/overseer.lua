return {
  -- Name the <leader>o prefix in the which-key popup.
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>o", group = "overseer" },
      },
    },
  },
  {
    "stevearc/overseer.nvim",
    -- Loaded early (not on-demand) so its nvim-dap integration is in place
    -- before the first debug session: it handles preLaunchTask/postDebugTask
    -- from launch.json configurations.
    event = "VeryLazy",
    opts = {},
    -- stylua: ignore
    keys = {
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run Task" },
      { "<leader>oo", "<cmd>OverseerToggle<cr>", desc = "Task Panel" },
      { "<F4>", "<cmd>OverseerToggle<cr>", desc = "Task Panel" },
      { "<leader>ol", function()
        local overseer = require("overseer")
        local tasks = overseer.list_tasks({ recent_first = true })
        if vim.tbl_isempty(tasks) then
          vim.notify("No tasks have been run yet", vim.log.levels.WARN)
        else
          overseer.run_action(tasks[1], "restart")
        end
      end, desc = "Restart Last Task" },
      -- dispose(true) force-stops running tasks too; plain `d` in the list only cancels a
      -- running task on the first press and needs a second press to actually remove it.
      { "<leader>oD", function()
        local count = 0
        for _, task in ipairs(require("overseer").list_tasks({})) do
          task:dispose(true)
          count = count + 1
        end
        vim.notify(("Disposed %d task(s)"):format(count))
      end, desc = "Dispose All Tasks" },
    },
  },
}
