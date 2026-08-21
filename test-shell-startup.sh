#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stdout_file="$(mktemp)"
stderr_file="$(mktemp)"
trap 'rm -f -- "${stdout_file}" "${stderr_file}"' EXIT

if ! env -i \
  HOME=/home/vscode \
  USER=vscode \
  LOGNAME=vscode \
  SHELL=/usr/bin/zsh \
  TERM=xterm-256color \
  ZDOTDIR="${repo_root}" \
  PATH=/usr/bin:/bin \
  POWERLEVEL9K_DISABLE_GITSTATUS=true \
  /usr/bin/zsh -lic \
    'print -r -- "${P9K_VERSION:-}"; command -v cargo; command -v rustc' \
    >"${stdout_file}" 2>"${stderr_file}"; then
  cat "${stderr_file}" >&2
  exit 1
fi

if [[ -s "${stderr_file}" ]]; then
  cat "${stderr_file}" >&2
  exit 1
fi

mapfile -t startup_proof <"${stdout_file}"
if [[ "${startup_proof[0]:-}" != 1.20.18 ]]; then
  echo "Powerlevel10k did not initialize at version 1.20.18" >&2
  exit 1
fi
if [[ "${startup_proof[1]:-}" != /usr/local/cargo/bin/cargo ]]; then
  echo "zsh startup did not preserve the image-owned Cargo path" >&2
  exit 1
fi
if [[ "${startup_proof[2]:-}" != /usr/local/cargo/bin/rustc ]]; then
  echo "zsh startup did not preserve the image-owned rustc path" >&2
  exit 1
fi
