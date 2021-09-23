local cmd = vim.cmd
local g = vim.g
local opt = vim.opt

if vim.fn.has("termguicolors") then
  opt.termguicolors = true
end

cmd "colorscheme MscheMe"

require"lualine".setup {
  options = {
    icons_enabled = false,
    theme = "github",
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
