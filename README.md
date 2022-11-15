## dot
Dot files for my work spaces.

## Usage
- Clone this repository at the `$HOME` directory. 
- Add `source $HOME/dot/.config/bash/.bashrc` to your bash configuration file or add `source $HOME/dot/.config/zsh/.zshrc` to your zsh configuration file if you use zsh.
- Use `stow` (install GNU `stow` or conda `stow`) to configure nvim with `stow -d $HOME/dot/.config/ -t $HOME/config/nvim/ nvim`.
