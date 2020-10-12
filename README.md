# dot
dot files for my work space

## Files
Currently contains...
- `.bashrc`
- `.init.vim`
- `.tmux.conf`
- `tmux-keep-zoom`
- `tmux-resize-screen`
Setting file for the bash
- `.bashrc`
Setting file for neovim
- `.init.vim`
Setting file for tmux
- `.tmux.conf`
- `tmux-keep-zoom`
- `tmux-resize-screen`


## Usage
Clone this repository to your home directory (check with "echo $HOME" command in shell).

`install.sh` file move the dot files in this repository to your home directory.
The default shell rc setting is based on `bash`, so if you use other shell such as `zsh`,
you should change several settings in `bashrc`.

To install neovim with `install_nvim.sh`, you need `curl` and `pip`.
After installing neovim, you should install `pynvim` and `jedi` via conda or pip.
