-- Enable copilot for specific filetypes only
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python", "lua", "bash", },
    callback = function()
        vim.lsp.enable({"copilot_ls"})
    end
})

require("copilot").setup({
    suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        trigger_on_accept = true,
        keymap = {
            accept = "<Tab>",
            accept_word = false,
            accept_line = false,
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
        },
    },
    nes = {
        enabled = true, -- requires copilot-lsp as a dependency
        auto_trigger = true,
        keymap = {
          accept_and_goto = "<C-g>",
          accept = false,
          dismiss = "<Esc>",
        },
    },
    copilot_model = "claude-haiku-4.5",
    disable_limit_reached_message = false, -- Set to `true` to suppress completion limit reached popup
    root_dir = function()
        return vim.fs.dirname(vim.fs.find(".git", { upward = true })[1])
    end,
})
