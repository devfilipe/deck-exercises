#!/usr/bin/env bash
# Every command 03-many-teams/README.md tells a reader to run, in the order it
# tells them to, against a throwaway copy of the exercise.
#
# Act 6 (`deck propose`) is here only as far as it goes for free: the refusal
# that costs nothing, and `--show-prompt`. Nothing in CI makes a paid API call.

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/lib.sh"
SRC=$(cd "$HERE/.." && pwd)/03-many-teams

WORK=${1:?usage: 03-many-teams.sh <empty-work-dir>}
rm -rf "$WORK/many-teams"
cp -r "$SRC" "$WORK/many-teams"
cd "$WORK/many-teams" || exit 1

heading "03 · many teams, one registry"

# ------------------------------------------------------------- set it up
ok "setup.sh" -- ./setup.sh
capture -- deck doctor
exited "doctor" 0
also "six warnings, and no problem" "6 warning(s)"
also "no pack configured yet" "no extension pack configured"
also "the coupling is understood" \
  "OK coupling  catalog-api <-> deploy-scripts   (declared by catalog-api, which is enough)"
also "and what it does not do is stated" \
  "a coupling can never make this graph cyclic"

capture -- deck impact catalog-api
exited "impact catalog-api" 0
also "reports the ordered chain" "2. storefront-web"
also "and the coupling apart from it" "coupled with, in no order:"
also "saying so" "A coupling is mutual and carries no order"

# ---------------------------------------------------- act 1 · paths, targets
python3 - <<'PY'
import pathlib
p = pathlib.Path(".deck/workspace.yaml"); s = p.read_text()
s = s.replace("paths: {}", "paths:\n  tools: tools")
s = s.replace("targets: []",
  "targets:\n- { host: 10.0.0.4, role: staging, alias: lab-1, notes: the shared staging box }")
p.write_text(s)
PY
says "paths names the directory the workspace uses" "tools" -- deck paths
says "targets is the allowlist" "10.0.0.4	staging	lab-1" -- deck targets
capture -- deck doctor
exited "doctor again" 0
also "the target warning is gone, and it is a note now" \
  ".. 10.0.0.4  alias=lab-1  (use --net to test reachability)"
not_also "with nothing left to warn about there" "no target declared"

# ---------------------------------------------------- act 2 · two collections
ok "pack new org-baseline" -- deck pack new org-baseline --dir ./org-packs/_workspaces/all/default \
  --description "What every repository in the organisation follows"
cat > org-packs/_workspaces/all/default/config/gates.yaml <<'YAML'
version: 1

gates:
  - id: readme
    title: Every repository documents itself
    from_level: static
    per_repo: "test -f README.md"

  - id: todos
    title: What is still marked TODO
    from_level: static
    per_repo: "${path.tools}/count-todos.sh"
    measures:
      - id: open_items
        title: lines still marked TODO
        pattern: '(\d+) TODO'
        unit: lines
        better: lower

  - id: build
    title: Build
    from_level: build
    per_repo: "${repo.build}"
YAML
python3 - <<'PY'
import pathlib
p = pathlib.Path(".deck/workspace.yaml")
p.write_text(p.read_text().replace("packs_root: []", "packs_root:\n- org-packs"))
PY
capture -- deck gate run --task ORG-1
exited "the organisation ladder is green" 0
also "three gates over four repositories" "3 gate(s) passed in 12 run(s)"
also "and four numbers were kept" "4 measurement(s) added to the series"
also "catalog-api has one TODO" "open_items   1 lines"

# One gate, a different command per repository, from the descriptor's
# ${repo.build}. Three repositories, three different logs, one gate id.
ok "the shared build gate ran catalog-schema's own command" \
  -- grep -q '"fields"' .deck/gates/logs/ORG-1/build-catalog-schema.log
ok "and storefront-web's, which is a different one" \
  -- grep -q '"pages"' .deck/gates/logs/ORG-1/build-storefront-web.log

ok "pack new catalog-schema" -- deck pack new catalog-schema \
  --dir ./ai-packs/_repos/catalog-schema --description "The contract everyone else reads"
cat > ai-packs/_repos/catalog-schema/config/gates.yaml <<'YAML'
version: 1

gates:
  - id: required-fields
    title: Every declared field says whether it is required
    from_level: static
    per_repo: "python3 check-fields.py"
YAML
python3 - <<'PY'
import pathlib
p = pathlib.Path(".deck/workspace.yaml")
p.write_text(p.read_text().replace("packs_root:\n- org-packs",
                                   "packs_root:\n- org-packs\n- ai-packs"))
