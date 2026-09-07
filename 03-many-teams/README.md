# 3 · Many teams, one registry

Four repositories, two pack collections, one initiative, and a decision nobody
had made yet.

The first two exercises had one team and one collection of knowledge. That is
where everybody starts and almost nobody stays: a second team turns up with
conventions of its own, an initiative cuts across half the registry and none of
the rest, and a question arrives that no catalog has an entry for. This exercise
is those three things.

About an hour. No agent required; nothing here needs the network, and the one
step that costs money is optional and marked.

> Every block of output on this page was copied from a real run, and
> [CI replays it](../verify/03-many-teams.sh) on every push. The only edit is the
> absolute path of your checkout, shown as `…/03-many-teams`. Commit hashes,
> timestamps and the consultation id are from that run; yours will differ.

---

## Set it up

```bash
./setup.sh
deck doctor
```

`setup.sh` makes the four directories into repositories and seeds `.deck/` with
the registry — the repositories, the roles, the edges. Exercise 1 taught you to
write those; repeating it here would buy nothing.

What it deliberately does **not** seed is everything this exercise is about:
`packs_root`, `paths`, `targets` and `scopes` are empty, and you fill them.

```
workspace
  OK root …/03-many-teams  (descriptor at …/03-many-teams/.deck)
  OK descriptor present  4 repositories, 0 target(s)
  !! packs  none — the core alone knows no build, deploy or lint command
```

`doctor` ends with **6 warnings and no problem**: no pack, four repositories
with no `origin`, and no target. Every one of them is a true statement about a
valid state, which is why they are warnings.

## The shape

```
   catalog-schema      the published contract. One file, one list of fields,
        │              and the only place a field is ever declared.
        ├──────────────────────┐
        ▼                      ▼
   catalog-api           storefront-web      the pages a customer sees
        ╎
        ╎ couples
        ╎
   deploy-scripts        the commands that put a build where it runs
```

Three of those edges are `impacts:` — one direction, an order. The fourth is
different:

```bash
deck impact catalog-api
```

```
a change in catalog-api reaches 1 repository

execution order:
  1. catalog-api
  2. storefront-web

coupled with, in no order:
  - deploy-scripts  the commands that put a build where it runs   (declared by catalog-api)

  A coupling is mutual and carries no order: revisit these, do not sequence them.
  They take no part in the execution order above, and never in a build order.
```

`catalog-api` shells out to the deployment scripts at run time, and the scripts
read the configuration `catalog-api` writes at start-up. Each side breaks the
other and **neither goes first**. Written as two `impacts:` edges that is a
cycle and the topological order stops existing; written as one edge with the
other in a comment, a constraint is thrown away that no command can then use.

`couples:` is that relationship recorded — and `doctor` says exactly what it
does and does not do with it:

```
  OK coupling  catalog-api <-> deploy-scripts   (declared by catalog-api, which is enough)
  OK coupling effect  what it does: `deck impact`, `deck mount` and a scope's boundary report reach both sides. What it does not: no part in `deck order`, in the cycle check above, or in any build order — a coupling can never make this graph cyclic
```

Hold on to it. In the last act it is what tells you the initiative's boundary is
drawn in the wrong place.

---

# Act 1 · What the workspace uses, and what it may touch

Two lines in the descriptor, and neither is about a repository.

## `paths` — used, not changed

`tools/count-todos.sh` counts what is still marked TODO. It belongs to no
repository: it is a thing the workspace *uses*. Something you change is a
repository; something you only invoke is a path.

In `.deck/workspace.yaml`, replace `paths: {}`:

```yaml
paths:
  tools: tools
```

```bash
deck paths
```

```
tools	…/03-many-teams/tools
```

The gate you write in a minute says `${path.tools}/count-todos.sh`. That is what
keeps a pack portable across machines: the pack names `tools`, and this file —
yours, per machine, never versioned — says where yours is.

## `targets` — an allowlist, not a list of machines

Replace `targets: []`:

```yaml
targets:
- { host: 10.0.0.4, role: staging, alias: lab-1, notes: the shared staging box }
```

```bash
deck targets
```

