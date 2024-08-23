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

        wk.add({
            -- Terminal
            { "<leader>c",   group = "code" },
            { "<leader>cf",  "<cmd>vsplit term://$SHELL<CR>",                            desc = "new terminal" },
            { "<leader>cp",  "<cmd>vsplit term://python<CR>",                            desc = "new python terminal" },

            -- Comment
            { "<leader>cg",  group = "Comments" },
            { "<leader>cgc", "<cmd>Neogen class<CR>",                                    desc = "class" },
            { "<leader>cgf", "<cmd>Neogen func<CR>",                                     desc = "func" },
            { "<leader>cgt", "<cmd>Neogen func<CR>",                                     desc = "type" },
            { "<leader>cgf", "<cmd>Neogen func<CR>",                                     desc = "file" },

            -- Telescope
            { "<leader>f",   group = "Find (telescope)" },
            { "<leader>cf",  "<cmd>Telescope find_files<CR>",                            desc = "files" },
            { "<leader>ch",  "<cmd>Telescope help_tags<CR>",                             desc = "help" },
            { "<leader>ck",  "<cmd>Telescope keymaps<CR>",                               desc = "keymaps" },
            { "<leader>cr",  "<cmd>Telescope oldfiles<CR>",                              desc = "old files" },
            { "<leader>cg",  "<cmd>Telescope live_grep<CR>",                             desc = "grep" },
            { "<leader>cb",  "<cmd>Telescope current_buffer_fuzzy_find<CR>",             desc = "fuzzy" },
            { "<leader>cm",  "<cmd>Telescope marks<CR>",                                 desc = "marks" },
            { "<leader>cM",  "<cmd>Telescope man_pages<CR>",                             desc = "man pages" },
            { "<leader>cs",  "<cmd>Telescope lsp_document_symbols<CR>",                  desc = "symbols" },
            { "<leader>cd",  "<cmd>Telescope buffers<CR>",                               desc = "buffers" },
            { "<leader>cq",  "<cmd>Telescope quickfix<CR>",                              desc = "quickfix" },
            { "<leader>cl",  "<cmd>Telescope loclist<CR>",                               desc = "loclist" },
            { "<leader>cj",  "<cmd>Telescope jumplist<CR>",                              desc = "marks" },

            -- Noice
            { "<leader>n",   group = "Noice (Notice)" },
            { "<leader>nl",  "<cmd>Noice last<CR>",                                      desc = "Noice Last Message" },
            { "<leader>nh",  "<cmd>Noice history<CR>",                                   desc = "Noice History" },
            { "<leader>na",  "<cmd>Noice all<CR>",                                       desc = "Noice All" },
            { "<leader>nd",  "<cmd>Noice dismiss<CR>",                                   desc = "Dismiss All" },

            -- Outline
            { "<leader>o",   group = "Outline" },
            { "<leader>ot",  "<cmd>AerialToggle!<CR>",                                   desc = "Toggle" },
            { "<leader>on",  "<cmd>AerialPrev<CR>",                                      desc = "Prev" },
            { "<leader>op",  "<cmd>AerialNext<CR>",                                      desc = "Next" },

            -- Vim
            { "<leader>v",   group = "Vim" },
            { "<leader>vt",  toggle_light_dark_theme,                                    desc = "switch theme" },
            { "<leader>vc",  "<cmd>Telescope colorscheme<CR>",                           desc = "colortheme" },
            { "<leader>vl",  "<cmd>Lazy<CR>",                                            desc = "Lazy" },
            { "<leader>vm",  "<cmd>Mason<CR>",                                           desc = "Mason" },
            { "<leader>vs",  "<cmd>e $MYVIMRC | <cmd>cd %:p:h | split . | wincmd k<CR>", desc = "Settings" },
            { "<leader>vh",  '<cmd>execute "h " .. expand("<cword>")<CR>',               desc = "help" },
        })
    end
}
