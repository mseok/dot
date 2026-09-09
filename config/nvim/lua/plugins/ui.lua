require("tokyonight").setup({
  style = "night",
  light_style = "day",
  transparent = true,
  cache = false,
})

local day_start = 7
local night_start = 19
local last_style

local function style_for_time()
  local hour = tonumber(os.date("%H"))
  return hour >= day_start and hour < night_start and "day" or "night"
end

local function apply_time_theme()
  local style = style_for_time()
  if style == last_style then
    return
  end

  last_style = style
  vim.o.background = style == "day" and "light" or "dark"
  vim.cmd.colorscheme("tokyonight-" .. style)
  vim.cmd("highlight StatusLine guibg=NONE")
end

apply_time_theme()
vim.fn.timer_start(60 * 1000, vim.schedule_wrap(apply_time_theme), {
  ["repeat"] = 60 * 1000,
})