```
10.0.0.4	staging	lab-1
```

Nothing is deployed in this exercise, and nothing has to be. The point is what
the list *is*: deck denies `ssh`, `scp` and `http` to any host that is not in it,
so an empty list means no deployment and no behaviour gate — which is what
`doctor` was warning about. Run `deck doctor` again and that warning is gone,
replaced by a note:

```
targets (allowlist)
  .. 10.0.0.4  alias=lab-1  (use --net to test reachability)
```

Add a machine deliberately, never "just in case", and never a customer's.

---

# Act 2 · Two collections, and what merge order means

An organisation ends up with knowledge at two altitudes: what every repository
follows because the organisation says so, and what one repository needs because
of what it is. Those have different owners and different review, so they are
different collections.

## The organisation layer

```bash
deck pack new _common --dir ./org-packs/_common \
  --description "What every repository in the organisation follows"
```

`_common` is one of the four names deck reads as "every repository" —
`_workspace`, `_all`, `_shared`, `_common` — so the pack applies everywhere
without naming anybody.

Replace `org-packs/_common/config/gates.yaml` with the ladder the organisation
runs everywhere:

```yaml
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
```

Then point the descriptor at it — `packs_root` takes a **list**, because
layering is real:

```yaml
packs_root:
- org-packs
```

```bash
deck packs
deck gate run --task ORG-1
```

```
task ORG-1 · level deploy · 4 repositories
target 10.0.0.4 (staging)

  ok   readme       catalog-schema             0.0s
  ok   readme       catalog-api                0.0s
  ok   readme       storefront-web             0.0s
  ok   readme       deploy-scripts             0.0s
  ok   todos        catalog-schema             0.0s
       open_items   0 lines
  ok   todos        catalog-api                0.0s
       open_items   1 lines
  ok   todos        storefront-web             0.0s
       open_items   2 lines
  ok   todos        deploy-scripts             0.0s
       open_items   0 lines
  ok   build        catalog-schema             0.1s
  ok   build        catalog-api                0.0s
  ok   build        storefront-web             0.0s
  ok   build        deploy-scripts             0.0s

  3 gate(s) passed in 12 run(s)
  evidence: …/03-many-teams/.deck/gates/ORG-1.json
  4 measurement(s) added to the series · deck metrics list
```

Two things in that output are the whole act.

**`build` is one gate, and it ran a different command in each repository.** The
pack wrote `${repo.build}` once; the descriptor says what each repository's
command is — `python3 -m json.tool catalog.json` here, `sh -n deploy.sh` there.
The pack stays the organisation's and the commands stay each repository's, and
neither has to know about the other.

**`todos` did not judge anything.** It passed, and it kept four numbers. A
*measure* is read out of the output a gate already produced — never a second
command, which could disagree with the first — and appended to a series. Nothing
about a measurement can fail a gate. Come back to that in Act 5.

## The repository layer

`catalog-schema` owns the contract, and the contract has a rule nothing else in
the organisation cares about: every field says whether it is required. That
knowledge belongs to one repository.

```bash
deck pack new catalog-schema --dir ./ai-packs/catalog-schema \
  --description "The contract everyone else reads"
```

Replace `ai-packs/catalog-schema/config/gates.yaml`:

```yaml
version: 1

gates:
  - id: required-fields
    title: Every declared field says whether it is required
    from_level: static
    per_repo: "python3 check-fields.py"
```

The gate names a command; `catalog-schema/check-fields.py` is the command, and
it lives in the repository it checks. A pack that shipped the checker itself
would be a pack that has to be updated whenever the contract's shape moves.

Add the second collection to the descriptor:

```yaml
packs_root:
- org-packs
- ai-packs
```

```bash
deck packs
```

```
packs   2 in play, merged most general first

  1  _common                      every repository     0 toggle(s) · 3 gate(s) · 0 rule(s)
     …/03-many-teams/org-packs/_common
  2  catalog-schema               catalog-schema       0 toggle(s) · 1 gate(s) · 0 rule(s)
     …/03-many-teams/ai-packs/catalog-schema

roots
  …/03-many-teams/org-packs
  …/03-many-teams/ai-packs
```

