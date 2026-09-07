#!/bin/sh
# Put a built artifact where it runs. Fictional: it prints what it would do.
set -eu

artifact=${1:?usage: deploy.sh <artifact> <host-alias>}
host=${2:?usage: deploy.sh <artifact> <host-alias>}

printf 'would install %s on %s\n' "$artifact" "$host"
