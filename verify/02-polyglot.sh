#!/usr/bin/env bash
# Every command 02-polyglot/README.md tells a reader to run, and every edit it
# tells them to make, applied to a throwaway copy of the exercise.
#
# The copy matters: the exercise is a working tree a reader mutates, and a check
# that mutated the checked-in one would pass once and never again.

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/lib.sh"
SRC=$(cd "$HERE/.." && pwd)/02-polyglot

WORK=${1:?usage: 02-polyglot.sh <empty-work-dir>}
rm -rf "$WORK/polyglot"
cp -r "$SRC" "$WORK/polyglot"
cd "$WORK/polyglot" || exit 1

heading "02 · polyglot"

# ------------------------------------------------------------ set it up
ok "setup.sh" -- ./setup.sh
capture -- deck doctor
exited "doctor" 0
also "reports six warnings, and no problem" "6 warning(s)"
says "the ladder is 5 gates over 9 runs, all green" \
  "5 gate(s) passed in 9 run(s)" -- deck gate run --task try-it

capture -- ./hello-cli/bin/hello --lang pt
exited "the app runs" 0
also "and greets in Portuguese" "Olá, Mundo!"

capture -- ./hello-cli/bin/hello --lang xx
exited "an undeclared code fails" 1
also "listing the codes that exist" "this build knows en, es, fr, pt"

capture -- deck impact hello-commands
exited "impact" 0
also "reaches three repositories" "a change in hello-commands reaches 3 repositories"
also "and marks the one that builds nothing" "hello-docs  (downstream — keep up, does not build)"

# --------------------------------------------------------------- POLY-1
capture -- deck board show POLY-1
exited "board show POLY-1" 0
also "one repository declared" "repos     hello-commands"
also "four reached" "reaches   hello-commands, hello-core, hello-cli, hello-docs"

ok "claim POLY-1" -- deck board claim POLY-1 someone --yes
capture -- deck mount --task POLY-1 --repos hello-commands
exited "mount POLY-1" 0
also "three artifacts: one workspace rule, two repository rules" "3 artifact(s)"
# The workspace layer lands once, at the root, rather than once per repository:
# it is a statement about the workspace, and four copies would say it four times
# and be read four times.
ok "the workspace rule lands once, at the root" -- test -f .claude/rules/deck-layering.md
ok "and not copied into each repository" -- test ! -e hello-cli/.claude/rules/deck-layering.md
ok "the hello-commands rule is only there" \
  -- test -f hello-commands/.claude/rules/deck-adding-a-language.md
ok "and not in hello-core" \
  -- test ! -e hello-core/.claude/rules/deck-adding-a-language.md
ok "the hello-core rule is only there" \
  -- test -f hello-core/.claude/rules/deck-resolution.md

cat > hello-commands/locales/de.json <<'JSON'
{
  "code": "de",
  "name": "Deutsch",
  "greeting": "Hallo, Welt!"
}
JSON
capture -- ./hello-cli/bin/hello --lang de
exited "German works without touching core or cli" 0
also "and prints the German greeting" "Hallo, Welt!"

capture -- deck gate run --task POLY-1
exited "and the ladder fails anyway" 1
also "in a repository nobody opened" "FAIL table        hello-docs"
also "and stops rather than pretending to skip" "not attempted: an earlier gate failed"

python3 - <<'PY'
import pathlib
p = pathlib.Path("hello-docs/LANGUAGES.md"); s = p.read_text()
p.write_text(s.replace("| en | English", "| de | Deutsch | Hallo, Welt! |\n| en | English"))
PY
says "with the published table updated, 5 gates in 9 runs" \
  "5 gate(s) passed in 9 run(s)" -- deck gate run --task POLY-1

says "the plan warns that POLY-1 edits what it did not declare" \
  "!! POLY-1 reaches hello-docs, which POLY-5 edits" -- deck board plan

