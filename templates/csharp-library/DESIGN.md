# {{PROJECT_NAME}} — Design Reference

API surface, models, enums, and architecture decisions.
Load when implementing new methods, adding models, or reviewing public API shape.

---

## Public API

Class: `[ClassName]`

```csharp
// Setup / configuration
// [method signatures here]

// Core operations
// [method signatures here]
```

---

## Models

```csharp
public sealed class [ModelName]
{
    // [properties]
}
```

---

## Enums

```csharp
enum [EnumName] { [Values] }
```

---

## Exception Types

```csharp
[ExceptionName]    // [when thrown]
```

---

## Architecture Decisions

| Decision | Rationale |
|---|---|
| [Decision] | [Why] |

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| [Package] | [Version] | [What it does] |
