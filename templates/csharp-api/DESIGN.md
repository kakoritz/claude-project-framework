# {{PROJECT_NAME}} — Design Reference

Endpoints, models, middleware order, and SQL procs.
Load when adding new endpoints, changing DB schema, or reviewing architecture.

---

## Middleware Order

```csharp
app.UseCors();
app.UseAuthentication();
app.UseMiddleware<[ContextMiddleware]>();
app.UseAuthorization();
```

---

## Endpoints

| Method | Route | Handler | Auth |
|---|---|---|---|
| GET | `/health` | Health check | None |
| [METHOD] | `/api/[resource]` | [Handler] | [Role] |

---

## Models

```csharp
public record [ModelName](
    [Type] [Property],
    ...
);
```

---

## SQL Stored Procs

| Proc | Args | Notes |
|---|---|---|
| `[ProcName]` | `@[Param]` | [What it does] |

---

## File Map

```
src/
  {{PROJECT_NAME}}.Api/
    Program.cs
    rpa-config.json
    Middleware/
    Sql/
      SqlConnectionFactory.cs
      SqlDiagnosticEndpoint.cs
    Endpoints/
  {{PROJECT_NAME}}.Core/
    Data/IRepo.cs
    Data/Repo.cs
    Models/
```
