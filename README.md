# Claude Project Framework

A token-efficient multi-agent Claude Code setup for development teams.
Drop-in global configuration, auto-routing agents, project templates, and a two-layer
documentation system that keeps Claude context lean across every project type.

---

## What This Is

Instead of loading an entire repository into Claude's context window every session,
this framework routes tasks through specialized agents, compresses context before sending,
and caches shared documentation — so Claude stays fast and cheap at scale.

**Works with:** UiPath bots, C# libraries and APIs, Node.js/React apps, Python services.

---

## Quick Start

```bash
# Clone
git clone https://github.com/kakoritz/claude-project-framework.git ~/claude-project-framework
cd ~/claude-project-framework

# Install global config (Linux/Mac)
chmod +x install.sh && ./install.sh

# Install global config (Windows — run in PowerShell, no admin needed)
.\install.ps1
```

That's it. Open any project in Claude Code — the agents are live.

---

## How It Works

### Two-Layer Documentation

Every project uses **Delta MDs** — files that extend org-wide standards rather than repeat them.

```
Layer 1 — Global standards (this repo, docs/)
  ORCHESTRATOR_STANDARD.md   ← Orchestrator connection, OData patterns, folder hierarchy
  DEPLOYMENT_STANDARD.md     ← ECS Fargate pipeline, GitHub Actions, AWS resource naming

Layer 2 — Project Delta MDs (per-project, extends Layer 1)
  ORCHESTRATOR.md            ← this project's queue IDs, folder paths, process keys only
  DEPLOYMENT.md              ← this project's APP_NAME, ARNs, env vars only
  CLAUDE.md                  ← rules only, under 4KB
  DESIGN.md                  ← architecture, API surface, models (no duplication)
```

**Rule:** if it's the same across all projects, it lives in the global standard.
If it's unique to one project, it lives in the Delta MD.

The `doc-lookup` agent loads both layers automatically — project values override global values.

---

## Agents

Nine specialized agents auto-route based on what you ask. No slash commands needed —
Claude recognizes the intent and delegates.

| Agent | Model | Triggers on |
|---|---|---|
| `log-analyzer` | Haiku | Error logs, stack traces, crash output |
| `doc-lookup` | Haiku | "What does DESIGN.md say about X", "where is Y documented" |
| `pr-reviewer` | Haiku | "Review this diff", "check before I commit" |
| `uipath-helper` | Haiku | Folder paths, queue IDs, process keys, OData patterns |
| `standards-checker` | Haiku | "Check this against standards", "any violations" |
| `security-check` | Haiku | "Security review", "any injection risks", "check for exposed secrets" |
| `release-notes` | Haiku | "Update release notes", "generate changelog", "what changed in this version" |
| `test-advisor` | Sonnet | "Write tests", "what's not covered", "generate tests for this function" |
| `uipath-reviewer` | Haiku | "Prep for code review", "run pre-review checklist on this UiPath project" |

**Model selection rule:** use the cheapest model that can do the job.
Haiku handles 90% of tasks. Sonnet for code generation. Opus only for deep architecture — explicit request required.

### Adding Project-Specific Agents

Place agent `.md` files in `.claude/agents/` at the project root.
They extend the global agents — they don't replace them.

```
your-project/
  .claude/
    agents/
      swagger-lookup.md    ← keeps a 5MB NSwag file out of main context
      new-agent.md         ← scaffolds new agents following this standard
```

---

## Project Templates

Scaffold a new project with the right Claude MD files pre-populated:

```bash
# Linux/Mac
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
→ Creates MyNewBot.Performer/ with CLAUDE.md, STANDARDS.md, ORCHESTRATOR.md
→ All placeholders filled with project name and date
```

After running: fill in the `[placeholder]` values in each MD.

---

## UiPath Coding Standards

`STANDARDS_UIPATH.md` is a ready-to-use standards file for any UiPath project.
Copy it to your project root as `STANDARDS.md` — the `standards-checker` and `uipath-reviewer`
agents read it automatically.

Covers: argument prefixes (`in_`, `out_`, `io_`), variable type prefixes, workflow file tags,
Main.xaml rules, config file rules, logging requirements, error handling, commit protocol,
plus C# and Python naming standards.

---

## Customizing for Your Org

**1. Fill in `CLAUDE.md`**
Replace `[Your Name]`, `[Your Org]`, `[Your primary stack]`, and the infrastructure table
with your actual values.

**2. Fill in `docs/ORCHESTRATOR_STANDARD.md`**
Replace `[YOUR_ORG]`, `[YOUR_TENANT]`, and the folder hierarchy table with your
UiPath Orchestrator tenant details.

**3. Fill in `docs/DEPLOYMENT_STANDARD.md`**
Replace `[YOUR_SANDBOX_ACCOUNT]` and `[YOUR_GITHUB_ORG]` with your AWS account ID
and GitHub organization name.

**4. Push to your own private repo**
Keep your filled-in version private — it will contain infrastructure URLs and account IDs.
Use this public repo as the starting template only.

---

## install.ps1 / install.sh — What They Do

| Action | Behavior |
|---|---|
| Deploy agents | Always — creates `~/.claude/agents/`, copies all 9 agents |
| CLAUDE.md (fresh) | Copies directly — no prompt |
| CLAUDE.md (exists, already has framework content) | Skips silently |
| CLAUDE.md (exists, different content) | Prompts: Replace / Merge / Skip |
| Replace | Timestamps backup, copies framework version |
| Merge | Timestamps backup, prints ready-to-paste Claude Code merge prompt |

**Never overwrites** `settings.json`, `settings.local.json`, or `plugins/`.

---

## Repo Structure

```
claude-project-framework/
  agents/                    ← 9 global agents (auto-deploy via install scripts)
  docs/
    ORCHESTRATOR_STANDARD.md ← org-wide Orchestrator reference (fill in your values)
    DEPLOYMENT_STANDARD.md   ← org-wide ECS/GitHub Actions pipeline (fill in your values)
  templates/
    uipath-bot/              ← CLAUDE.md, STANDARDS.md, ORCHESTRATOR.md
    csharp-library/          ← CLAUDE.md, DESIGN.md
    csharp-api/              ← CLAUDE.md, DESIGN.md, DEPLOYMENT.md
    nodejs-react/            ← CLAUDE.md, DESIGN.md, DEPLOYMENT.md, ORCHESTRATOR.md
    python/                  ← CLAUDE.md, DESIGN.md
  windows/
    RTK.md                   ← RTK token optimizer (Windows only, deployed by install.ps1)
  CLAUDE.md                  ← global Claude context (customize for your org)
  STANDARDS_UIPATH.md        ← UiPath coding standards template
  install.sh                 ← Linux/Mac global install
  install.ps1                ← Windows global install
  new-project.sh             ← Linux/Mac project scaffold
  new-project.ps1            ← Windows project scaffold
```

---

## Contributing

Issues and PRs welcome. If you extend the framework for your stack (Java, Go, etc.)
a template PR is a good place to start.