**Most general first, so the most specific has the last word.** And notice what
nobody wrote: `required-fields` is scoped to `catalog-schema`, with no
`only_repos:` anywhere.

```bash
deck gate list
```

```
  ->   readme       Every repository documents itself runs
       over catalog-schema, catalog-api, storefront-web, deploy-scripts
  ->   todos        What is still marked TODO  runs
       over catalog-schema, catalog-api, storefront-web, deploy-scripts
  ->   required-fields Every declared field says whether it is required runs
       over catalog-schema
  ->   build        Build                      runs
       over catalog-schema, catalog-api, storefront-web, deploy-scripts
```

A gate declared by a pack named after a repository defaults to that repository.
Its `build` command silently running against a sibling would be an efficient way
to fail a delivery for a reason nobody can locate.

Watch it be real. Add a field to `catalog-schema/catalog.json` and leave out
`required`:

```json
    { "name": "price_history", "type": "array" }
```

```bash
deck gate run --task ORG-2
```

```
  FAIL required-fields catalog-schema             0.0s
       exit 1 · …/03-many-teams/.deck/gates/logs/ORG-2/required-fields-catalog-schema.log
       | no 'required' on: price_history
  --   build        not attempted: an earlier gate failed
```

Put it back the way it was — `git -C catalog-schema checkout catalog.json` — the
field comes back for real in Act 4.

## The trap: what `overrides:` does, and what it does not

`catalog-schema` might reasonably want its own `build`. Try it, in
`ai-packs/catalog-schema/config/gates.yaml`:

```yaml
  - id: build
    title: Build
    from_level: build
    per_repo: "python3 -m json.tool catalog.json && echo the contract parses"
```

```bash
deck gate run --task ORG-3
```

```
deck: catalog-schema: gate `build` already exists (from _common). Set `overrides: true` to extend it deliberately.
```

Good refusal: two gates answering to one name is not something anyone meant. So
add the flag it asks for, `overrides: true`, and run it again:

```
  ok   build        catalog-schema             0.0s
  FAIL build        catalog-api                0.1s
  FAIL build        storefront-web             0.0s
  FAIL build        deploy-scripts             0.0s
```

```
$ tail -1 .deck/gates/logs/ORG-3/build-catalog-api.log
FileNotFoundError: [Errno 2] No such file or directory: 'catalog.json'
```

**An override is not scoped to the pack that wrote it.** The default that put
`required-fields` in one repository applies to a *new* gate id; an override says
what it changes and nothing else, and here what it changed was every
repository's build command. You were lucky: this one failed loudly. An override
whose command happens to succeed everywhere is the same mistake, silent, with
three repositories now verified by a command written for a fourth.

Delete that entry. The organisation's `build` gate was already right, because it
never hard-coded a command: `${repo.build}` asks the descriptor, and the answer
is per repository by construction.

> If a repository genuinely needs a check no other one has, give it a **new id**
> in its own pack — which is what `required-fields` is — and leave the shared
> gate alone.

---

# Act 3 · An initiative is a subset with a board and a posture

Four repositories is small enough to hold in your head. Forty is not, and the
thing you actually work on is never all of them: it is six, for three months,
with a board of their own and a different appetite for risk.

That is a **scope**. In `.deck/workspace.yaml`, replace `scopes: {}`:

```yaml
scopes:
  catalogue:
    title: Publish price history
    repos: [catalog-schema, catalog-api]
```

```bash
deck scope catalogue
```

```
catalogue  Publish price history

  repositories  2 of 4
      catalog-schema               the published product contract — the only place a field is declared
      catalog-api                  serves what the contract declares, and invents no field of its own

  reaches       storefront-web   (outside the scope, still has to keep up)
  coupled with  deploy-scripts   (outside the scope, mutual and in no order)
                revisit them before shipping, do not sequence them — or
                take them into the scope, under `repos:` beside the 2 above

  board         the workspace board, narrowed
  posture       none recorded — it inherits the workspace's
                deck toggle set --at catalogue <id> <value>

  work in it:   deck --scope catalogue board plan
```

