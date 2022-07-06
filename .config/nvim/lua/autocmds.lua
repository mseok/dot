-- Autocmd
-- vim.api.nvim_exec([[autocmd FileType python nnoremap <C-i> :w<CR>:!python %<CR>]], false)
-- vim.api.nvim_exec([[autocmd FileType python set tabstop=4 shiftwidth=4]], false)
-- vim.api.nvim_exec([[autocmd User Startified setlocal cursorline]], false)

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
      pattern = "markdown,txt",
      callback = function()
        vim.api.nvim_win_set_option(0, "spell", true)
      end,
    },
    {
      pattern = "help,lspinfo,qf,startuptime",
      callback = function()
        vim.api.nvim_set_keymap("n", "q", "<cmd>close<CR>", {silent = true})
      end,
    },
    {
      pattern = "python",
      callback = function()
        vim.bo.tabstop = 4
        vim.bo.shiftwidth = 4
        vim.api.nvim_set_keymap("n", "<C-s>", "<cmd>lua save_and_execute()<CR>", {noremap=true})
      end
    },
    {
      pattern = "lua",
      callback = function()
        vim.api.nvim_set_keymap("n", "<C-s>", "<cmd>lua save_and_execute()<CR>", {noremap=true})
      end
    },
    {
      pattern = "bash",
      callback = function()
        vim.api.nvim_set_keymap("n", "<C-s>", "<cmd>lua save_and_execute()<CR>", {noremap=true})
      end
    },
  }
}

for event, opt_tbls in pairs(autocmd_dict) do
  for _, opt_tbl in pairs(opt_tbls) do
    vim.api.nvim_create_autocmd(event, opt_tbl)
  end
end
