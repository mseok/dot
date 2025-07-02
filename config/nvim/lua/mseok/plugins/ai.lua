return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    enabled = not vim.g.vscode, -- Disable in VS Code - VS Code has its own Copilot
    config = function()
      require("copilot").setup({
        copilot_model = "gpt-4.1",
        -- copilot_model = "claude-sonnet-4",
      })
    end,
  },

  {
    "GeorgesAlkhouri/nvim-aider",
    cmd = "Aider",
    -- Example key mappings for common actions:
    keys = {
      { "<leader>a/", "<cmd>Aider toggle<cr>", desc = "Toggle Aider" },
      { "<leader>as", "<cmd>Aider send<cr>", desc = "Send to Aider", mode = { "n", "v" } },
      { "<leader>ac", "<cmd>Aider command<cr>", desc = "Aider Commands" },
      { "<leader>ab", "<cmd>Aider buffer<cr>", desc = "Send Buffer" },
      { "<leader>a+", "<cmd>Aider add<cr>", desc = "Add File" },
      { "<leader>a-", "<cmd>Aider drop<cr>", desc = "Drop File" },
      { "<leader>ar", "<cmd>Aider add readonly<cr>", desc = "Add Read-Only" },
      { "<leader>aR", "<cmd>Aider reset<cr>", desc = "Reset Session" },
      { "<leader>a+", "<cmd>AiderTreeAddFile<cr>", desc = "Add File from Tree to Aider", ft = "NvimTree" },
      { "<leader>a-", "<cmd>AiderTreeDropFile<cr>", desc = "Drop File from Tree from Aider", ft = "NvimTree" },
      { "<C-h>", "<C-\\><C-n><C-w>h", desc = "Navigate to left window in terminal", mode = "t" },
      { "<C-j>", "<C-\\><C-n><C-w>j", desc = "Navigate to bottom window in terminal", mode = "t" },
      { "<C-k>", "<C-\\><C-n><C-w>k", desc = "Navigate to top window in terminal", mode = "t" },
      { "<C-l>", "<C-\\><C-n><C-w>l", desc = "Navigate to right window in terminal", mode = "t" },
    },
    dependencies = {
      {
        "nvim-neo-tree/neo-tree.nvim",
        opts = function(_, opts)
          opts.window = {
            mappings = {
              ["+"] = { "nvim_aider_add", desc = "add to aider" },
              ["-"] = { "nvim_aider_drop", desc = "drop from aider" },
              ["="] = { "nvim_aider_add_read_only", desc = "add read-only to aider" },
            },
          }
          require("nvim_aider.neo_tree").setup(opts)
        end,
      },
    },
    config = true,
  },

  {
    "greggh/claude-code.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for git operations
    },
    config = function()
      require("claude-code").setup()
    end,
  },
}
