local map = vim.keymap.set

-- Treesitter configuration (using new API for nvim-treesitter main branch)
-- Install parsers asynchronously (will be no-op if already installed)
require('nvim-treesitter').install({ "python", "bash", "lua", "vim", "vimdoc", "query" })

-- Enable treesitter highlighting and indentation using Neovim's built-in features
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local bufnr = args.buf
    -- Enable treesitter highlighting for this buffer
    pcall(vim.treesitter.start, bufnr)
    -- Enable treesitter-based indentation for this buffer
    vim.bo[bufnr].indentexpr = "v:lua.require('nvim-treesitter.indent').get_indent()"
  end,
})

-- Oil file manager
require("oil").setup({
	lsp_file_methods = {
		enabled = true,
		timeout_ms = 1000,
		autosave_changes = true,
	},
	columns = {
		"permissions",
		"icon",
	},
	float = {
		max_width = 0.7,
		max_height = 0.6,
		border = "rounded",
	},
})
map("n", "<leader>e", "<cmd>Oil<CR>")

-- Telescope
local telescope = require("telescope")
telescope.setup({
	defaults = {
		preview = { treesitter = false },
		color_devicons = true,
		sorting_strategy = "ascending",
		borderchars = {
			"─", -- top
			"│", -- right
			"─", -- bottom
			"│", -- left
			"┌", -- top-left
			"┐", -- top-right
			"┘", -- bottom-right
			"└", -- bottom-left
		},
		path_displays = { "smart" },
		layout_config = {
			height = 0.9,
			width = 0.9,
			prompt_position = "top",
			preview_cutoff = 40,
		}
	}
})

-- Telescope keymaps
local builtin = require("telescope.builtin")

map("n", "<leader>ff", builtin.find_files)
map("n", "<leader>fr", builtin.oldfiles)
map("n", "<leader>fh", builtin.help_tags)
map("n", "<leader>fm", builtin.man_pages)
map("n", "<leader>fg", builtin.live_grep)
map("n", "<leader>fb", builtin.buffers)
map("n", "<leader>r", builtin.registers)

-- Marks
require("marks").setup {
	builtin_marks = { "<", ">", "^" },
	refresh_interval = 250,
	sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
	excluded_filetypes = {},
	excluded_buftypes = {},
	mappings = {}
}
vim.keymap.set("n", "ma", "<cmd>MarksListAll<CR>")

-- Mini.pairs
require('mini.pairs').setup()
