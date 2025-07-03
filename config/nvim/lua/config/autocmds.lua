-- VS Code specific setup
if vim.g.vscode then
  -- Minimal autocmds for VS Code
  -- Highlight on yank
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
    callback = function()
      vim.highlight.on_yank()
    end,
  })
  
  -- Add any VS Code specific autocmds here
else
  function _G.save_and_execute()
    vim.cmd("silent! write")
    local filetype = vim.bo.filetype
    if filetype == "python" then
      vim.cmd("!python %")
    elseif filetype == "bash" then
      vim.cmd("!bash %")
    end
  end

  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
  local autocmd_dict = {
    FileType = {
      {
        pattern = "python",
        callback = function()
          vim.bo.tabstop = 4
          vim.bo.shiftwidth = 4
          vim.api.nvim_set_keymap("n", "<C-s>", "<cmd>lua save_and_execute()<CR>", { noremap = true })
          vim.fn.setreg("l", 'yoprint("DEBUG: ' .. esc .. "pa:" .. esc .. 'A", ' .. esc .. "pA)" .. esc)
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

  -- LSP (use previous gd convention instead of C-](tagfunc))
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LspConfig", {}),
    callback = function(ev)
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc="Go to definition" })
    end,
  })
end
