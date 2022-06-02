-- Dashboard
vim.g.dashboard_default_executive = "telescope"
vim.g.dashboard_executive = "telescope"
vim.g.dashboard_custom_section = {
  a = {
    description = { "Recents                  <Space> f h" },
    command="Telescope oldfiles"
  },
  b = {
    description = { "Find File                <Space> f f" },
    command="Telescope find_files"
  },
  c = {
    description = { "New File                 <Space> n f" },
    command="DashboardNewFile"
  },
  d = {
    description = { "Change ColorScheme       <Space> c c" },
    command="DashboardChangeColorscheme"
  },
  e = {
    description = { "Update Plugins           <Space> u  " },
    command="PackerUpdate"
  },
  f = {
    description = { "Exit                     q          " },
    command="exit"
  },
}
vim.g.dashboard_custom_footer = {""}

vim.api.nvim_set_keymap("n", "<leader>fh", ":Telescope oldfiles<CR>", {silent=true, noremap=true})
vim.api.nvim_set_keymap("n", "<leader>ff", ":Telescope find_files<CR>", {silent=true, noremap=true})
vim.api.nvim_set_keymap("n", "<leader>nf", ":DashboardNewFile<CR>", {silent=true, noremap=true})
vim.api.nvim_set_keymap("n", "<leader>cc", ":DashboardChangeColorscheme<CR>", {silent=true, noremap=true})
vim.api.nvim_set_keymap("n", "<leader>u", ":PackerUpdate<CR>", {silent=true, noremap=true})
vim.api.nvim_set_keymap("n", "q", ":exit<CR>", {silent=true, noremap=true})
