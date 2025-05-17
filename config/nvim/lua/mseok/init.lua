require("mseok.core.autocmds")
require("mseok.core.options")
require("mseok.core.remap")
require("mseok.core.keys")

require("mseok.lazy")

-- lsp
if not vim.g.vscode then
    -- Enable LSP servers for Neovim 0.11+
    vim.lsp.enable {
        "basedpyright", -- Python
        "bashls",       -- Bash
        "lua_ls",       -- Lua
    }
end
