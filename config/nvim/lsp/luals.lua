return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc" },
  settings = {
    Lua = {
      -- make the language server recognize "vim" global
      diagnostics = {
        globals = { "vim", "require" },
      },
      runtime = {
        version = "LuaJIT",
      },
      workspace = {
        -- make language server aware of runtime files
        library = {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.stdpath("config") .. "/lua"] = true,
        },
      },
      signatureHelp = { enabled = true },
    },
  },
}
