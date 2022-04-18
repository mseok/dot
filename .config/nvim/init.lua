local function getCurrentDir()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end
package.path = package.path .. ";" .. getCurrentDir() .. "lua/?.lua"
package.path = package.path .. ";" .. getCurrentDir() .. "lua/?/init.lua"

if vim.fn.has("autocmd") then
	vim.api.nvim_exec([[au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]], false)
end

local disabled_built_ins = {
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "getscript",
  "getscriptPlugin",
  "vimball",
  "vimballPlugin",
  "2html_plugin",
  "logipat",
  "rrhelper",
  "spellfile_plugin",
  "matchit"
}

for _, plugin in pairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

require("keybindings")
require("plugins")
require("plugins/nvim_lsp")
require("plugins/cmp")
require("plugins/treesitter")
require("plugins/gitsigns")
require("plugins/telescope")
require("plugins/bufferline")
require("plugins/dashboard")
require("plugins/autoformat")
require("plugins/indentline")
require("colors")
vim.cmd [[luafile $HOME/dot/.config/nvim/lua/plugins/init.lua]]
