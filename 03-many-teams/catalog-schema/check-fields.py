#!/usr/bin/env python3
"""Every field the contract declares has to say whether it is required.

A field with no `required` key is not a small omission: every reader downstream
has to guess, and two readers will guess differently. The check lives here, in
the repository that owns the contract, and the pack only names the command that
runs it.
"""

import json
import sys
from pathlib import Path

fields = json.loads(Path("catalog.json").read_text(encoding="utf-8"))["fields"]
missing = [f["name"] for f in fields if "required" not in f]

if missing:
    print("no 'required' on: " + ", ".join(missing))
    sys.exit(1)

print(f"{len(fields)} fields, all of them say whether they are required")
