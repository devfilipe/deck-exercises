---
paths: ["hello_core/*.py"]
---

`Catalog.greet` is the one place a code becomes a greeting. What it does with a
code nobody declared is a product decision — the `unknown_locale` toggle — not
an implementation detail to settle in passing.

Whatever that answer is, it has to be the same in `hello-core` and in
`hello-cli`: the CLI must not soften an error the core raised, and must not
raise one the core chose to absorb.
