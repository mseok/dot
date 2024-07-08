vim.g.map_leader = " "

vim.opt.mouse = ""
vim.g.autoformat = false

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.wo.wrap = true

vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    },
    paste = {
        ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    },
}
vim.opt.cursorline = true         -- Enable highlighting of the current line

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.g.netrw_browse_split = false
vim.g.netrw_winsize = 25
