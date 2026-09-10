# deck exercises

Three hands-on exercises for [deck](https://github.com/devfilipe/deck), a control
plane for coding agents working across repositories.

All three are meant to be typed, not read. None needs an agent: everything works
in a plain terminal, and the last step of the first two adds Claude on top so you
can see what changes — and what does not.

| | | takes |
|---|---|---|
| **[1 · Your first workspace](01-first-workspace/)** | Build one from an empty directory. Three repositories, one dependency chain, one gate, one decision. You write every file. | ~20 min |
| **[2 · polyglot](02-polyglot/)** | Join a project that already exists. Four repositories, five tasks that each teach one thing about propagation, decisions and verification. | ~1 h |
| **[3 · Many teams, one registry](03-many-teams/)** | Two pack collections, one initiative carved out of the registry, and a question nobody had an answer for — recorded, answered, and folded into a pack. | ~1 h |

Do them in order. The first shows you where everything lives; the second shows
you why it is worth the trouble; the third is what happens when there is more
than one team and more than one thing going on at once.

## Before you start

```bash
git clone https://github.com/devfilipe/deck.git ~/tools/deck
ln -s ~/tools/deck/plugins/deck/bin/deck ~/.local/bin/deck
deck --help
```

Python 3.10+ and PyYAML. `git`. For exercise 2 also `pytest` and `ruff`. For the
optional last step of exercises 1 and 2, Claude Code:

```bash
claude plugin marketplace add ~/tools/deck
claude plugin install deck@deck
```

Nothing in any exercise needs the network. The one step that costs money —
`deck propose`, in exercise 3 — is optional, marked, and taught in the form that
is free.

## Every command here is checked

```bash
./verify.sh                                   # deck from PATH
DECK_BIN=~/tools/deck/plugins/deck/bin/deck ./verify.sh
./verify.sh 03                                # one exercise
```

`verify.sh` replays every command the exercises tell you to run, and asserts the
strings the exercises say you will see. It works on a copy in a temporary
directory, so a run leaves your checkout exactly as it found it.

That script is the reason to trust the pages. An exercise is a list of claims —
type this, see that — and a README checks none of them, so a repository like this
one drifts silently until a reader hits a command that no longer exists. It had
already happened: when these checks were first written they found six claims in
the two existing exercises that deck no longer honoured, including one step
whose output was empty.

[CI](.github/workflows/ci.yml) runs it on every push and every night against
deck at its tip, which turns "an exercise broke" from something a reader
discovers into something a maintainer is told.

## What you will have learned

| | |
|---|---|
| **The map** | `impacts` is an edge list you write once, and it is what makes a change stop being a surprise two repositories away — and `couples` is the pair that breaks both ways with no order between them |
| **The decisions** | a toggle is a decision recorded with its reason and its cost, asked at the moment the change makes it relevant — not a switch wired into your product |
| **The context** | a pack named after a repository applies to that repository, arrives at the start of a task and leaves at the end; collections layer, most general first |
| **The initiative** | a scope is a named subset of the registry with a board and a posture of its own, and the report worth reading is what its boundary leaks |
| **The proof** | the rung a delivery reached is a fact with a file behind it, and a gate proves what it asserts and nothing more |
| **The record** | a question nobody could answer is written down, answered by a person, and folded into a pack — because an answer is a transcript until someone writes it down |
| **The line** | Claude Code writes code, spawns agents and asks questions; deck answers about *your* workspace and records what happened. Neither does the other's job |

## What is not covered yet

`deck console`, `deck ui` and `deck statusline` — the three surfaces meant to sit
beside a running agent — and `deck import`, which derives a registry from a
Google `repo` manifest, git submodules or npm workspaces. All four want a
workspace shape or a terminal these exercises do not have.

## Where things live, in every exercise

| Path | Scope | Versioned |
|---|---|---|
| `~/.deck/workspaces/<name>/` | your machine | **no** — paths, hosts, evidence, the selected scope |
| `ai-packs/`, `org-packs/` | the team, and the organisation | **yes** — the descriptor, commands, decisions and rules |
| `docs/board.yaml` | the team | **yes** — the tasks |

The split is *machine* against *team*, not project against team. A workspace set
up with a collection gains nothing in its own tree: the descriptor is versioned
with the packs, and everything true of one checkout and nobody else's lives
under your home directory, keyed by the workspace's name.

A collection is two directories, and they answer two questions:

```
<collection>/
├── _repos/<repository>          one repository, wherever it is checked out
└── _workspaces/<name>/<scope>   a workspace, and a phase of work inside it
```

`<name>` may be `all` — every workspace — and `<scope>` may be `default` — the
whole workspace rather than one initiative. Layers merge most general first, so
a repository can override the organisation and never the reverse. Exercise 1
uses one layer, exercise 2 adds per-repository packs, exercise 3 adds a scope.

Exercise 3 starts with no collection at all, and there `.deck/` in the workspace
root is where the descriptor lives — that path is still how a workspace begins
before it has anywhere to version anything.

Nothing deck writes belongs in a product repository, and nothing it places there
survives an unmount.

## Licence

MIT, like deck.
