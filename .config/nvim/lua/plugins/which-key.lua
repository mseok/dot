local M = {}

local whichkey = require "which-key"

local next = next

local conf = {
  window = {
    border = "single", -- none, single, double, shadow
    position = "bottom", -- bottom, top
  },
}
whichkey.setup(conf)

local function normal_keymap()
  local opts = {
    mode = "n", -- Normal mode
    prefix = "<leader>",
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
  }

  local keymap = {
    ["w"] = { "<cmd>update!<CR>", "Save" },
    ["q"] = { "<cmd>lua require('utils').quit()<CR>", "Quit" },

    b = {
      name = "Buffer",
      n = { "<cmd>bn<CR>", "Next Buffer" },
      p = { "<cmd>bp<CR>", "Prev Buffer" },
      d = { "<cmd>bd<CR>", "Delete Buffer" },
    },

    f = {
      name = "Find",
      f = { "<cmd>lua require('utils.finder').find_files()<CR>", "Find Files" },
      d = { "<cmd>lua require('utils.finder').find_dotfiles()<CR>", "Find Dotfiles" },
      b = { "<cmd>lua require('utils.finder').find_buffers()<CR>", "Find Buffers" },
      h = { "<cmd>lua require('utils.finder').find_history()<CR>", "Old Files" },
    },

    z = {
      name = "System",
      i = { "<cmd>PackerInstall<CR>", "Packer Install" },
      p = { "<cmd>PackerProfile<CR>", "Packer Profile" },
      s = { "<cmd>PackerSync<CR>", "Packer Sync" },
      S = { "<cmd>PackerStatus<CR>", "Packer Status" },
      u = { "<cmd>PackerUpdate<CR>", "Packer Update" },
      c = { "<cmd>PackerCompile<CR>", "Packer Compile" },
    },

    t = {
      name = "Toggle",
      a = { "<cmd>lua require('utils').copy_mode()<CR>", "Toggle All" },
      t = { "<cmd>lua require('utils.term').open_term()<CR>", "Toggle Terminal" },
    },

    g = {
      name = "Git",
      h = { "<cmd>Gitsigns preview_hunk<CR>", "Preview Git Hunk" },
      n = { "<cmd>Gitsigns prev_hunk<CR>", "Git next hunk" },
      p = { "<cmd>Gitsigns next_hunk<CR>", "Git prev hunk" },
    },
  }
  whichkey.register(keymap, opts)
end

function M.setup()
  normal_keymap()
end

return M
