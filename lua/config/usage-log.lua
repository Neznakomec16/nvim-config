-- Keystroke usage log for habit coaching. Records ONLY real key presses in
-- normal/visual/operator-pending modes (typed ~= "" filters out mapping
-- expansions and macro replays); insert-mode text, command-line input and
-- searches never reach the file. One space-separated keytrans stream per day
-- under stdpath("state")/usage-log/ — ask the assistant to analyze it
-- ("проанализируй мой nvim-лог") for frequency/anti-pattern coaching.
-- :UsageLog toggles recording for the session.
local M = {}

local dir = vim.fn.stdpath("state") .. "/usage-log"
vim.fn.mkdir(dir, "p")

local queue = {}
local enabled = true

local function flush()
  if #queue == 0 then
    return
  end
  local f = io.open(dir .. "/keys-" .. os.date("%Y-%m-%d") .. ".log", "a")
  if f then
    f:write(table.concat(queue, " ") .. " ")
    f:close()
  end
  queue = {}
end

vim.on_key(function(_, typed)
  if not enabled or typed == "" or typed == nil then
    return
  end
  local m = vim.fn.mode()
  if m ~= "n" and m ~= "v" and m ~= "V" and m ~= "\22" and m ~= "o" then
    return
  end
  queue[#queue + 1] = vim.fn.keytrans(typed)
  if #queue >= 200 then
    flush()
  end
end, vim.api.nvim_create_namespace("usage_log"))

vim.api.nvim_create_autocmd({ "VimLeavePre", "FocusLost" }, {
  group = vim.api.nvim_create_augroup("usage_log_flush", { clear = true }),
  callback = flush,
})

local timer = vim.uv.new_timer()
timer:start(60000, 60000, vim.schedule_wrap(flush))

vim.api.nvim_create_user_command("UsageLog", function()
  enabled = not enabled
  flush()
  vim.notify("Usage log: " .. (enabled and "on" or "off") .. " (" .. dir .. ")")
end, { desc = "Toggle keystroke usage logging" })

return M