**The report that matters is what the subset does not hold**, and it leaks two
ways, on two lines rather than one:

| | what it is | order |
|---|---|---|
| `reaches` | the `impacts:` chain runs out of the scope: `storefront-web` has to keep up | yes — it is a chain |
| `coupled with` | the scope holds one half of a `couples:` pair | **no** — merging it into the line above would hand a coupling a position in a sequence it has no place in |

The second line is the one worth having before the work starts. `catalog-api`
and `deploy-scripts` break each other with evidence on both sides; an initiative
that owns one and not the other has a boundary that is wrong, or a dependency
its owners have not agreed with anyone. Neither line is an error. Both are a
question to settle now rather than in the merge.

## What `--scope` narrows

```bash
deck --scope catalogue board list
deck --scope catalogue gate list
```

```
  scope catalogue — the workspace board, narrowed to its repositories

  [ ] CAT-1                    Publish a price-history field on the contract
        catalog-schema
  [ ] CAT-2                    Serve price history from the api
        catalog-api
```

`WEB-1` and `OPS-1` are still on the board; they are not this initiative's. A
scope may also declare a `backlog:` of its own, and then that file *is* its
board and the workspace's is not read at all.

It narrows what a command **acts on**, never what deck **knows**: `deck impact
catalog-api` still reports the whole chain and marks what falls outside, because
a subset that hides an edge is worse than no subset at all.

## A posture of its own

```bash
deck toggle set --at catalogue gate_level build \
  --why "this initiative has no staging slot of its own yet"
```

```
gate_level = build  (scope catalogue → …/03-many-teams/.deck/toggles.yaml)
  why: this initiative has no staging slot of its own yet
```

```bash
deck --scope catalogue toggle explain gate_level   # effective : build
deck toggle explain gate_level                     # effective : deploy
```

A scope sits between the repository and the workspace in the precedence chain —
narrower than "everywhere", wider than one checkout:

```
task > DECK_<ID> in the environment > repos: > scopes: > values: > profile > catalog default
```

And `--why` is not decoration. `deck --scope catalogue toggle explain gate_level`
prints it back under **why this value was chosen**, kept apart from the
catalog's **why the toggle exists**. A value nobody wrote a reason for is
reported as having none, which is the point: six months later, a decision and a
value nobody revisited must not look the same.

## A pack that belongs to the initiative

Some knowledge only matters while an initiative is running. It should arrive
with it and leave with it, and it should be versioned by the people who own the
initiative rather than the people who own the registry.

```bash
deck pack new catalogue-work --dir ./org-packs/catalogue-work \
  --scope catalogue --from-workspace \
  --description "What this initiative needs, and only while it runs"
```

```
  Bound to the `catalogue` scope: it loads under `deck --scope catalogue` and
  nowhere else, and its template ships that initiative rather than the
  registry. `deck packs` lists it either way, in play or waiting.
```

`--from-workspace` wrote the initiative into the pack's descriptor template:

```yaml
# org-packs/catalogue-work/templates/workspace/workspace.yaml
scopes:
  catalogue:
    title: Publish price history
    repos:
    - catalog-schema
    - catalog-api
```

That is what makes a scope the **team's** rather than one person's. `.deck/` is
per machine, so a scope nobody templated is a scope only its author has. The
registry is never merged — which repositories exist is a description of a thing
that exists, and a second opinion about it is a contradiction — but scopes are,
from every pack, because how to divide attention is a decision and several can
be true at once.

Give the pack the check the initiative is accountable for, in
`org-packs/catalogue-work/config/gates.yaml`:

```yaml
version: 1

gates:
  - id: history-documented
    title: Price history is described where it is published
    from_level: static
    per_repo: "grep -q price-history README.md"
```

and the rule that should reach an agent while it works, in
`org-packs/catalogue-work/rules/history.md` (delete the scaffolded
`rules/example.md`):

```markdown
---
paths: ["*.json"]
---

Price history is a list, and a list published on a contract has no natural end.
Before adding one, say how far back it goes: the payload grows with every entry
and nothing downstream can shorten it afterwards.

The decision is recorded as `price_history_window`. Read it, do not re-derive it.
```

