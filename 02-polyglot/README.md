# 2 · polyglot

A CLI that prints "Hello, World!" in the language you ask for. Four repositories,
three layers plus one that builds nothing and still has to keep up, and five
tasks that each teach one thing.

Unlike the first exercise, this one already exists. You are joining a project
rather than founding one — which is how most people meet a workspace.

About an hour. No agent required.

> Every command below, and every edit it asks you to make, is replayed by
> [CI](../verify/02-polyglot.sh) on every push against deck at its tip.

---

## Set it up

```bash
./setup.sh
deck doctor
deck gate run --task try-it
```

`setup.sh` makes the four directories into repositories, seeds `.deck/` and
copies the board in. Expect **5 gates in 9 runs, all green**, and `5 warning(s)`
from `doctor` — one per repository with no `origin` remote, plus the empty
`targets` list. All five are valid states, which is why they are warnings.

```bash
./hello-cli/bin/hello --lang pt      # Olá, Mundo!
./hello-cli/bin/hello --lang xx      # fails, and lists the codes that exist
```

## The shape

```
   hello-commands     layer 1 — JSON only. Commands in commands/, one language
         │                      per file in locales/. Imports nothing.
         ├──────────────┐
         ▼              │
   hello-core           │  layer 2 — objects. Loads the contract, resolves a
         │              │            code. Knows no greeting.
         ▼              │
   hello-cli            │  layer 3 — argparse and printing. Knows no greeting
                        │            and no language name.
                        ▼
                  hello-docs     the published table. `downstream`: builds
                                 nothing, must agree with the contract.
```

Four languages today: `en`, `es`, `fr`, `pt`. German is the first task.

```bash
deck impact hello-commands
```

## The ladder

| rung | gate | over |
|---|---|---|
| static | `lint` — ruff | every repository |
| static | `contract` — the JSON keeps its shape | hello-commands |
| static | `table` — the docs agree with the contract | hello-docs |
| build | `test` — pytest | every repository |
| build | `resolvable` — every declared language reaches the app | hello-core |

`table` runs on a `downstream` repository, which build gates skip. Its pack says
`include_downstream: true`, because `downstream` means "produces no artifact",
not "is never checked".

`hello-cli` and `hello-core` each carry a `ruff.toml` pinning one rule. It is
worth two minutes: ruff 0.16 dropped `E402` from its defaults, which turned the
`# noqa: E402` those repositories need into an *unused* directive and failed the
`lint` gate on files nobody had touched. Nothing about the code changed — a tool
it had not pinned did. deck has never heard of ruff; the gate runs the string
the pack declares, and what that string means is the repository's business.

## The decisions

| toggle | asked when you touch | the question |
|---|---|---|
| `cmd_compat` | `hello-commands/**` | may this rename or remove something published? |
| `unknown_locale` | `hello-core/**`, `hello-cli/**` | unknown code: fail, or fall back to English? |
| `locale_aliases` | `hello-cli/**`, `hello-commands/**` | accept `pt-BR`, or declared codes only? |

All three default to a question rather than an answer. That is deliberate: they
are decisions, and deck's job is to put them to a person at the moment the
change makes them relevant — never to answer them.

## The loop, for every task

```bash
deck board show POLY-n
deck board claim POLY-n "$USER" --yes
deck toggle ask-plan --stage plan --files <a file you are about to touch>
deck mount --task POLY-n --repos <what you will edit>
#   … work …
deck gate run --task POLY-n
deck unmount --task POLY-n
deck board done POLY-n --yes
```

---

# The tasks

Do them in order. Each one is built on what the previous one left.

## POLY-1 · Add German

```bash
deck board show POLY-1
```

```
POLY-1  Add German (de) to the contract

  status    open
  repos     hello-commands
  external  jira:POLY-1

  reaches   hello-commands, hello-core, hello-cli, hello-docs
```

The task declares **one** repository and `reaches` says four. The fourth is
`hello-docs`, which produces no artifact and still has to keep up — `deck impact
hello-commands` is where that is spelled out:

```
  4. hello-docs  (downstream — keep up, does not build)
```

Hold on to that distinction; POLY-1 exists to show it.

Claim it, mount, and do exactly what the task names:

```bash
deck board claim POLY-1 "$USER" --yes
deck mount --task POLY-1 --repos hello-commands
```

Notice where each rule landed:

```bash
ls hello-commands/.claude/rules hello-core/.claude/rules hello-cli/.claude/rules
```

