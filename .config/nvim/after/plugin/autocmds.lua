local api = vim.api
local cmd = vim.cmd
local keymap = vim.keymap

local autocmd_dict = {
  FileType = {
    {
      pattern = "markdown,txt",
      callback = function()
        api.nvim_win_set_option(0, "spell", true)
      end,
    },
    {
      pattern = "help,lspinfo,qf,startuptime",
      callback = function()
        keymap.set("n", "q", "<cmd>close<CR>", {silent = true})
      end,
    },
    {
      pattern = "python",
      callback = function()
        keymap.set("n", "<leader>s", "<cmd>lua require('utils').save_and_execute()<CR>", {noremap=true})
        keymap.set("n", "<leader>nf", "<cmd>Neoformat black<CR>", {noremap=true})
      end
    },
    {
      pattern = "lua",
      callback = function()
        keymap.set("n", "<leader>s", "<cmd>lua require('utils').save_and_execute()<CR>", {noremap=true})
      end
    },
    {
      pattern = "bash,sh",
      callback = function()
        keymap.set("n", "<leader>s", "<cmd>lua require('utils').save_and_execute()<CR>", {noremap=true})
      end
    },
  },
  BufReadPost = {
    {
      pattern = "*",
      callback = function()
        api.nvim_exec([[if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]], false)
      end
    }
  }
}

for event, opt_tbls in pairs(autocmd_dict) do
  for _, opt_tbl in pairs(opt_tbls) do
    api.nvim_create_autocmd(event, opt_tbl)
  end
end