python3 - <<'PY'
import pathlib
p = pathlib.Path("docs/board.yaml"); s = p.read_text()
p.write_text(s.replace(
    "- id: POLY-1\n  title: Add German (de) to the contract\n  repos:\n  - hello-commands\n",
    "- id: POLY-1\n  title: Add German (de) to the contract\n  repos:\n  - hello-commands\n  - hello-docs\n"))
PY
capture -- deck board plan
exited "board plan" 0
also "and now POLY-1 runs alone" "group 1 (alone)"
not_also "with the warning gone" "!! POLY-1 reaches hello-docs"
says "why says which repository collides" \
  "POLY-1 and POLY-5 must not run together: both would edit hello-docs" \
  -- deck board why POLY-1 POLY-5

says "unmount takes back all three" "3 removed · 0 left alone" \
  -- deck unmount --task POLY-1
capture -- deck board done POLY-1 --yes
exited "done accepts a task the ladder passed under" 0
also "and says what it did not close" "jira:POLY-1 is not touched"

# --------------------------------------------------------------- POLY-2
ok "claim POLY-2" -- deck board claim POLY-2 someone --yes
capture -- deck toggle ask-plan --stage plan --files hello-commands/locales/en.json
exited "ask-plan" 0
also "puts the contract decision to a person" \
  '"question": "May this change rename or remove something the contract publishes?"'
also "with what each value costs" \
  '"description": "Core and cli have to be updated in the same delivery."'

capture -- deck toggle set --at workspace cmd_compat breaking
exited "recording it at the workspace layer" 0
also "writes it where another terminal will see it" "(workspace → "
says "and explain reports where the value came from" "source     : workspace" \
  -- deck toggle explain cmd_compat

