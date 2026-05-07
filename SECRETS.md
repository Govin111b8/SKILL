# SkillConnect — Secrets Management Guide

This document describes how secrets are managed across environments. **Never commit real values to source control.**

---

## Required Secrets

| Secret | Description | How to generate |
|--------|-------------|-----------------|
| `JWT_SECRET` | JWT signing key (≥ 32 chars) | `node -e "console.log(require('crypto').randomBytes(48).toString('base64'))"` |
| `JWT_REFRESH_SECRET` | Refresh token signing key | same as above |
| `ENCRYPTION_KEY` | AES-256 key for PII (64 hex chars) | `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"` |
| `DB_PASSWORD` | PostgreSQL password | Use a password manager |
| `REDIS_PASSWORD` | Redis AUTH password | `openssl rand -base64 32` |
| `RAZORPAY_KEY_ID` | Razorpay API key ID | Razorpay dashboard |
| `RAZORPAY_KEY_SECRET` | Razorpay API secret | Razorpay dashboard |
| `RAZORPAY_WEBHOOK_SECRET` | Webhook HMAC secret | Razorpay dashboard |
| `SENDGRID_API_KEY` | Email service key | SendGrid dashboard |
| `MSG91_AUTH_KEY` | SMS OTP service key | MSG91 dashboard |
| `AWS_ACCESS_KEY_ID` | S3 / Rekognition access key | AWS IAM |
| `AWS_SECRET_ACCESS_KEY` | S3 / Rekognition secret | AWS IAM |
| `S3_BUCKET` | Upload bucket name | AWS S3 |
| `FCM_SERVER_KEY` | Firebase push notification key | Firebase console |
| `HYPERVERGE_APP_ID` | KYC face match app ID | HyperVerge dashboard |
| `HYPERVERGE_APP_KEY` | KYC face match API key | HyperVerge dashboard |
| `SENTRY_DSN` | Error tracking DSN | Sentry project settings |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin UI | `openssl rand -base64 16` |

---

## Local Development (`.env` file)

Copy `.env.example` to `.env` and fill in values. The `.env` file is gitignored.

```bash
cp backend/.env.example backend/.env
```

Never set `ENCRYPTION_KEY` to all-zeros in production (the test/CI value `000...000` is for automated testing only).

---

## Kubernetes (Production)

Secrets are stored in Kubernetes Secrets, populated via one of:

### Option A: kubectl (manual, for initial bootstrap)
```bash
kubectl create secret generic skillconnect-secrets \
  --from-env-file=.env.production \
  -n skillconnect
```

### Option B: External Secrets Operator + AWS Secrets Manager (recommended)

1. Install ESO:
   ```bash
   helm repo add external-secrets https://charts.external-secrets.io
   helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace
   ```

2. Store secrets in AWS Secrets Manager:
   ```bash
   aws secretsmanager create-secret \
     --name skillconnect/production \
     --secret-string file://.env.production
   ```

3. Apply the ExternalSecret CRD (see `k8s/base/external-secret.yaml`).

### Option C: HashiCorp Vault

Use the Vault Agent Injector to mount secrets as environment variables into pods. See [Vault docs](https://developer.hashicorp.com/vault/docs/platform/k8s/injector).

---

## CI/CD (GitHub Actions)

Store secrets in **GitHub → Repository Settings → Secrets and variables → Actions**:

| GitHub Secret Name | Used for |
|--------------------|----------|
| `PROD_DB_HOST` | Production DB hostname |
| `PROD_DB_PASSWORD` | Production DB password |
| `PROD_DB_USER` | Production DB user |
| `PROD_DB_NAME` | Production DB name |
| `PROD_JWT_SECRET` | Production JWT secret |
| `PROD_ENCRYPTION_KEY` | Production encryption key |
| `PROD_SENTRY_DSN` | Production Sentry DSN |
| `STAGING_DEPLOY_COMMAND` | SSH command / ECS deploy command for staging |

---

## Security Practices

1. **Rotation**: Rotate all secrets every 90 days or immediately after a suspected breach.
2. **Least privilege**: IAM roles should have minimal permissions (S3 bucket-scoped, not `s3:*`).
3. **Audit logging**: Enable CloudTrail / GCP Audit Logs for all secret access.
4. **No logs**: Ensure `ENCRYPTION_KEY`, `JWT_SECRET`, and DB passwords are never logged (they are not in the current codebase, but verify after any logger changes).
5. **Dependency scanning**: `npm audit` runs in CI and fails on `--audit-level=critical`.
