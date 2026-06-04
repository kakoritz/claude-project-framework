# Deployment Standard — Node.js/React to AWS ECS Fargate

Standard deployment pipeline for web apps.
**Fill in your org's values.** Project DEPLOYMENT.md files extend this with app-specific names, ARNs, and env vars.

Substitute `APP_NAME` with your app's kebab-case name (e.g. `my-dashboard`).
Substitute `YOUR_SANDBOX_ACCOUNT` with your AWS sandbox account ID.

---

## Architecture

```
GitHub (development branch)
  → CI tests pass
  → GitHub Actions builds Docker image
  → Pushes image to AWS ECR
  → Forces ECS Fargate service redeploy
  → New container is live
```

**Two environments, two AWS accounts:**

| Environment | Branch | AWS Account | Deploy Trigger |
|---|---|---|---|
| Development | `development` | Sandbox (`[YOUR_SANDBOX_ACCOUNT]`) | Automatic on push |
| Production | `main` | Production (TechOps-provisioned) | Manual approval required |

**Secrets flow:**
```
Local .env → AWS Secrets Manager → ECS task injects → container at runtime
```

---

## Standard Resource Naming

| Resource | Name Pattern |
|---|---|
| ECR Repository | `APP_NAME` |
| ECS Cluster | `APP_NAME` |
| ECS Service | `APP_NAME` |
| CloudWatch Log Group | `/ecs/APP_NAME` |
| Secrets Manager secret | `APP_NAME/env` |
| Task Execution Role | `ecsTaskExecutionRole` (shared) |
| GitHub Deploy Role | `github-actions-APP_NAME-deploy` |

---

## Standard ECS Task Definition (baseline)

```json
{
  "family": "APP_NAME",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::YOUR_SANDBOX_ACCOUNT:role/ecsTaskExecutionRole"
}
```

---

## Part 1 — One-Time AWS Setup (CloudShell)

### 1.1 — ECR Repository
```bash
aws ecr create-repository --repository-name APP_NAME --region us-east-1 --image-scanning-configuration scanOnPush=true
```

### 1.2 — ECS Cluster
```bash
aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com   # skip if exists
aws ecs create-cluster --cluster-name APP_NAME --region us-east-1 --capacity-providers FARGATE
```

### 1.3 — CloudWatch Log Group
```bash
aws logs create-log-group --log-group-name /ecs/APP_NAME --region us-east-1
```

### 1.4 — ECS Task Execution Role (shared — once per account)
```bash
aws iam create-role --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam attach-role-policy --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam attach-role-policy --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite
```

### 1.5 — GitHub Actions OIDC Deploy Role
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
GITHUB_ORG="[YOUR_GITHUB_ORG]"
GITHUB_REPO="[YOUR_REPO_NAME]"

aws iam create-role --role-name github-actions-APP_NAME-deploy \
  --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Federated\":\"arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com\"},\"Action\":\"sts:AssumeRoleWithWebIdentity\",\"Condition\":{\"StringEquals\":{\"token.actions.githubusercontent.com:aud\":\"sts.amazonaws.com\"},\"StringLike\":{\"token.actions.githubusercontent.com:sub\":\"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main\"}}}]}"
```

### 1.6 — Push Secrets to Secrets Manager
Upload `.env` via CloudShell → Actions → Upload file, then:
```bash
node -e "
const fs=require('fs'),obj={};
fs.readFileSync('.env','utf8').split('\n').forEach(l=>{const m=l.match(/^([A-Z_][A-Z0-9_]*)=(.+)$/);if(m)obj[m[1]]=m[2].trim()});
console.log(JSON.stringify(obj));
" | xargs -0 aws secretsmanager create-secret --name "APP_NAME/env" --region us-east-1 --secret-string
```

### 1.7 — Create ECS Service
```bash
SUBNET=$(aws ec2 describe-subnets --filters Name=default-for-az,Values=true --query 'Subnets[0].SubnetId' --output text)
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=default --query 'SecurityGroups[0].GroupId' --output text)
aws ecs create-service --cluster APP_NAME --service-name APP_NAME --task-definition APP_NAME \
  --launch-type FARGATE --desired-count 1 \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=ENABLED}" \
  --region us-east-1
```

---

## Part 2 — GitHub Setup

Create environments: `development` (no rules) and `production` (required reviewer).

Add to both environments:

| Secret | Value |
|---|---|
| `AWS_REGION` | `us-east-1` |
| `ECR_REGISTRY` | `YOUR_SANDBOX_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com` |
| `AWS_DEPLOY_ROLE_ARN` | `arn:aws:iam::YOUR_SANDBOX_ACCOUNT:role/github-actions-APP_NAME-deploy` |

---

## Ongoing Operations

| Action | Command |
|---|---|
| Update secrets | `aws secretsmanager update-secret --secret-id APP_NAME/env --secret-string file://.env` |
| View logs | CloudWatch → `/ecs/APP_NAME` |
| Scale up | `aws ecs update-service --cluster APP_NAME --service APP_NAME --desired-count 2` |
