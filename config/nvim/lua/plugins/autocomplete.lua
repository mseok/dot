-- Blink.cmp - LSP and basic completions
-- Uses traditional vim completion keys: <C-n>, <C-p>, <C-y>
-- AI completions (Copilot) use <Tab> (configured in ai.lua)
require("blink.cmp").setup({
    fuzzy = {
        implementation = "lua",
    },
    keymap = {
        preset = "enter",
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-y>"] = { "accept", "fallback" },
        ["<C-e>"] = { "hide", "fallback" },
        -- Disable Tab for blink.cmp to avoid conflicts with AI completions
        ["<Tab>"] = {},
        ["<S-Tab>"] = {},
    },
    completion = {
        menu = {
            auto_show = true,
        },
    },
})

