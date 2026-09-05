# deck exercises

Two hands-on exercises for [deck](https://github.com/devfilipe/deck), a control
plane for coding agents working across repositories.

Both are meant to be typed, not read. Neither needs an agent: everything works
in a plain terminal, and the last step of each adds Claude on top so you can see
what changes — and what does not.

| | | takes |
|---|---|---|
| **[1 · Your first workspace](01-first-workspace/)** | Build one from an empty directory. Three repositories, one dependency chain, one gate, one decision. You write every file. | ~20 min |
| **[2 · polyglot](02-polyglot/)** | Join a project that already exists. Four repositories, five tasks that each teach one thing about propagation, decisions and verification. | ~1 h |

Do them in order. The first shows you where everything lives; the second shows
you why it is worth the trouble.

## Before you start

```bash
git clone https://github.com/devfilipe/deck.git ~/tools/deck
ln -s ~/tools/deck/plugins/deck/bin/deck ~/.local/bin/deck
deck --help
```

Python 3.10+ and PyYAML. `git`. For exercise 2 also `pytest` and `ruff`. For the
optional last step of each, Claude Code:

```bash
claude plugin marketplace add ~/tools/deck
claude plugin install deck@deck
```

## What you will have learned

| | |
|---|---|
| **The map** | `impacts` is an edge list you write once, and it is what makes a change stop being a surprise two repositories away |
| **The decisions** | a toggle is a decision recorded with its reason and its cost, asked at the moment the change makes it relevant — not a switch wired into your product |
| **The context** | a pack named after a repository applies to that repository, arrives at the start of a task and leaves at the end |
| **The proof** | the rung a delivery reached is a fact with a file behind it, and a gate proves what it asserts and nothing more |
| **The line** | Claude Code writes code, spawns agents and asks questions; deck answers about *your* workspace and records what happened. Neither does the other's job |

## Where things live, in both exercises

| Path | Scope | Versioned |
|---|---|---|
| `.deck/` | your machine | **no** — paths, hosts, evidence |
| `ai-packs/` | the team | **yes** — the commands, decisions and rules |
| `docs/board.yaml` | the team | **yes** — the tasks |

Nothing deck writes belongs in a product repository, and nothing it places there
survives an unmount.

## Licence

MIT, like deck.
