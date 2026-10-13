# Dev Container dotfiles

Portable, deliberately small zsh configuration for Linux development containers.

The configuration:

- preserves the image-owned toolchain path in Bash without importing host paths;
- uses Oh My Zsh only when the image provides it;
- enables only the built-in `git` and `history` plugins;
- loads Powerlevel10k from the authenticated Wunderbarcode image path first, with conventional
  devcontainer fallbacks;
- reuses the existing Powerlevel10k prompt configuration;
- skips the Node version segment when `node` is Bun's compatibility symlink; and
- never assumes Homebrew, pyenv, macOS, iTerm2, or host-specific tool paths.

Configure Cursor or VS Code's **Dotfiles: Repository** setting to this repository URL and keep the
default target path of `~/dotfiles`. The Dev Containers dotfiles installer will link `.bashrc`,
`.zshrc`, and `.p10k.zsh` into the remote user's home directory.

The Node version segment remains enabled when a separate Node executable is
installed. Bun compatibility links are detected by their resolved executable path,
without launching a runtime or changing the image's toolchain.

Run the regressions inside a Linux devcontainer that supplies Zsh and
Powerlevel10k, with Bash, util-linux `script`, and GNU `timeout` available:

```sh
bash test-prompt-runtime.sh
bash test-shell-startup.sh
bash test-first-prompt-input.sh
```

These commands also work through plain `docker exec` or a headless test runner;
an existing terminal is not required. The startup test allocates a controlling
terminal when needed so Zsh job control and gitstatus initialize normally. It
checks the real Bash/Zsh configuration and preserves the installed toolchain paths.

The runtime-selection test records every stub invocation and requires an empty
log after each case, even if the prompt ignores a command's error status or output.
It covers Bun's Node alias, a separate Node executable, and a Node-only image.

The first-prompt regression launches interactive Zsh in a temporary home and
package directory. A fake Bun-backed Node command reproduces the offending probe's
input consumption. The test queues a command before the first prompt, requires
Powerlevel10k to be loaded, asserts that the command executed, and rejects any
runtime probe. It uses an evaluated output marker to distinguish execution from
terminal echo and a timeout to bound hangs. Temporary homes, logs, and fixtures
are removed on exit; installed dotfiles and runtimes are not changed.
