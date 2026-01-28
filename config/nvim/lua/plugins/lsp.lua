-- LSP configuration
require("mason").setup({})

-- local servers = { "pyright", "ruff", "lua_ls", "bashls" }
local servers = { "ty", "ruff", "lua_ls", "bashls" }
require("mason-lspconfig").setup({
  ensure_installed = servers,
  automatic_installation = true, -- automatically install missing servers
})

-- Mason keymap
vim.keymap.set("n", "<leader>m", "<cmd>Mason<CR>")

-- Register LSP configs from lsp/ directory
local lsp_configs = {
  -- pyright = dofile(vim.fn.stdpath("config") .. "/lsp/pyright.lua"),
  ruff = dofile(vim.fn.stdpath("config") .. "/lsp/ruff.lua"),
  lua_ls = dofile(vim.fn.stdpath("config") .. "/lsp/lua_ls.lua"),
  bashls = dofile(vim.fn.stdpath("config") .. "/lsp/bashls.lua"),
  ty = dofile(vim.fn.stdpath("config") .. "/lsp/ty.lua"),
}

if vim.fn.executable("copilot-language-server") == 1 then
  lsp_configs.copilot = dofile(vim.fn.stdpath("config") .. "/lsp/copilot.lua")
else
  vim.notify(
    "copilot-language-server not found; Sidekick NES disabled until installed.",
    vim.log.levels.WARN
  )
end

for name, config in pairs(lsp_configs) do
  vim.lsp.config(name, config)
end

local enabled_servers = {
  -- "pyright",
  "ruff",
  "lua_ls",
  "bashls",
  "ty",
}

if lsp_configs.copilot then
  table.insert(enabled_servers, "copilot")
end

vim.lsp.enable(enabled_servers)

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(args)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = args.buf })
    vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format, { buffer = args.buf })
  end,
})

vim.cmd [[set completeopt+=menuone,noselect,popup]]

-- LSP keymaps
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>lr", builtin.lsp_references)
