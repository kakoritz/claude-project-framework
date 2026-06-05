# Deployment — {{PROJECT_NAME}}

Extends: ~/claude-project-framework/docs/DEPLOYMENT_STANDARD.md

For full ECS Fargate runbook, GitHub Actions setup, and AWS patterns — see the standard.

---

## Project Identity

| Setting | Value |
|---|---|
| APP_NAME | `[kebab-case-name]` |
| GitHub repo | `dcli-com/{{PROJECT_NAME}}` |
| Container port | `[port]` |
| AWS Sandbox account | `329599626100` |

---

## AWS Resources

| Resource | Value |
|---|---|
| ECR Repository | `329599626100.dkr.ecr.us-east-1.amazonaws.com/[app-name]` |
| ECS Cluster | `[app-name]` |
| Secrets Manager | `[app-name]/env` |

---

## Container Environment Variables

```
[ENV_VAR_1]
[ENV_VAR_2]
PORT=[port]
NODE_ENV=production
```

---

## Status

- [ ] AWS one-time setup complete
- [ ] GitHub environments created
- [ ] First deploy triggered
- [ ] Azure App Registration updated (if SSO)
