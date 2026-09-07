#!/usr/bin/env bash
# Every command 01-first-workspace/README.md tells a reader to run, run against
# real deck, with the strings that README quotes asserted.
#
# Step 10 (`claude plugin …`) is not here: it needs Claude Code and an account,
# and the README marks it optional for that reason.

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/lib.sh"

WORK=${1:?usage: 01-first-workspace.sh <empty-work-dir>}
mkdir -p "$WORK/hello" && cd "$WORK/hello" || exit 1

heading "01 · your first workspace"

# ---------------------------------------------------------------- 0 and 1
ok "deck --help answers" -- deck --help

for r in hello-schema hello-api hello-cli; do
  mkdir -p $r
  git -C $r init -q
  echo "# $r" > $r/README.md
  git -C $r add -A
  git -C $r commit -qm "init"
done
ok "three repositories exist" -- test -d hello-schema/.git

# ------------------------------------------------------------------- 2
# Discovery stops at step 2 and exits non-zero: it has found no pack collection
# and refuses to invent one. The README's claim is the stopping, not the status.
capture -- deck setup --dry-run
exited "setup --dry-run refuses to guess, and says so in its status" 1
also "it stops at the pack collection" "No pack collection named."
also "having found the three repositories" "3 git repositories found"
ok "and written nothing" -- test ! -e .deck

# ------------------------------------------------------------------- 3
capture -- deck setup --packs-root ./ai-packs --create-packs
exited "setup, given the one decision it cannot make" 0
also "it links a pack per repository, by name" "linked   hello-api"
also "and one shared pack" "shared   (every repository)"
ok ".deck/ appeared" -- test -f .deck/workspace.yaml
ok "ai-packs/ appeared" -- test -d ai-packs/_workspace

# ------------------------------------------------------------------- 4
python3 - <<'PY'
import pathlib
p = pathlib.Path(".deck/workspace.yaml"); s = p.read_text()
s = s.replace("  hello-api:\n    path: hello-api\n    impacts: []",
              "  hello-api:\n    path: hello-api\n    impacts: [hello-cli]")
s = s.replace("  hello-schema:\n    path: hello-schema\n    impacts: []",
              "  hello-schema:\n    path: hello-schema\n    impacts: [hello-api]")
p.write_text(s)
PY
says "impact hello-schema reaches 2" \
  "a change in hello-schema reaches 2 repositories" -- deck impact hello-schema
says "and closes the chain transitively" "3. hello-cli" -- deck impact hello-schema
says "impact hello-api reaches 1" \
  "a change in hello-api reaches 1 repository" -- deck impact hello-api

# ------------------------------------------------------------------- 5
cat > ai-packs/_workspace/config/gates.yaml <<'YAML'
gates:
  - id: readme
    title: Every repository documents itself
    from_level: static
    per_repo: "test -f README.md"

  - id: build
    title: Build
    from_level: build
    per_repo: "echo building ${repo.name}"
YAML
capture -- deck gate list
exited "gate list" 0
also "names the ladder" "ladder   static -> build -> deploy -> behavior"
says "gate run is 2 gates over 3 repositories" \
  "2 gate(s) passed in 6 run(s)" -- deck gate run --task hello-1
ok "evidence outlives the session" -- test -f .deck/gates/hello-1.json

rm hello-cli/README.md
capture -- deck gate run --task hello-2
exited "a broken gate is a non-zero exit" 1
also "and it names the repository" "FAIL readme       hello-cli"
also "and does not attempt the rung above" "not attempted: an earlier gate failed"
git -C hello-cli checkout -q README.md

# ------------------------------------------------------------------- 6
cat >> ai-packs/_workspace/config/toggles.yaml <<'YAML'
  - id: schema_compat
    group: quality
    title: Schema compatibility
    summary: How far a change may alter the published contract.
    type: enum
    values: [strict, additive, breaking]
    default: ask
    stage: [plan]
    applies_to: ["hello-schema/**"]
    risk: high
    rationale: >
      hello-cli is installed separately and does not negotiate versions. A
      removed or renamed field breaks every deployed client silently, and the
      breakage arrives as a support ticket weeks later, not as a red build.
    impact:
      strict: Nothing published moves. Slowest, always safe.
      additive: New fields only. Old clients keep working untouched.
      breaking: Every installed client needs updating first.
    question:
      header: Compat
      text: May this change alter the published contract?
      options:
        - { value: strict,   label: No change,  description: "Nothing published moves." }
        - { value: additive, label: Add only,   description: "Old clients keep working." }
        - { value: breaking, label: May break,  description: "Every installed cli needs updating first." }
