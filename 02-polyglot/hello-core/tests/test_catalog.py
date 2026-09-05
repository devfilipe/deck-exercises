import os
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.environ.setdefault("HELLO_COMMANDS", str(ROOT.parent / "hello-commands"))

from hello_core import Catalog, UnknownLocale  # noqa: E402


def test_every_declared_language_resolves():
    catalog = Catalog()
    assert catalog.codes(), "the contract declares no language at all"
    for code in catalog.codes():
        assert catalog.greet(code), f"{code} resolves to an empty greeting"


def test_the_commands_load():
    catalog = Catalog()
    assert "greet" in catalog.commands
    assert "list" in catalog.commands


def test_an_undeclared_language_is_refused():
    with pytest.raises(UnknownLocale):
        Catalog().greet("xx")
