return {
    "danymat/neogen",

    event = "VeryLazy",

    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "L3MON4D3/LuaSnip",
    },

    config = function()
        local neogen = require("neogen")
        neogen.setup({
            snippet_engine = "luasnip",
            languages = {
                python = {
                    template = {
                        -- for a full list of annotation_conventions, see supported-languages below,
                        annotation_convention = "numpydoc"
                    }
                },
            }
        })
    end,
}
