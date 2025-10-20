-- LSP configuration
require("mason").setup({})

-- Mason keymap
vim.keymap.set("n", "<leader>m", "<cmd>Mason<CR>")

-- Register LSP configs from lsp/ directory
local lsp_configs = {
    pyright = dofile(vim.fn.stdpath("config") .. "/lsp/pyright.lua"),
    ruff = dofile(vim.fn.stdpath("config") .. "/lsp/ruff.lua"),
    lua_ls = dofile(vim.fn.stdpath("config") .. "/lsp/lua_ls.lua"),
    bashls = dofile(vim.fn.stdpath("config") .. "/lsp/bashls.lua"),
    copilot_ls = dofile(vim.fn.stdpath("config") .. "/lsp/copilot_ls.lua"),
}

for name, config in pairs(lsp_configs) do
    vim.lsp.config(name, config)
end

vim.lsp.enable({
    "pyright",
    "ruff",
    "lua_ls",
    "bashls",
    "copilot_ls",
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

-- LSP keymaps
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>lr", builtin.lsp_references)
