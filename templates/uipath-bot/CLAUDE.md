# {{PROJECT_NAME}} — Claude Context

Standard protocol for every change. Read this before touching anything.

---

## What This Is

[One sentence describing what this bot does and which business process it automates.]

- **Type:** [Dispatcher / Performer / Both]
- **GitHub:** https://github.com/dcli-com/{{PROJECT_NAME}}
- **Team:** robotic-process-automation
- **Branches:** `main` (stable) · `development` (active) — PRs target `main`
- **Jira epic:** [EPIC-###]

---

## Running Locally

1. Open `{{PROJECT_NAME}}` in UiPath Studio
2. Ensure `Config.xlsx` is in project root
3. Verify `OrchestratorPrimary` entry exists in Windows Credential Manager
4. Run via Studio — do not run `Main.xaml` directly

---

## Windows Credential Manager Entries Required

| Target | Holds |
|---|---|
| `OrchestratorPrimary` | UiPath OAuth2 Client ID + Client Secret |

---

## Hard Rules

- No hardcoded values — all config in `Config.xlsx` or Orchestrator assets
- Argument prefixes required: `in_`, `out_`, `io_` — bare names are a violation
- Variable type prefixes required: `str`, `dt`, `dtbl`, `int`, `bool`, `arr`, `dict`
- No business logic or custom variables in `Main.xaml` — framework only
- No bare Catch blocks — catch specific exception types
- Use `[DCLI] Log Execution Event` — not bare Log Message

---

## Key Files

| File | Purpose |
|---|---|
| `Main.xaml` | Framework entry point — no custom logic |
| `Config.xlsx` | All configuration values — edit here only |
| `Process/` | All custom workflow files |

Coding standards → **STANDARDS.md**
Orchestrator folder paths, queue IDs, process keys → **ORCHESTRATOR.md**

---

## Active State (as of {{DATE}})

- [ ] Initial project setup
- [ ] Config.xlsx populated
- [ ] QA testing — pending
- [ ] Code review — pending
- [ ] SDD in Confluence — pending
