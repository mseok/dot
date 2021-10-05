local cmd = vim.cmd
local g = vim.g
local opt = vim.opt

if vim.fn.has("termguicolors") then
  opt.termguicolors = true
end

cmd "colorscheme MscheMe"

require("indent_blankline").setup {
    char = "¦",
    show_trailing_blankline_indent = false,
}

local custom_gruvbox = require'lualine.themes.gruvbox'
local colors = {
  black   = "#1c1b19",
  white   = "#f8f6f2",
  red     = "#ff2c4b",
  green   = "#aeee31",
  yellow  = "#fade3d",
  magenta = "#a72e9c",
  orange  = "#ff875f",
  blue    = "#5fafff",
  pink    = "#ffafd7",
  cyan    = "#00d787",
}
custom_gruvbox.normal.a.bg = colors.pink
custom_gruvbox.insert.a.bg = colors.cyan
custom_gruvbox.visual.a.bg = colors.orange
custom_gruvbox.command.a.bg = colors.blue
custom_gruvbox.normal.b.fg = custom_gruvbox.normal.a.bg
custom_gruvbox.normal.c.fg = custom_gruvbox.normal.a.bg
custom_gruvbox.insert.c.bg = custom_gruvbox.normal.c.bg
custom_gruvbox.insert.b.fg = custom_gruvbox.insert.a.bg
custom_gruvbox.insert.c.fg = custom_gruvbox.insert.a.bg
custom_gruvbox.visual.c.bg = custom_gruvbox.normal.c.bg
custom_gruvbox.visual.b.fg = custom_gruvbox.visual.a.bg
custom_gruvbox.visual.c.fg = custom_gruvbox.visual.a.bg
custom_gruvbox.command.c.bg = custom_gruvbox.normal.c.bg
custom_gruvbox.command.b.fg = custom_gruvbox.command.a.bg
custom_gruvbox.command.c.fg = custom_gruvbox.command.a.bg

require"lualine".setup {
  options = {
    icons_enabled = true,
    theme = custom_gruvbox,
    component_separators = {"", ""},
    section_separators = {"", ""},
    disabled_filetypes = {}
  },
  sections = {
    lualine_a = {"mode"},
    lualine_b = {
      {"branch"},
      {
        "diff",
        colored = true, -- displays diff status in color if set to true
        -- all colors are in format #rrggbb
        color_added = colors.green, -- changes diff"s added foreground color
        color_modified = colors.yellow, -- changes diff"s modified foreground color
        color_removed = colors.red, -- changes diff"s removed foreground color
        symbols = {added = "+", modified = "~", removed = "-"} -- changes diff symbols
      },
    },
    lualine_c = {"filename"},
    lualine_x = {"encoding", "fileformat", "filetype"},
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
