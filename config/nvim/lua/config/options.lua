vim.g.mapleader = " "

vim.opt.mouse = ""
vim.g.autoformat = false

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.wo.wrap = true

if vim.g.vscode then
  vim.opt.clipboard = ""
else
  vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
end
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = function(lines)
      require("vim.ui.clipboard.osc52").copy("+")(lines)
    end,
  },
  paste = {
    ["+"] = function()
      return require("vim.ui.clipboard.osc52").paste("+")
    end,
  },
}

vim.opt.cursorline = true -- Enable highlighting of the current line
vim.opt.wildmode = "full"

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

if not vim.g.vscode then
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
else
end

-- Settings that should apply in both VS Code and regular Neovim
vim.opt.ignorecase = true
vim.opt.smartcase = true