Declare it in `org-packs/catalogue-work/config/mount.yaml`:

```yaml
rules:
  - { file: rules/history.md }
```

```bash
deck packs                      # catalogue-work: not in play
deck --scope catalogue packs    # catalogue-work: 2nd, between _common and catalog-schema
```

```
not in play   bound to an initiative, and loaded only while it is active
  catalogue-work               scope catalogue      0 toggle(s) · 1 gate(s) · 1 rule(s)
     …/03-many-teams/org-packs/catalogue-work
     bring it in with: deck --scope catalogue <command>
```

The full order, most general first:

```
   named explicitly     `packs:` in the descriptor
          ↓
   _common              every repository, by its name
          ↓
   scope: catalogue     every repository the initiative holds, while it is active
          ↓
   catalog-schema       that repository, and no other
```

---

# Act 4 · The work, and a question nobody had an answer for

```bash
deck --scope catalogue board claim CAT-1 "$USER" --yes
deck --scope catalogue mount --task CAT-1 --repos catalog-schema
```

```
mounted for task CAT-1

  rule     catalog-schema               …/03-many-teams/org-packs/catalogue-work/rules/history.md
  rule     catalog-api                  …/03-many-teams/org-packs/catalogue-work/rules/history.md

  2 artifact(s) · manifest at …/03-many-teams/.deck/mounts/CAT-1.json
```

The rule landed in **both** scope repositories, from `--repos catalog-schema`
alone: mounting places what the change *reaches*, not only what you named.

It is placed as a plain file, not a symlink — `ls -l
catalog-schema/.claude/rules/` shows `-rw-r--r--`. Claude Code loads
`.claude/rules/*.md` but does not follow a symlink there, and a mount that
reported success while placing something the runtime silently ignores would be
worse than no mount at all. Every placed file is recorded in a manifest, and
`unmount` removes exactly those.

Now do the task. Add the field to `catalog-schema/catalog.json`:

```json
    { "name": "price_history", "type": "array" }
```

```bash
deck --scope catalogue gate run --task CAT-1
```

```
task CAT-1 · level build · 2 repositories
target 10.0.0.4 (staging)

  ok   readme       catalog-schema             0.0s
  ok   readme       catalog-api                0.0s
  ok   todos        catalog-schema             0.0s
       open_items   0 lines · was 0 on ORG-3
  ok   todos        catalog-api                0.0s
       open_items   1 lines · was 1 on ORG-3
  FAIL history-documented catalog-schema             0.0s
  FAIL history-documented catalog-api                0.0s
  --   required-fields not attempted: an earlier gate failed
  --   build        not attempted: an earlier gate failed
```

`level build`, not `deploy` — the posture you recorded at the scope is in force,
and the report says which rung it reached rather than hiding the difference.

The rule you mounted says the decision is recorded as `price_history_window`.
It is not:

```bash
deck --scope catalogue toggle get price_history_window
```

```
deck: unknown toggle: price_history_window
```

**This is the moment the exercise exists for.** There is no catalog entry, no
default, and no honest way to invent one: how far back a published list goes is
a product decision with a payload cost, and nobody has made it. An agent that
guessed here would be guessing about something a customer sees.

```bash
deck ask new "How far back does the published price history go?" --task CAT-1 \
  --context "The contract can publish an unbounded array. Nobody has said how much of it the storefront is allowed to show, and the payload grows with every entry." \
  --options "unbounded,90-days,12-months"
```

```
recorded 20260907-022954-how-far-back-does-the-published-price-hi
  How far back does the published price history go?

  It is written down and will outlive this session. Answer it with:
    deck ask resolve 20260907-022954-how-far-back-does-the-published-price-hi "<the answer>"

  Nothing waits on it. Say in your report what you did in the meantime,
  and what would change if the answer goes the other way.
```

Three things in that reply:

- **It outlives the session.** A question asked in a chat window and answered in
  a chat window is gone when the window closes, and the next run asks it again.
- **Nothing waits on it.** Recording a question is not a lock. Work continues,
  and the report says what was assumed.
- **The id is a timestamp and the question.** Yours will differ. Everything
  below uses `$ASK`:

