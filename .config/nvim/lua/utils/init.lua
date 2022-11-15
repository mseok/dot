local M = {}

local cmd = vim.cmd
local api = vim.api

function M.quit()
  local bufnr = api.nvim_get_current_buf()
  local modified = api.nvim_buf_get_option(bufnr, "modified")
  if modified then
    vim.ui.input({
      prompt = "You have unsaved changes. Quit anyway? (y/n) ",
    }, function(input)
      if input == "y" then
        cmd "q!"
      end
    end)
  else
    cmd "q!"
  end
end

function M.reload_modules()
  local current_file = vim.fn.expand('%:p')
  local req_file = current_file:gmatch('%/lua%/(.+).lua$'){0}
  if not req_file then
    return
  end
  req_file = req_file:gsub('/', '.')

  local init_file = "init"
  if req_file:sub(-string.len(init_file)) == init_file then
    -- in case it is 'init.lua'
    for basename in req_file:gmatch("([^.]+)")
      do
        req_file = basename
        break
      end
  end

  require("plenary.reload").reload_module("plenary")
  require("plenary.reload").reload_module(req_file)
end

function M.copy_mode()
  status_ok, _ = pcall(require, "gitsigns")
  if status_ok then
    api.nvim_command("Gitsigns toggle_signs")
  end
  vim.opt.number = not(vim.o.number)
  vim.opt.relativenumber = not(vim.o.relativenumber)
end

function M.save_and_execute()
  cmd("silent! write")
  local filetype = vim.bo.filetype
  if filetype == "python" then
    cmd("!python %")
  elseif filetype == "bash" or filetype == "sh" then
    cmd("!bash %")
  elseif filetype == "lua" then
    print("sourced " .. vim.fn.expand("%:p"))
    cmd("luafile %")
    require('utils').reload_modules()
  end
end

return M
