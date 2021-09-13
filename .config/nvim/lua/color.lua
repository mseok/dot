local cmd = vim.cmd

vim.opt.termguicolors = true
-- vim.cmd[[colorscheme badwolf]]
vim.g.tokyonight_colors = { fg = "#f8f6f2", bg = "#242321" }
vim.cmd[[colorscheme tokyonight]]
-- vim.g.tokyonight_style == "day"
vim.g.tokyonight_style = "night"
vim.g.tokyonight_italic_comments = false
vim.g.tokyonight_italic_keywords = false

require"lualine".setup {
  options = {
    icons_enabled = false,
    theme = "tokyonight",
    component_separators = {" "},
    section_separators = {" "},
    disabled_filetypes = {}
  },
  sections = {
    lualine_a = {"mode"},
    lualine_b = {"branch"},
    lualine_c = {"filename"},
    lualine_x = {"encoding", "fileformat", "filename", "filetype"},
    lualine_y = {"progress"},
    lualine_z = {"location"}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {"filename"},
    lualine_x = {"location"},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {}
}