```bash
ASK=$(deck ask list --json | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["id"])')
deck ask show "$ASK"
```

Now answer it as the person who is allowed to:

```bash
deck ask resolve "$ASK" "12-months — older entries are aggregated, not published." \
  --who someone@example.com
```

```
answered 20260907-022954-how-far-back-does-the-published-price-hi
  How far back does the published price history go?
  -> 12-months — older entries are aggregated, not published.

  This answer is a transcript until someone writes it down.
  It probably wants to become: toggle — it had named options, so it may be a decision that recurs

  Fold it:   deck ask fold <id> --as <rule|toggle|gate> --into <pack>
  Or draft:  deck propose toggle "<the decision, in one line>" --yes
  Until then the next run has to ask again.
```

**"A transcript until someone writes it down."** That sentence is the whole
feature. An answered question that stays in the consultation log has cost a
person's attention once and will cost it again.

## Folding it in

```bash
deck ask fold "$ASK" --as toggle --into org-packs/catalogue-work \
  --gate-id price_history_window --title "Price-history window" --group quality \
  --impact "unbounded=Every entry ever recorded is published. The payload grows without limit and nothing downstream can shorten it." \
  --impact "90-days=A quarter of history. The smallest payload that still shows a trend." \
  --impact "12-months=A year of history. Older entries are aggregated, not published."
```

The choice of `--as` is a judgement, and deck's suggestion is a suggestion:

| `--as` | when | what you must supply |
|---|---|---|
| `rule` | it is context an agent needs while editing certain files | `--paths` |
| `toggle` | it is a decision that will be re-made | `--impact` per value |
| `gate` | a machine can check it | `--command` |

`--impact` is the one that is not optional in spirit. deck writes the question
and the answer from the record; what taking each value **costs** is knowledge
only the person answering has, and a toggle without it is a list of words.

```yaml
# org-packs/catalogue-work/config/toggles.yaml
  - id: price_history_window
    group: quality
    title: Price-history window
    summary: "How far back does the published price history go?"
    type: enum
    values: [unbounded, 90-days, 12-months]
    default: 12-months
    impact:
      unbounded: Every entry ever recorded is published. The payload grows without limit and nothing downstream can shorten it.
      90-days: A quarter of history. The smallest payload that still shows a trend.
      12-months: A year of history. Older entries are aggregated, not published.
    askable: false
```

```bash
deck --scope catalogue toggle explain price_history_window   # effective : 12-months
deck toggle get price_history_window                         # unknown toggle
```

The decision exists inside the initiative and nowhere else, exactly like the
pack that carries it.

**Read `askable: false` carefully.** The fold recorded a decision that was
already taken; whether an agent should be interrupted to take it *again*, at
which stage, is a second decision, and the wording of a question does not
contain it. If this really is a choice every future contract change has to make,
you say so by hand — `stage: [plan]`, `applies_to:`, a `question:` block with a
header of twelve characters or fewer, and `default: ask` instead of the answer.
`deck toggle ask-plan` returns it only when all of that is true, and `default:
12-months` alone means decided, not pending.

## Finish the task

```bash
deck --scope catalogue gate run --task CAT-1
```

Two failures to clear, and neither is busywork:

- **`required-fields`** — the field you added has no `required` key. Give it
  `"required": false`.
- **`history-documented`** — the initiative's own gate wants `price-history`
  described where it is published, in the README of both scope repositories.

```bash
deck --scope catalogue gate run --task CAT-1
```

```
  5 gate(s) passed in 9 run(s)
  evidence: …/03-many-teams/.deck/gates/CAT-1.json
  2 measurement(s) added to the series · deck metrics list
```

Commit in each repository, naming the task in the message — that is how the
bundle in the next act attributes a change set:

```bash
git -C catalog-schema commit -aqm "CAT-1: publish a bounded price-history field"
git -C catalog-api commit -aqm "CAT-1: document the price-history window"

deck unmount --task CAT-1
deck --scope catalogue board done CAT-1 --yes
```

---

# Act 5 · What a reviewer reads instead of the diff

```bash
deck --scope catalogue bundle --task CAT-1
```

