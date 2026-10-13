#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Zsh job control and gitstatus require a controlling terminal. Allocate one
# even when invoked by docker exec, a pipe, or CI, and keep the real startup
# configuration intact rather than trying to disable its gitstatus settings.
if [[ ! -t 0 ]]; then
  if ! command -v script >/dev/null; then
    echo "Headless startup testing requires util-linux script" >&2
    exit 1
  fi
  export DOTFILES_STARTUP_TEST="${repo_root}/test-shell-startup.sh"
  exec script -q -e -c 'exec /usr/bin/bash "$DOTFILES_STARTUP_TEST"' /dev/null </dev/null
fi

stdout_file="$(mktemp)"
stderr_file="$(mktemp)"
bash_stdout_file="$(mktemp)"
bash_stderr_file="$(mktemp)"
trap 'rm -f -- "${stdout_file}" "${stderr_file}" "${bash_stdout_file}" \
  "${bash_stderr_file}"' EXIT

if ! env -i \
  HOME="${HOME}" \
  USER="$(id -un)" \
  LOGNAME="$(id -un)" \
  SHELL=/usr/bin/zsh \
  TERM=xterm-256color \
  ZDOTDIR="${repo_root}" \
  PATH="${PATH}" \
  ZSH="${ZSH:-${HOME}/.oh-my-zsh}" \
  /usr/bin/zsh -lic \
    'print -r -- "${P9K_VERSION:-}"; command -v bun || true; command -v cargo || true; command -v rustc || true; \
      print -r -- "${(j:,:)POWERLEVEL9K_LEFT_PROMPT_ELEMENTS}"; \
      print -r -- "${(j:,:)POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS}"' \
    >"${stdout_file}" 2>"${stderr_file}"; then
  cat "${stderr_file}" >&2
  exit 1
fi

if [[ -s "${stderr_file}" ]]; then
  cat "${stderr_file}" >&2
  exit 1
fi

mapfile -t startup_proof <"${stdout_file}"
if [[ -z "${startup_proof[0]:-}" ]]; then
  echo "Powerlevel10k did not initialize" >&2
  exit 1
fi
expected_tools=()
for tool in bun cargo rustc; do
  if resolved="$(command -v "${tool}")"; then
    expected_tools+=("${resolved}")
  fi
done
for index in "${!expected_tools[@]}"; do
  if [[ "${startup_proof[index + 1]:-}" != "${expected_tools[index]}" ]]; then
    echo "zsh startup did not preserve an installed toolchain path" >&2
    exit 1
  fi
done
prompt_offset=$((1 + ${#expected_tools[@]}))
if [[ "${startup_proof[prompt_offset]:-}" != os_icon,dir,vcs,newline,prompt_char ]]; then
  echo "Powerlevel10k left prompt is not devcontainer-focused" >&2
  exit 1
fi
expected_right_prompt=\
'status,command_execution_time,background_jobs,direnv,virtualenv,node_version,go_version,'\
'rust_version,dotnet_version,package,context,time,newline'
if command -v node >/dev/null && command -v bun >/dev/null &&
    [[ "$(readlink -f "$(command -v node)")" == "$(readlink -f "$(command -v bun)")" ]]; then
  expected_right_prompt="${expected_right_prompt/,node_version/}"
fi
if [[ "${startup_proof[prompt_offset + 1]:-}" != "${expected_right_prompt}" ]]; then
  echo "Powerlevel10k right prompt is not devcontainer-focused" >&2
  exit 1
fi

if ! env -i \
  HOME="${HOME}" \
  USER="$(id -un)" \
  LOGNAME="$(id -un)" \
  SHELL=/usr/bin/bash \
  PATH="${PATH}" \
  DOTFILES_ROOT="${repo_root}" \
  /usr/bin/bash --noprofile --norc -c \
    'source "${DOTFILES_ROOT}/.bashrc"; command -v bun || true; command -v cargo || true; command -v rustc || true' \
    >"${bash_stdout_file}" 2>"${bash_stderr_file}"; then
  cat "${bash_stderr_file}" >&2
  exit 1
fi

if [[ -s "${bash_stderr_file}" ]]; then
  cat "${bash_stderr_file}" >&2
  exit 1
fi

mapfile -t bash_startup_proof <"${bash_stdout_file}"
for index in "${!expected_tools[@]}"; do
  if [[ "${bash_startup_proof[index]:-}" != "${expected_tools[index]}" ]]; then
    echo "bash startup did not preserve an installed toolchain path" >&2
    exit 1
  fi
done

printf '%s\n' 'Bash/Zsh startup and installed toolchain paths passed.'
