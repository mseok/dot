-- Dashboard
local home = os.getenv("HOME")
local dashboard = require("dashboard")

dashboard.custom_center = {
  {
    icon = '',
    desc = 'Recently Opened Files                   ',
    action =  'Telescope oldfiles hidden=true',
    shortcut = '<Space> f h'
  },
  {
    icon = '',
    desc = 'New File                                ',
    action =  'DashboardNewFile',
    shortcut = '<Space> n f'
  },
  {
    icon = '',
    desc = 'Find File                               ',
    action = 'Telescope find_files hidden=true',
    shortcut = '<Space> f f'
  },
  {
    icon = '',
    desc = 'Open Personal dotfiles                  ',
    action = 'Telescope dotfiles path=' .. home ..'/dot/.config/nvim/',
    shortcut = '<Space> f d'
  },
}

