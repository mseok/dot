return {
    {
        "catppuccin/nvim",
        priority = 1000, -- make sure to load this before all the other start plugins
        name = "catppuccin",
        config = function()
            -- load the colorscheme here
            require("catppuccin").setup({
                transparent_background = true
            })
            vim.api.nvim_set_hl(0, "NotifyBackground", { bg = "#000000" }) --nvim-notify
            -- vim.cmd([[colorscheme catppuccin-frappe]])
        end,
    },

    {
        "rose-pine/neovim",
        priority = 1000, -- make sure to load this before all the other start plugins
        name = "rose-pine",
        config = function()
            -- load the colorscheme here
            require("rose-pine").setup({
                styles = {
                    bold = true,
                    italic = true,
                    transparency = true,
                },
            })
            vim.api.nvim_set_hl(0, "NotifyBackground", { bg = "#000000" }) --nvim-notify
            vim.cmd([[colorscheme rose-pine]])
        end,
    },

    -- {
    --     "slugbyte/lackluster.nvim",
    --     lazy = false,
    --     priority = 1000,
    --     init = function()
    --         -- vim.cmd.colorscheme("lackluster")
    --         vim.cmd.colorscheme("lackluster-hack") -- my favorite
    --         -- vim.cmd.colorscheme("lackluster-mint")
    --     end,
    --     config = function()
    --         -- load the colorscheme here
    --         require("lackluster").setup({
    --             tweak_background = {
    --                 normal = 'default', -- main background
    --             }
    --         })
    --     end
    -- },

    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        }
    },

    -- {
    --     "f-person/auto-dark-mode.nvim",
    --     opts = {
    --         update_interval = 1000,
    --         set_dark_mode = function()
    --             vim.api.nvim_set_option_value("background", "dark", {})
    --             vim.cmd("colorscheme catppuccin-frappe")
    --         end,
    --         set_light_mode = function()
    --             vim.api.nvim_set_option_value("background", "light", {})
    --             vim.cmd("colorscheme catppuccin-latte")
    --         end,
    --     },
    -- },

    {
        "nvim-lua/plenary.nvim",
        name = "plenary",
        priority = 1000
    },

    -- Plugins that do not need many settings
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({})
        end,
    },
    {
        "mbbill/undotree",
        event = "VeryLazy",
        config = function()
            vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Undo tree" })
        end
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {} -- this is equalent to setup({}) function
    },
    {
        "LunarVim/bigfile.nvim",
    },
    {
        "folke/trouble.nvim",
        opts = {}, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            {
                "<leader>cs",
                "<cmd>Trouble symbols toggle focus=false<cr>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>cl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Location List (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Quickfix List (Trouble)",
            },
        },
    },
    {
        'stevearc/aerial.nvim',
        opts = {},
        -- Optional dependencies
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons"
        },
    }
}
