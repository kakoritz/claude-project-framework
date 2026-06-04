# {{PROJECT_NAME}} — Design Reference

Module structure, classes, and architecture decisions.
Load when adding new modules, refactoring, or reviewing design.

---

## Architecture

```
[entry].py          ← CLI entry point / orchestration
[module]/
  [file].py         ← [purpose]
config.yaml         ← all configuration
.env                ← secrets (never committed)
requirements.txt
tests/
  test_[module].py
```

---

## Key Classes

```python
@dataclass
class [ClassName]:
    [field]: [type]
    ...
```

---

## Key Functions

```python
def [function_name]([param]: [type]) -> [return_type]:
    """[one-line description]"""
```

---

## Configuration

All config in `config.yaml`. Secrets in `.env` via `python-dotenv`.

| Key | Type | Purpose |
|---|---|---|
| `[key]` | `[type]` | `[what it controls]` |

---

## Dependencies

| Package | Purpose |
|---|---|
| `[package]` | `[what it does]` |
