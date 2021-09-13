if vim.fn.has("autocmd") then 
	vim.api.nvim_exec([[au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]], false)
end

require("color")
require("keybindings")
require("plugins/nvim_lsp")
require("plugins/cmp")
require("plugins/plugins")
require("plugins/treesitter")
