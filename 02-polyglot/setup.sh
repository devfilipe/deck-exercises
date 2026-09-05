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

mkdir -p .deck docs
[ -f .deck/workspace.yaml ] || cp seed/workspace.yaml .deck/workspace.yaml
[ -f docs/board.yaml ]      || cp seed/board.yaml docs/board.yaml
[ -f .deck/toggles.yaml ]   || printf 'version: 1\nvalues: {}\n' > .deck/toggles.yaml

echo
echo "Ready. From $HERE:"
echo "    deck doctor"
echo "    deck board list"
echo "    deck gate run --task try-it     # 5 gates, 9 runs, all green"
