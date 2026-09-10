# deploy-scripts

The commands that put a build where it runs. `catalog-api` shells out to these
at run time, and these read the configuration `catalog-api` writes at start-up.

Each side breaks the other and neither goes first, which is what `couples:` in
the descriptor is for — not `impacts:`, which would claim an order that does not
exist.
