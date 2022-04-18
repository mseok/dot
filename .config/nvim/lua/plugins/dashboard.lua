-- Dashboard
vim.g.dashboard_default_executive = "telescope"
vim.g.dashboard_custom_section = {
  b = {description = {"  Recents                  <leader> f h"}, command="Telescope oldfiles"},
  a = {description = {"  Find File                <leader> f f"}, command="Telescope find_files"},
  c = {description = {"  Find Word                <leader> f w"}, command="Telescope live_grep"},
  d = {description = {"  New File                 <leader> n f"}, command="DashboardNewFile"},
  e = {description = {"  Change ColorScheme       <leader> c c"}, command="DashboardChangeColorscheme"},
  g = {description = {"  Update Plugins           <leader> u  "}, command="PackerUpdate"},
  i = {description = {"  Exit                     <leader> q  "}, command="exit"},
}

custom_map("n", "<leader>fh", ":Telescope oldfiles<CR>", {silent = true, noremap=true})
custom_map("n", "<leader>ff", ":Telescope find_files<CR>", {silent = true, noremap=true})
custom_map("n", "<leader>fw", ":Telescope live_grep<CR>", {silent = true, noremap=true})
custom_map("n", "<leader>nf", ":DashboardNewFile<CR>", {silent = true, noremap=true})
custom_map("n", "<leader>cc", ":DashboardChangeColorscheme<CR>", {silent = true, noremap=true})
