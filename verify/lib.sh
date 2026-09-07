# Shared by every check script. Sourced, never run.
#
# The point of this file is that a README claim and a check are the same
# sentence written twice: `says` takes the command the exercise tells a reader
# to run and the string the exercise says it prints. When deck's output moves,
# the check fails with both halves in front of you.

set -uo pipefail

PASSED=0
FAILED=0
FAILURES=()

# Colour only when someone is watching.
if [ -t 1 ]; then B=$'\033[1m'; R=$'\033[31m'; G=$'\033[32m'; D=$'\033[2m'; Z=$'\033[0m'
else B=''; R=''; G=''; D=''; Z=''; fi

_out=""
_status=0

# Run a command, keeping stdout and stderr together in $_out and the real exit
# status in $_status. Never through a pipe: a pipe reports the pipe's status.
_run() {
  local tmp
  tmp=$(mktemp)
  "$@" >"$tmp" 2>&1
  _status=$?
  _out=$(cat "$tmp")
  rm -f "$tmp"
}

_pass() { PASSED=$((PASSED + 1)); printf '  %sok%s   %s\n' "$G" "$Z" "$1"; }

_fail() {
  FAILED=$((FAILED + 1))
  FAILURES+=("$1")
  printf '  %sFAIL%s %s\n' "$R" "$Z" "$1"
  printf '%s\n' "$_out" | sed "s/^/       $D|$Z /" | head -25
}

# ok <label> -- <command...>            exit 0
ok() {
  local label=$1; shift; [ "${1:-}" = "--" ] && shift
  _run "$@"
  if [ "$_status" -eq 0 ]; then _pass "$label"
  else _fail "$label  (exit $_status, expected 0)"; fi
}

# fails <label> -- <command...>         any non-zero exit
fails() {
  local label=$1; shift; [ "${1:-}" = "--" ] && shift
  _run "$@"
  if [ "$_status" -ne 0 ]; then _pass "$label"
  else _fail "$label  (exit 0, expected non-zero)"; fi
}

# says <label> <substring> -- <command...>        exit 0 and prints substring
says() {
  local label=$1 needle=$2; shift 2; [ "${1:-}" = "--" ] && shift
  _run "$@"
  if [ "$_status" -ne 0 ]; then
    _fail "$label  (exit $_status, expected 0)"
  elif printf '%s' "$_out" | grep -qF -- "$needle"; then
    _pass "$label"
  else
    _fail "$label  (did not print: $needle)"
  fi
}

# fails_saying <label> <substring> -- <command...>   non-zero and prints it
fails_saying() {
  local label=$1 needle=$2; shift 2; [ "${1:-}" = "--" ] && shift
  _run "$@"
  if [ "$_status" -eq 0 ]; then
    _fail "$label  (exit 0, expected non-zero)"
  elif printf '%s' "$_out" | grep -qF -- "$needle"; then
    _pass "$label"
  else
    _fail "$label  (did not print: $needle)"
  fi
}

# capture -- <command...>              run it, assert nothing, keep the output
# also <label> <substring>             assert against what capture last kept
#
# Two claims about one command are two `also` lines, never two runs: running a
# command twice to check it twice is how a check ends up passing against a
# state the reader never sees.
capture() { [ "${1:-}" = "--" ] && shift; _run "$@"; }

also() {
  local label=$1 needle=$2
  if printf '%s' "$_out" | grep -qF -- "$needle"; then _pass "$label"
  else _fail "$label  (did not print: $needle)"; fi
}

# not_also <label> <substring>         the last capture must NOT print it
not_also() {
  local label=$1 needle=$2
  if printf '%s' "$_out" | grep -qF -- "$needle"; then
    _fail "$label  (printed what it should not: $needle)"
  else _pass "$label"; fi
}

# exited <label> <n>                   the last capture's exit status
exited() {
  local label=$1 want=$2
  if [ "$_status" -eq "$want" ]; then _pass "$label"
  else _fail "$label  (exit $_status, expected $want)"; fi
}

heading() { printf '\n%s%s%s\n' "$B" "$1" "$Z"; }

summary() {
  printf '\n%s%s%s\n' "$B" "$1" "$Z"
  printf '  %d passed, %d failed\n' "$PASSED" "$FAILED"
  if [ "$FAILED" -ne 0 ]; then
    printf '\n%sWhat no longer holds:%s\n' "$R" "$Z"
    for f in "${FAILURES[@]}"; do printf '  - %s\n' "$f"; done
    return 1
  fi
  return 0
}
