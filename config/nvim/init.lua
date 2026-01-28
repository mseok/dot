vim.env.VIRTUAL_ENV = nil

require("config/options")
require("config/keymaps")
require("config/autocmds")

if not vim.g.vscode then
  require("plugins")
end
