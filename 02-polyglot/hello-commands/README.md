# hello-commands

Layer 1: the contract. Command descriptors in `commands/`, one language per file
in `locales/`. No Python here beyond the check that this data keeps its shape.

Adding a language is adding one file. Everything downstream has to keep up, and
`deck impact hello-commands` is what says who.
