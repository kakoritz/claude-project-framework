# Setup — Prerequisites & CLI Reference

Everything the agents depend on. Install what applies to your stack.

---

## Required for All Machines

| Tool | Purpose | Install |
|---|---|---|
| **git** | All agents that read diffs, history, staged files | Built-in on Mac/Linux. Windows: [git-scm.com](https://git-scm.com) |
| **gh** (GitHub CLI) | `pr-reviewer`, `release-notes` | `winget install GitHub.cli` / `brew install gh` |
| **Claude Code** | The CLI itself | `npm install -g @anthropic-ai/claude-code` |

```bash
# Verify
git --version
gh --version
claude --version
```

---

## UiPath Stack

| Tool | Purpose | Install |
|---|---|---|
| **uip** (UiPath CLI) | `uipath-helper` — folder lookups, queue queries, process lists | `npm install -g @uipath/uipath-cli` |
| **UiPath Studio** | Running / debugging bots | UiPath download portal |

```bash
# Verify
uip --version
uip auth login    # one-time auth to your Orchestrator
```

---

## .NET / C# Stack

| Tool | Purpose | Install |
|---|---|---|
| **dotnet** SDK | `dependency-audit` — outdated/vulnerable package check | [dot.net/download](https://dot.net/download) |

```bash
dotnet --version
dotnet list package --outdated    # test it works
```

---

## Node.js / React Stack

| Tool | Purpose | Install |
|---|---|---|
| **node + npm** | `dependency-audit` — npm outdated / npm audit | [nodejs.org](https://nodejs.org) |

```bash
node --version
npm --version
npm audit    # test it works
```

---

## Python Stack

| Tool | Purpose | Install |
|---|---|---|
| **python3 + pip** | `dependency-audit` — pip list --outdated | [python.org](https://python.org) |
| **pip-audit** (optional) | Vulnerability scanning | `pip install pip-audit` |

```bash
python3 --version
pip --version
pip list --outdated
```

---

## AWS / ECS Stack

| Tool | Purpose | Install |
|---|---|---|
| **aws** (AWS CLI) | `docker-advisor`, `env-checker` — ECS queries, Secrets Manager | `winget install Amazon.AWSCLI` / `brew install awscli` |
| **docker** | `docker-advisor` | [Docker Desktop](https://www.docker.com/products/docker-desktop) |

```bash
aws --version
aws configure    # one-time: access key, secret, region
docker --version
```

---

## MCP Servers (Optional but Recommended)

MCP servers give agents live access to external systems — GitHub PRs, Jira tickets,
AWS resources — without leaving the Claude Code terminal.

### GitHub MCP
Lets agents read pull requests, issues, and comments directly.

```bash
gh extension install github/gh-mcp-server
```

Add to `~/.claude/settings.json`:
```json
{
  "mcpServers": {
    "github": {
      "command": "gh",
      "args": ["mcp", "serve"],
      "env": {}
    }
  }
}
```

### UiPath MCP
Lets `uipath-helper` query Orchestrator live (jobs, queues, folders).
Install via Claude Code: `/install-plugin uipath@uipath-marketplace`

### AWS MCP (Community)
```bash
npm install -g @aws/aws-mcp-server
```

---

## Verify Everything

Run this after installing to confirm what's available:

```bash
echo "=== Core ===" && git --version && gh --version
echo "=== UiPath ===" && uip --version 2>/dev/null || echo "uip: not installed"
echo "=== .NET ===" && dotnet --version 2>/dev/null || echo "dotnet: not installed"
echo "=== Node ===" && node --version 2>/dev/null || echo "node: not installed"
echo "=== Python ===" && python3 --version 2>/dev/null || echo "python3: not installed"
echo "=== AWS ===" && aws --version 2>/dev/null || echo "aws: not installed"
echo "=== Docker ===" && docker --version 2>/dev/null || echo "docker: not installed"
```

---

## What Breaks Without Each Tool

| Missing tool | Affected agents | Fallback |
|---|---|---|
| `gh` | pr-reviewer, release-notes | Agents will ask you to paste diff manually |
| `uip` | uipath-helper | Agent reads ORCHESTRATOR.md only, no live queries |
| `dotnet` | dependency-audit (C#) | Agent skips .NET check, reports tool missing |
| `npm` | dependency-audit (JS) | Agent skips npm check, reports tool missing |
| `pip` | dependency-audit (Python) | Agent skips pip check, reports tool missing |
| `aws` | docker-advisor, env-checker | ECS-specific advice only, no live queries |
| `docker` | docker-advisor | Reviews Dockerfile statically, no build test |
