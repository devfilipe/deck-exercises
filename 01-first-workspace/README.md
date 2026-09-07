# 1 · Your first workspace

Build one from an empty directory, and use it. Nothing is downloaded and nothing
is pre-made: every file here is one you write, which is the point — by the end
you will know where each thing lives and why.

About twenty minutes. No agent required; the last step adds one.

> Every command below is replayed by [CI](../verify/01-first-workspace.sh) on
> every push, and every quoted output is asserted. If a step here stops working,
> the build says so before you do. The one exception is step 10, which needs
> Claude Code and is marked optional for that reason.

---

## 0 · Check the tool answers

```bash
mkdir -p ~/lab/hello && cd ~/lab/hello
deck --help | head -5
```

A list of subcommands means step 0 is done. deck does not know anything about
this directory yet — there is no repository and no descriptor here. That is the
expected state.

## 1 · Give the workspace something to be a workspace *of*

deck exists for what an agent cannot work out on its own: how your repositories
pull on each other. With one repository there is nothing to answer, so make
three with a real dependency between them.

```bash
for r in hello-schema hello-api hello-cli; do
  mkdir -p $r
  git -C $r init -q
  echo "# $r" > $r/README.md
  git -C $r add -A
  git -C $r commit -qm "init"
done
```

The shape you will declare in step 4, not now:

```
hello-schema   the contract (changes first)
     ↓
hello-api      implements the contract
     ↓
hello-cli      consumes the api
```

`deck setup` finds repositories by looking for `.git`. A directory without one
is not counted, deliberately: what is not versioned is not traceable.

## 2 · Look, without writing anything

```bash
deck setup --dry-run
```

```
deck setup  (discovery — nothing will be written)  ·  ~/lab/hello

1  What is in this workspace?
   3 git repositories found:
     hello-api
     hello-cli
     hello-schema

2  Where will the knowledge live?
   No pack collection named.
   Knowledge has to live somewhere a team can review and version, and
   that is a decision worth making deliberately rather than by default.
   Re-run with --packs-root <path> — a directory in this workspace, or a
   separate repository your team shares:

      deck setup --packs-root ./ai-packs          # beside the code
      deck setup --packs-root ~/work/ai-packs     # a shared repository
```

It exits **non-zero**, and `ls -A` shows nothing was written.

**It stops at step 2 on purpose.** Not an error, and not missing information —
it is the one decision in the whole process the tool has no right to make for
you: where the team's knowledge will live. A default here would become the
permanent answer of everyone who never read the question.

Notice also that it found the repositories alphabetically, not in dependency
order. It does not know there *is* a dependency yet. That is step 4.

## 3 · Make the decision

```bash
deck setup --packs-root ./ai-packs --create-packs
```

```
4  Linking packs to repositories, by name
   linked   hello-api                          ~/lab/hello/ai-packs/hello-api
   linked   hello-cli                          ~/lab/hello/ai-packs/hello-cli
   linked   hello-schema                       ~/lab/hello/ai-packs/hello-schema
   shared   (every repository)                 ~/lab/hello/ai-packs/_workspace
   created 4 pack(s); each one is a skeleton to fill in
```

(deck prints the absolute path, not `~`. Every output on this page is real;
the only edit is that shortening.)

**The link between a pack and a repository is the directory name.** There is no
mapping table, because a mapping table is a file nobody keeps current.
`_workspace` is what applies to all of them.

> In a real team this would be `--packs-root ~/work/ai-packs`, pointing at a
> repository the team shares, so several products draw on one collection. The
> mechanism is identical.

Look at what appeared:

```bash
ls -A            # .deck/ and ai-packs/
cat .deck/workspace.yaml
```

The division that holds forever:

| | Where | Versioned |
|---|---|---|
| `.deck/` | your machine | **no** — paths, hosts and tokens differ per person |
| `ai-packs/` | the team | **yes** — it is the knowledge, reviewed like code |

## 4 · Write the edges

The first of three things only you can write. deck does not infer them: a
manifest declares a *checkout*, never a *propagation*.

In `.deck/workspace.yaml`, change two `impacts:` lines:

```yaml
repos:
  hello-api:
    path: hello-api
    impacts: [hello-cli]          # was []
  hello-cli:
    path: hello-cli
    impacts: []                   # stays empty: nothing depends on it
  hello-schema:
    path: hello-schema
    impacts: [hello-api]          # was []
```

Read an edge as **"when this changes, that has to be revisited"** — the opposite
direction from what intuition suggests, and the one that is useful for planning.

```bash
deck impact hello-schema
deck impact hello-api
```