```
CAT-1  Publish a price-history field on the contract

  READY — everything this bundle checks is in place

  .. the task declares no acceptance criteria, so nothing states what it was for
  .. the ladder reached `build`; deploy, behavior did not run
  .. the ladder ran inside scope `catalogue` over 2 of 4 repositories; deploy-scripts, storefront-web were not covered
  .. storefront-web is reached by this change and has no commit under it — deliberate, or the chain stopped early

what changed
  basis    commits whose message names CAT-1
  catalog-schema       1 commit(s) · 2 file(s) · +8 -0
       81eab3c  CAT-1: publish a bounded price-history field
  catalog-api          1 commit(s) · 1 file(s) · +2 -0
       a883d46  CAT-1: document the price-history window
  storefront-web       reached, no commit under this task

what was verified
  level    build   ladder static -> build -> deploy -> behavior   2026-09-07T02:30:23
  scope    catalogue   the ladder climbed inside this initiative, not the whole registry
  no gate  deploy, behavior   the record holds none at these rungs
  ok   readme         passed
  ok   todos          passed
  ok   history-documented passed
  ok   required-fields passed
  ok   build          passed
  5 gate(s) passed in 9 run(s)

what was measured
  todos.open_items (catalog-schema) 0 lines
       0 lines, unchanged across 9 runs (ORG-1 -> CAT-1)
  todos.open_items (catalog-api) 1 lines
       1 lines, unchanged across 9 runs (ORG-1 -> CAT-1)

what was decided
    gate_level             build          from scope catalogue
       why  this initiative has no staging slot of its own yet

what was asked
  [answered] How far back does the published price history go?
           -> 12-months — older entries are aggregated, not published.

where each claim comes from
  the change set           git log, in each repository listed above
  verification             …/03-many-teams/.deck/gates/CAT-1.json
  gate output              …/03-many-teams/.deck/gates/logs/CAT-1
  decisions                deck toggle explain <id> — every layer, strongest first
  questions                …/03-many-teams/.deck/consultations
  measurements             deck metrics show <id> — every sample, with the run it came from
  what it cost             deck cost --task CAT-1
```

Read the `..` lines before the green one. **READY is a statement about what this
bundle checks**, and the lines above it are what it could not check: that the
ladder stopped at `build`, that it ran over two of four repositories, that a
repository the change reaches has no commit under it. Each is a legitimate
state and each is something a reviewer would otherwise have to reconstruct.

`where each claim comes from` is the part to steal for your own project. Every
line above it has a file behind it, and the bundle says which. A summary that
cannot be checked is a summary that gets believed.

```bash
deck --scope catalogue bundle --task CAT-1 --markdown --write
```

```
READY — everything this bundle checks is in place
  written to …/03-many-teams/.deck/bundles/CAT-1.md
  Paste it into the pull request, or attach it. It is derived, so re-run it
  after the next commit rather than editing it.
```

Run it **before** the unmount and it refuses, because two artifacts deck placed
are still in the working directories. Merging with a `.claude/` directory
somebody's tool wrote is how a product repository acquires files nobody owns.

## The numbers under the gates

```bash
deck metrics list
```

```
store    workspace · …/03-many-teams/.deck/metrics
declared 1 measurement(s), by 1 gate(s)

  todos.open_items  (catalog-api)    lines still marked TODO
       1 lines, unchanged across 9 runs (ORG-1 -> CAT-1)
  todos.open_items  (catalog-schema) lines still marked TODO
       0 lines, unchanged across 9 runs (ORG-1 -> CAT-1)
```

Remove the `TODO:` line from `catalog-api/README.md`, commit, and run the ladder
once more:

```bash
deck metrics show todos.open_items --repo catalog-api
```

```
todos.open_items  (catalog-api)
  gate     todos  (pack _common)
  pattern  (\d+) TODO
  better   lower · unit lines
  file     …/03-many-teams/.deck/metrics/todos.open_items@catalog-api.jsonl

  when                  task             rung            value
  ...
  2026-09-07T02:30:46   CAT-1            build               0

  1 -> 0 lines across 10 runs (ORG-1 -> CAT-1), -1, moving the right way (`better: lower`)
  Nothing here failed anything. A gate reports a threshold; this reports a direction.
```

