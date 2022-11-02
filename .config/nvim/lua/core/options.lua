local cmd = vim.cmd
local opt = vim.opt
local g = vim.g

cmd "syntax enable"
cmd "filetype plugin indent on"

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- search
opt.ignorecase = true
opt.smartcase = true

-- appearance
opt.termguicolors = true
opt.background = "dark"
opt.number = true
opt.relativenumber = true

-- backspace
opt.backspace = "indent,eol,start" 

-- split windows
opt.splitbelow = true
opt.splitright = true

-- clipboard
opt.clipboard:append("unnamedplus")

-- netrw
g.netrw_banner = 0
g.netrw_winsize = 20
g.netrw_localcopydircmd = "cp -r"
g.netrw_altv = 1
g.netrw_browse_split = 4
g.netrw_liststyle = 3

opt.mouse = ""
