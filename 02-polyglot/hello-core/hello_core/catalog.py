"""Turn the JSON contract into objects, and resolve a language code.

Where the contract lives is not this layer's business to guess: HELLO_COMMANDS
names it, and the default is the sibling checkout, which is the layout the
workspace descriptor declares.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path

DEFAULT_COMMANDS = Path(__file__).resolve().parents[2] / "hello-commands"


class UnknownLocale(LookupError):
    """Asked for a language the contract does not declare."""


@dataclass(frozen=True)
class Locale:
    code: str
    name: str
    greeting: str


@dataclass(frozen=True)
class Command:
    name: str
    summary: str
    params: tuple[dict, ...]


class Catalog:
    """Everything the contract declares, loaded once."""

    def __init__(self, root: Path | None = None) -> None:
        self.root = Path(root or os.environ.get("HELLO_COMMANDS") or DEFAULT_COMMANDS)
        if not self.root.is_dir():
            raise FileNotFoundError(
                f"the command contract is not at {self.root}. "
                "Set HELLO_COMMANDS to the hello-commands checkout."
            )
        self.locales = self._load_locales()
        self.commands = self._load_commands()

    def _load_locales(self) -> dict[str, Locale]:
        found = {}
        for path in sorted(self.root.joinpath("locales").glob("*.json")):
            data = json.loads(path.read_text(encoding="utf-8"))
            found[data["code"]] = Locale(data["code"], data["name"], data["greeting"])
        return found

    def _load_commands(self) -> dict[str, Command]:
        found = {}
        for path in sorted(self.root.joinpath("commands").glob("*.json")):
            data = json.loads(path.read_text(encoding="utf-8"))
            found[data["name"]] = Command(data["name"], data.get("summary", ""), tuple(data.get("params", [])))
        return found

    def greet(self, code: str) -> str:
        """The greeting for a code.

        What to do with a code nobody declared is a product decision, not an
        implementation detail — see the `unknown_locale` toggle. Today it
        raises, which is the answer that cannot hide a typo.
        """
        locale = self.locales.get(code)
        if locale is None:
            known = ", ".join(sorted(self.locales))
            raise UnknownLocale(f"no language {code!r}; this build knows {known}")
        return locale.greeting

    def codes(self) -> list[str]:
        return sorted(self.locales)
