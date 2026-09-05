# hello-commands

A [deck](https://github.com/devfilipe/deck) pack: the operating knowledge for
this workspace, in a form an agent can execute against and a reviewer can check.

It is also a Claude Code plugin. The same directory carries `skills/`, and can
carry `agents/` and `hooks/`, which Claude Code loads directly.

```
config/detect.yaml     how deck recognises this workspace, and what it needs
config/toggles.yaml    the decisions this domain keeps re-making
config/gates.yaml      the verification ladder, and the commands behind it
config/mount.yaml      what gets placed in a repository, and how
config/profiles.yaml   named postures
rules/                 `paths:`-scoped rules, symlinked in on mount
skills/                procedures, loaded on demand by description
templates/workspace/   a filled-in descriptor for this shape of workspace
```

## Use it

```bash
export DECK_PACKS=$PWD          # or list it under `packs:` in the descriptor
deck doctor
deck toggle list
```

## Keep it honest

```bash
deck pack validate .            # structure, catalog, and the plugin manifest
```

Every entry should say why it exists and what each value costs. A catalog people
cannot read is a catalog people start ignoring.