The first reaches 2 repositories, in the order `hello-schema → hello-api →
hello-cli`. The second reaches 1.

Transitivity is the point: you declared `schema → api` and `api → cli`, never
`schema → cli`. deck closes it. That is what stops someone changing the contract,
building the api, and forgetting the cli.

## 5 · Write the commands

The second. deck has never heard of `npm`, `bitbake` or `make` — it runs the
strings your pack declares.

Replace `ai-packs/_workspace/config/gates.yaml` with:

```yaml
gates:
  - id: readme
    title: Every repository documents itself
    from_level: static
    per_repo: "test -f README.md"

  - id: build
    title: Build
    from_level: build
    per_repo: "echo building ${repo.name}"
```

`readme` is a real test — it passes or fails on whether the file exists.
`from_level` is the rung each gate enters at; the ladder is
`static → build → deploy → behavior`, and it comes from the values of the
`gate_level` toggle, not from deck's code.

```bash
deck gate list
deck gate run --task hello-1
```

Expect `2 gate(s) passed in 6 run(s)` — two gates over three repositories — and
an evidence path under `.deck/gates/`, which outlives the session.

To watch it be honest, break something on purpose:

```bash
rm hello-cli/README.md
deck gate run --task hello-2      # fails, and names the repository
git -C hello-cli checkout README.md
```

## 6 · Write one decision

The third. A *toggle* is a decision your team keeps re-making, written once — and
which an agent knows how to turn into a question at the right moment.

In `ai-packs/_workspace/config/toggles.yaml`, under the `toggles:` key, indented
as the commented example is:

```yaml
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
```

Three details that earn their place:

- **`default: ask`** — there is no default answer. It stays pending until a
  person decides.
- **`applies_to`** — the question only appears when the change touches
  `hello-schema/`. Asking outside that is noise.
- **`impact` per value** — what choosing it *costs*, not a restatement of the
  value's name.

```bash
deck toggle validate --strict     # checks the wording, not only the syntax
deck toggle explain schema_compat
```

`--strict` enforces things a reader would otherwise pay for: a header of at most
12 characters, at most four askable values, every value reachable through an
option, `off`/`on`/`yes`/`no` quoted.

Now watch the filters:

```bash
deck toggle ask-plan --stage plan --files hello-cli/main.py
deck toggle ask-plan --stage plan --files hello-schema/contract.yaml
deck toggle ask-plan --stage verify --files hello-schema/contract.yaml
```

All three print JSON, and none of them prints nothing: the core's own
`requirement_link` is asked at `plan` whatever you touch. What changes across
the three is whether `schema_compat` is in `questions`:

| Situation | Asks `schema_compat`? |
|---|---|
| editing `hello-cli/main.py` | **no** — outside `applies_to` |
| editing `hello-schema/contract.yaml` | **yes** |
| at stage `verify` | **no** — the toggle is `stage: [plan]` |

That is what stops an agent burying you in irrelevant questions.

## 7 · Check the whole thing

```bash
deck doctor
deck packs
```

`doctor` should be `OK` everywhere and end with `4 warning(s)` — one per
repository with no `origin` remote, plus one for the empty `targets` list.
**Warnings, not problems** — deck distinguishes them, and a workspace with
nothing to deploy to is a valid state.

`deck packs` lists the four packs in merge order: `_workspace` first, then the
per-repository ones.

## 8 · Declare where tasks live

deck does not invent a board. It points at what the team already keeps — a file,
a requirements matrix, a tracker. Here, a file versioned with the code.

In `.deck/workspace.yaml`, replace `backlog: []`:

```yaml
backlog:
  - { type: tasks, file: docs/board.yaml }
```

```bash
mkdir -p docs
deck board new "Add a version field to the greeting contract" \
  --id HW-1 --repos hello-schema --ext jira:HW-1 --yes
deck board show HW-1
```

The line that matters:

```
  reaches   hello-schema, hello-api, hello-cli
```

You declared the task as touching **one** repository. deck closed the reach
through the edges from step 4 and answered **three**, in execution order. That is
the difference between "what I will edit" and "what this change obliges me to
revisit" — the answer nobody remembers to give in full at six in the evening.

`--ext jira:HW-1` records where the task lives in another system. Declare a Jira
source that returns `HW-1` one day and the two become a single task, not two
rows.

> A board file has no default location on purpose. `.deck/` is per machine, so a
> shared board there would be invisible to the team and gone with the checkout.

## 9 · Give the agent context, and take it back

