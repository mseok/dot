-- Dashboard
vim.g.dashboard_default_executive = "telescope"
vim.g.dashboard_custom_section = {
  b = {description = {"  Recents                  <Space> f h"}, command="Telescope oldfiles"},
  a = {description = {"  Find File                <Space> f f"}, command="Telescope find_files"},
  c = {description = {"  Find Word                <Space> f w"}, command="Telescope live_grep"},
  d = {description = {"  New File                 <Space> n f"}, command="DashboardNewFile"},
  e = {description = {"  Change ColorScheme       <Space> c c"}, command="DashboardChangeColorscheme"},
  g = {description = {"  Update Plugins           <Space> u  "}, command="PackerUpdate"},
  i = {description = {"  Exit                     <Space> q  "}, command="exit"},
}

custom_map("n", "<leader>fh", ":Telescope oldfiles<CR>", {silent = true, noremap=true})
custom_map("n", "<leader>ff", ":Telescope find_files<CR>", {silent = true, noremap=true})
custom_map("n", "<leader>fw", ":Telescope live_grep<CR>", {silent = true, noremap=true})
custom_map("n", "<leader>nf", ":DashboardNewFile<CR>", {silent = true, noremap=true})
custom_map("n", "<leader>cc", ":DashboardChangeColorscheme<CR>", {silent = true, noremap=true})
custom_map("n", "<leader>u", ":PackerUpdate<CR>", {silent = true, noremap=true})
custom_map("n", "<leader>q", ":exit<CR>", {silent = true, noremap=true})
