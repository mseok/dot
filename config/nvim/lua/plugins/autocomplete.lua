-- Blink.cmp
require("blink.cmp").setup({
    fuzzy = {
        implementation = "lua", -- or "prefer_rust" to try Rust first, then Lua
    },
})

