vim.pack.add({
	{ src = "https://github.com/folke/tokyonight.nvim" },
	{ src = "https://github.com/chentoast/marks.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter",        version = "main" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim",          version = "0.1.8" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/folke/sidekick.nvim" },
	{ src = "https://github.com/zbirenbaum/copilot.lua" },
	{ src = "https://github.com/nvim-mini/mini.pairs" },
	{ src = "https://github.com/Saghen/blink.cmp" },
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

-- Load plugin configurations
require("plugins.ui")
require("plugins.editor")
require("plugins.lsp")
require("plugins.autocomplete")
require("plugins.ai")
