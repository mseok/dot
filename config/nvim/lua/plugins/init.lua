vim.pack.add({
  { src = "https://github.com/folke/tokyonight.nvim" },
  { src = "https://github.com/chentoast/marks.nvim" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter",             version = "master",       build = ":TSUpdate", lazy = false },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter" },
  { src = "https://github.com/nvim-telescope/telescope.nvim",               version = "0.1.8" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/nvim-mini/mini.pairs" },
  { src = "https://github.com/Saghen/blink.cmp" },
  { src = "https://github.com/NickvanDyke/opencode.nvim" },
  { src = "https://github.com/giuxtaposition/blink-cmp-copilot" },
  { src = "https://github.com/zbirenbaum/copilot.lua" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
})

vim.keymap.set("n", "<leader>u", "<cmd>lua vim.pack.update()<CR>", { desc = "Update Plugins" })

-- Load plugin configurations
require("plugins.ui")
require("plugins.editor")
require("plugins.lsp")
require("plugins.ai") -- Must load before autocomplete (copilot.lua before blink-cmp-copilot)
require("plugins.autocomplete")
require("plugins.git")
