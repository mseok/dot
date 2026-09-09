require("tokyonight").setup({
  style = "night",
  light_style = "day",
  transparent = true,
  cache = false,
})

local last_style

local function style_for_background()
  local forced_style = vim.env.DOT_THEME
  if forced_style == "dark" then
    return "night"
  elseif forced_style == "light" then
    return "day"
  end

  -- Neovim 0.11+ asks the host terminal for its background color via OSC 11
  -- and keeps vim.o.background updated, including after a runtime theme
  -- change. This works through SSH because the terminal is the host of the
  -- PTY, not the machine running the Neovim process.
  return vim.o.background == "light" and "day" or "night"
end

local function apply_theme()
  local style = style_for_background()
  if style == last_style then
    return
  end

  last_style = style
  if vim.env.DOT_THEME == "dark" or vim.env.DOT_THEME == "light" then
    vim.o.background = style == "day" and "light" or "dark"
  end
  vim.cmd.colorscheme("tokyonight-" .. style)
  vim.cmd("highlight StatusLine guibg=NONE")
end

local theme_group = vim.api.nvim_create_augroup("dot_theme", { clear = true })

-- The built-in OSC 11 handler intentionally uses :noautocmd when it updates
-- vim.o.background, so OptionSet alone cannot observe terminal theme changes.
-- TermResponse lets us reapply the TokyoNight variant after that response.
if vim.fn.has("nvim-0.11") == 1 then
  vim.api.nvim_create_autocmd("TermResponse", {
    group = theme_group,
    callback = function(event)
      local sequence = event.data and event.data.sequence
      if type(sequence) == "string" and sequence:match("^\027%]11;") then
        vim.schedule(apply_theme)
      end
    end,
  })
end

-- Also react to an explicit `:set background=...`.
vim.api.nvim_create_autocmd("OptionSet", {
  group = theme_group,
  pattern = "background",
  callback = apply_theme,
})

-- Give the initial UI attachment one opportunity to settle the
-- terminal-derived value.
vim.api.nvim_create_autocmd("UIEnter", {
  group = theme_group,
  callback = function()
    vim.schedule(apply_theme)
  end,
})

apply_theme()
