# Tech Supplement §D — Infrastructure & DevOps Blueprint
## Implementation Plan (Pin-to-Pin)

> **Reference:** SkillConnect_Technical_Supplement_v1.0.docx §D  
> **Current Score:** 7 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 4

---

## Infrastructure Status

### What's Built
| Component | Status |
|---|---|
| Docker Compose (local dev) | ✅ Full stack with Postgres, Redis, backend, frontend |
| Multi-stage Dockerfiles (frontend + backend) | ✅ |
| K8s base manifests (namespace, configmap, secret template) | ✅ |
| K8s Backend Deployment + PgBouncer sidecar | ✅ |
| K8s Frontend Deployment | ✅ |
| K8s PostgreSQL StatefulSet + Redis Deployment | ✅ |
| K8s Ingress (cert-manager + Let's Encrypt) | ✅ |
| K8s HPA (backend 2–10, frontend 2–6 replicas) | ✅ |
| K8s PodDisruptionBudgets | ✅ |
| 7-stage GitHub Actions CI/CD | ✅ |
| Prometheus + Grafana monitoring | ✅ |
| nginx production config with HTTPS | ✅ |

### What's Missing
| Component | Status |
|---|---|
| K8s Kustomize overlays (staging/production) | ❌ |
| Automated PostgreSQL backups (pg_dump CronJob) | ❌ |
| RDS Multi-AZ read replica | ❌ |
| Terraform / CDK infrastructure-as-code | ❌ |
| AWS Secrets Manager / Vault integration | ❌ |
| ClamAV sidecar in Docker Compose + K8s | ❌ |
| Load testing scripts (k6 / Artillery) | ❌ |
| Staging environment pipeline step | ⚠️ In CI but staging host not configured |
| Blue/green production deploy | ⚠️ Defined in CI; needs target cluster |

---

## Gap Analysis

### Gap 1 — Kustomize Overlays Missing
**Files:** `k8s/`  
**Fix:** Create `k8s/overlays/staging/` and `k8s/overlays/production/`:
- Staging: 1 replica, DEBUG logs, lower resource limits, test DB
- Production: HPA enabled, WARN+ logs, production secrets, multi-AZ DB

### Gap 2 — Automated Database Backups
**Fix:**
1. Create `k8s/base/db-backup-cronjob.yaml`: K8s CronJob running `pg_dump` every 6h
2. Upload dump to S3 bucket `skillconnect-db-backups` with 90-day lifecycle policy
3. Test restore in staging monthly (document procedure in `RUNBOOKS.md`)

### Gap 3 — Secrets Management
**File:** `SECRETS.md` — guide exists but no implementation  
**Fix:**
1. Install External Secrets Operator in K8s cluster
2. Create `ExternalSecret` manifests pointing to AWS Secrets Manager
3. Migrate all secrets from K8s Secret manifests to AWS Secrets Manager
4. Reference `SECRETS.md` for per-secret documentation

### Gap 4 — ClamAV Sidecar Not in Compose/K8s
**Fix:**
1. Add ClamAV service to `docker-compose.yml`:
   ```yaml
   clamav:
     image: clamav/clamav:latest
     ports: ["3310:3310"]
   ```
2. Add ClamAV container to backend K8s Deployment as sidecar
3. Backend `uploadController.js` scans files via ClamAV TCP socket before S3 upload

### Gap 5 — Load Testing Scripts Missing
**Fix:**
1. Create `tests/load/` directory
2. Write k6 scripts for:
   - `search.js` — 100 concurrent users searching for "plumber"
   - `profile.js` — 200 concurrent users loading a profile
   - `contact.js` — 50 concurrent users logging contacts
3. Target: P95 < 300ms for search, < 1s for profile
4. Add k6 smoke test (10 VUs, 30 seconds) as CI stage

### Gap 6 — Staging Pipeline Target Not Configured
**File:** `.github/workflows/ci.yml`  
**Fix:** Set `STAGING_HOST`, `STAGING_USER`, `STAGING_SSH_KEY` secrets in GitHub. Configure staging auto-deploy to push Docker image and restart K8s deployments on staging cluster.

---

## Implementation Tasks (Sprint 4)

### Infrastructure
- [ ] **T1** Create `k8s/overlays/staging/` with staging-specific patches
- [ ] **T2** Create `k8s/overlays/production/` with production HPA + resource limits
- [ ] **T3** Create `k8s/base/db-backup-cronjob.yaml` (pg_dump every 6h to S3)
- [ ] **T4** Add ClamAV service to `docker-compose.yml`
- [ ] **T5** Add ClamAV sidecar to backend K8s Deployment

### CI/CD
- [ ] **T6** Configure staging auto-deploy in GitHub Actions (set secrets)
- [ ] **T7** Add k6 smoke test as CI stage (runs on staging after deploy)
- [ ] **T8** Create `tests/load/search.js`, `profile.js`, `contact.js` k6 scripts

### Secrets
- [ ] **T9** Deploy External Secrets Operator to K8s cluster
- [ ] **T10** Create `ExternalSecret` manifests for all application secrets
- [ ] **T11** Migrate secrets from YAML manifests to AWS Secrets Manager

### Documentation
- [ ] **T12** Create `RUNBOOKS.md` with: DB restore procedure, k6 test guide, staging deploy guide

---

## Acceptance Criteria
- [ ] `kubectl apply -k k8s/overlays/staging` deploys staging with correct config
- [ ] `kubectl apply -k k8s/overlays/production` deploys production with full HPA
- [ ] DB backup CronJob runs every 6h; backups visible in S3 within 10 minutes
- [ ] k6 smoke test passes in CI: P95 search < 300ms under 10 concurrent users
- [ ] ClamAV scans files before upload; infected file upload returns 422
- [ ] All secrets loaded from AWS Secrets Manager in staging environment
