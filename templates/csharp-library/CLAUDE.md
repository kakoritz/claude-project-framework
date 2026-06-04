# {{PROJECT_NAME}} — Claude Context

Standard protocol for every change. Read this before touching anything.

---

## What This Is

[One sentence describing what this library provides and who consumes it.]

- **Target framework:** net8.0-windows
- **Output type:** Library
- **Root namespace:** [Namespace]
- **GitHub:** https://github.com/dcli-com/{{PROJECT_NAME}}
- **Team:** robotic-process-automation
- **Branches:** `main` (stable) · `development` (active) — PRs target `main`

---

## Key Files

| File | Purpose |
|---|---|
| [ClassName].cs | [Purpose] |
| Exceptions/Exceptions.cs | Custom exception types |

Full API signatures, models, and enums → **DESIGN.md**

---

## Hard Rules

- No inline SQL — all DB calls through repository pattern if applicable
- All public APIs must have typed return values — no raw `object` or `dynamic`
- Classes: `PascalCase` · Methods: `PascalCase` · Private fields: `_camelCase`
- Constants: `UPPER_CASE` · Interfaces: `IPascalCase`
- No magic strings — use constants or enums

---

## Active State (as of {{DATE}})

- [ ] Initial implementation
- [ ] Unit tests added
- [ ] NuGet package / integration — pending
