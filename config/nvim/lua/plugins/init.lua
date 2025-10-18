vim.pack.add({
	{ src = "https://github.com/folke/tokyonight.nvim" },
	{ src = "https://github.com/chentoast/marks.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter",        version = "main" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim",          version = "0.1.8" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/folke/sidekick.nvim.git" },
	{ src = "https://github.com/zbirenbaum/copilot.lua.git" },
	{ src = "https://github.com/nvim-mini/mini.pairs.git" },
	{ src = "https://github.com/Saghen/blink.cmp.git" },
})

local function pack_clean()
	local active_plugins = {}
	local unused_plugins = {}

	for _, plugin in ipairs(vim.pack.get()) do
		active_plugins[plugin.spec.name] = plugin.active
	end

	for _, plugin in ipairs(vim.pack.get()) do
		if not active_plugins[plugin.spec.name] then
			table.insert(unused_plugins, plugin.spec.name)
		end
	end

	if #unused_plugins == 0 then
		print("No unused plugins.")
		return
	end

	local choice = vim.fn.confirm("Remove unused plugins?", "&Yes\n&No", 2)
	if choice == 1 then
		vim.pack.del(unused_plugins)
	end
end

vim.keymap.set("n", "<leader>pc", pack_clean)

-- colorscheme
require("tokyonight").setup({
    style = "night",
    transparent = false,
    cache = false,
})
vim.cmd("colorscheme tokyonight-night")
vim.cmd("hi StatusLine guibg = NONE")

require("mason").setup({})

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
			height = 100,
			width = 400,
			prompt_position = "top",
			preview_cutoff = 40,
		}
	}
})

vim.lsp.enable({
    "pyright",
    "ruff",
    "lua_ls",
    "bash-language-server",
    "copilot-language-server",
})

vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('my.lsp', {}),
	callback = function(args)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = args.buf })
        vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format, { buffer = args.buf })
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		if client:supports_method('textDocument/completion') then
			-- Optional: trigger autocompletion on EVERY keypress. May be slow!
			local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
			client.server_capabilities.completionProvider.triggerCharacters = chars
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end
	end,
})
vim.cmd [[set completeopt+=menuone,noselect,popup]]

require("marks").setup {
	builtin_marks = { "<", ">", "^" },
	refresh_interval = 250,
	sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
	excluded_filetypes = {},
	excluded_buftypes = {},
	mappings = {}
}
require('mini.pairs').setup()

-- Common
local map = vim.keymap.set
vim.g.sidekick_nes = false
-- NOTE: HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- Marks
vim.keymap.set("n", "ma", "<cmd>MarksListAll<CR>")

-- Telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files)
vim.keymap.set("n", "<leader>fr", builtin.oldfiles)
vim.keymap.set("n", "<leader>fh", builtin.help_tags)
vim.keymap.set("n", "<leader>fm", builtin.man_pages)
vim.keymap.set("n", "<leader>fg", builtin.live_grep)
vim.keymap.set("n", "<leader>fb", builtin.buffers)
vim.keymap.set("n", "<leader>r", builtin.registers)

vim.keymap.set("n", "<leader>lr", builtin.lsp_references)

vim.keymap.set("n", "<leader>e", "<cmd>Oil<CR>")
vim.keymap.set("n", "<leader>m", "<cmd>Mason<CR>")

-- AI
require("copilot").setup({
    -- suggestion = {
    --     enabled = not vim.g.ai_cmp,
    --     auto_trigger = true,
    --     hide_during_completion = vim.g.ai_cmp,
    --     keymap = {
    --         accept = "<Tab>", -- handled by nvim-cmp / blink.cmp
    --         accept_word = false,
    --         accept_line = false,
    --         next = "<C-j>",
    --         prev = "<C-k>",
    --         dismiss = "<C-e>",
    --     },
    -- },
    -- panel = { enabled = false },
    -- filetypes = {
    --     markdown = true,
    --     help = true,
    -- },
})

vim.g.sidekick_nes = true
require("sidekick").setup()
require("blink.cmp").setup({
    accept_key = "<Tab>",
    enable_auto_trigger = true,
    nes = {enabled = true},
    keymap = {
      ["<Tab>"] = {
        "snippet_forward",
        function() -- sidekick next edit suggestion
          return require("sidekick").nes_jump_or_apply()
        end,
        function() -- if you are using Neovim's native inline completions
          return vim.lsp.inline_completion.get()
        end,
        "fallback",
      },
    },
})
