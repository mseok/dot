-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

function _G.save_and_execute()
  vim.cmd("silent! write")
  local filetype = vim.bo.filetype
  if filetype == "python" then
    vim.cmd("!python %")
  elseif filetype == "bash" then
    vim.cmd("!bash %")
  elseif filetype == "lua" then
    vim.cmd("luafile %")
  end
end

local autocmd_dict = {
  FileType = {
    {
      pattern = "python",
      callback = function()
        vim.bo.tabstop = 4
        vim.bo.shiftwidth = 4
        vim.api.nvim_set_keymap("n", "<C-s>", "<cmd>lua save_and_execute()<CR>", { noremap = true })
      end,
    },
    {
      pattern = "lua",
      callback = function()
        vim.api.nvim_set_keymap("n", "<C-s>", "<cmd>lua save_and_execute()<CR>", { noremap = true })
      end,
    },
    {
      pattern = "bash",
      callback = function()
        vim.api.nvim_set_keymap("n", "<C-s>", "<cmd>lua save_and_execute()<CR>", { noremap = true })
      end,
    },
  },
}

for event, opt_tbls in pairs(autocmd_dict) do
  for _, opt_tbl in pairs(opt_tbls) do
    vim.api.nvim_create_autocmd(event, opt_tbl)
  end
end
