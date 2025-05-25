return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({})
    end,
  },

  {
    "olimorris/codecompanion.nvim",

    cmd = {
      "CodeCompanion",
      "CodeCompanionActions",
      "CodeCompanionChat",
      "CodeCompanionCmd",
    },

    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "codecompanion" },
      },
    },

    keys = {
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
      { "<leader>ac", "<cmd>CodeCompanionChat<cr>", mode = "n", desc = "CodeCompanion Chat" },
      { "<leader>ac", "<cmd>CodeCompanionChat<cr>", mode = "v", desc = "CodeCompanion Chat with selection" },
      { "<leader>ai", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "CodeCompanion Inline" },
      { "<leader>at", "<cmd>CodeCompanionChat Toggle<cr>", mode = "n", desc = "Toggle CodeCompanion Chat" },
    },

    opts = {
      language = "English",
      adapters = {
        copilot = function()
          return require("codecompanion.adapters").extend("copilot", {
            schema = {
              model = {
                -- default = "o4-mini"
                -- default = "claude-3.7-sonnet",
                -- default = "Gemini-2.0-Flash"
                default = "claude-sonnet-4",
              },
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "copilot",
        },
        inline = {
          adapter = "copilot",
        },
      },
      display = {
        diff = {
          enabled = true,
          close_chat_at = 240,
          layout = "horizontal",
          opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
          provider = "default",
        },
      },
    },
  },
}
