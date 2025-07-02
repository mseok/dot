return {
  "neovim/nvim-lspconfig",

  event = "BufReadPre",

  dependencies = {
    "saghen/blink.cmp",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },

  config = function()
    -- Setup mason so it can manage external tooling
    require("mason").setup()

    -- Ensure the servers specified below are installed
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "pyright", "bashls" },
    })

    -- Diagnostic configuration
    vim.diagnostic.config({
      virtual_text = true,
      underline = true,
      update_in_insert = false,
    })

    -- LSP handlers
    vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      virtual_text = true,
      signs = true,
      underline = true,
      update_in_insert = false,
    })

    -- on_attach function for keymaps
    local on_attach = function(client, bufnr)
      local opts = { noremap = true, silent = true, buffer = bufnr }

      -- set keybinds
      opts.desc = "Show LSP references"
      vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

      opts.desc = "Go to declaration"
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

      opts.desc = "Show LSP definitions"
      vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

      opts.desc = "Show LSP implementations"
      vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

      opts.desc = "Show LSP type definitions"
      vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

      opts.desc = "See available code actions"
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

      opts.desc = "Smart rename"
      vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, opts)

      opts.desc = "Go to previous diagnostic"
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

      opts.desc = "Go to next diagnostic"
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

      opts.desc = "Show documentation for what is under cursor"
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

      opts.desc = "Restart LSP"
      vim.keymap.set("n", "<leader>ls", ":LspRestart<CR>", opts)

      opts.desc = "Signature Help"
      vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
    end

    -- Get capabilities for autocompletion
    local capabilities = require("blink.cmp").get_lsp_capabilities()

    -- Get the list of servers configured via mason-lspconfig
    local servers = require("mason-lspconfig").get_installed_servers()

    -- Loop through the servers and set them up with lspconfig
    for _, server_name in ipairs(servers) do
      local server_opts = {
        on_attach = on_attach,
        capabilities = capabilities,
        flags = {
          allow_incremental_sync = true,
          debounce_text_changes = 150,
        },
      }

      if server_name == "pyright" then
        local util = require("lspconfig.util")
        server_opts.root_dir = function(fname)
          return util.root_pattern(".git", "setup.py", "setup.cfg", "pyproject.toml", "requirements.txt")(fname)
            or util.path.dirname(fname)
        end
        server_opts.settings = {
          pyright = {
            analysis = {
              diagnosticMode = "openFilesOnly",
              exclude = { "data*/", "storage*/", "wandb*/", "nogit*/", "outputs*/", "sample*/", "analysis*/" },
              pythonVersion = "3.10",
              typeCheckingMode = "standard",
              diagnosticSeverityOverrides = {
                reportImplicitStringConcatenation = false,
                reportGeneralTypeIssues = "warning",
                reportDeprecated = "warning",
                reportUnusedVariable = false,
                reportUnusedImport = false,
              },
            },
          },
        }
      end

      if server_name == "lua_ls" then
        server_opts.settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.stdpath("config") .. "/lua"] = true,
              },
            },
          },
        }
      end

      require("lspconfig")[server_name].setup(server_opts)
    end
  end,
}
