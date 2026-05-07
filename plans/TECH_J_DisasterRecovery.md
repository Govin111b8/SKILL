# Tech Supplement §J — Disaster Recovery & Business Continuity
## Implementation Plan (Pin-to-Pin)

> **Reference:** SkillConnect_Technical_Supplement_v1.0.docx §J  
> **Current Score:** 3 / 10  
> **Target Score:** 8 / 10  
> **Sprint:** Sprint 7

---

## Recovery Objectives (§J.1)

| Objective | Target | Status |
|---|---|---|
| RTO (Recovery Time Objective) | < 30 minutes | ❌ No DR procedure tested |
| RPO (Recovery Point Objective) | < 6 hours | ❌ No automated backups |
| MTTR (Mean Time to Restore) | < 45 minutes | ❌ Not measured |
| Uptime SLA | 99.5% monthly | ❌ Not monitored / no alerts |

---

## Backup Strategy Status (§J.2)

| Asset | Method | Frequency | Retention | Status |
|---|---|---|---|---|
| PostgreSQL DB | RDS snapshots + transaction log shipping | Every 6 hours | 90 days | ❌ No automated backup |
| Redis Cache | RDB snapshots to S3 | Hourly | 7 days | ❌ Not configured |
| S3 Media | Cross-region replication to ap-southeast-1 | Real-time | Indefinite | ❌ Not configured |
| Application Code | GitHub (primary) | Every push | Forever | ✅ |
| Infrastructure Code | Git + Terraform state | Every apply | Forever | ⚠️ No Terraform; K8s in Git |
| Secrets | AWS Secrets Manager cross-region | On change | 90 versions | ❌ Not configured |
| Elasticsearch Index | S3 snapshot repository | Daily | 30 days | ❌ No Elasticsearch |

---

## Disaster Scenarios (§J.3)

| Scenario | Probability | Response Plan | Status |
|---|---|---|---|
| AWS AZ failure | Low | Multi-AZ absorbs automatically | ❌ Not Multi-AZ |
| AWS region outage | Very Low | Activate DR in ap-southeast-1 | ❌ No DR region |
| PostgreSQL primary failure | Low | RDS Multi-AZ failover (60–120s) | ❌ Not Multi-AZ |
| Ransomware / data corruption | Very Low | Restore from last clean snapshot | ❌ No snapshots |
| DDoS attack | Medium | Cloudflare absorbs L3/L4; WAF for L7 | ❌ No Cloudflare |
| Third-party outage (Razorpay, MSG91) | Medium | Graceful degradation per service | ⚠️ Partial |
| Security breach | Very Low | Isolate, revoke JWTs, notify users | ⚠️ JWT revoke possible; no incident plan |

---

## Gap Analysis

### Gap 1 — No Automated Database Backups
**Fix:**
1. Create K8s CronJob: `k8s/base/db-backup-cronjob.yaml`
   - Schedule: `0 */6 * * *` (every 6 hours)
   - Command: `pg_dump $DATABASE_URL | gzip | aws s3 cp - s3://skillconnect-backups/db/$(date +%Y%m%d-%H%M).sql.gz`
2. S3 lifecycle policy: 90-day retention, then delete
3. Test restore monthly: document in RUNBOOKS.md

### Gap 2 — No Redis Persistence / Backup
**Files:** `docker-compose.yml`, `k8s/base/redis-deployment.yaml`  
**Fix:**
1. Enable Redis RDB snapshots: `save 3600 1` (every hour if 1+ key changed)
2. Mount volume for Redis data persistence
3. Add `redis-rdb-backup` CronJob: copy RDB file to S3 hourly

### Gap 3 — No S3 Cross-Region Replication
**Fix:**
1. Create S3 replication rule: ap-south-1 (primary) → ap-southeast-1 (Singapore DR)
2. Enable S3 versioning on primary bucket (required for replication)
3. Destination bucket encrypted with separate KMS key

### Gap 4 — No Multi-AZ PostgreSQL
**Fix (for production AWS RDS):**
1. Enable Multi-AZ on RDS instance
2. Set `SYNCHRONOUS_COMMIT=on` for zero data loss on failover
3. Connect via RDS endpoint (DNS auto-flips to standby on failover)

### Gap 5 — No DR Environment
**Fix:**
1. Create minimal K8s cluster in ap-southeast-1 (Singapore)
2. Deploy same K8s manifests (using kustomize overlay `dr`)
3. Connect to S3 replica for media; point to DB read replica in Singapore
4. DNS failover: Route 53 health check on ap-south-1; failover to ap-southeast-1

### Gap 6 — No Incident Response Plan for Security Breach
**Fix:** Create `INCIDENT_RESPONSE.md`:
1. Detect: Cloudwatch alarm / Sentry / PagerDuty alert
2. Contain: Isolate affected pods; revoke all JWTs platform-wide
3. Assess: Enumerate affected data; identify breach vector
4. Notify: Email affected users within 72h (DPDPA requirement); notify CERT-In within 6h
5. Recover: Restore from clean snapshot; apply security patches
6. Document: Post-incident report

### Gap 7 — DR Drill Not Done
**Requirement:** DR drill every 6 months  
**Fix:** Schedule first DR drill. Document drill procedure in RUNBOOKS.md:
1. Trigger simulated region failure by cutting network to ap-south-1
2. Verify ap-southeast-1 standby comes online within 30 minutes
3. Run smoke test on standby environment
4. Measure actual RTO; compare to 30-min target
5. Document results and address gaps

---

## Implementation Tasks (Sprint 7)

### Immediate
- [ ] **T1** Create `k8s/base/db-backup-cronjob.yaml` (pg_dump every 6h to S3)
- [ ] **T2** Enable Redis RDB persistence and S3 upload hourly
- [ ] **T3** Enable RDS Multi-AZ (production AWS setup task)
- [ ] **T4** Enable S3 versioning + cross-region replication to ap-southeast-1
- [ ] **T5** Create `INCIDENT_RESPONSE.md` with full security breach procedure
- [ ] **T6** Create `RUNBOOKS.md` with DR drill procedure

### Phase 2
- [ ] **T7** Set up Route 53 health checks for automatic DNS failover
- [ ] **T8** Deploy DR environment in ap-southeast-1 with kustomize DR overlay
- [ ] **T9** Configure DR environment to use S3 replica + DB read replica
- [ ] **T10** Conduct first DR drill; document results

---

## Acceptance Criteria
- [ ] pg_dump CronJob runs every 6h; backup file appears in S3 within 10 minutes
- [ ] Redis RDB file uploaded to S3 hourly; data survives pod restart
- [ ] S3 media files replicate to ap-southeast-1 bucket within 15 minutes of upload
- [ ] INCIDENT_RESPONSE.md covers all 4 required steps (detect, contain, notify, recover)
- [ ] DR drill conducted; actual RTO ≤ 30 minutes documented in results report
- [ ] RDS Multi-AZ enabled; failover tested (< 2 minutes downtime)
