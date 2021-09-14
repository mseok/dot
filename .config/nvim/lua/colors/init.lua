local cmd = vim.cmd
local g = vim.g
local opt = vim.opt

if vim.fn.has("termguicolors") then
  opt.termguicolors = true
end
-- cmd [[colorscheme edge]]
-- g.edge_disable_italic_comment = 0
-- g.edge_transparent_backgroud = 1
-- g.edge_current_word = "underline"
-- g.edge_better_performance = 1

-- cmd [[colorscheme modus-vivendi]]   -- Dark
-- -- cmd [[colorscheme modus-operandi]]  -- Light
-- g.modus_yellow_comments = 1
-- g.modus_green_strings = 1
-- g.modus_faint_syntax = 1
-- g.modus_termtrans_enable = 1

-- cmd [[colorscheme falcon]]

require('material').setup({
	contrast = true, -- Enable contrast for sidebars, floating windows and popup menus like Nvim-Tree
	borders = true, -- Enable borders between verticaly split windows
	italics = {
		comments = false, -- Enable italic comments
		keywords = false, -- Enable italic keywords
		functions = false, -- Enable italic functions
		strings = false, -- Enable italic strings
		variables = false -- Enable italic variables
	},
	text_contrast = {
		lighter = false, -- Enable higher contrast text for lighter style
		darker = true    -- Enable higher contrast text for darker style
	},
	disable = {
		background = false, -- Prevent the theme from setting the background (NeoVim then uses your teminal background)
		term_colors = false, -- Prevent the theme from setting terminal colors
		eob_lines = false -- Hide the end-of-buffer lines
	},
	custom_highlights = {} -- Overwrite highlights with your own
})
g.material_style = "darker"
cmd [[colorscheme material]]

require"lualine".setup {
  options = {
    icons_enabled = false,
    -- theme = "tokyonight",
    theme = 'material-nvim',
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
