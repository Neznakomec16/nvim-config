return {
  {
    "okuuva/auto-save.nvim",
    cmd = "ASToggle",
    event = { "InsertLeave", "TextChanged" },
    opts = {
      -- InsertLeave + TextChanged (defaults) cover "edited, jumped to terminal, ran the task";
      -- debounce keeps format-on-save/LSP from firing on every keystroke burst
      debounce_delay = 1000,
      condition = function(buf)
        -- only real, named, writable files: skip terminals, prompts, plugin panels, unnamed scratch
        if vim.fn.getbufvar(buf, "&buftype") ~= "" then
          return false
        end
        if vim.fn.getbufvar(buf, "&modifiable") ~= 1 then
          return false
        end
        if vim.api.nvim_buf_get_name(buf) == "" then
          return false
        end
        return true
      end,
    },
  },
}
