vim.g.mapleader = " "

-- Keep these in VS Code mode too - they're useful for navigation
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- VS Code specific setup
if vim.g.vscode then
  -- Add VS Code specific remaps here if needed
  -- general keymaps
  vim.keymap.set(
    { "n", "v" },
    "<leader>t",
    "<cmd>lua require('vscode').action('workbench.action.terminal.toggleTerminal')<CR>"
  )
  vim.keymap.set(
    { "n", "v" },
    "<leader>b",
    "<cmd>lua require('vscode').action('editor.debug.action.toggleBreakpoint')<CR>"
  )
  vim.keymap.set({ "n", "v" }, "<leader>a", "<cmd>lua require('vscode').action('editor.action.quickFix')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>sp", "<cmd>lua require('vscode').action('workbench.actions.view.problems')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>nd", "<cmd>lua require('vscode').action('notifications.clearAll')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>ff", "<cmd>lua require('vscode').action('workbench.action.quickOpen')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>cp", "<cmd>lua require('vscode').action('workbench.action.showCommands')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>pr", "<cmd>lua require('vscode').action('code-runner.run')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>cf", "<cmd>lua require('vscode').action('editor.action.formatDocument')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>hp", "<cmd>lua require('vscode').action('editor.action.closePnael')<CR>")

  -- harpoon keymaps
  vim.keymap.set({ "n", "v" }, "<leader>h", "<cmd>lua require('vscode').action('vscode-harpoon.addEditor')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>H", "<cmd>lua require('vscode').action('vscode-harpoon.editorQuickPick')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>he", "<cmd>lua require('vscode').action('vscode-harpoon.editEditors')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>h1", "<cmd>lua require('vscode').action('vscode-harpoon.gotoEditor1')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>h2", "<cmd>lua require('vscode').action('vscode-harpoon.gotoEditor2')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>h3", "<cmd>lua require('vscode').action('vscode-harpoon.gotoEditor3')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>h4", "<cmd>lua require('vscode').action('vscode-harpoon.gotoEditor4')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>h5", "<cmd>lua require('vscode').action('vscode-harpoon.gotoEditor5')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>h6", "<cmd>lua require('vscode').action('vscode-harpoon.gotoEditor6')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>h7", "<cmd>lua require('vscode').action('vscode-harpoon.gotoEditor7')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>h8", "<cmd>lua require('vscode').action('vscode-harpoon.gotoEditor8')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>h9", "<cmd>lua require('vscode').action('vscode-harpoon.gotoEditor9')<CR>")

  -- project manager keymaps
  vim.keymap.set({ "n", "v" }, "<leader>pa", "<cmd>lua require('vscode').action('projectManager.saveProject')<CR>")
  vim.keymap.set(
    { "n", "v" },
    "<leader>po",
    "<cmd>lua require('vscode').action('projectManager.listProjectsNewWindow')<CR>"
  )
  vim.keymap.set({ "n", "v" }, "<leader>pe", "<cmd>lua require('vscode').action('projectManager.editProjects')<CR>")
else
  -- These are for native Neovim only
  vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
  vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
  vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
  vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

  -- Paste with no register deletion
  vim.keymap.set("x", "<leader>p", '"_dP')

  -- Yank to system clipboard
  vim.keymap.set("n", "<leader>y", '"+y', { desc = "yank to system clipboard" })
  vim.keymap.set("v", "<leader>y", '"+y', { desc = "yank to system clipboard" })
  vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "yank line to system clipboard" })

  -- No register deletion
  vim.keymap.set("n", "<leader>d", '"_d', { desc = "No register deletion" })
  vim.keymap.set("v", "<leader>d", '"_d', { desc = "No register deletion" })

  vim.keymap.set("n", "<leader>bp", "<cmd>bp<CR>", { desc = "buffer previous" })
  vim.keymap.set("n", "<leader>bn", "<cmd>bn<CR>", { desc = "buffer next" })
  vim.keymap.set("n", "<leader>bd", "<cmd>bd<CR>", { desc = "buffer delete" })

  -- [,] mappings
  vim.keymap.set("n", "[b", "<cmd>bp<CR>", { desc = "buffer previous" })
  vim.keymap.set("n", "]b", "<cmd>bn<CR>", { desc = "buffer next" })
  vim.keymap.set("n", "[t", "<cmd>tabprevious<CR>", { desc = "tab previous" })
  vim.keymap.set("n", "]t", "<cmd>tabNext<CR>", { desc = "tab next" })

  -- Add undo break-points
  vim.keymap.set("i", ",", ",<c-g>u")
  vim.keymap.set("i", ".", ".<c-g>u")
  vim.keymap.set("i", ";", ";<c-g>u")

  -- better indenting
  vim.keymap.set("v", "<", "<gv")
  vim.keymap.set("v", ">", ">gv")

  -- terminal
  vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

  -- goto current file's directory
  vim.keymap.set("n", "<leader>cd", vim.cmd("cd " .. vim.fn.expand("%:p:h")))

  -- faster netrw
  vim.keymap.set("n", "<leader>e", ":Explore<CR>", { noremap = true, silent = true, desc = "Open Netrw file explorer" })
end
