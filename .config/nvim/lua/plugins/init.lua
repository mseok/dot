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
  use {"nvim-treesitter/playground"}
  use {"hrsh7th/cmp-nvim-lsp"}
  use {"hrsh7th/cmp-buffer"}
  use {"hrsh7th/cmp-path"}
  use {"saadparwaiz1/cmp_luasnip"}
  use {"hrsh7th/nvim-cmp"}
  use {"L3MON4D3/LuaSnip"}
	use {"neovim/nvim-lspconfig"}
  use {"projekt0n/github-nvim-theme"}
  use {"rktjmp/lush.nvim"}
  use {"~/dot/.config/nvim/lua/colors/MscheMe"}
  use {
    "hoob3rt/lualine.nvim",
    requires = {"kyazdani42/nvim-web-devicons", opt = true}
  }
  use {"windwp/nvim-autopairs"}
  use {"lukas-reineke/indent-blankline.nvim"}
  use {
    "lewis6991/gitsigns.nvim",
    requires = {
      "nvim-lua/plenary.nvim"
	  }
	}
  use {"nvim-treesitter/nvim-treesitter-textobjects"}
  use {"mhinz/vim-startify"}
  use {"sbdchd/neoformat"}
end)
