require("mseok.core.autocmds")
require("mseok.core.options")
require("mseok.core.remap")
require("mseok.core.keys")

if not vim.g.vscode then
    require("mseok.lazy")
end
