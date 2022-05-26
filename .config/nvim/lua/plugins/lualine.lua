local cmd = vim.cmd
local g = vim.g
local opt = vim.opt

require"lualine".setup {
  options = {
    icons_enabled = false, -- Should change to true if has nerd fonts
    disabled_filetypes = {},
  },
  sections = {
    lualine_a = {"mode"},
    lualine_b = {
      {"branch"},
      {
        "diff",
        colored = true, -- displays diff status in color if set to true
        symbols = {added = "+", modified = "~", removed = "-"} -- changes diff symbols
      },
    },
    lualine_c = {"filename"},
    lualine_x = {"encoding", "fileicon", "filetype"},
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
