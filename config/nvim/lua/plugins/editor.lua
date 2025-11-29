local map = vim.keymap.set

-- Treesitter configuration (using new API for nvim-treesitter main branch)
-- Install parsers asynchronously (will be no-op if already installed)
require("nvim-treesitter.configs").setup({
  ensure_installed = { "python", "bash", "lua", "vim", "vimdoc", "query" },
  highlight = { enable = true },

  textobjects = {
    select = {
      enable = true,

      -- Automatically jump forward to textobj if cursor is before it
      lookahead = true,

      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",

        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",

        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",

        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",

        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",

        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",

        ["acm"] = "@comment.outer",
      },
    },
  },
})

-- Oil file manager
require("oil").setup({
  lsp_file_methods = {
    enabled = true,
    timeout_ms = 1000,
    autosave_changes = true,
  },
  columns = {
    "permissions",
    "icon",
  },
  float = {
    max_width = 0.7,
    max_height = 0.6,
    border = "rounded",
  },
})
map("n", "<leader>e", "<cmd>Oil<CR>")

-- Telescope
local telescope = require("telescope")
telescope.setup({
  defaults = {
    preview = { treesitter = false },
    color_devicons = true,
    sorting_strategy = "ascending",
    borderchars = {
      "─", -- top
      "│", -- right
      "─", -- bottom
      "│", -- left
      "┌", -- top-left
      "┐", -- top-right
      "┘", -- bottom-right
      "└", -- bottom-left
    },
    path_displays = { "smart" },
    layout_config = {
      height = 0.9,
      width = 0.9,
      prompt_position = "top",
      preview_cutoff = 40,
    }
  }
})

-- Telescope keymaps
local builtin = require("telescope.builtin")

map("n", "<leader>ff", builtin.find_files)
map("n", "<leader>fr", builtin.oldfiles)
map("n", "<leader>fh", builtin.help_tags)
map("n", "<leader>fm", builtin.man_pages)
map("n", "<leader>fg", builtin.live_grep)
map("n", "<leader>fb", builtin.buffers)
map("n", "<leader>r", builtin.registers)

map("n", "<leader>x", "<cmd>lua vim.diagnostic.setloclist()<CR>")

-- Marks
require("marks").setup {
  builtin_marks = {},
  refresh_interval = 250,
  sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
  excluded_filetypes = {},
  excluded_buftypes = {},
  mappings = {}
}
vim.keymap.set("n", "ma", "<cmd>MarksListAll<CR>")

-- Mini.pairs
require('mini.pairs').setup()
