#!/bin/sh
# Count what is still marked TODO in the repository this is run from.
#
# It lives in `tools/`, outside every repository, because it belongs to none of
# them. The descriptor names this directory under `paths:`, and the gate that
# runs it says `${path.tools}/count-todos.sh` — so the pack stays portable and
# each machine says where its copy is.
set -eu

n=$(grep -ro TODO --include='*.md' --include='*.json' --include='*.sh' . | wc -l)
printf '%s TODO\n' "$(echo "$n" | tr -d ' ')"
