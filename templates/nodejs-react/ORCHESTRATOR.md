# Orchestrator Reference — {{PROJECT_NAME}}

Extends: ~/dotfiles-claude/docs/ORCHESTRATOR_STANDARD.md

For connection settings, OData patterns, folder hierarchy, and uip CLI — see the standard.
Delete this file if the project does not interact with UiPath Orchestrator.

---

## This Project's Orchestrator Usage

- Auth: OAuth2 `client_credentials` via environment variables (`ORCHESTRATOR_CLIENT_ID`, `ORCHESTRATOR_CLIENT_SECRET`)
- Folders used: [list folders this app reads/triggers]
- Queues used: [list queues this app reads/writes]

---

## Process Keys (Bot Control)

| Process | Folder | Key | Args |
|---|---|---|---|
| [Process name] | `[FolderPath]` | [KEY] | [args or —] |
