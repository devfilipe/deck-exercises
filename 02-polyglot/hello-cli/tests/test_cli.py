import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.environ.setdefault("HELLO_COMMANDS", str(ROOT.parent / "hello-commands"))

from hello_cli import main  # noqa: E402


def test_the_default_is_english(capsys):
    assert main([]) == 0
    assert capsys.readouterr().out.strip() == "Hello, World!"


def test_a_declared_language_prints_its_greeting(capsys):
    assert main(["--lang", "pt"]) == 0
    assert capsys.readouterr().out.strip() == "Olá, Mundo!"


def test_an_undeclared_language_fails_loudly(capsys):
    assert main(["--lang", "xx"]) == 1
    assert "xx" in capsys.readouterr().err