PY
capture -- deck packs
exited "packs" 0
also "two in play, most general first" "packs   2 in play, merged most general first"
also "the organisation layer first" "1  all/default                  every repository"
also "the repository layer second" "2  catalog-schema               catalog-schema"

capture -- deck gate list
exited "gate list" 0
also "a repository pack's gate defaults to that repository" \
  "  ->   required-fields Every declared field says whether it is required runs
       over catalog-schema"

python3 - <<'PY'
import json, pathlib
p = pathlib.Path("catalog-schema/catalog.json"); d = json.loads(p.read_text())
d["fields"].append({"name": "price_history", "type": "array"})
p.write_text(json.dumps(d, indent=2) + "\n")
PY
capture -- deck gate run --task ORG-2
exited "a field that does not say whether it is required fails" 1
also "and the log names it" "no 'required' on: price_history"
git -C catalog-schema checkout -q catalog.json

# The trap the README warns about, run so the warning stays true.
cat >> ai-packs/_repos/catalog-schema/config/gates.yaml <<'YAML'

  - id: build
    title: Build
    from_level: build
    per_repo: "python3 -m json.tool catalog.json && echo the contract parses"
YAML
fails_saying "a second gate under one name is refused" \
  "already exists (from all/default). Set" -- deck gate run --task ORG-3

# Add the flag the refusal asked for, and watch what it does.
cat > ai-packs/_repos/catalog-schema/config/gates.yaml <<'YAML'
version: 1

gates:
  - id: required-fields
    title: Every declared field says whether it is required
    from_level: static
    per_repo: "python3 check-fields.py"

  - id: build
    title: Build
    from_level: build
    overrides: true
    per_repo: "python3 -m json.tool catalog.json && echo the contract parses"
YAML
capture -- deck gate run --task ORG-3
exited "an override written in a repository pack changes that repository only" 0
also "the pack's own repository runs its own command" "ok   build        catalog-schema"
ok "and the log proves the command that ran there was catalog-schema's" \
  -- grep -q "the contract parses" \
     .deck/gates/logs/ORG-3/build-catalog-schema.log
# The half that matters more, because it is the one you cannot see from the
# summary line: the siblings kept the shared command. `catalog.json` appearing
# in their log would mean an override written for one repository had been
# handed to three others.
ok "while a sibling still runs the shared command, not this one" \
  -- bash -c '! grep -q "catalog.json" .deck/gates/logs/ORG-3/build-catalog-api.log'
cat > ai-packs/_repos/catalog-schema/config/gates.yaml <<'YAML'
version: 1

gates:
  - id: required-fields
    title: Every declared field says whether it is required
    from_level: static
    per_repo: "python3 check-fields.py"
YAML

# ------------------------------------------------------------ act 3 · scopes
python3 - <<'PY'
import pathlib
p = pathlib.Path(".deck/workspace.yaml")
p.write_text(p.read_text().replace("scopes: {}", """scopes:
  catalogue:
    title: Publish price history
    repos: [catalog-schema, catalog-api]"""))
PY
capture -- deck scope catalogue
exited "scope catalogue" 0
also "two of four repositories" "repositories  2 of 4"
also "the boundary leaks a chain" \
  "reaches       storefront-web   (outside the scope, still has to keep up)"
also "and a coupling, with no order" \
  "coupled with  deploy-scripts   (outside the scope, mutual and in no order)"
also "the board is the workspace's, narrowed" "board         the workspace board, narrowed"
also "and it has no posture of its own yet" "posture       none recorded"
says "scopes lists it" "catalogue            2 repositories" -- deck scopes

capture -- deck --scope catalogue board list
exited "the scope's board" 0
also "holds the initiative's tasks" "[ ] CAT-1"
not_also "and not the others" "WEB-1"
says "the whole board still holds them" "WEB-1" -- deck board list

capture -- deck toggle set --at catalogue gate_level build \
  --why "this initiative has no staging slot of its own yet"
exited "a posture recorded at the scope" 0
also "written into this machine's choices" "gate_level = build  (scope catalogue"
also "with the reason beside it" "why: this initiative has no staging slot of its own yet"
capture -- deck --scope catalogue toggle explain gate_level
exited "explain, inside the scope" 0
also "the scope's value is in force" "effective  : build"
also "and it says which layer said so" "source     : scope catalogue"
also "keeping why-it-exists and why-this-value apart" \
  "why this value was chosen (scope catalogue):"
says "outside the scope nothing changed" "effective  : deploy" \
  -- deck toggle explain gate_level

