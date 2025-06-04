return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
    enabled = not vim.g.vscode,  -- Disable in VS Code
  },
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    enabled = not vim.g.vscode,  -- Disable in VS Code
    opts = {
      enabled = true,
      message_template = " <summary> • <date> • <author> • <<sha>>", -- template for the blame message, check the Message template section for more options
      date_format = "%Y-%m-%d", -- template for the date, check Date format section for more options
      virtual_text_column = 1, -- virtual text start column, check Start virtual text at column section for more options
    },
  },
}
