return {
    "neovim/nvim-lspconfig",

    event = "BufReadPre",

    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
    },

    config = function()
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = { "lua_ls", "basedpyright", "bashls" },
        })

        vim.diagnostic.config({
            virtual_text = true,
            underline = true,
            update_in_insert = false,
        })

        -- import lspconfig plugin
        local lspconfig = require("lspconfig")
        local util = require("lspconfig.util")

        -- import cmp-nvim-lsp plugin
        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        local keymap = vim.keymap -- for conciseness

        local opts = { noremap = true, silent = true }

        local on_attach = function(client, bufnr)
            opts.buffer = bufnr

            -- set keybinds
            opts.desc = "Show LSP references"
            keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

            opts.desc = "Go to declaration"
            keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

            opts.desc = "Show LSP definitions"
            keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

            opts.desc = "Show LSP implementations"
            keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

            opts.desc = "Show LSP type definitions"
            keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

            opts.desc = "See available code actions"
            keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

            opts.desc = "Smart rename"
            keymap.set("n", "<leader>lr", vim.lsp.buf.rename, opts) -- smart rename

            opts.desc = "Go to previous diagnostic"
            keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

            opts.desc = "Go to next diagnostic"
            keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

            opts.desc = "Show documentation for what is under cursor"
            keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

            opts.desc = "Restart LSP"
            keymap.set("n", "<leader>ls", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

            opts.desc = "Signature Help"
            keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts) -- show signature help
        end

        local lsp_flags = {
            allow_incremental_sync = true,
            debounce_text_changes = 150,
        }

        vim.lsp.handlers["textDocument/publishDiagnostics"] =
            vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
                virtual_text = true,
                signs = true,
                underline = true,
                update_in_insert = false,
            })

        -- used to enable autocompletion (assign to every lsp server config)
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
        capabilities.textDocument.completion.completionItem.snippetSupport = true
        -- See https://github.com/neovim/neovim/issues/23291
        if capabilities.workspace == nil then
            capabilities.workspace = {}
            capabilities.workspace.didChangeWatchedFiles = {}
        end
        capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

        -- configure python server
        lspconfig["basedpyright"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            flags = lsp_flags,
            root_dir = function(fname)
                return util.root_pattern(".git", "setup.py", "setup.cfg", "pyproject.toml", "requirements.txt")(
                    fname
                ) or util.path.dirname(fname)
            end,
            settings = {
                basedpyright = {
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
            },
        })

        -- configure bash server
        lspconfig["bashls"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })

        -- configure lua server (with special settings)
        lspconfig["lua_ls"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = { -- custom settings for lua
                Lua = {
                    -- make the language server recognize "vim" global
                    diagnostics = {
                        globals = { "vim" },
                    },
                    workspace = {
                        -- make language server aware of runtime files
                        library = {
                            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                            [vim.fn.stdpath("config") .. "/lua"] = true,
                        },
                    },
                },
            },
        })
    end,
}
