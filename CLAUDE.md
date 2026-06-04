# Global Claude Context — [Your Name] / [Your Org]

Applies to every project. Project CLAUDE.md adds only what's unique to that repo.

---

## Who I Am

[Your role] at [Your Organization].
Primary stack: [Your primary stack — e.g. UiPath, C#, Python, Node.js/React, AWS].

---

## Standard Branch Protocol (All Projects)

- All work on `development` — never commit directly to `main`
- `main` is protected — only path in is a PR from `development`
- CI runs on every push to `development` and every PR to `main`
- Open PR only when CI is green
- Release = squash and merge

---

## Standard Doc Structure (All Projects)

Every project has these files. Load them only when relevant — not all at once.

| File | Load when... |
|---|---|
| `CLAUDE.md` | Always (rules only — keep under 4KB) |
| `DESIGN.md` | Working on architecture, new features, component changes |
| `ORCHESTRATOR.md` | Touching UiPath Orchestrator calls, folder paths, queue IDs |
| `DEPLOYMENT.md` | Deploying, configuring CI/CD, infrastructure changes |
| `AGENTS.md` | Adding or modifying project agents |
| `RELEASE_NOTES.md` | Asked about version history — otherwise never |
| `README.md` | Onboarding someone — otherwise never |

---

## Agent Standards

### Model Selection — Hard Rules

| Model | Use for | Never use for |
|---|---|---|
| `claude-haiku-4-5-20251001` | Lookup, search, read, summarize, log analysis, review | Complex code generation |
| `claude-sonnet-4-6` | Code implementation, refactoring, multi-step tasks | Simple lookups |
| `claude-opus-4-8` | Deep architecture decisions only — explicit request required | Anything Sonnet can handle |

Rule: **Use the cheapest model that can do the job.** Haiku handles 90% of lookup and review work.

### When to Use an Agent vs. Stay in Main Context

Use an agent when:
- The task requires reading a large reference file (swagger, orchestrator config, log file)
- The task is self-contained with a clear input/output (review this diff, look up this DTO)
- The task type recurs frequently across sessions

Stay in main context when:
- The task needs continuity with what came before
- The task requires back-and-forth judgment calls
- The result feeds directly into the next step

### Global Agents (Available in Every Project)

Defined in `~/.claude/agents/`. These run on every project automatically.

| Agent | Model | Trigger |
|---|---|---|
| `log-analyzer` | Haiku | User shares error logs, crash output, stack traces |
| `doc-lookup` | Haiku | User asks what a project doc says, or finds something in DESIGN/DEPLOYMENT/ORCHESTRATOR |
| `pr-reviewer` | Haiku | User asks to review changes, check a diff, or review before committing |
| `uipath-helper` | Haiku | User asks about folder paths, queue IDs, process keys, OData patterns |
| `standards-checker` | Haiku | User asks to check code against standards, validate best practices, or review before commit |
| `security-check` | Haiku | User asks for security check, vulnerability scan, injection risks, data exposure review |
| `release-notes` | Haiku | User asks to update release notes, generate a changelog entry, or create a release summary |
| `test-advisor` | Sonnet | User asks to write unit tests, generate tests for new code, or audit test coverage |
| `uipath-reviewer` | Haiku | User asks to prep a UiPath project for code review or run pre-code-review checklist |
| `dependency-audit` | Haiku | User asks if packages are up to date, wants vulnerability check, asks what's outdated |
| `env-checker` | Haiku | User asks if ready to deploy, wants .env validated, checks for committed secrets |
| `db-advisor` | Haiku | User shares SQL, asks about stored proc performance, schema review, index suggestions |
| `jira-helper` | Haiku | User asks to write a Jira ticket, format commit message, write acceptance criteria |
| `docker-advisor` | Haiku | User shares Dockerfile, asks about container optimization, layer caching, ECS patterns |
| `azure-helper` | Haiku | User asks about Azure AD / MSAL setup, app registrations, AADSTS errors, auth flows |

### Project Agents (Per-Project)

Defined in `.claude/agents/` at the project root. Add agents for anything large or
project-specific that should stay out of main context.

---

## Org Infrastructure (Fill In Your Values)

| System | Detail |
|---|---|
| UiPath Orchestrator | `[YOUR_ORCHESTRATOR_URL]` |
| Bot machine | `[YOUR_BOT_MACHINE]` |
| Cloud hosting | `[AWS / Azure / GCP]` |
| Auth | `[Your auth provider]` |
| Container registry | `[Your registry]` |
| Secrets | `[Your secrets manager]` |

---

## Code Style (All Projects)

- No comments unless the WHY is genuinely non-obvious
- No `.env` ever committed
- New config entries always go in the one designated file — never scattered
- Output: direct and dense — no preambles, no trailing summaries

---

## Token-Efficient Habits

- Reference specific files by name — don't scan whole projects
- Paste only the relevant error block, not full logs (use log-analyzer agent for full logs)
- `/compact` when a session gets long
- `/clear` when switching to a completely different task or project
