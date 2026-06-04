# {{PROJECT_NAME}} — Claude Context

Standard protocol for every change. Read this before touching anything.

---

## What This Is

[One sentence describing what this API does and who calls it.]

- **Stack:** ASP.NET Core [version] Minimal API · Dapper · SQL Server
- **Port:** [port]
- **Auth:** [Azure AD / DevBypass / None]
- **GitHub:** https://github.com/dcli-com/{{PROJECT_NAME}}
- **Team:** robotic-process-automation
- **Branches:** `main` (stable) · `development` (active) — PRs target `main`

---

## Running Locally

```
cd src/{{PROJECT_NAME}}.Api
dotnet run
```

Navigate to **https://localhost:[port]**

---

## Windows Credential Manager Entries Required

| Target | Holds |
|---|---|
| `[CredentialName]` | [What it holds] |

---

## Hard Rules

- No inline SQL — all DB calls through `IRepo` → stored procs only
- `PascalCase` classes/methods · `camelCase` params · `_camelCase` private fields
- No magic strings — use constants or enums
- Null checks before property access on external data
- No secrets in config files — Windows Credential Manager only

---

## Key Files

| File | Purpose |
|---|---|
| `Program.cs` | Entry point, middleware order, DI |
| `rpa-config.json` | Operator config |
| `Sql/SqlConnectionFactory.cs` | WCM credential reader + connection |
| `Endpoints/` | All route definitions |

Full endpoint list, models, middleware detail → **DESIGN.md**

---

## Active State (as of {{DATE}})

- [ ] Initial API setup
- [ ] DB schema / stored procs — pending
- [ ] Auth wired up — pending
- [ ] Deployment — pending
