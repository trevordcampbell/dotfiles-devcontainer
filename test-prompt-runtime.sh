#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf -- "${scratch}"' EXIT
mkdir "${scratch}/bin"

# Any runtime execution while selecting prompt segments is a regression.
cat >"${scratch}/bin/bun" <<'RUNTIME'
#!/bin/sh
echo "Unexpected runtime probe" >&2
exit 99
RUNTIME
chmod +x "${scratch}/bin/bun"
ln -s bun "${scratch}/bin/node"

check_prompt() {
  local expected="$1"
  env -i HOME="${scratch}" PATH="${scratch}/bin:/usr/bin:/bin" \
    PROMPT_CONFIG="${repo_root}/.p10k.zsh" EXPECT_NODE="${expected}" \
    /usr/bin/zsh -fc '
      source "$PROMPT_CONFIG"
      if (( EXPECT_NODE )); then
        (( ${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[(Ie)node_version]} )) || exit 1
      else
        (( ! ${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[(Ie)node_version]} )) || exit 1
      fi
      [[ ${(j:,:)POWERLEVEL9K_LEFT_PROMPT_ELEMENTS} == os_icon,dir,vcs,newline,prompt_char ]]
    '
}

check_prompt 0

# A genuine separate Node command keeps the segment even when Bun is installed.
rm "${scratch}/bin/node"
cp "${scratch}/bin/bun" "${scratch}/bin/node"
check_prompt 1

# Node-only images also retain their existing segment.
rm "${scratch}/bin/bun"
check_prompt 1

printf '%s\n' 'Prompt runtime selection passed: Bun alias, separate Node, Node-only.'
