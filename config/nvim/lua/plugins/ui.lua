-- Colorscheme configuration
require("tokyonight").setup({
    style = "storm",
    transparent = true,
    cache = false,
})
vim.cmd("colorscheme tokyonight")
vim.cmd("hi StatusLine guibg = NONE")
