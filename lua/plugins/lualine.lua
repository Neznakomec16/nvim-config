-- File path lives in the winbar (top of each window, under the tabline) —
-- nvim's native per-window bar — instead of the statusline or tabline.
-- `pretty_path` with `length = 0` shows the full path without the stock
-- `dir/…/file.py` truncation; lualine renders the winbar, so no extra plugin.
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- drop LazyVim's `{ LazyVim.lualine.pretty_path() }` from lualine_c:
      -- it is the only entry that is a bare single-function table (root_dir and
      -- the trouble symbols component both carry a `cond` key).
      opts.sections.lualine_c = vim.tbl_filter(function(c)
        return not (type(c) == "table" and type(c[1]) == "function" and next(c, 1) == nil)
      end, opts.sections.lualine_c)

      local path_components = {
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        { LazyVim.lualine.pretty_path({ length = 0, modified_sign = " ●" }) },
      }
      opts.winbar = { lualine_c = path_components }
      opts.inactive_winbar = { lualine_c = path_components }

      -- no winbar in plugin/tool windows; nvim-dap-view draws its own winbar
      -- with section tabs and controls (see plugins/dap.lua) and must not be
      -- overridden
      opts.options = opts.options or {}
      opts.options.disabled_filetypes = opts.options.disabled_filetypes or {}
      opts.options.disabled_filetypes.winbar = {
        "dashboard",
        "snacks_dashboard",
        "snacks_picker_list",
        "snacks_picker_input",
        "snacks_picker_preview",
        "snacks_terminal",
        "terminal",
        "trouble",
        "Trouble",
        "lazy",
        "mason",
        "noice",
        "qf",
        "help",
        "dap-repl",
        "dap-view",
        "dap-view-term",
        "dap-view-help",
        "dap-view-hover",
      }
    end,
  },
}
