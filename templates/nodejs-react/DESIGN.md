# {{PROJECT_NAME}} — Design Reference

Component map, API routes, and architecture decisions.
Load when adding new features, changing routes, or reviewing component structure.

---

## Architecture

```
Browser
  → React frontend (port [frontend-port])
  → Express backend (port [backend-port])
      → [External services]
```

---

## API Routes

| Method | Route | Handler | Auth |
|---|---|---|---|
| GET | `/api/health` | Health check | None |
| [METHOD] | `/api/[resource]` | [What it does] | [Role] |

---

## Component Map

```
frontend/src/
  App.jsx              ← root, routing
  context/
    AuthContext.jsx    ← useAuth() hook
  components/
    [Component].jsx    ← [purpose]
  views/
    [View].jsx         ← [purpose]
```

---

## Backend Structure

```
backend/
  server.js            ← entry, all routes
  lib/
    [service].js       ← [purpose]
```

---

## State Management

[Describe how state flows — context, props, localStorage, etc.]

---

## Auth Flow

[Describe auth mechanism — MSAL, role-based, dev bypass, etc.]
