-- autopairing
require("nvim-autopairs").setup({})

-- git
require("gitsigns").setup({
  signs = {
    add = { hl = "GitGutterAdd", text = "+" },
    change = { hl = "GitGutterChange", text = "~" },
    delete = { hl = "GitGutterDelete", text = "_" },
    topdelete = { hl = "GitGutterDelete", text = "‾" },
    changedelete = { hl = "GitGutterChange", text = "~" },
  },
})

function _G.copy_mode()
    vim.api.nvim_command("Gitsigns toggle_signs")
    vim.api.nvim_command("IndentBlanklineToggle")
end

-- indentline
vim.g.indent_blankline_char = '┊'
vim.g.indent_blankline_filetype_exclude = { 'help', 'packer' }
vim.g.indent_blankline_buftype_exclude = { 'terminal', 'nofile' }
vim.g.indent_blankline_char_highlight = 'LineNr'
vim.g.indent_blankline_show_trailing_blankline_indent = false

-- Autoformatting
vim.g.neoformat_basic_format_align = 1
vim.g.neoformat_basic_format_retab = 1
vim.g.neoformat_basic_format_trim = 1
vim.g.neoformat_enabled_python = {"flake8", "autopep8", "black"}
vim.api.nvim_exec([[autocmd FileType python noremap <leader>nf :Neoformat black<CR>]], false)

-- Glow
vim.g.glow_binary_path = vim.env.HOME .. "/dot/bin"
