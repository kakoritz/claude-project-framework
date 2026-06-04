# UiPath Orchestrator — Organization Standards

Global reference for all projects that interact with UiPath Orchestrator.
**Fill in your org's values below.** Project ORCHESTRATOR.md files extend this with project-specific queue IDs and process keys.

---

## Connection

| Setting | Value |
|---|---|
| Organization | `[YOUR_ORG]` |
| Tenant | `[YOUR_TENANT]` |
| Orchestrator base URL | `https://cloud.uipath.com/[YOUR_ORG]/[YOUR_TENANT]/orchestrator_` |
| Identity / token URL | `https://cloud.uipath.com/identity_/connect/token` |
| OAuth2 grant type | `client_credentials` |
| Default scope | `OR.Assets OR.Queues OR.Queues.Read OR.Queues.Write OR.Execution OR.Folders OR.Robots OR.Machines OR.Logs OR.Logs.Read` |
| Credential source | Windows Credential Manager → `OrchestratorPrimary` (username = Client ID, password = Client Secret) |
| Bot machine | `[YOUR_BOT_MACHINE]` |

---

## Environment Folder Structure

Every project mirrors across all three environments:

| Root | Purpose |
|---|---|
| `Production` | Live runs |
| `Test` | QA / testing |
| `Development` | Dev / WIP |

---

## Production Folder Hierarchy

Add your org's production folder tree here. Example pattern:

| Department | Folder Path |
|---|---|
| [Department A] | `Production/[DeptA]/[Process Name]` |
| [Department B] | `Production/[DeptB]/[Process Name]` |

---

## OData API Patterns

```
# Auth token
POST https://cloud.uipath.com/identity_/connect/token
  grant_type=client_credentials&client_id=...&client_secret=...&scope=...

# All OData calls require folder ID as header:
X-UIPATH-OrganizationUnitId: {folderId}

# Resolve folder ID from path
GET odata/Folders?$filter=FullyQualifiedName eq 'Production/[Dept]/[Process]'

# Resolve queue definition ID from name
GET odata/QueueDefinitions?$filter=Name eq '{queueName}'

# Running jobs
GET odata/Jobs?$filter=State eq 'Running'&$top=100

# Error logs (time-bounded)
GET odata/RobotLogs?$filter=Level eq 'Error' and TimeStamp ge 2026-01-01T00:00:00Z&$top=500

# Processed queue items (use EndProcessing for time filter, not CreationTime)
GET odata/QueueItems?$filter=QueueDefinitionId eq {id} and Status eq 'Successful'
  and EndProcessing ge 2026-01-01T00:00:00Z&$top=100&$skip=0&$orderby=EndProcessing asc

# Pagination — stop when page returns fewer than $top
$top=100&$skip=0  →  next page: $skip=100
```

OData status values: `'New'`, `'Successful'`, `'Failed'`, `'Abandoned'`, `'Retried'`, `'Deleted'`

---

## uip CLI Reference

```powershell
uip auth login
uip or folders list --output json
uip or jobs list --folder-path "Production/[Dept]/[Process]" --state Running
uip resource queues list --folder-path "Production/[Dept]/[Process]"
uip or processes list --all-fields
uip mcp serve
```

---

## Credential Setup (Windows)

1. Control Panel → Credential Manager → Windows Credentials → Add a generic credential
2. Address: `OrchestratorPrimary` · Username: Client ID · Password: Client Secret
3. Read via: `WindowsCredentialManager.Read("OrchestratorPrimary")`
