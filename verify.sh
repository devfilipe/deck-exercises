#!/usr/bin/env bash
# Run every command the exercises tell a reader to run, against real deck.
#
# An exercise is a set of claims: type this, see that. Nothing in a README
# checks itself, so without this script every claim here is true only on the day
# it was written — which is how this repository once drifted a full release
# behind the tool it teaches.
#
#   ./verify.sh                      # deck from PATH
#   DECK_BIN=/path/to/deck ./verify.sh
#   ./verify.sh 02                   # one exercise
#
# It runs in a temporary directory and copies each exercise there first, so a
# run leaves your checkout exactly as it found it.
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# deck is invoked as `deck` throughout, because that is how the exercises
# invoke it. DECK_BIN puts a chosen one on PATH for the duration.
if [ -n "${DECK_BIN:-}" ]; then
  [ -x "$DECK_BIN" ] || { echo "DECK_BIN is not executable: $DECK_BIN" >&2; exit 2; }
  BIN=$(mktemp -d)
  ln -sf "$(cd "$(dirname "$DECK_BIN")" && pwd)/$(basename "$DECK_BIN")" "$BIN/deck"
  PATH="$BIN:$PATH"
  export PATH
fi

command -v deck >/dev/null || {
  echo "deck is not on PATH. Either install it, or:  DECK_BIN=/path/to/deck ./verify.sh" >&2
  exit 2
}

# A committer identity, in case the machine has none. The exercises make
# commits, and git refuses without one.
git config --get user.email >/dev/null 2>&1 || {
  export GIT_AUTHOR_NAME="deck exercises" GIT_AUTHOR_EMAIL="someone@example.com"
  export GIT_COMMITTER_NAME="deck exercises" GIT_COMMITTER_EMAIL="someone@example.com"
}

WHICH=${1:-all}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "deck      $(command -v deck)  ·  $(deck --version 2>&1)"
echo "workspace $WORK"

FAILED=0
for script in "$HERE"/verify/[0-9]*.sh; do
  name=$(basename "$script")
  case "$WHICH" in
    all) ;;
    *) [[ "$name" == "$WHICH"* ]] || continue ;;
  esac
  bash "$script" "$WORK" || FAILED=1
done

echo
if [ "$FAILED" -ne 0 ]; then
  echo "Something an exercise tells a reader to do no longer works."
  echo "Fix the exercise, or the check, before the next reader finds it."
  exit 1
fi
echo "Every command in the exercises still does what the exercises say."
