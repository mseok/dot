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
  package_root = util.join_paths(fn.stdpath("data"), "site", "pack")
})
packer.startup(function()
  use {"wbthomason/packer.nvim"}
	use {"nvim-treesitter/nvim-treesitter"}
  use {"hrsh7th/nvim-cmp"}
  use {"hrsh7th/cmp-buffer"}
  use {"hrsh7th/cmp-path"}
  use {"hrsh7th/cmp-nvim-lsp"}
  use {"saadparwaiz1/cmp_luasnip"}
  use {"L3MON4D3/LuaSnip"}
	use {"neovim/nvim-lspconfig"}
  use {"folke/tokyonight.nvim"}
  use {"sainnhe/edge"}
  use {"ishan9299/modus-theme-vim"}
  use {"fenetikm/falcon"}
  use {"marko-cerovac/material.nvim"}
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
  use {"nvie/vim-flake8"}
end)
