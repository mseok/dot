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

vim.keymap.set("n", "<leader>y", '"+y', { desc = "yank to system clipboard" })
vim.keymap.set("v", "<leader>y", '"+y',
    { desc = "yank to system clipboard in visual mode. You can combinate this like Vjj<leadyer>y." })

vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
        ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
        ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
        ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
}

-- statusline
function _G.current_mode()
    local modes = {
        ['n'] = 'NORMAL',
        ['i'] = 'INSERT',
        ['v'] = 'VISUAL',
        ['V'] = 'V-LINE',
        [''] = 'V-BLOCK',
        ['c'] = 'COMMAND',
        ['R'] = 'REPLACE',
        ['s'] = 'SELECT',
        ['S'] = 'S-LINE',
        [''] = 'S-BLOCK',
        ['t'] = 'TERMINAL',
    }
    local mode_code = vim.fn.mode()
    return ' ' .. (modes[mode_code] or mode_code) .. ' '
end

function _G.macro_recording()
    local reg = vim.fn.reg_recording()
    if reg ~= '' then
        return 'Recording @' .. reg
    end
    return ''
end

vim.o.statusline = "%{v:lua.current_mode()}%f %y %m %= %{v:lua.macro_recording()} %l:%c %p%%"
