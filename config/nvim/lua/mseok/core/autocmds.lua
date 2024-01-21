vim.api.nvim_create_autocmd("BufReadPost", {
    group = vim.api.nvim_create_augroup("last_loc", { clear = true }),
    callback = function(event)
        local exclude = { "gitcommit" }
        local buf = event.buf
        if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
            return
        end
        vim.b[buf].lazyvim_last_loc = true
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

function _G.save_and_execute()
    vim.cmd("silent! write")
    local filetype = vim.bo.filetype
    if filetype == "python" then
        vim.cmd("!python %")
    elseif filetype == "bash" then
        vim.cmd("!bash %")
    end
end

local autocmd_dict = {
    FileType = {
        {
            pattern = "python",
            callback = function()
                vim.bo.tabstop = 4
                vim.bo.shiftwidth = 4
                vim.api.nvim_set_keymap("n", "<C-s>", "<cmd>lua save_and_execute()<CR>", { noremap = true })
            end,
        },
        {
            pattern = "bash",
            callback = function()
                vim.api.nvim_set_keymap("n", "<C-s>", "<cmd>lua save_and_execute()<CR>", { noremap = true })
            end,
        },
    },
}

for event, opt_tbls in pairs(autocmd_dict) do
    for _, opt_tbl in pairs(opt_tbls) do
        vim.api.nvim_create_autocmd(event, opt_tbl)
    end
end
