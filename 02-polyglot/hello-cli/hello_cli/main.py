"""The CLI. Every flag it offers comes from what hello-commands declares.

Nothing here knows a greeting or a language name. Adding a language is a change
to the contract, not to this file — and if that ever stops being true, the
layering has been broken.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

CORE = Path(__file__).resolve().parents[2] / "hello-core"
if CORE.is_dir():
    sys.path.insert(0, str(CORE))

from hello_core import Catalog, UnknownLocale  # noqa: E402


def build_parser(catalog: Catalog) -> argparse.ArgumentParser:
    greet = catalog.commands["greet"]
    parser = argparse.ArgumentParser(prog="hello", description=greet.summary)
    parser.add_argument("--lang", "-l", default=os.environ.get("HELLO_LANG", "en"), help=greet.params[0]["help"])
    return parser


def main(argv: list[str] | None = None) -> int:
    catalog = Catalog()
    args = build_parser(catalog).parse_args(argv)
    try:
        print(catalog.greet(args.lang))
    except UnknownLocale as exc:
        print(f"hello: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
