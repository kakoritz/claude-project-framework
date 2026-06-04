# {{PROJECT_NAME}} — Claude Context

Standard protocol for every change. Read this before touching anything.

---

## What This Is

[One sentence describing what this app does and who uses it.]

- **Frontend:** React [version] + Vite + Tailwind CSS · port [port]
- **Backend:** Node.js + Express (ESM modules) · port [port]
- **Auth:** [MSAL / None / DevBypass]
- **GitHub:** https://github.com/dcli-com/{{PROJECT_NAME}}
- **Team:** robotic-process-automation
- **Branches:** `main` (stable) · `development` (active) — PRs target `main`

---

## Running Locally

```bash
cd backend && npm run dev    # Terminal 1
cd frontend && npm run dev   # Terminal 2
```

Open **http://localhost:[frontend-port]**. Vite proxies `/api/*` → backend port.

---

## Hard Rules

- ESM `import` only — no `require()`
- `async/await` over raw promise chains
- No `var` — use `const` or `let`
- No `console.log` in production paths
- No secrets in code — `.env` only, never committed
- Theme: Tailwind `dark:` alongside light classes — never remove light classes

---

## Key Files

| File | Purpose |
|---|---|
| `backend/server.js` | Express entry point, all routes |
| `frontend/src/App.jsx` | Root component, routing |
| `frontend/src/context/AuthContext.jsx` | `useAuth()` hook |

Full component map, API routes, architecture → **DESIGN.md**
Deployment → **DEPLOYMENT.md**

---

## Active State (as of {{DATE}})

- [ ] Initial setup
- [ ] Auth wired up — pending
- [ ] ECS deployment — pending
