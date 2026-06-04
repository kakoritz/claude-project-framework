# {{PROJECT_NAME}} — Claude Context

Standard protocol for every change. Read this before touching anything.

---

## What This Is

[One sentence describing what this Python project does.]

- **Python:** 3.11+
- **Venv:** `/home/[user]/.venvs/[venv-name]/` (local disk — not on NAS, symlinks unsupported)
- **GitHub:** https://github.com/dcli-com/{{PROJECT_NAME}}
- **Team:** robotic-process-automation
- **Branches:** `main` (stable) · `development` (active) — PRs target `main`

---

## Setup

```bash
python3 -m venv /home/[user]/.venvs/[venv-name]
/home/[user]/.venvs/[venv-name]/bin/pip install -r requirements.txt
cp .env.example .env && nano .env
```

## Running

```bash
/home/[user]/.venvs/[venv-name]/bin/python [entry_point].py [args]
```

---

## Hard Rules

- Module/file names: `snake_case`
- Functions/variables: `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_CASE`
- Type hints on all function signatures
- Dataclasses for structured return values — not bare dicts
- No bare `except:` — catch specific exception types
- No `.env` committed

---

## Key Files

| File | Purpose |
|---|---|
| `[entry].py` | Entry point / CLI |
| `config.yaml` | Configuration |
| `requirements.txt` | Dependencies |

Full module structure and design → **DESIGN.md**

---

## Active State (as of {{DATE}})

- [ ] Initial setup
- [ ] Tests added — pending
