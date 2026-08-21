# Dev Container dotfiles

Portable, deliberately small zsh configuration for Linux development containers.

The configuration:

- preserves the image-owned toolchain path in Bash without importing host paths;
- uses Oh My Zsh only when the image provides it;
- enables only the built-in `git` and `history` plugins;
- loads Powerlevel10k from the authenticated Wunderbarcode image path first, with conventional
  devcontainer fallbacks;
- reuses the existing Powerlevel10k prompt configuration; and
- never assumes Homebrew, pyenv, macOS, iTerm2, or host-specific tool paths.

Configure Cursor or VS Code's **Dotfiles: Repository** setting to this repository URL and keep the
default target path of `~/dotfiles`. The Dev Containers dotfiles installer will link `.bashrc`,
`.zshrc`, and `.p10k.zsh` into the remote user's home directory.

Run the startup contract inside a compatible devcontainer with:

```sh
bash test-shell-startup.sh
```