ok "pack new, bound to the initiative" -- deck pack new catalogue-work \
  --dir ./org-packs/_workspaces/all/catalogue --scope catalogue --from-workspace \
  --description "What this initiative needs, and only while it runs"
ok "detect.yaml binds it to the scope" \
  -- grep -q "^scope: catalogue" org-packs/_workspaces/all/catalogue/config/detect.yaml
ok "and --from-workspace shipped the carve-up in its template" \
  -- grep -q "    title: Publish price history" \
     org-packs/_workspaces/all/catalogue/templates/workspace/workspace.yaml

cat > org-packs/_workspaces/all/catalogue/config/gates.yaml <<'YAML'
version: 1

gates:
  - id: history-documented
    title: Price history is described where it is published
    from_level: static
    per_repo: "grep -q price-history README.md"
YAML
cat > org-packs/_workspaces/all/catalogue/rules/history.md <<'MD'
---
paths: ["*.json"]
---

Price history is a list, and a list published on a contract has no natural end.
Before adding one, say how far back it goes: the payload grows with every entry
and nothing downstream can shorten it afterwards.

The decision is recorded as `price_history_window`. Read it, do not re-derive it.
MD
rm org-packs/_workspaces/all/catalogue/rules/example.md
capture -- deck packs
exited "packs, outside the initiative" 0
also "the scope-bound pack is listed, and waiting" \
  "not in play   bound to an initiative, and loaded only while it is active"
also "with the command that brings it in" "bring it in with: deck --scope catalogue <command>"
capture -- deck --scope catalogue packs
exited "packs, inside it" 0
also "three in play now" "packs   3 in play, merged most general first"
also "and it merges between the organisation and the repository" \
  "2  all/catalogue                scope catalogue"

# ------------------------------------------------------------- act 4 · work
ok "claim CAT-1" -- deck --scope catalogue board claim CAT-1 someone --yes
capture -- deck --scope catalogue mount --task CAT-1 --repos catalog-schema
exited "mount CAT-1" 0
# One artifact, not one per repository in the scope. A scope layer is a
# statement about an initiative, so it lands once at the workspace root and is
# read once, the same way the workspace layer does.
also "the initiative's rule lands once, at the root" "1 artifact(s)"
ok "it is a file, not a symlink" -- test -f .claude/rules/deck-history.md
ok "and Claude Code would read it, which a symlink there would not be" \
  -- test ! -L .claude/rules/deck-history.md

python3 - <<'PY'
import json, pathlib
p = pathlib.Path("catalog-schema/catalog.json"); d = json.loads(p.read_text())
d["fields"].append({"name": "price_history", "type": "array"})
p.write_text(json.dumps(d, indent=2) + "\n")
PY
capture -- deck --scope catalogue gate run --task CAT-1
exited "the ladder fails" 1
also "at the rung the scope's posture set, not the workspace's" "level build"
also "on the initiative's own gate" "FAIL history-documented catalog-schema"
fails_saying "and the decision the rule points at does not exist yet" \
  "unknown toggle: price_history_window" \
  -- deck --scope catalogue toggle get price_history_window

capture -- deck ask new "How far back does the published price history go?" \
  --task CAT-1 \
  --context "The contract can publish an unbounded array. Nobody has said how much of it the storefront is allowed to show, and the payload grows with every entry." \
  --options "unbounded,90-days,12-months"
exited "ask new" 0
also "it outlives the session" "It is written down and will outlive this session."
also "and nothing waits on it" "Nothing waits on it."

ASK=$(deck ask list --json | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["id"])')
says "ask show reads it back" "How far back does the published price history go?" \
  -- deck ask show "$ASK"
capture -- deck ask resolve "$ASK" \
  "12-months — older entries are aggregated, not published." --who someone@example.com
exited "ask resolve" 0
also "and it says an answer is not yet a record" \
  "This answer is a transcript until someone writes it down."
also "suggesting what it wants to become" "It probably wants to become: toggle"

capture -- deck ask fold "$ASK" --as toggle --into org-packs/_workspaces/all/catalogue \
  --gate-id price_history_window --title "Price-history window" --group quality \
  --impact "unbounded=Every entry ever recorded is published. The payload grows without limit and nothing downstream can shorten it." \
  --impact "90-days=A quarter of history. The smallest payload that still shows a trend." \
  --impact "12-months=A year of history. Older entries are aggregated, not published."
exited "ask fold" 0
also "into the pack the initiative owns" "folded $ASK into catalogue as a toggle"
ok "and the entry lands unasked, which is a second decision" \
  -- grep -q "^    askable: false" org-packs/_workspaces/all/catalogue/config/toggles.yaml
