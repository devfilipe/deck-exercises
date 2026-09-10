#!/usr/bin/env bash
# Turn this directory into a working deck workspace.
#
# The four layers ship as plain directories so they can live inside this
# repository. A workspace is repositories, so the first thing to do is make
# them repositories.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
HERE="$PWD"

command -v deck >/dev/null || { echo "deck is not on PATH — see the root README"; exit 1; }

for r in hello-commands hello-core hello-cli hello-docs ai-packs; do
  if [ ! -d "$r/.git" ]; then
    git -C "$r" init -q
    git -C "$r" add -A
    git -C "$r" commit -qm "initial: the exercise, before any task"
    echo "  initialised $r"
  fi
done

mkdir -p docs
[ -f docs/board.yaml ] || cp seed/board.yaml docs/board.yaml

# `deck setup` is what creates the machine half — the overlay saying where this
# checkout is, the recorded choices, and the selection. It is deliberately not
# hand-written here: a reader who copies these lines into a real project should
# be copying the command, not a directory layout they would then have to keep
# current. The descriptor it writes is a fresh discovery, and the line after
# replaces it with the one this exercise ships, which already carries the edges
# and the board.
deck setup --packs-root ./ai-packs --workspace polyglot \
  --repos hello-commands,hello-core,hello-cli,hello-docs >/dev/null
cp seed/workspace.yaml ai-packs/_workspaces/polyglot/default/workspace.yaml

echo
echo "Ready. From $HERE:"
echo "    deck doctor"
echo "    deck board list"
echo "    deck gate run --task try-it     # 5 gates, 9 runs, all green"
