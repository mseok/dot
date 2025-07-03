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

vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
vim.opt.cursorline = true -- Enable highlighting of the current line

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

vim.opt.showmode = true
vim.opt.updatetime = 50

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.g.netrw_browse_split = false
vim.g.netrw_winsize = 25

vim.opt.foldopen = "mark,percent,quickfix,search,tag,undo"

vim.keymap.set("n", "<leader>y", '"+y', { desc = "yank to system clipboard" })
vim.keymap.set(
"v",
"<leader>y",
'"+y',
{ desc = "yank to system clipboard in visual mode. You can combinate this like Vjj<leadyer>y." }
)

-- Settings that should apply in both VS Code and regular Neovim
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- LazyVim specific settings
vim.g.snacks_animate = false
vim.g.ai_cmp = false
vim.g.lazyvim_python_lsp = "pyright"
vim.g.lazyvim_python_ruff = "ruff"
