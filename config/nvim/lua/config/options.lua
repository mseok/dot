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
vim.opt.autoindent = true
vim.wo.wrap = true
vim.cmd([[filetype plugin indent on]])

-- 1. Detect if we are in an SSH session or on a local Mac
local is_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
local is_mac = vim.fn.has("macunix") == 1

if is_mac and not is_ssh then
  -- CASE A: Local Mac (Fixes your current crash)
  vim.opt.clipboard = ""
elseif is_ssh then
  -- CASE B: SSH Environment
  vim.opt.clipboard = "unnamedplus"
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
else
  -- CASE C: Linux Local (Optional fallback)
  -- Standard behavior for local Linux machines
  vim.opt.clipboard = "unnamedplus"
end

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

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },
  virtual_text = true, -- show inline diagnostics
})