`deck-layering.md` (from `_workspace`) in all three; `deck-adding-a-language.md`
only in `hello-commands`; `deck-resolution.md` only in `hello-core`. Each pack
stayed in its own scope without anyone declaring it.

They are **copies**, not symlinks — `ls -l` shows `-rw-r--r--`. Claude Code
loads `.claude/rules/*.md` and does not follow a symlink there, so a mount that
linked instead of copying would report success while placing something the
runtime ignores. Edit the pack, not the copy; the manifest under `.deck/mounts/`
lists exactly what was placed, and `unmount` removes exactly that.

```bash
cat > hello-commands/locales/de.json <<'JSON'
{
  "code": "de",
  "name": "Deutsch",
  "greeting": "Hallo, Welt!"
}
JSON

./hello-cli/bin/hello --lang de       # Hallo, Welt!
deck gate run --task POLY-1
```

`Hallo, Welt!` prints without touching `hello-core` or `hello-cli` — exactly what
the layering rule promises. And the ladder fails.

**Read the failure carefully.** `lint` green, `contract` green, the app works:
everything in the repository you opened is fine. The failure is in
`hello-docs/LANGUAGES.md`, which promises four languages while the contract now
declares five — a repository you never opened, guarding an obligation nobody
would have remembered. It is the `reaches` from a minute ago, made concrete.

Note also `not attempted: an earlier gate failed`. The ladder is fail-fast by
rung, and says so rather than marking the rest as skipped.

Add the row to `hello-docs/LANGUAGES.md`, keeping the codes in order:

```
| de | Deutsch | Hallo, Welt! |
```

```bash
deck gate run --task POLY-1        # 5 gates, 9 runs
deck board plan | grep '!!'
```

That `!!` line is about you: POLY-1 declares `repos: [hello-commands]` and you
just edited `hello-docs`. Fix the task in `docs/board.yaml`:

```yaml
    repos:
    - hello-commands
    - hello-docs
```

```bash
deck board plan | head -12
deck board why POLY-1 POLY-5
```

Before, POLY-1 and POLY-5 shared a parallel group with a warning. Now that
POLY-1 admits editing `hello-docs`, they genuinely collide and the plan separates
them. That is the whole difference between *reaching* and *editing*, and it is
why `repos` is your declaration rather than deck's deduction: only you knew that
adding a language obliges a change to the published table.

```bash
deck unmount --task POLY-1
deck board done POLY-1 --yes
```

`done` accepts because the ladder ran and passed under that name. It also tells
you `jira:POLY-1` was not touched — deck does not close tracker items, because a
Jira transition is a workflow and not a field write.

**What it taught:** the repository you edited is green and the delivery is broken.

## POLY-2 · Rename a published key

The contract calls the text `greeting`. Rename it to `message`.

```bash
deck board claim POLY-2 "$USER" --yes
deck toggle ask-plan --stage plan --files hello-commands/locales/en.json
```

`cmd_compat` comes back pending, with three options and what each costs. With no
agent in the room, you are the one who reads and answers.

That JSON is the entire contract between deck and an agent: **deck supplies the
content, the runtime supplies the box.** It is what became the options screen in
exercise 1.

```bash
deck toggle set --at workspace cmd_compat breaking
deck toggle explain cmd_compat | head -8
```

`effective: breaking`, `source: workspace`. The `--at workspace` matters:
without it the value is bound to this shell session and disappears in another
terminal. The layer is `--at`, and the values it takes are `task`, `workspace`,
or the name of a scope — not to be confused with `deck --scope <name>`, which
chooses the initiative a command works inside.

```bash
deck mount --task POLY-2 --repos hello-commands
```

Rename in the repository that **owns** the contract, and nowhere else yet:

```bash
sed -i 's/"greeting":/"message":/' hello-commands/locales/*.json
sed -i 's/"code", "name", "greeting"/"code", "name", "message"/' hello-commands/tests/test_catalog.py
deck gate run --task POLY-2
```

`contract` passes. The JSON parses, the owning repository's test was updated,
that repository is entirely consistent with itself — and the delivery is broken,
with a `KeyError` in `hello-docs`, a repository you did not open.

You declared `breaking`, which means precisely this: the readers land in the same
delivery.

**`hello-core/hello_core/catalog.py`** — three places:

```bash
sed -i 's/    greeting: str/    message: str/;
        s/data\["greeting"\]/data["message"]/;
        s/return locale.greeting/return locale.message/' hello-core/hello_core/catalog.py
```

**`hello-docs/tests/test_table_matches_the_contract.py`** — one:

```bash
sed -i 's/d\["greeting"\]/d["message"]/' hello-docs/tests/test_table_matches_the_contract.py
deck gate run --task POLY-2
```

Green — and `hello-cli` never changed a line. The graph said `hello-commands`
reaches `hello-cli`, and it was right: reaching is an **obligation to revisit**,
not a prediction of editing. The revisit concluded nothing was needed, because
the CLI never reads a contract key — it calls `catalog.greet()` and layer 2
absorbs the change. The abstraction paid for itself, and the `test` gate is the
proof.

| | means | filled by |
|---|---|---|
| `impacts` / `reaches` | must be revisited | you, once |
| `repos` on a task | was actually edited | you, per task |
| the ladder | which of the two came true | deck |

Correct `repos` in `docs/board.yaml` to the three you edited, then close.

**What it taught:** a declared break makes the readers land together, and the
graph gives you the obligation to check, not the guarantee to edit.

## POLY-3 · Decide what an unknown code does

```bash
deck board claim POLY-3 "$USER" --yes
./hello-cli/bin/hello --lang xx
```

**The code already behaves one way** — it fails loudly — and nobody ever decided
that. Two tests pin it, so it is pinned by accident rather than by choice. That
is the state the toggle exists to undo.

| value | the argument for it | what it costs |
|---|---|---|
| `error` | a typo is caught immediately; the output teaches the valid codes | a missing translation stops the caller |
| `fallback_en` | the app never fails in a user's face | nobody ever learns a language is missing |

For a greeting CLI, `error` is defensible and is what the code already does. Take
`fallback_en` for the exercise: it is a defensible product call and it shows you
existing tests turning red, which is this task's lesson.

```bash
deck toggle set --at workspace unknown_locale fallback_en
./hello-cli/bin/hello --lang xx
```

The behaviour did not change, and that is correct. A toggle is a **record of a
decision**, not a switch wired into your code. deck does not inject runtime
configuration into your product — if it did, `hello-cli` would need a control
plane to start. Implementing the decision is still work.

```bash
deck mount --task POLY-3 --repos hello-core,hello-cli
```

In `hello-core/hello_core/catalog.py`, give `Catalog` the policy, defaulting to
what was decided:

```python
    def __init__(self, root: Path | None = None, on_unknown: str = "fallback_en") -> None:
        self.on_unknown = on_unknown
        self.root = Path(root or os.environ.get("HELLO_COMMANDS") or DEFAULT_COMMANDS)
        if not self.root.is_dir():
            raise FileNotFoundError(
                f"the command contract is not at {self.root}. "
                "Set HELLO_COMMANDS to the hello-commands checkout."
            )
        self.locales = self._load_locales()
        self.commands = self._load_commands()
```

and rewrite `greet`:

```python
    def greet(self, code: str) -> str:
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
```

Run the ladder **before** touching a single test:

```bash
deck gate run --task POLY-3
```

`DID NOT RAISE UnknownLocale`, and a captured `Hello, World!`. Neither is a bug:
the code now does what the decision says, and the tests still demand the decision
you revoked. They became documentation of a policy that no longer holds.

Replace the old test in `hello-core/tests/test_catalog.py` — **delete
`test_an_undeclared_language_is_refused`** and add two:

```python
def test_an_undeclared_language_falls_back_to_english():
    catalog = Catalog()
    assert catalog.greet("xx") == catalog.greet("en")


def test_the_strict_policy_is_still_available():
    with pytest.raises(UnknownLocale):
        Catalog(on_unknown="error").greet("xx")
```

The second matters: `error` still exists and is still supported. What changed is
the **default**, and the default is what carries the team's decision. Testing
only the new path lets the other rot unnoticed.

In `hello-cli/tests/test_cli.py`, **delete `test_an_undeclared_language_fails_loudly`**
and add:

```python
def test_an_undeclared_language_falls_back(capsys):
    assert main(["--lang", "xx"]) == 0
    assert capsys.readouterr().out.strip() == "Hello, World!"
```

```bash
grep -c "^def test" hello-core/tests/test_catalog.py hello-cli/tests/test_cli.py   # 4 and 3
deck gate run --task POLY-3
```

Adding the new test without removing the old one leaves the suite demanding two
contradictory decisions at once, and the green new test makes it feel finished.
A ladder that runs everything is what catches it.

Close it — and notice you did not have to correct `repos` this time. POLY-3
declared `hello-core, hello-cli` from the start, because whoever wrote the task
already knew which layers would be edited. That is the normal case, and the
reason deck reports `reaches` beside `repos` instead of demanding you get it
right first time.

