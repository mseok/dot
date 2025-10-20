-- AI plugins configuration
-- This file configures GitHub Copilot integration using copilot-lsp

-- ============================================================
-- copilot-lsp - GitHub Copilot Integration
-- ============================================================
-- copilot-lsp provides a comprehensive LSP implementation for GitHub
-- Copilot, including inline completions and AI-powered suggestions

vim.g.copilot_nes_debounce = 500

local copilot_lsp = require("copilot-lsp")
copilot_lsp.setup({
    -- Server settings for copilot-language-server
    server = {
        settings = {
            telemetry = {
                telemetryLevel = "all",
            },
        },
        filetypes = { "py", "lua" }, -- Enable for specific file types
    },
    -- Inline completion settings
    inline_completion = {
        enable = true,
        auto_trigger = true,
    },
    -- NES (Next Edit Suggestions) settings
    nes = {
        move_count_threshold = 3, -- Clear NES after 3 cursor movements
    },
    -- Disable built-in keymap to use our custom keymaps below
    keymap = {
        preset = "none",
    },
})

vim.keymap.set({"n", "i"}, "<tab>", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local state = vim.b[bufnr].nes_state
    if state then
        local _ = require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit()
        return nil
    else
        -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
        return "<C-i>"
    end
end
)

-- -- ============================================================
-- -- Tab Keymaps for Next Edit Suggestions (NES) - Both Modes
-- -- ============================================================
-- -- Helper function to handle NES navigation
-- local function handle_nes_tab()
--     local bufnr = vim.api.nvim_get_current_buf()
--     local state = vim.b[bufnr].nes_state
--     if state then
--         -- Try to walk to start of next edit, or apply and move to end
--         local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
--             or (
--                 require("copilot-lsp.nes").apply_pending_nes()
--                 and require("copilot-lsp.nes").walk_cursor_end_edit()
--             )
--         return true
--     end
--     return false
-- end
-- 
-- local map = vim.keymap.set
-- 
-- -- Tab in normal mode: Navigate to next NES or apply if at start
-- map({ "n", "i" }, "<Tab>", function()
--     if handle_nes_tab() then
--         return
--     end
--     -- Fallback to normal Tab behavior
--     return "<Tab>"
-- end, { expr = true, desc = "Navigate/Apply Next Edit Suggestion" })
-- 
-- map({ "n", "i" }, "<S-Tab>", function()
--     local bufnr = vim.api.nvim_get_current_buf()
--     local state = vim.b[bufnr].nes_state
--     if state then
--         require("copilot-lsp.nes").walk_cursor_start_edit_backward()
--         return
--     end
--     -- Fallback
--     return "<S-Tab>"
-- end, { expr = true, desc = "Navigate to Previous Edit Suggestion" })
