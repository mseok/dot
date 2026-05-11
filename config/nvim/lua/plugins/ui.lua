require("tokyonight").setup({
  style = "night",
  light_style = "day",
  transparent = true,
  cache = false,
})

vim.cmd.colorscheme("tokyonight")
vim.cmd("highlight StatusLine guibg=NONE")
