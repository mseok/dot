-- Blink.cmp - LSP and basic completions
require("blink.cmp").setup({
  fuzzy = {
    implementation = "lua",
  },
  keymap = {
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<C-y>"] = { "accept", "fallback" },
    ["<C-e>"] = { "hide", "fallback" },
    ["<Tab>"] = {
      -- jump forward in snippets if possible
      function(cmp)
        return cmp.snippet_active() and cmp.snippet_forward()
      end,
      -- invoke your sidekick’s jump/apply
      function(cmp)
        local ok, sidekick = pcall(require, "sidekick")
        return ok and sidekick.nes_jump_or_apply()
      end,
      -- accept Copilot ghost text if visible
      function(cmp)
        local ok, s = pcall(require, "copilot.suggestion")
        if ok and s.is_visible() then
          s.accept()
          return true
        end
      end,
      -- otherwise fall back
      "fallback",
    },
  },
  completion = {
    menu = {
      auto_show = true,
    },
    keyword_length = 1,
  },
})

vim.api.nvim_create_autocmd("User", {
  pattern = "BlinkCmpMenuOpen",
  callback = function() vim.b.copilot_suggestion_hidden = true end,
})
vim.api.nvim_create_autocmd("User", {
  pattern = "BlinkCmpMenuClose",
  callback = function() vim.b.copilot_suggestion_hidden = false end,
})

-- Make ghost text readable with your colorscheme
vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#6C7086", italic = true })
