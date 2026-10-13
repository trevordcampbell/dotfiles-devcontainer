#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for tool in script timeout zsh; do
  command -v "$tool" >/dev/null || { echo "First-prompt test requires $tool" >&2; exit 1; }
done
scratch="$(mktemp -d)"
trap 'rm -rf -- "${scratch}"' EXIT
mkdir "${scratch}/bin" "${scratch}/home" "${scratch}/project"
cp "${repo_root}/.zshrc" "${scratch}/home/.zshrc"
cp "${repo_root}/.p10k.zsh" "${scratch}/home/.p10k.zsh"
printf '%s\n' '{"name":"prompt-regression","version":"1.0.0"}' >"${scratch}/project/package.json"

# Model the offending Bun-backed node probe: consume queued terminal input.
# A log makes any probe a failure even if a future shell masks its exit status
# or happens to recover the input. No installed runtime or dotfile is changed.
cat >"${scratch}/bin/bun" <<'RUNTIME'
#!/bin/sh
printf '%s\n' "$0 $*" >>"$PROBE_LOG"
IFS= read -r ignored || true
printf '%s\n' 'v0.0.0'
RUNTIME
chmod +x "${scratch}/bin/bun"
ln -s bun "${scratch}/bin/node"
: >"${scratch}/probes"

export PROMPT_TEST_HOME="${scratch}/home"
export PROMPT_TEST_PROJECT="${scratch}/project"
export PROMPT_TEST_PATH="${scratch}/bin:/usr/bin:/bin"
export PROMPT_TEST_ZSH="${ZSH:-${HOME}/.oh-my-zsh}"
export PROMPT_TEST_USER="$(id -un)"
export PROMPT_TEST_LOG="${scratch}/probes"

# Queue a command before the first prompt, rather than using zsh -c (which
# never draws a prompt). Its evaluated marker cannot match terminal echo.
# Require a loaded theme, so a missing Powerlevel10k cannot give a false pass.
if ! printf '%s\n' \
  'if [[ -n ${P9K_VERSION:-} ]]; then print -r -- FIRST_INPUT_EXECUTED_"$((20 + 7))"; else print -r -- MISSING_THEME; fi; exit' | \
  timeout --kill-after=2s 10s script -q -e -c '
    cd "$PROMPT_TEST_PROJECT"
    exec env -i HOME="$PROMPT_TEST_HOME" ZDOTDIR="$PROMPT_TEST_HOME" \
      PATH="$PROMPT_TEST_PATH" ZSH="$PROMPT_TEST_ZSH" \
      USER="$PROMPT_TEST_USER" LOGNAME="$PROMPT_TEST_USER" \
      SHELL=/usr/bin/zsh TERM=xterm-256color HISTFILE=/dev/null \
      DISABLE_AUTO_UPDATE=true PROBE_LOG="$PROMPT_TEST_LOG" /usr/bin/zsh -l
  ' /dev/null >"${scratch}/terminal" 2>&1; then
  echo "First-prompt shell failed or timed out" >&2
  if [[ -s "${scratch}/probes" ]]; then
    echo "Runtime probes recorded before failure:" >&2
    cat "${scratch}/probes" >&2
  fi
  cat "${scratch}/terminal" >&2
  exit 1
fi
if [[ -s "${scratch}/probes" ]]; then
  echo "First prompt probed Bun's node compatibility link:" >&2
  cat "${scratch}/probes" >&2
  exit 1
fi
if ! grep -q 'FIRST_INPUT_EXECUTED_27' "${scratch}/terminal"; then
  echo "First queued command was lost or Powerlevel10k did not load" >&2
  cat "${scratch}/terminal" >&2
  exit 1
fi
printf '%s\n' 'First-prompt input passed: queued command preserved; zero Bun/Node probes.'
