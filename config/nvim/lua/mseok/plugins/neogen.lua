return {
    "danymat/neogen",

    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "L3MON4D3/LuaSnip",
    },

    event = "VeryLazy",

    config = function()
        local neogen = require("neogen")
        neogen.setup({
            snippet_engine = "luasnip",
            languages = {
                python = {
                    template = {
                        annotation_convention = "numpydoc" -- for a full list of annotation_conventions, see supported-languages below,
                    }
                },
            }
        })

        local keymap = vim.keymap
        keymap.set("n", "<leader>cgc", function()
            neogen.generate({ type = "func" })
        end, { desc = "Class comment" })
        keymap.set("n", "<leader>cgf", function()
            neogen.generate({ type = "type" })
        end, { desc = "Function comment" })
        keymap.set("n", "<leader>cgt", function()
            neogen.generate({ type = "class" })
        end, { desc = "Type comment" })

    end,
}
