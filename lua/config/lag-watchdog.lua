-- Redraw-lag instrumentation.
--
-- Two parts:
--  1. A watchdog around the bufferline tabline expression. nvim evaluates
--     _G.nvim_bufferline() on every tabline redraw; in long sessions this call
--     has degraded from ~15ms to 600ms+ and once saturated the event queue
--     with scheduled :redrawtabline (livelock, 100% CPU, 2026-09-18 and
--     2026-10-06). Every slow call is logged with session context so the
--     degradation can be attributed when it happens again.
--  2. :LagProbe — measures a full redraw with statusline / tabline / winbar
--     disabled one at a time, to name the slow layer on the spot.
--
-- Log: ~/.local/state/nvim/lag-watchdog.log

local M = {}

local LOG = vim.fn.stdpath("state") .. "/lag-watchdog.log"
local started = vim.uv.now()
local SLOW_MS = 50 -- log calls above this
local NOTIFY_MS = 200 -- notify (throttled) above this
local last_notify = 0

local function log_line(line)
  local f = io.open(LOG, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S ") .. line .. "\n")
    f:close()
  end
end

-- Context that may explain a degraded eval. Collected only on slow calls:
-- nvim_get_hl over all groups is itself not free.
local function context()
  local bufs = 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) then bufs = bufs + 1 end
  end
  local hl_count = 0
  for _ in pairs(vim.api.nvim_get_hl(0, {})) do
    hl_count = hl_count + 1
  end
  return string.format(
    "bufs=%d wins=%d diags=%d hl_groups=%d uptime_min=%d",
    bufs,
    #vim.api.nvim_list_wins(),
    #vim.diagnostic.get(),
    hl_count,
    ((vim.uv.now() - started) / 60000)
  )
end

local function wrap_bufferline()
  local orig = _G.nvim_bufferline
  if type(orig) ~= "function" then return false end
  _G.nvim_bufferline = function()
    local t0 = vim.uv.hrtime()
    local result = orig()
    local ms = (vim.uv.hrtime() - t0) / 1e6
    if ms > SLOW_MS then
      log_line(string.format("nvim_bufferline %.0fms %s", ms, context()))
      local now = vim.uv.now()
      if ms > NOTIFY_MS and now - last_notify > 60000 then
        last_notify = now
        vim.schedule(function()
          vim.notify(
            string.format("bufferline eval %.0fms — лог: %s", ms, LOG),
            vim.log.levels.WARN,
            { title = "lag-watchdog" }
          )
        end)
      end
    end
    return result
  end
  return true
end

-- bufferline defines _G.nvim_bufferline in setup(), which runs after VeryLazy.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    if not wrap_bufferline() then
      -- Plugin not loaded yet; retry once the UI has settled.
      vim.defer_fn(wrap_bufferline, 2000)
    end
  end,
})

-- :LagProbe — name the slow chrome layer. Each step toggles one layer off,
-- times 3 full redraws, restores. Numbers land in :messages and the log.
vim.api.nvim_create_user_command("LagProbe", function()
  local uv = vim.uv
  local function timed(label)
    local t0 = uv.hrtime()
    for _ = 1, 3 do
      vim.cmd("redraw!")
    end
    return string.format("%s=%.0fms", label, (uv.hrtime() - t0) / 3e6)
  end

  local out = { timed("base") }

  local ls = vim.o.laststatus
  vim.o.laststatus = 0
  table.insert(out, timed("no_statusline"))
  vim.o.laststatus = ls

  local st = vim.o.showtabline
  vim.o.showtabline = 0
  table.insert(out, timed("no_tabline"))
  vim.o.showtabline = st

  local saved = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    saved[w] = vim.wo[w].winbar
    vim.wo[w].winbar = ""
  end
  table.insert(out, timed("no_winbar"))
  for w, v in pairs(saved) do
    if vim.api.nvim_win_is_valid(w) then vim.wo[w].winbar = v end
  end

  local report = table.concat(out, "  ")
  log_line("LagProbe " .. report .. " " .. context())
  vim.notify(report, vim.log.levels.INFO, { title = "LagProbe" })
end, { desc = "Measure redraw cost per UI layer (statusline/tabline/winbar)" })

return M