ok "mount POLY-2" -- deck mount --task POLY-2 --repos hello-commands
sed -i 's/"greeting":/"message":/' hello-commands/locales/*.json
sed -i 's/"code", "name", "greeting"/"code", "name", "message"/' hello-commands/tests/test_catalog.py
capture -- deck gate run --task POLY-2
exited "the owning repository is consistent and the delivery is broken" 1
also "the contract gate passes" "ok   contract     hello-commands"
also "and a repository nobody opened does not" "FAIL table        hello-docs"

sed -i 's/    greeting: str/    message: str/;
        s/data\["greeting"\]/data["message"]/;
        s/return locale.greeting/return locale.message/' hello-core/hello_core/catalog.py
sed -i 's/d\["greeting"\]/d["message"]/' hello-docs/tests/test_table_matches_the_contract.py
says "the readers land in the same delivery" "5 gate(s) passed in 9 run(s)" \
  -- deck gate run --task POLY-2
ok "and hello-cli never changed a line" \
  -- git -C hello-cli diff --quiet

python3 - <<'PY'
import pathlib
p = pathlib.Path("docs/board.yaml"); s = p.read_text()
p.write_text(s.replace(
    "- id: POLY-2\n  title: Rename greeting to message in the contract\n  repos:\n  - hello-commands\n",
    "- id: POLY-2\n  title: Rename greeting to message in the contract\n  repos:\n"
    "  - hello-commands\n  - hello-core\n  - hello-docs\n"))
PY
ok "unmount POLY-2" -- deck unmount --task POLY-2
ok "close POLY-2" -- deck board done POLY-2 --yes

# --------------------------------------------------------------- POLY-3
ok "claim POLY-3" -- deck board claim POLY-3 someone --yes
capture -- ./hello-cli/bin/hello --lang xx
exited "the behaviour nobody decided" 1
also "which now knows German too" "this build knows de, en, es, fr, pt"

ok "record the decision" -- deck toggle set --at workspace unknown_locale fallback_en
capture -- ./hello-cli/bin/hello --lang xx
exited "and the code has not changed" 1
also "because a toggle is a record, not a switch" "no language 'xx'"

ok "mount POLY-3" -- deck mount --task POLY-3 --repos hello-core,hello-cli
python3 - <<'PY'
import pathlib
p = pathlib.Path("hello-core/hello_core/catalog.py"); s = p.read_text()
s = s.replace(
    "    def __init__(self, root: Path | None = None) -> None:\n        self.root",
    '    def __init__(self, root: Path | None = None, on_unknown: str = "fallback_en") -> None:\n'
    "        self.on_unknown = on_unknown\n        self.root")
old = s[s.index("    def greet(self, code: str) -> str:"):s.index("    def codes(self)")]
s = s.replace(old, '''    def greet(self, code: str) -> str:
        """The greeting for a code.

        What happens to a code nobody declared is a product decision, recorded
        as the `unknown_locale` toggle and implemented here as the default. It
        is not read from deck at run time: the app must not need a control
        plane to start.
        """
        locale = self.locales.get(code)
        if locale is not None:
            return locale.message
        if self.on_unknown == "fallback_en" and "en" in self.locales:
            return self.locales["en"].message
        known = ", ".join(sorted(self.locales))
        raise UnknownLocale(f"no language {code!r}; this build knows {known}")

''')
p.write_text(s)
PY
capture -- deck gate run --task POLY-3
exited "the tests still demand the decision that was revoked" 1
# Assert the test names and the failure kind, not pytest's wording of them:
# how much of the traceback pytest prints, and whether it spells the exception
# out in full, varies by version, and neither is a claim this exercise makes.
also "one asserts an exception that no longer comes" "DID NOT RAISE"
also "naming the test that encoded the old decision" \
  "test_an_undeclared_language_is_refused"
also "and the other still demands the loud failure" \
  "test_an_undeclared_language_fails_loudly"

python3 - <<'PY'
import pathlib
p = pathlib.Path("hello-core/tests/test_catalog.py"); s = p.read_text()
p.write_text(s.replace('''def test_an_undeclared_language_is_refused():
    with pytest.raises(UnknownLocale):
        Catalog().greet("xx")
''', '''def test_an_undeclared_language_falls_back_to_english():
    catalog = Catalog()
    assert catalog.greet("xx") == catalog.greet("en")


def test_the_strict_policy_is_still_available():
    with pytest.raises(UnknownLocale):
        Catalog(on_unknown="error").greet("xx")
'''))
p = pathlib.Path("hello-cli/tests/test_cli.py"); s = p.read_text()
p.write_text(s.replace('''def test_an_undeclared_language_fails_loudly(capsys):
    assert main(["--lang", "xx"]) == 1
    assert "xx" in capsys.readouterr().err
''', '''def test_an_undeclared_language_falls_back(capsys):
    assert main(["--lang", "xx"]) == 0
    assert capsys.readouterr().out.strip() == "Hello, World!"
'''))
PY
capture -- grep -c "^def test" hello-core/tests/test_catalog.py hello-cli/tests/test_cli.py
also "four tests in hello-core" "hello-core/tests/test_catalog.py:4"
also "three in hello-cli" "hello-cli/tests/test_cli.py:3"
says "and the ladder is green again" "5 gate(s) passed in 9 run(s)" \
  -- deck gate run --task POLY-3
ok "unmount POLY-3" -- deck unmount --task POLY-3
ok "close POLY-3" -- deck board done POLY-3 --yes

# ---------------------------------------------------------- POLY-4 and 5
capture -- deck board plan
exited "board plan" 0
also "the last two are genuinely parallel" "group 1 (parallel)"

ok "claim POLY-4" -- deck board claim POLY-4 someone --yes
ok "claim POLY-5" -- deck board claim POLY-5 someone --yes
ok "mount POLY-4" -- deck mount --task POLY-4 --repos hello-cli
ok "mount POLY-5" -- deck mount --task POLY-5 --repos hello-docs
capture -- deck mounts
exited "mounts" 0
also "two live manifests, POLY-4" "POLY-4"
also "and POLY-5" "POLY-5"

python3 - <<'PY'
import pathlib
p = pathlib.Path("hello-cli/hello_cli/main.py"); s = p.read_text()
s = s.replace(
    '    parser.add_argument("--lang", "-l", default=os.environ.get("HELLO_LANG", "en"), help=greet.params[0]["help"])\n    return parser',
    '    parser.add_argument("--lang", "-l", default=os.environ.get("HELLO_LANG", "en"), help=greet.params[0]["help"])\n'
    '    parser.add_argument("--list", action="store_true", help=catalog.commands["list"].summary)\n    return parser')
s = s.replace("    args = build_parser(catalog).parse_args(argv)\n    try:",
              "    args = build_parser(catalog).parse_args(argv)\n\n"
              "    if args.list:\n"
              "        for code in catalog.codes():\n"
              '            print(f"{code}\\t{catalog.locales[code].name}")\n'
              "        return 0\n\n    try:")
p.write_text(s)
p = pathlib.Path("hello-cli/tests/test_cli.py")
p.write_text(p.read_text() + '''

def test_list_prints_every_declared_language(capsys):
    assert main(["--list"]) == 0
    out = capsys.readouterr().out
    for code in ("de", "en", "es", "fr", "pt"):
        assert code in out
''')
PY
says "POLY-4 is one repository and no propagation" "5 gate(s) passed in 9 run(s)" \
  -- deck gate run --task POLY-4
capture -- ./hello-cli/bin/hello --list
exited "--list runs" 0
also "and its help came from the contract" "Deutsch"

cat > hello-docs/LANGUAGES.md <<'MD'
# Supported languages

This table is what the product promises. It has to agree with the contract in
`hello-commands/locales/`, and a test here proves it does.

| code | language | message |
|---|---|---|
| de | Deutsch | Hallo, Welt! |
| en | English | Hello, World! |
| es | Español | ¡Hola, Mundo! |
| fr | Français | Bonjour, le Monde ! |
| pt | Português | Olá, Mundo! |
MD
cat >> hello-docs/tests/test_table_matches_the_contract.py <<'PY'


def test_the_header_names_the_text_field():
    """The column carrying the text is named after the contract key.

    Not every column: `language` is a better heading for a person than `name`.
    This one matters because it is the key that got renamed, and a heading still
    saying `greeting` is vocabulary drift you can see.
    """
    header = next(
        line
        for line in (ROOT / "LANGUAGES.md").read_text(encoding="utf-8").splitlines()
        if line.startswith("| code |")
    )
    sample = json.loads(sorted(CONTRACT.glob("*.json"))[0].read_text(encoding="utf-8"))
    text_field = next(f for f in sample if f not in ("code", "name"))
    assert text_field in header, f"the table header does not name {text_field!r}"
PY
sed -i 's/| message |/| greeting |/' hello-docs/LANGUAGES.md
capture -- deck gate run --task POLY-5-check
exited "the new test is watched failing before it is trusted" 1
also "and it names what the header does not say" \
  "assert 'message' in '| code | language | greeting |'"
sed -i 's/| greeting |/| message |/' hello-docs/LANGUAGES.md
says "then it passes" "5 gate(s) passed in 9 run(s)" -- deck gate run --task POLY-5

ok "unmount POLY-4" -- deck unmount --task POLY-4
ok "unmount POLY-5" -- deck unmount --task POLY-5
says "and nothing is left placed" "nothing mounted" -- deck mounts
ok "close POLY-4" -- deck board done POLY-4 --yes
ok "close POLY-5" -- deck board done POLY-5 --yes
capture -- deck board list
exited "board list" 0
also "every task is closed" "[x] POLY-5"

# ------------------------------------------------------------ start over
for r in hello-commands hello-core hello-cli hello-docs; do
  git -C $r checkout -q .
  git -C $r clean -qfd
done
# Starting over means clearing both halves: the machine state under the home
# directory, and the descriptor the collection carries. Removing only one of
# them leaves `setup` refusing, which is the right refusal and a confusing way
# to end an exercise.
rm -rf docs "$DECK_HOME_STATE/workspaces/polyglot" ai-packs/_workspaces/polyglot/default/workspace.yaml
rm -f "$DECK_HOME_STATE/selected"
ok "the reset the README documents works" -- ./setup.sh
says "and the workspace is green from the start again" \
  "5 gate(s) passed in 9 run(s)" -- deck gate run --task try-it

summary "02 · polyglot"
