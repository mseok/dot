local disabled_built_ins = {
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "getscript",
  "getscriptPlugin",
  "vimball",
  "vimballPlugin",
  "2html_plugin",
  "logipat",
  "rrhelper",
  "spellfile_plugin",
  "matchit"
}

for _, plugin in pairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

local fn = vim.fn
local api = vim.api

local install_path = fn.stdpath("data").."/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({"git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path})
  vim.cmd "packadd packer.nvim"
end

local packer = require"packer"
local util = require"packer.util"

packer.init({
  package_root = util.join_paths(fn.stdpath("data"), "site", "pack"),
  git = {
      clone_timeout = 300, -- 5 mins
  },
  profile = {
      enable = true,
  },
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
})
packer.startup(function()
  use {"wbthomason/packer.nvim"}
  use {
    "nvim-treesitter/nvim-treesitter",
    config = function()
      require("plugins.treesitter")
    end
  }
  use {
    "hrsh7th/nvim-cmp",
    requires = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      require("plugins.nvim-cmp")
    end
  }
  use {
    "neovim/nvim-lspconfig",
    config = function()
      require("plugins.nvim-lspconfig")
    end
  }

  use {
    "hoob3rt/lualine.nvim",
    requires = {"kyazdani42/nvim-web-devicons", opt = true},
    config = function()
      require("plugins.lualine")
    end
  }
  use {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("plugins.gitsigns")
    end
  }
  use {
    "nvim-telescope/telescope.nvim",
    requires = {"nvim-lua/plenary.nvim"},
    config = function()
      require("plugins.telescope")
    end
  }
  use {
    "glepnir/dashboard-nvim",
    config = function()
      require("plugins.dashboard-nvim")
    end
  }
  use {
    "sbdchd/neoformat",
    config = function()
      require("plugins.neoformat")
    end
  }
  use {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup{}
    end
  } -- Autopairing parentheses, quotes

  use {"akinsho/toggleterm.nvim", tag = '*', config = function()
    require("toggleterm").setup()
  end}

  -- Colorscheme
  use {"catppuccin/nvim", as = "catppuccin"}

  use {"RRethy/vim-illuminate"} -- Highlight the words on the cursor
  use {"tpope/vim-surround"}

  use {
    "folke/which-key.nvim",
    event = "VimEnter",
    module = { "which-key" },
    config = function()
      require("plugins.which-key").setup()
    end,
    disable = false,
  }
end)

require "utils"
