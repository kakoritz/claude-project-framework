---
# DCLI UiPath Coding Standards
# Copy to any UiPath project root as STANDARDS.md
# Loaded automatically by the standards-checker agent.
# Last updated: 2026-06-03
---

## Project & Repository Naming

- Format: `UPPER_CASE` with underscores, end with `_DISPATCHER` or `_PERFORMER`
- Examples: `MR_REBILL_MAIN_PERFORMER`, `TIR_DISPATCHER`
- N Drive format: `<DeptAbbreviation>_<ProcessName>_<BotType>` (e.g., `DI_DoubleInOut_Performer`)
- Project name in `project.json` must match repository name exactly

## Argument Naming (UiPath)

- Prefix all arguments with direction indicator:
  - `in_` — input (e.g., `in_CustomerData`)
  - `out_` — output (e.g., `out_InvoiceReport`)
  - `io_` — bidirectional (e.g., `io_TransactionStatus`)
- No bare argument names — `CustomerData` without prefix is a violation

## Variable Naming (UiPath)

- Use camelCase with a type prefix:
  - `str` — String (e.g., `strCustomerName`)
  - `dt` — DateTime (e.g., `dtInvoiceDate`)
  - `dtbl` — DataTable (e.g., `dtblResults`)
  - `int` — Integer (e.g., `intRetryCount`)
  - `bool` — Boolean (e.g., `boolIsValid`)
  - `arr` — Array (e.g., `arrQueueItems`)
  - `dict` — Dictionary (e.g., `dictTransactionArgs`)
- Keep variables within the scope they are used — never hoist unnecessarily

## Workflow / File Naming

- Use descriptive PascalCase with a purpose tag prefix:
  - `[BL]` — Business Logic (e.g., `[BL] ProcessInvoice.xaml`)
  - `[DL]` or `[DB]` — Data Layer (e.g., `[DB] ExecuteQuery.xaml`)
  - `[Controller]` — Control Logic (e.g., `[Controller] Main Process.xaml`)
  - `[Vendor]`, `[Terminal]` — grouped vendor/terminal logic
- Bad: `sqlfiletoexport.xaml` → Good: `[DB] PortHouston_ExportData.xaml`
- N Drive files: `Performer_ProjectName_Purpose.ext` (e.g., `Performer_TIR_SqlQuery_MatchLookup.sql`)

## Main.xaml Rules

- NO custom variables or business logic in Main.xaml — it is framework-only
- NO direct argument passing between sequences except via: Config dict, TransactionItem dict, TransactionArguments dict, DataTables, defined working Dicts
- If your scenario requires an exception: stop, consult architecture team, get approval

## Code Structure

- Controller-based architecture: each section of the bot lives in its own controller
- Controllers in own subfolder; child processes mirror their parent controller
- Shared utilities → `0.Common` or `Components` folder
- No spaghetti code — every controller does one thing
- Functions/sequences over ~40 activities = flag for decomposition

## Config File Rules

- No hard-coded values — all values in `Config.xlsx` or Orchestrator assets
- Config sections: Files, Storage Bucket, Database, Cloud, Business Exceptions
- `OutputFileFolder` is the ONLY allowed path in Environment tab
- All other paths → Constants tab, built with `Path.Combine` — never string concatenation
- Config source of truth = project root; Storage Bucket = execution copy only
- Never edit a config from a downloaded Storage Bucket file

## Logging

- Use `[DCLI] Log Execution Event` — not bare Log Message activities
- Log at three levels: Process (start/stop), Transaction (begin/end), Task (key actions within a transaction)
- `Log Execution Start` and `Log Execution End` must appear in every sequence
- Log levels: `Info` (general flow), `Warning` (potential issue), `Error` (failure)
- No junk logging — every log message must be meaningful and auditable
- No `Debug`-level logs left in production workflows

## Error Handling

- Error handling at the controller level — not buried in leaf sequences
- Use Try-Catch-Finally with specific exception types — never bare Catch
- Business exceptions and system exceptions handled separately
- Retry Scope for transient errors (3 retries, 5-second interval is standard)
- Avoid rethrowing without adding context

## Before Code Review

- Workflow Analyzer: 100% pass — zero warnings or errors
- Every activity has a descriptive annotation and unique display name
- Minimum 5 successful test runs, each processing 10+ transactions
- Must include controlled business exception scenarios
- All Jira tickets have substantive comments (what/why/how — not "done")
- SDD updated in Confluence with: Jira ticket #, description, date, developer

## Commit Protocol

- Daily commits required regardless of work size
- Format: `JIRA-1234: [description of change, intent, and impact]`
- Branch: never commit to `main` or `development` directly — always feature branch → PR → review

---

## C# Naming Standards (DCLI)

- Classes: `PascalCase` (e.g., `InvoiceProcessor`, `QueueManager`)
- Methods: `PascalCase` (e.g., `ProcessTransaction`, `LoadConfig`)
- Variables/parameters: `camelCase` (e.g., `invoiceAmount`, `transactionId`)
- Constants: `UPPER_CASE` (e.g., `MAX_RETRY_COUNT`)
- Interfaces: `IPascalCase` (e.g., `IQueueService`)
- Private fields: `_camelCase` (e.g., `_connectionString`)
- No magic strings — use constants or enums
- Null checks before property access on external data

## Python Naming Standards (DCLI)

- Modules/files: `snake_case` (e.g., `queue_manager.py`, `config_loader.py`)
- Classes: `PascalCase` (e.g., `InvoiceProcessor`)
- Functions/variables: `snake_case` (e.g., `process_transaction`, `invoice_amount`)
- Constants: `UPPER_CASE` (e.g., `MAX_RETRY_COUNT`)
- Type hints required on all function signatures
- Dataclasses for structured return values — not bare dicts or tuples
- No bare `except:` — always catch specific exception types
