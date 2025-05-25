return {
  -- intra-buffer
  {
    "folke/flash.nvim",

    event = "VeryLazy",

    opts = {
      modes = {
        search = {
          enabled = false,
        },
      },
    },

        -- stylua: ignore
        keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
            { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
            { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
            { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
        },
  },

  -- inter-buffer
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    config = function()
      local harpoon = require("harpoon")

      harpoon:setup()

      vim.keymap.set("n", "<leader>h", function()
        harpoon:list():add()
      end)
      vim.keymap.set("n", "<leader>H", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)

      for i = 1, 9, 1 do
        vim.keymap.set("n", "<leader>" .. tostring(i), function()
          harpoon:list():select(i)
        end)
      end

      vim.keymap.set("n", "<c-p>", function()
        harpoon:list():prev()
      end)
      vim.keymap.set("n", "<c-n>", function()
        harpoon:list():next()
      end)

      vim.api.nvim_create_autocmd({ "BufEnter" }, {
        desc = "Source ftplugin/$1.lua to override Issue #626",
        group = vim.api.nvim_create_augroup("Harpoon_Optlocal", { clear = true }),
        callback = function()
          local ft = vim.bo.filetype
          vim.cmd("silent! source ~/.config/nvim/after/ftplugin/" .. ft .. ".lua")
        end,
      })
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}
