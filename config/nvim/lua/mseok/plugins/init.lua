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
            vim.cmd([[colorscheme catppuccin-frappe]])
        end,
    },

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
        event = "VeryLazy",
        config = function()
            require("trouble").setup({
                icons = false,
            })
        end,
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
