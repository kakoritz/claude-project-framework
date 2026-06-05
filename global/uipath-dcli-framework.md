# DCLI UiPath REFramework 2.5 — Framework Reference

Living reference for how DCLI's custom REFramework and library behave.
Add to this as new patterns are confirmed. Do not guess — only document what has been verified.

---

## Exception Taxonomy

Two types. Every child workflow throws one or neither — never both.

| Type | Class | Meaning |
|---|---|---|
| SysEx | `System.Exception` | Unknown, unexpected — something broke |
| BRE | `UiPath.Core.BusinessRuleException` | Known, intentional — a business decision was made |

**Key rule**: BRE = the robot knew what was happening and made a deliberate choice (postpone, skip, reject). SysEx = the robot did not expect this and cannot continue.

---

## Config Dictionary as State Bus

`io_Config` is a `Dictionary(Of String, Object)` passed by reference through the entire call chain. It carries:

- Runtime config values (connection strings, folder paths, thresholds)
- Error state: `io_Config("BusinessError")` and `io_Config("SystemError")`
- Counters: `TotalTirsExtracted`, `TotalTirsMocked`, `TotalTirsFailed`, `BusinessErrorsTotal`, `SystemErrorsTotal`
- Connection objects: `AwsDbConnection`, etc.

`io_TrnArgs` is a parallel `Dictionary(Of String, Object)` scoped to the current transaction (S3 URLs, flags, file paths, etc.).

---

## Exception Flow — "Children throw, daddy catches"

1. **Vendor/component workflow** throws `New UiPath.Core.BusinessRuleException("...")` or lets a system exception bubble naturally
2. **Business Process controller** (`[Controller] Business Process.xaml`) has a top-level TryCatch with two catches:
   - `Catch(BusinessRuleException)` → stamps `io_Config("BusinessError") = exception`
   - `Catch(Exception)` → stamps `io_Config("SystemError") = exception`
3. Business Process completes its finally/cleanup regardless
4. **SetTransactionStatus** is called from Main.xaml and reads the config to determine outcome

Children do not need to know what happens to exceptions — they just throw the right type. The controller handles routing.

---

## Tollgate Pattern

Business Process checks config before each major step:

```vb
(Not io_Config.ContainsKey("BusinessError") OrElse io_Config("BusinessError") Is Nothing) AndAlso
(Not io_Config.ContainsKey("SystemError") OrElse io_Config("SystemError") Is Nothing)
```

If either error is set, the step is skipped. This means a failure in step 2 cleanly stops steps 3 and 4 without needing nested try-catches everywhere.

---

## SetTransactionStatus Routing

Reads `io_Config` and routes to one of:

| Condition | Outcome |
|---|---|
| No error set | `Successful` |
| `BusinessError` set, message contains `[BRE-POSTPONE]` | `PostponeTransactionItem` |
| `BusinessError` set, message contains `[BRE-RETRY]` | `RetryCurrentTransaction` |
| `BusinessError` set, no tag match | `Failed` (Business Exception) |
| `SystemError` set, message contains `[EX-POSTPONE]` | `PostponeTransactionItem` |
| `SystemError` set, message contains `[EX-RETRY]` | `RetryCurrentTransaction` |
| `SystemError` set, no tag match | `Failed` (Application Exception) |

### Exception Message Tags

Embed these tags in exception messages to control routing:

| Tag | Effect |
|---|---|
| `[BRE-POSTPONE]` | Postpone the queue item (defer date from config) |
| `[BRE-RETRY]` | Retry the transaction immediately |
| `[EX-POSTPONE]` | Postpone (system error path) |
| `[EX-RETRY]` | Retry (system error path) |

---

## BNSF-Specific DeferDate

When the queue item's `Terminal` SpecificContent contains `"BNSF"`, the postpone defer date uses a config key:

```vb
DateTime.Now.AddDays(CInt(io_Config("BNSF_PostponeIntervalDays")))
```

All other terminals default to `DateTime.Now.AddHours(1)`.

---

## N: Drive Folder Structure (All DCLI UiPath Projects)

Standard layout under `N:\Robotics Process Automation (RPA)\Automations\{ProjectFolderName}\`:

```
{ProjectFolderName}\
├── {Config file}          ← root only — the project's Config.xlsx or equivalent
├── Input\                 ← artifacts that live in Orchestrator storage bucket
│   └── (SQL files, crosswalk files, templates, etc.)
└── Output\
    ├── Production\        ← bot output for Production environment
    ├── Test\              ← bot output for Test environment
    └── Development\       ← bot output for Development environment
```

- **Root**: one config file only — always `*.xlsx`, filename varies per project. Use `Get-Item *.xlsx` to resolve it without hardcoding.
- **Input**: anything that should be uploaded to the Orchestrator storage bucket for the bot to read at runtime
- **Output**: environment-scoped folders for bot-generated files; env determined at runtime from config

When documenting a project, the global standard (above) lives here. The project-specific N: drive path and its Input file inventory live in that project's `DEPLOYMENT.md`.

---

## N: Drive Access Protocol (All Operations)

**Always ask the engineer before performing any N: drive operation** — read, upload, edit, or delete. Never assume.

| Operation | Pattern |
|---|---|
| **Read** | Copy file to local `temp/` → perform work → delete `temp/` when work is complete or assumed complete |
| **Upload** | Copy file to local `temp/` → run `uip resource bucket-files upload` from local path → delete `temp/` |
| **Edit** | Copy file to local `temp/` → make edits locally → present changes to engineer → engineer manually copies back to N: drive (never automate the write-back) → delete `temp/` |
| **Delete** | Never delete from N: drive without explicit engineer confirmation |

**Why**: Direct PowerShell reads/writes to N: drive (UNC path) are flagged by TechOps scanning. The `uip` CLI is a signed vendor binary using OAuth2 — uploading from a local path via CLI is the approved pattern. Raw PowerShell HTTP calls to Orchestrator are not.

---

## Dispatcher / Performer Pattern

- **Dispatcher**: reads source data, adds items to Orchestrator queue
- **Performer**: dequeues one item at a time, runs business logic, sets transaction status
- Never mix dispatcher and performer logic in one process
- **Queue selection is runtime-dynamic**: the queue name is built from config and transaction arguments at runtime. Queues are NOT linked to processes via Orchestrator triggers — do not flag "unlinked" queues as an issue.

---

## DCLI Library Components (Known)

| Component | Purpose |
|---|---|
| `[DCLI] Log Execution Event` | Structured task-level logging with EventName, EventState, EventType |
| `[DCLI] DB Connection Manager` | Manages AWS DB connection lifecycle |
| `[DCLI] .sql File - Query Builder` | Pulls SQL from Orchestrator storage bucket, substitutes parameters |
| `[DCLI] Kill Processes` | Kills browser/app processes after each transaction |
| `[DCLI] File List Cleanup` | Deletes transaction-scoped temp files |
| `[DCLI] Take Screenshot` | Captures screenshot on failure, stores path in `io_TrnArgs("TransactionScreenshot")` |
| `[DCLI] BRE Add To Log` | Appends BRE outcome to the run's BRE report |

---

## Notes

- `io_Config` keys are case-sensitive in VB.NET dictionary lookups
- Always check `ContainsKey` before accessing — missing keys throw KeyNotFoundException
- `in_TransactionArguments` in Business Process = same dict as `io_TrnArgs` in vendor workflows (passed by reference)
