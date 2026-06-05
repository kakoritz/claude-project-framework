# Release Notes — claude-project-framework

---

## v1.4.0 — 2026-06-05

### Agents (17 total)
- **Added** `orchestrator-helper` — Orchestrator env lookups (folder paths, queue IDs, OData, uip CLI). Split from uipath-helper.
- **Added** `code-indexer` — AST structure lookup via `ast-extract.py`. Returns file structure without loading full file content.
- **Added** `orch-scanner` — Scans live Orchestrator via OData and auto-populates `ORCHESTRATOR.md` with queue/asset/bucket/process IDs.
- **Updated** `uipath-helper` — Now focuses on XAML/REFramework design and pre-code-review checklist. Loads `uipath-dcli-framework.md` if present.
- **Removed** `uipath-reviewer` — Checklist absorbed into `uipath-helper`.

### Hooks
- **Added** `ast-extract.py` — Tree-sitter AST extractor. Returns classes, methods, functions, properties for C#/JS/TS/Python.
- **Added** `ts-context.py` — Tree-sitter context hook. Returns string literals and assignments only (used by secret scanner for false-positive reduction).
- **Updated** `secret-scanner.sh` / `secret-scanner.ps1` — AST-aware scanning. Writes content to temp file, runs `ts-context.py`, scans only code context (not comments). Falls back to regex if tree-sitter not installed.

### Tools
- **Added** `tools/scan-orchestrator.py` — stdlib-only OData scanner. Configurable via `UIPATH_BASE_URL` / `UIPATH_TOKEN_URL` env vars or `--base-url` / `--token-url` flags. Generates a complete `ORCHESTRATOR.md` delta.
- **Added** `tools/claude-md.py` — Framework section marker management. `add-markers` wraps known headings in `<!-- BEGIN/END:framework-* -->` tags. `update-sections` shows per-section unified diffs with Y/n prompts.

### Setup Scripts (renamed from install)
- `install.sh` / `install.ps1` → `setup.sh` / `setup.ps1`
- Auto-detect mode: fresh install if no agents exist, update mode if agents present
- Update mode: diffs agents/hooks individually, only overwrites changed files
- Per-section CLAUDE.md update via framework markers
- `global/*.md` deploy — org-private knowledge files land in `~/.claude/` automatically
- Version sentinel written to `~/.claude/.framework-version` on every run

### Templates
- `templates/uipath-bot/ORCHESTRATOR.md` — Updated structure matches `scan-orchestrator.py` output. Includes run hint.

### New Project
- `new-project.sh` / `new-project.ps1` — Added Orchestrator scan step for `uipath-bot` type. Prompts for folder paths, runs `scan-orchestrator.py` to auto-populate `ORCHESTRATOR.md`.

### Global Knowledge
- **Added** `global/uipath-dcli-framework.md` — DCLI-private UiPath framework reference. Full exception taxonomy, config state bus, tollgate pattern, SetTransactionStatus routing with message tags, N: Drive folder structure and access protocol, DCLI library components.

### Governance
- Semantic versioning: `MAJOR.MINOR.PATCH`
- Added `RELEASE_NOTES.md` (this file)
- Added `AGENTS.md` — repo maintenance guide, sync workflow, versioning philosophy, update contract

---

## v1.3.0 — 2026-05-01 *(approximate)*

- Initial public release with 15 agents
- `orchestrator-helper` / `uipath-helper` / `uipath-reviewer` as separate agents
- `secret-scanner` and `claude-md-guard` hooks
- `install.sh` / `install.ps1` (fresh install only)
- Templates for uipath-bot, csharp-api, csharp-library, nodejs-react, python
