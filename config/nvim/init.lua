vim.env.VIRTUAL_ENV = nil

require("vim._core.ui2").enable({})

require("config/options")
require("config/keymaps")
require("config/autocmds")

if not vim.g.vscode then
  require("plugins")
end
