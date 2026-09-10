---
paths: ["locales/*.json", "commands/*.json"]
---

Adding a language is adding one file to `locales/`, named after its code, with
`code`, `name` and `greeting`. Nothing else in this repository changes.

What does change is downstream: `deck impact hello-commands` names it. The
`resolvable` gate in hello-core is what proves the new language actually reaches
the app rather than merely parsing here.

Before renaming or removing any key, check the `cmd_compat` toggle. Every reader
of this contract addresses it by key name, so a rename is invisible to a test
that only checks the file parses.
