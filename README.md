# Claude Project Framework

A token-efficient multi-agent Claude Code setup for development teams.
15 auto-routing agents, a two-layer documentation system, project templates, and
smart install scripts — all designed around one principle: **never pay for tokens you don't need.**

**Works with:** UiPath bots · C# libraries and APIs · Node.js/React apps · Python services

---

## Why This Exists — The Token Problem

When you open Claude Code on a project, Claude reads your `CLAUDE.md` file on **every single message** of the session. If that file is 17KB (not unusual for a project that's been running a while), you're spending ~4,250 tokens just on context overhead — before you've even asked anything.

Multiply that across a full session:

| Scenario | Tokens per message | 100-message session |
|---|---|---|
| Bloated 17KB CLAUDE.md | ~4,250 input tokens | 425,000 tokens of overhead |
| Trimmed 3.5KB CLAUDE.md | ~875 input tokens | 87,500 tokens of overhead |
| **Savings** | **79%** | **337,500 tokens saved** |

That's before counting model choice. Running a log analysis or doc lookup through Sonnet costs roughly **12× more** than running it through Haiku — for the exact same result.

This framework tackles both problems:

1. **Keep CLAUDE.md lean** — rules only, under 4KB. Detail lives in separate files loaded on demand.
2. **Route tasks to the cheapest model that can do the job** — 15 specialized agents, 14 on Haiku.
3. **Share org-wide standards globally** — never copy the same boilerplate into every project.

---

## Core Concepts

### 1. The Context Window Is Not Free

Every token sent to Claude costs money. Every token in your `CLAUDE.md`, every line of a file you paste, every message in a long session — all of it counts. Claude Code loads `CLAUDE.md` automatically, so its size directly multiplies your cost.

**What belongs in CLAUDE.md:**
- Rules, conventions, hard constraints
- Key file names and what they do
- What NOT to do (the non-obvious stuff)
- Pointers to other docs

**What does NOT belong in CLAUDE.md:**
- Full API signatures (put in DESIGN.md, load on demand)
- Endpoint lists (put in DESIGN.md)
- Deployment runbooks (put in DEPLOYMENT.md)
- Org-wide standards repeated in every project (put in global docs, inherit)

### 2. Agents — Delegate, Don't Load

When you ask Claude to review a git diff, it doesn't need to know your full project architecture. When you ask it to look up a queue ID, it doesn't need your test suite. Agents solve this by handling specific task types in isolation — they read only what they need and return a focused result.

**Without agents:**
```
You → "Review my diff" → Claude loads FULL project context → reviews diff
                         (paying for all that context you didn't need)
```

**With agents:**
```
You → "Review my diff" → Claude routes to pr-reviewer agent
                       → agent reads ONLY the git diff
                       → returns structured review
                       → main context never touched
```

Agents also run on **Haiku by default** — the cheapest Claude model. For tasks like log analysis, doc lookup, standards checking, and code review, Haiku performs identically to Sonnet at a fraction of the cost.

### 3. Delta MDs — Inherit, Don't Repeat

Every project in your org deploys to the same AWS setup, talks to the same Orchestrator tenant, follows the same Git workflow. Repeating that in every project's docs means paying to load it in every session.

The Delta MD system solves this with two layers:

```
Layer 1 — Global Standards (this repo, docs/)
  ORCHESTRATOR_STANDARD.md   ← your org's Orchestrator: URLs, auth, folder hierarchy, OData patterns
  DEPLOYMENT_STANDARD.md     ← your org's pipeline: ECS Fargate, GitHub Actions, AWS naming

Layer 2 — Project Delta MDs (per-project repo)
  ORCHESTRATOR.md   → "Extends: ORCHESTRATOR_STANDARD.md" + THIS project's queue IDs only
  DEPLOYMENT.md     → "Extends: DEPLOYMENT_STANDARD.md" + THIS project's APP_NAME + ARNs only
  CLAUDE.md         → rules only, under 4KB
  DESIGN.md         → architecture, API surface, models — loaded only when working on design
```

The `doc-lookup` agent handles the merge automatically — it loads the global standard first, then the project delta, and project values win on any overlap.

**Result:** A project `ORCHESTRATOR.md` goes from 5KB of repeated boilerplate to 1KB of project-specific values. A `DEPLOYMENT.md` goes from 12KB to 1.5KB.

---

## Quick Start

```bash
# Clone
git clone https://github.com/kakoritz/claude-project-framework.git ~/claude-project-framework
cd ~/claude-project-framework

# Linux / Mac
chmod +x install.sh && ./install.sh

# Windows (PowerShell — no admin needed)
.\install.ps1
```

Open any project in Claude Code. The 15 agents are live immediately.

---

## The 15 Agents

Agents auto-route — Claude recognizes the intent from your message and delegates.
No slash commands. No extra configuration. Just ask naturally.

| Agent | Model | Auto-triggers when you say... |
|---|---|---|
| `log-analyzer` | Haiku | Share error logs, stack traces, crash output |
| `doc-lookup` | Haiku | "What does DESIGN.md say about X" · "where is Y documented" |
| `pr-reviewer` | Haiku | "Review this diff" · "check before I commit" · "any issues here" |
| `uipath-helper` | Haiku | "What's the queue ID for..." · "which folder is TIR in" · OData patterns |
| `standards-checker` | Haiku | "Does this meet standards" · "any naming violations" · "check before PR" |
| `security-check` | Haiku | "Security review" · "any injection risks" · "check for exposed secrets" |
| `release-notes` | Haiku | "Update release notes" · "generate changelog" · "what changed in v2.1" |
| `test-advisor` | **Sonnet** | "Write tests for this" · "what's not covered" · "audit test coverage" |
| `uipath-reviewer` | Haiku | "Prep for code review" · "run pre-review checklist" |
| `dependency-audit` | Haiku | "Are my packages up to date" · "any vulnerable dependencies" |
| `env-checker` | Haiku | "Ready to deploy" · "check my env vars" · "anything missing from .env" |
| `db-advisor` | Haiku | Share SQL · "review this stored proc" · "index suggestions" |
| `jira-helper` | Haiku | "Write this as a Jira ticket" · "format my commit message" · "acceptance criteria" |
| `docker-advisor` | Haiku | Share Dockerfile · "why is my image large" · "ECS container patterns" |
| `azure-helper` | Haiku | "MSAL not working" · "app registration setup" · AADSTS error codes |

**`test-advisor` runs on Sonnet** because writing good tests requires real code reasoning.
Everything else runs on Haiku — fast, cheap, and more than capable for lookup and review tasks.

### How Auto-Routing Works

Each agent has a `description` field that Claude reads when deciding what to delegate.
Claude matches your message intent against those descriptions and routes accordingly.
You never need to know which agent handles what — just ask naturally.

```
You: "Are any of my npm packages out of date?"
Claude: [routes to dependency-audit → runs npm outdated → returns structured table]

You: "Review my diff before I push"
Claude: [routes to pr-reviewer → reads git diff only → returns findings]

You: "What does ORCHESTRATOR.md say about the TIR queue IDs?"
Claude: [routes to doc-lookup → loads global standard + project delta → returns exact values]
```

### Project-Specific Agents

For anything large or project-specific, add agents to `.claude/agents/` at the project root.
They extend the global 15 — they don't replace them.

```
your-project/
  .claude/
    agents/
      swagger-lookup.md   ← keeps a 5MB NSwag file out of main context window
      new-agent.md        ← scaffolds new agents following team standards
```

Good candidates for project agents: large reference files (Swagger specs, log archives),
project-specific workflows that run repeatedly, vendor API lookups.

---

## Setting Up a New Project

```bash
# Linux / Mac
./new-project.sh

# Windows
.\new-project.ps1
```

```
DCLI New Project
================
Project name: MyNewBot.Performer

Project type:
  [1] UiPath Bot       (Dispatcher or Performer)
  [2] C# Library       (reusable .NET library)
  [3] C# API           (ASP.NET Core minimal API)
  [4] Web UX           (Node.js + React frontend + backend)
  [5] Python           (script, agent, or service)

Type (1-5): 1

Created: D:\repos\MyNewBot.Performer\
  OK CLAUDE.md
  OK STANDARDS.md
  OK ORCHESTRATOR.md

Next: fill in the [placeholder] values in each MD file.
      ORCHESTRATOR.md needs your queue IDs and folder paths.
```

All `{{PROJECT_NAME}}` and `{{DATE}}` placeholders are replaced automatically.
What's left to fill in: your project description, queue IDs, folder paths, and any project-specific constraints.

---

## UiPath Coding Standards

`STANDARDS_UIPATH.md` is a complete standards file for any UiPath project. Copy it to your project root as `STANDARDS.md` — the `standards-checker` and `uipath-reviewer` agents read it automatically.

**Covers:**
- Argument prefixes: `in_`, `out_`, `io_` — no bare names
- Variable type prefixes: `str`, `dt`, `dtbl`, `int`, `bool`, `arr`, `dict`
- Workflow file tag conventions: `[BL]`, `[DB]`, `[Controller]`, `[Queue]`, etc.
- Main.xaml rules (framework-only — no custom logic)
- Config file rules (no hardcoded values)
- Logging: `[DCLI] Log Execution Event` — not bare Log Message
- Error handling patterns (Try-Catch with specific exception types)
- Pre-code-review checklist
- C# naming standards
- Python naming standards

---

## Customizing for Your Org

**Step 1 — Fill in `CLAUDE.md`**
Replace `[Your Name]`, `[Your Org]`, `[Your primary stack]`, and the infrastructure table
with your actual values. Keep it under 4KB.

**Step 2 — Fill in `docs/ORCHESTRATOR_STANDARD.md`**
Replace `[YOUR_ORG]`, `[YOUR_TENANT]`, and the folder hierarchy table with your
UiPath Orchestrator tenant details. This becomes the single source of truth for
all Orchestrator context across every project.

**Step 3 — Fill in `docs/DEPLOYMENT_STANDARD.md`**
Replace `[YOUR_SANDBOX_ACCOUNT]` and `[YOUR_GITHUB_ORG]`. Every new web app project
will extend from this instead of repeating the full runbook.

**Step 4 — Keep your filled version private**
Fork this repo or create a new private repo. Your filled-in version will contain
infrastructure URLs, account IDs, and folder paths — keep it internal.
Use this public repo as the starting template only.

---

## install.ps1 / install.sh — What They Do

Safe to run on any existing machine. The scripts never overwrite machine-specific config.

| File | Behavior |
|---|---|
| `~/.claude/agents/*.md` | Always deployed / updated — creates folder if missing |
| `~/.claude/CLAUDE.md` (no existing file) | Copied directly |
| `~/.claude/CLAUDE.md` (already has framework content) | Silently skipped |
| `~/.claude/CLAUDE.md` (exists, different content, under 4KB) | Prompt: Replace / Merge / Skip |
| `~/.claude/CLAUDE.md` (exists, over 4KB) | Same prompt + size warning |
| Replace | Timestamps backup, copies framework version |
| Merge | Timestamps backup, prints ready-to-paste Claude Code prompt to merge intelligently |
| `settings.json` | **Never touched** |
| `settings.local.json` | **Never touched** |
| `plugins/` | **Never touched** |

The **Merge** option generates a prompt you paste into Claude Code. Claude reads both files, keeps your personal context, adds the DCLI global standards where missing, and keeps the result under 4KB.

---

## Hooks — Zero-Token Automation

Hooks are shell scripts that fire on Claude Code events. They run entirely on your machine — no API call, no model, no tokens. The only token cost is when a hook fires a warning and Claude reads it (~20 tokens). Otherwise: free.

This framework ships two hooks, both wired to the `Write` tool:

### secret-scanner (PreToolUse:Write)

Fires **before** Claude writes any file. Scans the content for secret patterns and **blocks the write** if it finds one.

```
Claude tries to write appsettings.json containing "password=hunter2"
  → secret-scanner fires
  → pattern matched: password\s*=\s*.{4,}
  → exits non-zero → write BLOCKED
  → Claude sees the error, stops, explains what it found
```

Patterns it catches: AWS access keys, Anthropic/OpenAI API keys, private keys, `password=`, `client_secret=`, `api_key=` with values. Skips `.env.example` and `.env.sample` — those are intentionally showing key names.

**Why this matters:** `env-checker` and `security-check` agents only run when you ask them. This hook is always on. You can't forget to run it.

### claude-md-guard (PostToolUse:Write)

Fires **after** Claude writes any `CLAUDE.md` file. Checks the file size. If over 4KB, outputs a warning Claude reads on the next turn.

```
Claude writes a CLAUDE.md that grew to 6.2KB during a session
  → claude-md-guard fires
  → "CLAUDE.md is 6.2KB — over the 4KB limit"
  → Claude trims before continuing
```

**Why this matters:** CLAUDE.md is loaded on every message. Letting it drift to 6KB costs 79% more context overhead per message than keeping it under 4KB. The hook enforces the rule automatically.

### Wiring Hooks Into settings.json

The install scripts deploy the hook files to `~/.claude/hooks/` and print the exact JSON to add. Merge into the `hooks` section of your `settings.json`:

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Write",
      "hooks": [{"type": "command", "command": "~/.claude/hooks/secret-scanner.sh"}]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Write",
      "hooks": [{"type": "command", "command": "~/.claude/hooks/claude-md-guard.sh"}]
    }
  ]
}
```

Windows — use the `.ps1` versions:
```json
"command": "powershell -File %USERPROFILE%\\.claude\\hooks\\secret-scanner.ps1"
```

Keep any existing hooks (like RTK) — just add to the arrays, don't replace them.

---

## Prerequisites

See `SETUP.md` for full CLI install instructions. Short version:

| Tool | Required for | Quick install |
|---|---|---|
| `git` | All agents | Built-in / git-scm.com |
| `gh` | pr-reviewer, release-notes | `winget install GitHub.cli` |
| `uip` | uipath-helper | `npm install -g @uipath/uipath-cli` |
| `aws` | docker-advisor, env-checker | `winget install Amazon.AWSCLI` |
| `dotnet` | dependency-audit (C#) | dot.net/download |
| `node/npm` | dependency-audit (JS) | nodejs.org |
| `docker` | docker-advisor | Docker Desktop |

Agents degrade gracefully — if a tool isn't installed, the agent says so and gives you the install command.

---

## Repo Structure

```
claude-project-framework/
  agents/                      ← 15 global agents, auto-deployed by install scripts
  docs/
    ORCHESTRATOR_STANDARD.md   ← org-wide Orchestrator reference template
    DEPLOYMENT_STANDARD.md     ← org-wide ECS/GitHub Actions pipeline template
  templates/
    uipath-bot/                ← CLAUDE.md, STANDARDS.md, ORCHESTRATOR.md
    csharp-library/            ← CLAUDE.md, DESIGN.md
    csharp-api/                ← CLAUDE.md, DESIGN.md, DEPLOYMENT.md
    nodejs-react/              ← CLAUDE.md, DESIGN.md, DEPLOYMENT.md, ORCHESTRATOR.md
    python/                    ← CLAUDE.md, DESIGN.md
  windows/
    RTK.md                     ← RTK token optimizer (Windows only)
  CLAUDE.md                    ← global Claude context template
  STANDARDS_UIPATH.md          ← UiPath coding standards (copy to project as STANDARDS.md)
  SETUP.md                     ← CLI prerequisites and MCP server setup
  install.sh                   ← Linux/Mac install
  install.ps1                  ← Windows install
  new-project.sh               ← Linux/Mac project scaffold
  new-project.ps1              ← Windows project scaffold
```

---

## The Payoff

| Without this framework | With this framework |
|---|---|
| 17KB CLAUDE.md loaded every message | 3.5KB CLAUDE.md — 79% less context overhead |
| Same model for everything | Haiku for 14/15 tasks — ~12× cheaper per lookup |
| Org standards copy-pasted into every project | One global standard, project Delta inherits |
| New project = blank folder, figure it out | New project = scaffold script, MDs ready in 30 seconds |
| No structure on what Claude reads when | Explicit doc loading table — Claude knows what to load and when |
| Agent that reviews logs needs full project context | log-analyzer reads the log only, nothing else |

---

## Contributing

Issues and PRs welcome. Stack extensions (Java, Go, Terraform, etc.) are a great place to start.
