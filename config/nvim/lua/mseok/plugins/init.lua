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
            vim.cmd([[colorscheme catppuccin-mocha]])
        end,
    },

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
            vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
        end
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {} -- this is equalent to setup({}) function
    },
}
