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

        keymap.set("n", "<leader>nf", function()
            neogen.generate({ type = "func" })
        end)
        keymap.set("n", "<leader>nt", function()
            neogen.generate({ type = "type" })
        end)
        keymap.set("n", "<leader>nc", function()
            neogen.generate({ type = "class" })
        end)

    end,
}