That last line is the distinction worth keeping. A **gate** asserts something
and blocks when it is false. A **measure** records a number and says which way
it is going. Turning "warnings went up" into a failure is how a team ends up
with a threshold nobody dares lower and a suppression file nobody reads; keeping
them apart is how a number stays honest enough to be looked at.

## What it cost

```bash
deck cost --task CAT-1
```

If no agent has worked in this workspace, that command **fails**:

```
deck: no session of this workspace has a transcript yet (~/.claude/projects/…)
  Sessions opened elsewhere are not counted. Use --any-project to widen,
  which reports what other projects spent and is almost never what you want.
```

That is the right answer and worth noticing. `cost` reads Claude Code's own
transcripts, scoped to this workspace and to the window a mount and a gate run
recorded. With nothing to read it refuses rather than reporting a zero it did
not measure — and a zero would have been indistinguishable from "nothing was
spent".

---

# Act 6 · What a parser cannot derive — optional, and it costs money

Everything so far ran offline and free. `deck propose` does not: it asks Claude
to read the workspace and draft something a parser could never work out, such as
which repositories force each other to change.

**You do not need to run it to finish this exercise.** It makes a paid API call.
What follows is the part worth learning either way.

```bash
deck propose impacts --repos catalog-schema catalog-api
```

```
deck: this asks Claude to read the workspace and draft a proposal.
  It runs read-only, costs money, and writes nothing but a file under
  .deck/proposals/. Re-run with --yes, or set `ai_assist: allow`.
```

Three claims in a refusal, before a cent is spent: read-only, costs money,
writes one file. Then look at exactly what would be sent — free, offline, and
the most useful thing in this act:

```bash
deck propose impacts --repos catalog-schema catalog-api --show-prompt
```

```
The graph holds two kinds of edge, and they are not interchangeable:

  EDGE      `impacts:`, reported in `edges`. One direction: `from` forces `to`.
            ...
  COUPLING  `couples:`, reported in `couplings`. Two repositories that drive
            each other and neither of which comes first. ...

**Evidence one way and a hunch the other is an edge, not a coupling.** Report
the direction you can cite as an edge, and put the hunch in `unsure`, naming
what you would have had to read to settle it — a person decides that one.
```

Read the whole thing. It is a worked example of asking a model for something
reviewable: it names the two answers it will accept, says what evidence each
one costs, tells the model where to put what it could not settle, and refuses
in advance the answer that would be comfortable and wrong.

And nothing it returns is applied on its own. A proposal is a **file** under
`.deck/proposals/`, which you read, and then:

```bash
deck propose apply .deck/proposals/<file> --confidence high --yes
```

`--confidence` defaults to `medium`, so the least certain suggestions are left
out unless you ask for them. The tool that drafted the graph is not the tool
that commits it, and the step between them is a person reading a diff.

---

## What this exercise taught

| | the lesson |
|---|---|
| **paths, targets** | what a workspace uses is not what it changes, and what it may touch is an allowlist |
| **couples** | some pairs break each other with no order between them, and writing that as two edges destroys the order everything else depends on |
| **two collections** | most general first, so the most specific has the last word — and a gate from a repository's pack defaults to that repository |
| **`overrides:`** | an override says what it changes and nothing else, so it reaches every repository the original did |
| **scopes** | an initiative is a subset with a board and a posture, and the useful report is what the subset leaks |
| **a scope-bound pack** | knowledge that arrives with an initiative and leaves with it, versioned by the people who own it |
| **ask / fold** | an answer is a transcript until someone writes it down, and what each value costs is the part only a person has |
| **bundle** | READY is a claim about what was checked, and every line names the file behind it |
| **metrics** | a gate asserts; a measure records a direction — and conflating them is how a number stops being honest |

## Start over

```bash
for r in catalog-schema catalog-api storefront-web deploy-scripts; do
  git -C $r checkout .
  git -C $r clean -qfd
done
rm -rf .deck docs org-packs ai-packs
./setup.sh
```
