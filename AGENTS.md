# AGENTS.md — Repo Maintenance Guide

This repo is co-managed by Adam Spiker and Claude (Sonnet). This file is the source of truth
for how changes get made and kept in sync.

---

## Purpose

`claude-project-framework` is the canonical reference for replicating Adam's global Claude
config to other DCLI engineers. When a new engineer runs `setup.ps1` or `setup.sh`,
they get a complete, working Claude setup identical to Adam's.

**`~/.claude/` is where changes happen first. This repo always lags — but must stay canonical.**

---

## Remotes

| Remote | URL | Push access |
|---|---|---|
| `origin` | `https://github.com/kakoritz/claude-project-framework` | personal account (managed here) |
| `work` | `https://github.com/AdamSSpiker/claude-project-framework` | work account (managed at work) |

This Claude (home) manages `kakoritz`. Work Claude manages `AdamSSpiker`.

---

## Sync Workflow

Changes flow between both remotes. When working here:

1. **Check AdamSSpiker for diffs** — fetch and diff `work/main` vs `origin/main`
2. **Apply work changes here** — cherry-pick or manually apply
3. **Commit + push** to `kakoritz/claude-project-framework`

When working at work, vice versa — work Claude checks kakoritz for diffs.

On-the-fly changes happen in any session — new agents, framework doc updates, CLAUDE.md tweaks.
When Adam shares a change with Claude, the workflow is:

1. **Verify** — read the file in `~/.claude/` and confirm the change actually landed
2. **Update repo** — edit the matching file(s) in this repo to match
3. **Wire setup scripts** — if a new file was added, verify it deploys via `setup.sh` / `setup.ps1`
4. **Commit + push**

---

## What the Setup Scripts Deploy

Both `setup.ps1` (Windows) and `setup.sh` (Linux/Mac) copy these to `~/.claude/`:

| Repo location | Destination | Wired via |
|---|---|---|
| `agents/*.md` | `~/.claude/agents/` | glob |
| `global/*.md` | `~/.claude/` | glob (md only) |
| `hooks/*` | `~/.claude/hooks/` | glob |
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | smart merge (backup + prompt on fresh, section diff on update) |

When adding a new file that needs to land in `~/.claude/`, place it in `global/` — it deploys automatically.

---

## Agent Inventory (Global — `agents/`)

| Agent | Model | Scope |
|---|---|---|
| `orchestrator-helper` | Haiku | Orchestrator env lookups only — folder paths, queue IDs, OData, uip CLI |
| `uipath-helper` | Haiku | XAML, REFramework 2.5, pre-review checklist; reads `uipath-dcli-framework.md` |
| `code-indexer` | Haiku | AST structure lookup — what classes/methods a file contains |
| `orch-scanner` | Haiku | Scan live Orchestrator and populate ORCHESTRATOR.md |
| `log-analyzer` | Haiku | Error logs, stack traces, crash output |
| `doc-lookup` | Haiku | Project doc lookups — DESIGN, DEPLOYMENT, ORCHESTRATOR |
| `pr-reviewer` | Haiku | Git diff review before committing |
| `standards-checker` | Haiku | Code standards validation |
| `security-check` | Haiku | OWASP-focused security review |
| `release-notes` | Haiku | Changelog and release note generation |
| `jira-helper` | Haiku | Jira ticket creation and updates |
| `dependency-audit` | Haiku | Package version and vulnerability checks |
| `env-checker` | Haiku | .env validation, deploy readiness |
| `db-advisor` | Haiku | SQL and stored proc review |
| `docker-advisor` | Haiku | Dockerfile and ECS container patterns |
| `azure-helper` | Haiku | Azure AD / MSAL / AADSTS errors |
| `test-advisor` | Sonnet | Unit test generation and coverage audit |

---

## Adding a New Agent

1. Create `agents/<name>.md` with frontmatter (`name`, `description`, `tools`, `model`)
2. Write a tight `description` — this is what drives auto-routing
3. Add a row to the agent table above and to the table in `CLAUDE.md` and `README.md`
4. Commit and push

Agents in `agents/` are copied to `~/.claude/agents/` by the setup scripts automatically — no wiring needed.

---

## Versioning — MAJOR.MINOR.PATCH

Version lives in `config.yaml`. Bump it on every push that changes deployed behavior.

| Bump | When | Update behavior |
|---|---|---|
| `PATCH` (x.x.1) | Agent/hook fixes, wording tweaks, new knowledge in `global/` | Silent auto-update — no prompting |
| `MINOR` (x.1.0) | New agents, new framework CLAUDE.md sections, new tools | Per-section Y/n diff — engineer confirms each change |
| `MAJOR` (1.0.0) | Breaking — renamed/removed sections, restructured CLAUDE.md, removed agents | Claude-assisted merge required — setup script prints a merge prompt |

---

## Update Philosophy

This framework is **not an enforced workflow**. It is opt-in approved configuration.

**The contract:**
- Content inside `<!-- BEGIN:framework-* -->` markers in `CLAUDE.md` = org owns it. Updates overwrite it.
- Content outside markers = engineer owns it. Never touched by setup scripts.

**Three engineer profiles:**

**1. Blind trust** — run `setup.sh --update`, take everything. Fast, always current, no surprises. Right for most engineers.

**2. Savvy** — review the diff first (`git diff` between repo version and `~/.claude/`), use Claude to help decide what to keep. Right for engineers who've made local customizations they care about.

**3. Contributor** — made changes locally that the team would benefit from. Share them back: open a PR or tell Adam. If it's good, it gets diffed, reviewed, and pushed as a new version for everyone.

**The risk is explicit:** pulling a MINOR or MAJOR update without reviewing means you accept org defaults for the framework sections. That's the point — org standards stay canonical. Personal sections are always safe.

**When AI is involved:**
- PATCH/MINOR: mechanical — setup script handles it, no Claude needed
- MAJOR: judgment call — Claude reads both files, proposes a merge, engineer approves
- Contributor flow: Claude diffs the engineer's changes against main, flags what's novel vs. what diverges from org standards, maintainer decides what to pull in
