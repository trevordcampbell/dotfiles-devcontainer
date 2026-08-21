# Portable interactive shell configuration for Linux development containers.

# Wunderbarcode publishes one root-owned toolchain PATH for every shell and editor
# subprocess. Source it when available instead of reconstructing or extending it.
if [[ -r /etc/profile.d/99-wunderbarcode-image-path.sh ]]; then
  source /etc/profile.d/99-wunderbarcode-image-path.sh
fi

export HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize

[[ -r "${HOME}/.fzf.bash" ]] && source "${HOME}/.fzf.bash"

if [[ $- == *i* && "${TERM:-}" != dumb ]]; then
  PS1='\[\e[1;36m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
fi
