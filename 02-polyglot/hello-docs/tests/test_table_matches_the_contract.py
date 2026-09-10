"""The published table and the contract cannot disagree.

hello-docs builds nothing. It is `downstream`: it produces no artifact and still
has to keep up, which is exactly the kind of obligation that gets forgotten at
six in the evening.
"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT.parent / "hello-commands" / "locales"


def _documented():
    rows = re.findall(r"^\| (\w[\w-]*) \| (.+?) \| (.+?) \|$", (ROOT / "LANGUAGES.md").read_text(encoding="utf-8"), re.M)
    return {code: (name, greeting) for code, name, greeting in rows if code != "code"}


def _declared():
    out = {}
    for path in sorted(CONTRACT.glob("*.json")):
        d = json.loads(path.read_text(encoding="utf-8"))
        out[d["code"]] = (d["name"], d["greeting"])
    return out


def test_no_language_is_missing_from_the_table():
    assert set(_declared()) - set(_documented()) == set()


def test_no_language_is_invented_by_the_table():
    assert set(_documented()) - set(_declared()) == set()


def test_the_greetings_match():
    documented, declared = _documented(), _declared()
    for code in declared:
        assert documented[code] == declared[code], f"{code}: table and contract disagree"
