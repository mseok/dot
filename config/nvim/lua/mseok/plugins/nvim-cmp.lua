return {
    "hrsh7th/nvim-cmp",

    branch = "main",

    -- event = "InsertEnter",

    dependencies = {
        "hrsh7th/cmp-buffer", -- source for text in buffer
        "hrsh7th/cmp-path", -- source for file system paths
        "hrsh7th/cmp-nvim-lsp", -- source for LSP
        "zbirenbaum/copilot-cmp", -- source for GitHub Copilot
        "L3MON4D3/LuaSnip", -- snippet engine
        "saadparwaiz1/cmp_luasnip", -- for autocompletion
        "rafamadriz/friendly-snippets", -- useful snippets
    },

    config = function()
        local cmp = require("cmp")

        local luasnip = require("luasnip")

        -- require("copilot_cmp").setup()

        local has_words_before = function()
            unpack = unpack or table.unpack
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
        end

        cmp.setup({
            completion = {
                completeopt = "menu,menuone,preview,noselect",
            },
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-p>"] = cmp.mapping.select_prev_item(), -- previous suggestion
                ["<C-n>"] = cmp.mapping.select_next_item(), -- next suggestion
                ["<C-f>"] = cmp.mapping.scroll_docs(-4),
                ["<C-d>"] = cmp.mapping.scroll_docs(4),
                ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                ["<C-space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.abort(), -- close completion window
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    elseif has_words_before() then
                        cmp.complete()
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
            }),
            -- sources for autocompletion
            sources = {
                { name = "otter" }, -- otter for quarto
                { name = "copilot" }, -- file system paths
                { name = "nvim_lsp" },
                { name = "luasnip" }, -- snippets
                { name = "buffer" }, -- text within current buffer
                { name = "path" }, -- file system paths
            },
        })

        -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
        require("luasnip.loaders.from_vscode").lazy_load()
        luasnip.filetype_extend("python", { "pydoc" })
        luasnip.filetype_extend("quarto", { "markdown" })
    end,
}