capture -- deck --scope catalogue toggle explain price_history_window
exited "explain the folded toggle" 0
also "the answer became the default" "effective  : 12-months"
also "and what each value costs came from the person" \
  "unbounded      Every entry ever recorded is published."
fails_saying "outside the initiative it does not exist" \
  "unknown toggle: price_history_window" -- deck toggle get price_history_window

python3 - <<'PY'
import json, pathlib
p = pathlib.Path("catalog-schema/catalog.json"); d = json.loads(p.read_text())
for f in d["fields"]:
    if f["name"] == "price_history":
        f["required"] = False
p.write_text(json.dumps(d, indent=2) + "\n")
PY
cat >> catalog-schema/README.md <<'MD'

`price-history` is published as a list, bounded to twelve months. See the
`price_history_window` toggle for why, and what the other answers would cost.
MD
cat >> catalog-api/README.md <<'MD'

`price-history` is served from the contract, bounded to twelve months.
MD
says "with both failures cleared, the ladder passes" "5 gate(s) passed in 9 run(s)" \
  -- deck --scope catalogue gate run --task CAT-1

git -C catalog-schema commit -aqm "CAT-1: publish a bounded price-history field"
git -C catalog-api commit -aqm "CAT-1: document the price-history window"

# ----------------------------------------------------------- act 5 · bundle
capture -- deck --scope catalogue bundle --task CAT-1
exited "bundle refuses while artifacts are still placed" 1
also "and says which command takes them back" "deck unmount --task CAT-1"

ok "unmount" -- deck unmount --task CAT-1
ok "close CAT-1" -- deck --scope catalogue board done CAT-1 --yes

capture -- deck --scope catalogue bundle --task CAT-1
exited "bundle" 0
also "READY is a claim about what it checked" \
  "READY — everything this bundle checks is in place"
also "and it names what it could not check" \
  "the ladder ran inside scope \`catalogue\` over 2 of 4 repositories"
also "the change set is attributed by commit message" \
  "basis    commits whose message names CAT-1"
also "it names a reached repository with no commit" \
  "storefront-web       reached, no commit under this task"
also "the rung reached" "level    build"
also "what was measured" "what was measured"
also "the decision, with the reason recorded beside it" \
  "why  this initiative has no staging slot of its own yet"
also "the question and its answer" \
  "-> 12-months — older entries are aggregated, not published."
also "and where every claim can be checked" "where each claim comes from"

capture -- deck --scope catalogue bundle --task CAT-1 --markdown --write
exited "bundle --markdown --write" 0
also "it saves a file to paste into a pull request" ".deck/bundles/CAT-1.md"
ok "which exists" -- test -f .deck/bundles/CAT-1.md

# ---------------------------------------------------------- act 5 · metrics
python3 - <<'PY'
import pathlib
p = pathlib.Path("catalog-api/README.md")
p.write_text(p.read_text().replace("TODO: the price route has no pagination.\n", ""))
PY
git -C catalog-api commit -aqm "CAT-1: paginate the price route"
ok "one more run of the ladder" -- deck --scope catalogue gate run --task CAT-1
capture -- deck metrics show todos.open_items --repo catalog-api
exited "metrics show" 0
also "the series is a file" ".deck/metrics/todos.open_items@catalog-api.jsonl"
also "the trend is reported with its direction" "moving the right way (\`better: lower\`)"
also "and it is kept apart from judgement" \
  "Nothing here failed anything. A gate reports a threshold; this reports a direction."

fails_saying "cost refuses to invent a number nobody measured" \
  "no session of this workspace has a transcript yet" -- deck cost --task CAT-1

# ---------------------------------------------------------- act 6 · propose
# Free, offline, and the whole point of the act: the refusal and the prompt.
capture -- env -u ANTHROPIC_API_KEY deck propose impacts --repos catalog-schema catalog-api
exited "propose refuses before it spends anything" 1
also "saying what it would do" "It runs read-only, costs money, and writes nothing but a file"
capture -- env -u ANTHROPIC_API_KEY deck propose impacts \
  --repos catalog-schema catalog-api --show-prompt
exited "--show-prompt costs nothing" 0
also "and it is a worked example of asking for something reviewable" \
  "Evidence one way and a hunch the other is an edge, not a coupling."

# ------------------------------------------------------------ start over
for r in catalog-schema catalog-api storefront-web deploy-scripts; do
  git -C $r checkout -q .
  git -C $r clean -qfd
done
rm -rf .deck docs org-packs ai-packs
ok "the reset the README documents works" -- ./setup.sh

summary "03 · many teams, one registry"
