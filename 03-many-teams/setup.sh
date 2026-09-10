#!/usr/bin/env bash
# Turn this directory into a working deck workspace.
#
# Four repositories, the registry, and the board. Everything deck-shaped beyond
# that — the pack collections, the layering, the scope — is what the exercise
# has you write.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
HERE="$PWD"

command -v deck >/dev/null || { echo "deck is not on PATH — see the root README"; exit 1; }

for r in catalog-schema catalog-api storefront-web deploy-scripts; do
  if [ ! -d "$r/.git" ]; then
    git -C "$r" init -q
    git -C "$r" add -A
    git -C "$r" commit -qm "initial: the exercise, before any task"
    echo "  initialised $r"
  fi
done

mkdir -p .deck docs
[ -f .deck/workspace.yaml ] || cp seed/workspace.yaml .deck/workspace.yaml
[ -f docs/board.yaml ]      || cp seed/board.yaml docs/board.yaml
[ -f .deck/toggles.yaml ]   || printf 'version: 1\nvalues: {}\n' > .deck/toggles.yaml

echo
echo "Ready. From $HERE:"
echo "    deck doctor"
echo "    deck repos"
echo "    deck impact catalog-schema"
