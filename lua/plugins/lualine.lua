-- Move the file path out of the statusline into the tabline (bufferline's right
-- custom area), where it has room to be shown in full instead of being
-- collapsed to `dir/…/file.py` by pretty_path's `length = 3`.

-- Highlight colors are resolved lazily and cached until the colorscheme changes,
-- so the tabline redraw does not hit nvim_get_hl on every keystroke.
local hl_cache = {}

local function color(name)
  if hl_cache[name] == nil then
    hl_cache[name] = Snacks.util.color(name) or false
  end
  return hl_cache[name] or nil
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("lualine_path_hl", { clear = true }),
  callback = function()
    hl_cache = {}
  end,
})

---Path of the current buffer, relative to cwd (falls back to `~`-shortened).
---@return string?
local function cwd_path()
  if vim.bo.buftype ~= "" then
    return nil
  end
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end
  path = vim.fs.normalize(path)
  local cwd = LazyVim.root.cwd()
  if cwd ~= "" and path:sub(1, #cwd + 1) == cwd .. "/" then
    return path:sub(#cwd + 2)
  end
  return vim.fn.fnamemodify(path, ":~")
end

---Tabline segment: `<icon> dir/sub/ file.py ●`
local function path_area()
  local path = cwd_path()
  if not path then
    return {}
  end

  local dir, name = path:match("^(.*/)([^/]+)$")
  dir, name = dir or "", name or path

  local items = {}

  local ok, MiniIcons = pcall(require, "mini.icons")
  if ok then
    local icon, icon_hl = MiniIcons.get("file", name)
    items[#items + 1] = { text = " " .. icon .. " ", fg = color(icon_hl) }
  else
    items[#items + 1] = { text = " " }
  end

  if dir ~= "" then
    items[#items + 1] = { text = dir:gsub("%%", "%%%%"), fg = color("Comment") }
  end
  items[#items + 1] = { text = name:gsub("%%", "%%%%"), fg = color("Normal") }
  if vim.bo.modified then
    items[#items + 1] = { text = " ● ", fg = color("MatchParen") }
  else
    items[#items + 1] = { text = " " }
  end

  return items
end

return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        -- keep the tabline visible with a single buffer, otherwise the path
        -- disappears whenever only one file is open
        always_show_bufferline = true,
        custom_areas = { right = path_area },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- drop LazyVim's `{ LazyVim.lualine.pretty_path() }` from lualine_c:
      -- it is the only entry that is a bare single-function table (root_dir and
      -- the trouble symbols component both carry a `cond` key).
      opts.sections.lualine_c = vim.tbl_filter(function(c)
        return not (type(c) == "table" and type(c[1]) == "function" and next(c, 1) == nil)
      end, opts.sections.lualine_c)
    end,
  },
}
