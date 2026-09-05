# hello-core

Layer 2: the objects. Reads what `hello-commands` declares and resolves a
language code to a greeting.

It finds the contract through `HELLO_COMMANDS`, falling back to the sibling
checkout. It never hardcodes a greeting: a language that is not in the contract
does not exist here.
