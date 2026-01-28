-- Blink.cmp - LSP completions
require("blink.cmp").setup({
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  fuzzy = {
    implementation = "lua",
  },
  keymap = {
    ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
    ["<C-n>"] = { "select_next", "fallback_to_mappings" },
    ["<C-y>"] = { "select_and_accept", "fallback" },
    ["<C-e>"] = { "cancel", "fallback" },
    ["<Tab>"] = {
      "snippet_forward",
      function()
        return require("sidekick").nes_jump_or_apply()
      end,
      function()
        if vim.lsp.inline_completion then
          return vim.lsp.inline_completion.get()
        end
      end,
      "fallback",
    },
  },
  completion = {
    menu = {
      auto_show = true,
    },
  },
  appearance = {
    kind_icons = {
      Text = "󰉿",
      Method = "󰊕",
      Function = "󰊕",
      Constructor = "󰒓",
      Field = "󰜢",
      Variable = "󰆦",
      Property = "󰖷",
      Class = "󱡠",
      Interface = "󱡠",
      Struct = "󱡠",
      Module = "󰅩",
      Unit = "󰪚",
      Value = "󰦨",
      Enum = "󰦨",
      EnumMember = "󰦨",
      Keyword = "󰻾",
      Constant = "󰏿",
      Snippet = "󱄽",
      Color = "󰏘",
      File = "󰈔",
      Reference = "󰬲",
      Folder = "󰉋",
      Event = "󱐋",
      Operator = "󰪚",
      TypeParameter = "󰬛",
    },
  },
})
