local function toggle_light_dark_theme()
    if vim.o.background == "light" then
        vim.o.background = "dark"
        require("catppuccin").setup({
            transparent_background = true
        })
        vim.cmd([[Catppuccin mocha]])
    else
        vim.o.background = "light"
        require("catppuccin").setup({
            transparent_background = false
        })
        vim.cmd([[Catppuccin latte]])
    end
end

return {
    "folke/which-key.nvim",

    event = "VeryLazy",

    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
    end,

    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    },

    config = function()
        local wk = require("which-key")

        wk.register({
            c = {
                name = "code",
                n = { ":vsplit term://$SHELL<CR>", "new terminal" },
                p = { ":vsplit term://python<CR>", "new python terminal" },
                g = {
                    name = "Comments",
                    c = { "<cmd>Neogen class<CR>", "class" },
                    f = { "<cmd>Neogen func<CR>", "func" },
                    t = { "<cmd>Neogen type<CR>", "type" },
                    F = { "<cmd>Neogen file<CR>", "file" }
                }
            },
            f = {
                name = "find (telescope)",
                f = { "<cmd>Telescope find_files<CR>", "files" },
                h = { "<cmd>Telescope help_tags<CR>", "help" },
                k = { "<cmd>Telescope keymaps<CR>", "keymaps" },
                r = { "<cmd>Telescope oldfiles<CR>", "old files" },
                g = { "<cmd>Telescope live_grep<CR>", "grep" },
                b = { "<cmd>Telescope current_buffer_fuzzy_find<CR>", "fuzzy" },
                m = { "<cmd>Telescope marks<CR>", "marks" },
                M = { "<cmd>Telescope man_pages<CR>", "man pages" },
                s = { "<cmd>Telescope lsp_document_symbols<CR>", "symbols" },
                d = { "<cmd>Telescope buffers<CR>", "buffers" },
                q = { "<cmd>Telescope quickfix<CR>", "quickfix" },
                l = { "<cmd>Telescope loclist<CR>", "loclist" },
                j = { "<cmd>Telescope jumplist<CR>", "marks" },
            },
            g = {
                name = "git",
                c = { ":GitConflictRefresh<CR>", "conflict" },
                g = { ":Neogit<CR>", "neogit" },
                s = { ":Gitsigns<CR>", "gitsigns" },
                b = {
                    name = "blame",
                    b = { ":GitBlameToggle<CR>", "toggle" },
                    o = { ":GitBlameOpenCommitURL<CR>", "open" },
                    c = { ":GitBlameCopyCommitURL<CR>", "copy" },
                },
            },
            n = {
                name = "noice",
                l = { ":Noice last<CR>", "Noice Last Message" },
                h = { ":Noice history<CR>", "Noice History" },
                a = { ":Noice all<CR>", "Noice All" },
                d = { ":Noice dismiss<CR>", "Dismiss All" },
            },
            o = {
                name = "Outline",
                t = { "<cmd>AerialToggle!<CR>", "Toggle" },
                n = { "<cmd>AerialPrev<CR>", "Prev" },
                p = { "<cmd>AerialNext<CR>", "Next" },
            },
            t = {
                name = "trouble",
                t = { require("trouble").toggle, "toggle" },
                -- n = { require("trouble").next({skip_groups = true, jump = true}), "next" },
                -- p = { require("trouble").prev({skip_groups = true, jump = true}), "previous" },
            },
            v = {
                name = "vim",
                t = { toggle_light_dark_theme, "switch theme" },
                c = { ":Telescope colorscheme<CR>", "colortheme" },
                l = { ":Lazy<CR>", "Lazy" },
                m = { ":Mason<CR>", "Mason" },
                s = { ":e $MYVIMRC | :cd %:p:h | split . | wincmd k<CR>", "Settings" },
                h = { ':execute "h " .. expand("<cword>")<CR>', "help" },
            },
        }, { mode = "n", prefix = "<leader>" })
    end
}
