"""The contract keeps its shape. This is the only test that guards the data."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REQUIRED = ("code", "name", "greeting")


def _locales():
    return sorted(ROOT.joinpath("locales").glob("*.json"))


def test_every_locale_has_the_required_fields():
    for path in _locales():
        data = json.loads(path.read_text(encoding="utf-8"))
        missing = [f for f in REQUIRED if not data.get(f)]
        assert not missing, f"{path.name}: missing {missing}"


def test_the_code_matches_the_filename():
    for path in _locales():
        data = json.loads(path.read_text(encoding="utf-8"))
        assert data["code"] == path.stem, f"{path.name} declares code {data['code']!r}"


def test_every_command_declares_its_params():
    for path in sorted(ROOT.joinpath("commands").glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        assert data.get("name") == path.stem
        assert isinstance(data.get("params"), list)
