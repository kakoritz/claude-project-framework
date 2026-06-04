# Agent Test Inputs

Sample inputs for manually verifying each agent triggers and responds correctly.
Run these in Claude Code after setup. Record pass/fail in the table below.

---

## Why Manual Testing

Agents are language model instructions — they cannot be unit tested like code.
The only way to verify they work is to run them against real inputs and check
that: (a) the agent auto-routes correctly, (b) the output format matches the spec,
(c) the response is accurate.

**Recommended:** run each test once per engineer on their first day. Log results below.

---

## Test Matrix

| Agent | Trigger phrase | Expected behavior | Tested? |
|---|---|---|---|
| log-analyzer | [paste a stack trace] | Returns structured error table | |
| doc-lookup | "What does ORCHESTRATOR.md say about queue IDs?" | Loads global standard + project delta, returns values | |
| pr-reviewer | "Review my diff before I push" | Runs git diff, returns findings by severity | |
| uipath-helper | "What folder is Pending Rebill in?" | Reads ORCHESTRATOR.md, returns folder path | |
| standards-checker | "Check my last changes against standards" | Runs git diff, flags violations | |
| security-check | "Any security issues in my diff?" | Runs git diff, checks OWASP patterns | |
| release-notes | "Generate changelog for this version" | Runs git log, returns formatted release notes | |
| test-advisor | "Write tests for this function" | Returns runnable test file matching project style | |
| uipath-reviewer | "Run pre-code-review checklist on this project" | Returns PASS/FAIL table per check | |
| dependency-audit | "Are my npm packages up to date?" | Runs npm outdated + audit, returns table | |
| env-checker | "Am I ready to deploy?" | Reads .env.example, checks .env, returns status | |
| db-advisor | [paste a stored proc] | Returns SQL review by severity | |
| jira-helper | "Write this as a Jira ticket: [description]" | Returns formatted ticket with ACs | |
| docker-advisor | [paste a Dockerfile] | Returns review by severity | |
| azure-helper | "My MSAL redirect is failing with AADSTS50011" | Returns specific fix for that error code | |

---

## Sample Inputs

### log-analyzer
Paste any stack trace or crash output. Example:
```
System.NullReferenceException: Object reference not set to an instance of an object.
   at DCLI.Applications.UiPath.Orchestrator.OrchestratorClient.StartTransactionAsync(String queueName, String folderPath)
   at TaskTracker.Api.Endpoints.QueueEndpoints.<>c__DisplayClass0_0.<MapQueueEndpoints>b__0(HttpContext ctx)
```

### doc-lookup
Ask: `"What does ORCHESTRATOR.md say about the TIR queue IDs?"`
Expected: loads ORCHESTRATOR_STANDARD.md first, then project ORCHESTRATOR.md, returns TIR queue table.

### pr-reviewer
Ask: `"Review my diff"` with uncommitted changes present.
Expected: runs `git diff HEAD`, returns findings table with file/line/severity.

### db-advisor
Paste:
```sql
CREATE PROCEDURE dbo.GetAllTasks
AS
BEGIN
    SELECT * FROM TT_Tasks WHERE IsActive = 1
END
```
Expected: flags SELECT *, missing NOCOUNT ON, missing error handling.

### docker-advisor
Paste:
```dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD node server.js
```
Expected: flags COPY . . before npm install (cache-busting), no .dockerignore check,
shell-form CMD (signal handling issue), running as root.

---

## Logging Results

| Engineer | Date | Agents tested | Issues found |
|---|---|---|---|
| | | | |
