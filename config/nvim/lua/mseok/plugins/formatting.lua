return {
    "stevearc/conform.nvim",

    lazy = true,

    cmd = { "ConformInfo" },

    keys = {
        {
            -- Customize or remove this keymap to your liking
            "<leader>cf",
            function()
                require("conform").format({ async = true, lsp_fallback = true })
            end,
            mode = "",
            desc = "Format buffer",
        },
    },

    -- Everything in opts will be passed to setup()
    opts = {
        -- Define your formatters
        formatters_by_ft = {
            lua = { "stylua" },
            python = {
                -- To fix auto-fixable lint errors.
                "ruff_fix",
                -- To run the Ruff formatter.
                "ruff_format",
                -- To organize the imports.
                "ruff_organize_imports",
            },
            bash = { "shfmt" },
            zsh = { "beautysh" },
            sh = { "shfmt" },
        },
        -- Customize formatters
        formatters = {
            shfmt = {
                prepend_args = { "-i", "2" },
            },
        },
    },

    init = function()
        -- If you want the formatexpr, here is the place to set it
        vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
}

