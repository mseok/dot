return {
    "folke/flash.nvim",
    config = function()
        local flash = require("flash")

        flash.setup({
            search = {
                incremental = true,
            },
            modes = {
                search = {
                    enabled = false
                }
            },
        })

        vim.keymap.set("n", "s", flash.jump)
        vim.keymap.set("n", "S", flash.treesitter)
    end
}