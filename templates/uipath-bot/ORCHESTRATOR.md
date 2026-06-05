# Orchestrator Reference — {{PROJECT_NAME}}

Extends: ~/claude-project-framework/docs/ORCHESTRATOR_STANDARD.md

For connection settings, OData patterns, folder hierarchy, and uip CLI — see the standard.

---

## Folder Paths

| Environment | Folder Path | Folder ID |
|---|---|---|
| Prod | `Production/[Department]/{{PROJECT_NAME}}` | [ID] |
| Test | `Test/[Department]/{{PROJECT_NAME}}` | [ID] |
| Dev  | `Development/[Department]/{{PROJECT_NAME}}` | [ID] |

_Run `python3 ~/claude-project-framework/tools/scan-orchestrator.py --folders "Prod/path,Test/path,Dev/path" --output ./ORCHESTRATOR.md` to auto-populate all IDs below._

---

## Queues

| Queue Name | ID | Environment |
|---|---|---|
| `[QUEUE_NAME]` | [ID] | Prod |
| `[QUEUE_NAME]` | [ID] | Test |
| `[QUEUE_NAME]` | [ID] | Dev |

---

## Storage Buckets

| Bucket Name | ID | Provider | Environment |
|---|---|---|---|
| `[BUCKET_NAME]` | [ID] | Azure | Prod |

---

## Assets

| Asset Name | ID | Type | Environment |
|---|---|---|---|
| `[ASSET_NAME]` | [ID] | Text | Prod |

---

## Processes

| Process Name | Key | Environment |
|---|---|---|
| `{{PROJECT_NAME}}` | `[KEY]` | Prod |

---

## Notes

