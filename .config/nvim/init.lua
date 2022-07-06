local function getCurrentDir()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end
package.path = package.path .. ";" .. getCurrentDir() .. "lua/?.lua"
package.path = package.path .. ";" .. getCurrentDir() .. "lua/?/init.lua"

if vim.fn.has("autocmd") then
	vim.api.nvim_exec([[au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]], false)
end

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

require("display")
require("keybindings")
require("autocmds")

local function directory_exist(dir_path)
  local f = io.popen('[ -d "' .. dir_path .. '" ] && echo y')
  local result = f:read(1)
  f:close()
  return result == "y"
end

local function requirePath(path) 
  if directory_exist("$HOME/dot") then
    files = io.popen('find $HOME/dot/.config/nvim/lua/' .. path .. ' -type f')
  elseif directory_exist("$XDG_CONFIG_HOME/dot") then
    files = io.popen('find $XDG_CONFIG_HOME/dot/.config/nvim/lua/' .. path .. ' -type f')
  elseif directory_exist("$XDG_CONFIG_DIRS/dot") then
    files = io.popen('find $XDG_CONFIG_DIRS/dot/.config/nvim/lua/' .. path .. ' -type f')
  elseif directory_exist("$XDG_DATA_HOME/dot") then
    files = io.popen('find $XDG_DATA_HOME/dot/.config/nvim/lua/' .. path .. ' -type f')
  elseif directory_exist("$XDG_DATA_DIRS/dot") then
    files = io.popen('find $XDG_DATA_HOME/dot/.config/nvim/lua/' .. path .. ' -type f')
  end

  for file in files:lines() do
    local req_file = file:gmatch('%/lua%/(.+).lua$'){0}:gsub('/', '.')
    status_ok, _ = pcall(require, req_file)
  end
end
requirePath("plugins")
requirePath("colors")
