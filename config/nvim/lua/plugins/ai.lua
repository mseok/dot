return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  build = ":Copilot auth",
  event = "InsertEnter",
  dependencies = { "giuxtaposition/blink-cmp-copilot" },
  opts = {
    suggestion = {
      enabled = not vim.g.ai_cmp,
      auto_trigger = true,
      hide_during_completion = vim.g.ai_cmp,
      keymap = {
        accept = "<Tab>", -- handled by nvim-cmp / blink.cmp
        accept_word = false,
        accept_line = false,
        next = "<C-j>",
        prev = "<C-k>",
        dismiss = "<C-e>",
      },
    },
    panel = { enabled = false },
    filetypes = {
      markdown = true,
      help = true,
    },
  },
}
