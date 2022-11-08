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
})
packer.startup(function()
  use {"wbthomason/packer.nvim"}
  use {"nvim-treesitter/nvim-treesitter"}
  use {
    "hrsh7th/nvim-cmp",
    requires = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
    }
  }
  use {"neovim/nvim-lspconfig"}

  use {
    "ms-jpq/coq_nvim",
    requires = {
      "ms-jpq/coq.artifacts",
    }
  }

  use {
    "folke/noice.nvim",
    requires = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
      }
  }

  use {
    "hoob3rt/lualine.nvim",
    requires = {"kyazdani42/nvim-web-devicons", opt = true}
  }
  use {
    "lewis6991/gitsigns.nvim",
    requires = {"nvim-lua/plenary.nvim" }
  }
  use {
    "nvim-telescope/telescope.nvim",
    requires = {"nvim-lua/plenary.nvim"}
  }
  use {"glepnir/dashboard-nvim"}
  use {"sbdchd/neoformat"} -- Autoformat the code
  use {"windwp/nvim-autopairs"} -- Autopairing parentheses, quotes

  -- Colorscheme
  use {"catppuccin/nvim", as = "catppuccin"}
  use {
    "m-demare/hlargs.nvim",
    requires = { "nvim-treesitter/nvim-treesitter" }
  }

  use {"RRethy/vim-illuminate"} -- Highlight the words on the cursor
  use {"tpope/vim-surround"}
end)
