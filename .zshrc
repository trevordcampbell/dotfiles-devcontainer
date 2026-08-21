# Portable interactive shell configuration for Linux development containers.

export ZSH="${ZSH:-${HOME}/.oh-my-zsh}"
ZSH_THEME=""
plugins=(git history)

if [[ -r "${ZSH}/oh-my-zsh.sh" ]]; then
  source "${ZSH}/oh-my-zsh.sh"
fi

# Prefer the authenticated Wunderbarcode image installation, then the conventional
# Oh My Zsh custom-theme and system-wide locations used by other devcontainers.
powerlevel10k_candidates=(
  /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme
  "${ZSH_CUSTOM:-${ZSH}/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme"
  /usr/share/powerlevel10k/powerlevel10k.zsh-theme
)
for powerlevel10k_theme in "${powerlevel10k_candidates[@]}"; do
  if [[ -r "${powerlevel10k_theme}" ]]; then
    source "${powerlevel10k_theme}"
    break
  fi
done
unset powerlevel10k_candidates powerlevel10k_theme

p10k_config="${ZDOTDIR:-${HOME}}/.p10k.zsh"
[[ -r "${p10k_config}" ]] && source "${p10k_config}"
unset p10k_config

[[ -r "${HOME}/.fzf.zsh" ]] && source "${HOME}/.fzf.zsh"
