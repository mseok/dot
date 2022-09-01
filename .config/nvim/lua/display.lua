local scopes = {o = vim.o, b = vim.bo, w = vim.wo}
function opt(scope, key, value)
  scopes[scope][key] = value
  if scope ~= "o" then scopes["o"][key] = value end
end

local indent = 2
vim.cmd "syntax enable"
vim.cmd "filetype plugin indent on"
opt("b", "expandtab", true)
opt("b", "smartindent", true)
opt("b", "tabstop", indent)
opt("b", "shiftwidth", indent)
opt("o", "hidden", true)
opt("o", "splitbelow", true)
opt("o", "splitright", true)
opt("o", "clipboard","unnamed,unnamedplus")
opt("o", "laststatus", 3)
opt("o", "cmdheight", 2)
vim.g.shada = "$XDG_DATA_HOME/nvim/shada/main.shada"

-- netrw
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 20
vim.g.netrw_localcopydircmd = "cp -r"
