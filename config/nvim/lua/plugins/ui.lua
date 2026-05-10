local dark_style = "storm"
local light_style = "day"
local refresh_ms = 30000
local active_background

local function hex_to_8bit(component)
  local value = tonumber(component, 16)
  if not value then
    return nil
  end

  local max = (16 ^ #component) - 1
  if max <= 0 then
    return nil
  end

  return math.floor((value / max) * 255 + 0.5)
end

local function color_to_background(red, green, blue)
  local function linearize(channel)
    channel = channel / 255
    if channel <= 0.03928 then
      return channel / 12.92
    end
    return ((channel + 0.055) / 1.055) ^ 2.4
  end

  local luminance = 0.2126 * linearize(red)
    + 0.7152 * linearize(green)
    + 0.0722 * linearize(blue)

  return luminance > 0.5 and "light" or "dark"
end

local function background_from_osc11(sequence)
  local value = sequence:match("%]11;([^\027\007]+)")
  if not value then
    return nil
  end

  local red, green, blue = value:match("^rgb:([%x]+)/([%x]+)/([%x]+)")
  if not red then
    red, green, blue = value:match("^rgba:([%x]+)/([%x]+)/([%x]+)/[%x]+")
  end

  if not red then
    local hex = value:match("^#([%x]+)")
    if hex and #hex >= 6 then
      if #hex >= 12 then
        red, green, blue = hex:sub(1, 4), hex:sub(5, 8), hex:sub(9, 12)
      else
        red, green, blue = hex:sub(1, 2), hex:sub(3, 4), hex:sub(5, 6)
      end
    end
  end

  red = red and hex_to_8bit(red)
  green = green and hex_to_8bit(green)
  blue = blue and hex_to_8bit(blue)

  if not red or not green or not blue then
    return nil
  end

  return color_to_background(red, green, blue)
end

local function apply_background(background, force)
  if background ~= "light" and background ~= "dark" then
    return
  end
  if not force and active_background == background and vim.g.colors_name == "tokyonight" then
    return
  end

  active_background = background
  require("tokyonight").setup({
    style = background == "light" and light_style or dark_style,
    transparent = true,
    cache = false,
  })

  if vim.o.background ~= background then
    vim.o.background = background
  end

  vim.cmd("colorscheme tokyonight")
  vim.cmd("highlight StatusLine guibg=NONE")
end

local function terminal_background_query()
  local query = "\027]11;?\007"
  if vim.env.TMUX then
    query = "\027Ptmux;\027" .. query .. "\027\\"
  end
  return query
end

local function query_terminal_background()
  if #vim.api.nvim_list_uis() == 0 then
    return
  end
  pcall(vim.api.nvim_ui_send, terminal_background_query())
end

apply_background(vim.o.background == "light" and "light" or "dark", true)

vim.api.nvim_create_autocmd("TermResponse", {
  callback = function(event)
    local sequence = event.data and event.data.sequence or vim.v.termresponse
    local background = sequence and background_from_osc11(sequence)
    if background then
      vim.schedule(function()
        apply_background(background)
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  callback = function()
    local background = vim.v.option_new
    vim.schedule(function()
      apply_background(background)
    end)
  end,
})

vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter", "FocusGained" }, {
  callback = function()
    vim.defer_fn(query_terminal_background, 50)
  end,
})

local timer = (vim.uv or vim.loop).new_timer()
if timer then
  timer:start(1000, refresh_ms, vim.schedule_wrap(query_terminal_background))
  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
      timer:stop()
      timer:close()
    end,
  })
end