YAML
says "the catalog passes --strict" "OK" -- deck toggle validate --strict
says "explain reports no default answer" "effective  : ask" \
  -- deck toggle explain schema_compat

_asked() { deck toggle ask-plan --stage "$1" --files "$2" \
  | python3 -c 'import json,sys; print(" ".join(q["id"] for q in json.load(sys.stdin)["questions"]))'; }

_run bash -c "$(declare -f _asked); _asked plan hello-cli/main.py"
if printf '%s' "$_out" | grep -q schema_compat; then
  _fail "outside applies_to it is not asked  (schema_compat was asked)"
else _pass "outside applies_to it is not asked"; fi

says "inside applies_to it is asked" "schema_compat" \
  -- deck toggle ask-plan --stage plan --files hello-schema/contract.yaml

_run bash -c "$(declare -f _asked); _asked verify hello-schema/contract.yaml"
if printf '%s' "$_out" | grep -q schema_compat; then
  _fail "at the wrong stage it is not asked  (schema_compat was asked)"
else _pass "at the wrong stage it is not asked"; fi

# ------------------------------------------------------------------- 7
capture -- deck doctor
exited "doctor" 0
also "reports four warnings, and no problem" "4 warning(s)"
also "naming the missing remotes" "no origin remote"
also "and the empty allowlist" "no target declared"
says "packs are merged most general first" \
  "_workspace                   every repository" -- deck packs

# ------------------------------------------------------------------- 8
python3 - <<'PY'
import pathlib
p = pathlib.Path(".deck/workspace.yaml"); s = p.read_text()
p.write_text(s.replace("backlog: []", "backlog:\n- { type: tasks, file: docs/board.yaml }"))
PY
mkdir -p docs
ok "board new writes the task" -- deck board new \
  "Add a version field to the greeting contract" \
  --id HW-1 --repos hello-schema --ext jira:HW-1 --yes
says "one declared repository, three reached" \
  "reaches   hello-schema, hello-api, hello-cli" -- deck board show HW-1

# ------------------------------------------------------------------- 9
cat > ai-packs/hello-schema/rules/contract.md <<'MD'
---
paths: ["*.yaml", "*.json"]
---

hello-cli is installed separately and does not negotiate versions. A removed or
renamed field breaks every deployed client silently — the breakage shows up as a
support ticket weeks later, not as a red build.

Before touching a name that already exists, check the `schema_compat` toggle.
MD
rm ai-packs/hello-schema/rules/example.md
python3 - <<'PY'
import pathlib
p = pathlib.Path("ai-packs/hello-schema/config/mount.yaml"); s = p.read_text()
p.write_text(s.replace(
    "rules:\n#   - { file: rules/api-contract.md, repos: [api-schema] }\n#   - { file: rules/conventions.md }",
    "rules:\n  - { file: rules/contract.md }"))
PY
ok "board claim" -- deck board claim HW-1 someone --yes
says "mount places one rule" "1 artifact(s)" -- deck mount --task HW-1 --repos hello-schema
ok "the rule landed in the repository the pack is named after" \
  -- test -f hello-schema/.claude/rules/deck-contract.md
ok "and nowhere else" -- test ! -e hello-api/.claude
says "the ladder still passes" "2 gate(s) passed in 6 run(s)" \
  -- deck gate run --task HW-1
says "unmount takes back exactly what it placed" "1 removed · 0 left alone" \
  -- deck unmount --task HW-1
ok "the repository is clean again" -- test ! -e hello-schema/.claude
says "done closes it, and says what it did not close" \
  "jira:HW-1 is not touched" -- deck board done HW-1 --yes

# `deck cost` reads Claude Code transcripts. There are none in CI, and the
# README says so; what is checked is that it fails honestly rather than
# reporting a zero it did not measure.
fails_saying "cost refuses to invent a number" \
  "no session of this workspace has a transcript yet" -- deck cost --task HW-1

summary "01 · your first workspace"
