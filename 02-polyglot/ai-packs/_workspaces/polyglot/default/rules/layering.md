---
paths: ["**/*.py", "**/*.json"]
---

Three layers, and the direction of dependency never reverses:

    hello-commands   JSON only. Declares languages and commands. Imports nothing.
          ↓
    hello-core       Loads the contract, resolves a code. Knows no greeting.
          ↓
    hello-cli        Argparse and printing. Knows no greeting and no language name.

A greeting string or a language name appearing in `hello-core` or `hello-cli` is
the bug, not the shortcut — the contract stops being the single source and the
next language gets added in three places instead of one.

`hello-core` finds the contract through `HELLO_COMMANDS`, never a hardcoded path.
