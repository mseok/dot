vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
function _G.save_and_execute()
  vim.cmd("silent! write")
  local filetype = vim.bo.filetype
  if filetype == "python" then
    vim.cmd("!python %")
  elseif filetype == "bash" then
    vim.cmd("!bash %")
  end
end

local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
local autocmd_dict = {
  FileType = {
    {
      pattern = "python",
      callback = function()
        vim.bo.tabstop = 4
        vim.bo.shiftwidth = 4
        vim.api.nvim_set_keymap("n", "<C-s>", "<cmd>lua save_and_execute()<CR>", { noremap = true })
        vim.fn.setreg("l", 'yoprint("DEBUG] ' .. esc .. "pa:" .. esc .. '$i, ' .. esc .. 'p')
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

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark_pos = vim.api.nvim_buf_get_mark(0, '"')
    local line = mark_pos[1]
    local col = mark_pos[2]
    local line_count = vim.api.nvim_buf_line_count(0)

    if line > 0 and line <= line_count then
      -- Set the cursor to the exact position stored in the '"' mark
      vim.api.nvim_win_set_cursor(0, { line, col })
    end
  end,
})

-- Automatically change directory to the file's directory
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local path = vim.fn.expand("%:p:h")
    if vim.fn.isdirectory(path) == 1 then
      vim.cmd("lcd " .. path)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "q", ":lclose<CR>", { buffer = true, silent = true })
  end,
})
