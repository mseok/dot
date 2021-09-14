function getCurrentDir()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end
package.path = package.path .. ";" .. getCurrentDir() .. "lua/?.lua"
package.path = package.path .. ";" .. getCurrentDir() .. "lua/?/init.lua"

if vim.fn.has("autocmd") then 
	vim.api.nvim_exec([[au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]], false)
end

require("keybindings")
require("plugins")
require("plugins/nvim_lsp")
require("plugins/cmp")
require("plugins/plugins")
require("plugins/treesitter")
require("colors")
require("colors/custom_highlight")
vim.cmd [[luafile $HOME/dot/.config/nvim/lua/plugins/init.lua]]