A pack is only worth having if something from it reaches the repository at the
moment of work. Write the rule `hello-schema` deserves, in
`ai-packs/hello-schema/rules/contract.md`:

```markdown
---
paths: ["*.yaml", "*.json"]
---

hello-cli is installed separately and does not negotiate versions. A removed or
renamed field breaks every deployed client silently — the breakage shows up as a
support ticket weeks later, not as a red build.

Before touching a name that already exists, check the `schema_compat` toggle.
```

Delete the scaffolded `ai-packs/hello-schema/rules/example.md`, and declare the
rule in `ai-packs/hello-schema/config/mount.yaml`:

```yaml
rules:
  - { file: rules/contract.md }
```

There is no `repos:` on that line, and none is needed: the pack is named
`hello-schema`, so what it declares applies there and nowhere else. A convention
written for one repository does not become law across the workspace by
forgetfulness.

```bash
deck board claim HW-1 "$USER" --yes
deck mount --task HW-1 --repos hello-schema

find hello-schema/.claude hello-api/.claude -type l -o -type f 2>&1
```

The rule appears at `hello-schema/.claude/rules/deck-contract.md`, and
`hello-api/.claude` does not exist.

It is placed as a **copy**, not a symlink — `ls -l` shows `-rw-r--r--`. That is
deliberate and it is not an implementation detail: Claude Code loads
`.claude/rules/*.md`, and it does not follow a symlink there. A mount that
reported success while placing something the runtime silently ignores would be
worse than no mount at all. Every placed file is listed in a manifest under
`.deck/mounts/`, and `unmount` removes exactly those and nothing else — which is
why the next command can say `1 removed · 0 left alone` rather than guessing.

Edit the pack, not the copy: re-mounting replaces it.

```bash
deck gate run --task HW-1
deck unmount --task HW-1
ls -A hello-schema/
```

`unmount` reports `1 removed · 0 left alone`, and takes the `.claude/`
directories it created with it. `hello-schema/` is back to `.git README.md`.

## 10 · Add the agent

Everything so far worked without one. The plugin is what makes Claude reach for
deck unprompted.

```bash
claude plugin enable deck@deck --scope project
claude plugin list | grep -A3 deck@      # ✔ enabled
```

That writes `.claude/settings.json` — the file a real team commits, so a
colleague who clones the workspace gets deck switched on without doing anything.

Open Claude in the directory and ask for something that touches the contract:

```
I need to add a `version` field to the hello-schema contract. What does it touch?
```

What should happen, and which skill asks for it:

| Claude should | because the skill says |
|---|---|
| run `deck impact hello-schema` rather than reading directories | `workspace`: no hardcoded paths; the descriptor is the only source |
| answer the three repositories **in order** | the topological order comes from the graph |
| ask you `May this change alter the published contract?` with the three options | `toggles`: consult `ask-plan` before planning |
| mount the rule before editing, and unmount at the end | `mount` |
| not say "done" before `deck gate run` | `gates`: BLOCKED is never a pass |

That question box is **Claude Code's**, not deck's. deck supplies the content —
the header, the text, the options with their consequences, straight out of the
catalog you wrote in step 6 — and the runtime supplies the box. deck never drew
a question UI and never will.

To close the loop:

```bash
deck gate run --task HW-1
deck unmount --task HW-1
deck board done HW-1 --yes
deck cost --task HW-1
```

`done` refuses a task with no gate evidence, or with a gate that failed: closing
is a claim about verification, so it wants the record that backs it.

`cost` covers the window from mount to unmount, and counts only sessions of this
workspace. If you did the whole exercise in a terminal without ever opening
Claude, it **fails** rather than printing a zero:

```
deck: no session of this workspace has a transcript yet (~/.claude/projects/…)
```

That is the right answer. It reads Claude Code's own transcripts, and a zero
would be indistinguishable from "nothing was spent".

---

## What you have now

```
~/lab/hello/
├── .deck/              yours. paths, choices, evidence. Not versioned.
├── ai-packs/           the team's. edges are in the descriptor; commands,
│   ├── _workspace/     decisions and rules live here. Versioned.
│   ├── hello-api/
│   ├── hello-cli/
│   └── hello-schema/
├── docs/board.yaml     the tasks
├── hello-api/
├── hello-cli/
└── hello-schema/
```

Version the half that is the team's:

```bash
git -C ai-packs init -q && git -C ai-packs add -A
git -C ai-packs commit -qm "hello packs: ladder, contract rule, schema_compat"
```

Next: **[2 · polyglot](../02-polyglot/)**, a project that already exists, with
four layers and five tasks that each teach one thing.
