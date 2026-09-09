if vim.fn.has("nvim-0.12") == 0 then
  vim.schedule(function()
    vim.notify(
      "This Neovim configuration requires Neovim 0.12+; run ./install.sh --upgrade",
      vim.log.levels.ERROR
    )
  end)
  return
end

local plugins = {
  { src = "https://github.com/folke/tokyonight.nvim" },
  { src = "https://github.com/chentoast/marks.nvim" },
  { src = "https://github.com/nvim-tree/nvim-tree.lua" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/nvim-telescope/telescope.nvim", version = vim.version.range("0.2") },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/nvim-mini/mini.pairs" },
  -- blink.cmp v2 split its shared runtime helpers into this dependency.
  { src = "https://github.com/Saghen/blink.lib" },
  { src = "https://github.com/Saghen/blink.cmp" },
  { src = "https://github.com/folke/sidekick.nvim" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
}

-- nvim-treesitter's current main branch and blink.cmp v2 are deliberate
-- Neovim 0.12+ migrations. The bootstrap installs the latest stable Neovim
-- on Linux; keep the Treesitter branches explicit because vim.pack does not
-- follow a changed upstream default branch automatically.
table.insert(plugins, {
  src = "https://github.com/nvim-treesitter/nvim-treesitter",
  version = "main",
})
table.insert(plugins, {
  src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  version = "main",
})

vim.pack.add(plugins)

vim.keymap.set("n", "<leader>u", "<cmd>lua vim.pack.update()<CR>", { desc = "Update Plugins" })

-- Load plugin configurations
require("plugins.ui")
require("plugins.editor")
require("plugins.lsp")
require("plugins.ai")
require("plugins.autocomplete")
require("plugins.git")
