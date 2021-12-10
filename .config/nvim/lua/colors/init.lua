local cmd = vim.cmd
local g = vim.g
local opt = vim.opt

if vim.fn.has("termguicolors") then
  opt.termguicolors = true
end

local catppuccin = require("catppuccin")
catppuccin.setup(
    {
		transparent_background = false,
		term_colors = false,
		styles = {
			comments = "italic",
			functions = "bold",
			keywords = "italic",
			strings = "NONE",
			variables = "NONE",
		},
		integrations = {
			treesitter = true,
			native_lsp = {
				enabled = true,
				virtual_text = {
					errors = "italic",
					hints = "italic",
					warnings = "italic",
					information = "italic",
				},
				underlines = {
					errors = "underline",
					hints = "underline",
					warnings = "underline",
					information = "underline",
				},
			},
			gitsigns = true,
			indent_blankline = {
				enabled = true,
				colored_indent_levels = true,
			},
		},
	}
)
cmd "colorscheme catppuccin"
cmd [[hi! Visual guibg=#5024c1]]

require("indent_blankline").setup {
    char = "¦",
    show_trailing_blankline_indent = false,
    show_current_context = true,
    show_current_context_start = true,
    char_highlight_list = {
      "IndentBlanklineIndent1",
    }
}

require"lualine".setup {
  options = {
    icons_enabled = true,
    theme = "catppuccin",
    disabled_filetypes = {}
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