**What it taught:** changing a decision invalidates the tests that encoded the
old one.

## POLY-4 and POLY-5 · The parallel pair

```bash
deck board plan
```

After three tasks where nothing parallelised, these two land in one group. The
coupling in the first three was real, and deck did not pretend otherwise.

You are in one terminal, so run them one after another — but mount both first,
which is what "parallel" means in state:

```bash
deck board claim POLY-4 "$USER" --yes
deck board claim POLY-5 "$USER" --yes
deck mount --task POLY-4 --repos hello-cli
deck mount --task POLY-5 --repos hello-docs
deck mounts
```

Two live manifests, each with its own artifacts and repositories. Every task has
its own scope — evidence, session toggles, mounted artifacts — which is what lets
two agents work in separate worktrees without undoing each other.

### POLY-4 · `--list`

In `hello-cli/hello_cli/main.py`, add the flag in `build_parser`:

```python
    parser.add_argument("--list", action="store_true", help=catalog.commands["list"].summary)
```

and give it its own exit path in `main`:

```python
def main(argv: list[str] | None = None) -> int:
    catalog = Catalog()
    args = build_parser(catalog).parse_args(argv)

    if args.list:
        for code in catalog.codes():
            print(f"{code}\t{catalog.locales[code].name}")
        return 0

    try:
        print(catalog.greet(args.lang))
    except UnknownLocale as exc:
        print(f"hello: {exc}", file=sys.stderr)
        return 1
    return 0
```

The flag's `help` comes from the **contract** (`commands/list.json`), not from a
string invented here. Layer 3 still knows nothing on its own.

A test in `hello-cli/tests/test_cli.py`:

```python
def test_list_prints_every_declared_language(capsys):
    assert main(["--list"]) == 0
    out = capsys.readouterr().out
    for code in ("de", "en", "es", "fr", "pt"):
        assert code in out
```

```bash
deck gate run --task POLY-4
./hello-cli/bin/hello --list
```

**What it taught:** one repository, no propagation. Not every task needs the whole
machine, and deck asks nothing of you beyond `gate run`.

### POLY-5 · The published table

The `table` gate already passes. Look at the header anyway:

```
| code | language | greeting |
```

POLY-2 renamed that key to `message` an hour ago. The documentation is using the
old vocabulary and no test notices — the test parses rows, not the header.

**A green gate proves what it asserts and nothing more.** Green does not mean
correct; it means what was checked is correct.

Fix `hello-docs/LANGUAGES.md` — header and alphabetical order:

```markdown
| code | language | message |
|---|---|---|
| de | Deutsch | Hallo, Welt! |
| en | English | Hello, World! |
| es | Español | ¡Hola, Mundo! |
| fr | Français | Bonjour, le Monde ! |
| pt | Português | Olá, Mundo! |
```

Then close the hole, in `hello-docs/tests/test_table_matches_the_contract.py`:

```python
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
```

It derives the field from the contract, so a future rename is caught too, without
demanding that human column names match machine field names.

Watch it fail before trusting it:

```bash
sed -i 's/| message |/| greeting |/' hello-docs/LANGUAGES.md
deck gate run --task POLY-5-check         # table fails
sed -i 's/| greeting |/| message |/' hello-docs/LANGUAGES.md
deck gate run --task POLY-5               # green
```

A test you have not seen fail is not a test, it is a hope.

```bash
deck unmount --task POLY-4
deck unmount --task POLY-5
deck mounts                               # empty
deck board done POLY-4 --yes
deck board done POLY-5 --yes
deck board list
```

**What it taught:** a green gate proves only what it asserts.

---

## What the five taught, in one table

| | the lesson |
|---|---|
| **POLY-1** | the repository you edited is green and the delivery is broken, in a repo you never opened |
| **POLY-2** | a declared break makes the readers land together — and the graph gives an obligation to check, not a guarantee to edit |
| **POLY-3** | changing a decision invalidates the tests that encoded the old one |
| **POLY-4** | one repository, no propagation — the contrast |
| **POLY-5** | a green gate proves what it asserts and nothing more |

Nothing here was caught by reading. All of it was caught by the ladder, with a
file and a line.

## Start over

```bash
for r in hello-commands hello-core hello-cli hello-docs; do
  git -C $r checkout .
  git -C $r clean -qfd
done
rm -rf .deck docs
./setup.sh
```

`setup.sh` is idempotent: it leaves the repositories alone if they already
exist and only writes the files that are missing.
