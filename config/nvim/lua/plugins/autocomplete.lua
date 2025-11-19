-- Blink.cmp - LSP and basic completions
require("blink.cmp").setup({
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  fuzzy = {
    implementation = "lua",
  },
  keymap = {
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<C-y>"] = { "accept", "fallback" },
    ["<C-e>"] = { "hide", "fallback" },
    ["<Tab>"] = {
      -- 1. jump forward in snippets if possible
      function(cmp)
        return cmp.snippet_active() and cmp.snippet_forward()
      end,
      -- 2. accept Copilot ghost text if visible (prioritize in insert mode)
      function(cmp)
        local ok, s = pcall(require, "copilot.suggestion")
        if ok and s.is_visible() then
          s.accept()
          return true
        end
      end,
      -- 3. invoke sidekick's NES jump/apply if available
      function(cmp)
        local ok, sidekick = pcall(require, "sidekick")
        return ok and sidekick.nes_jump_or_apply()
      end,
      -- 4. otherwise fall back to normal tab
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

-- Make ghost text readable with your colorscheme
vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#6C7086", italic = true })
