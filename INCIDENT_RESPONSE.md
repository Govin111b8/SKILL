# SkillConnect — Incident Response Playbook

> **Classification:** Internal | **Owner:** On-call Engineer
> **Last Updated:** May 2026

## Severity Levels

| Level | Response Time | Example | Owner |
|---|---|---|---|
| SEV-1 | 15 min | Platform down, payments failing, data breach | On-call Lead |
| SEV-2 | 30 min | Search down, KYC queue stuck, high error rate >5% | On-call Engineer |
| SEV-3 | 2 hours | Slow queries, email delivery failure, single feature broken | Assigned Engineer |
| SEV-4 | Next sprint | UI bugs, minor performance regression | Team Queue |

## On-Call Rotation

- **Primary:** Rotate weekly. Notified via PagerDuty.
- **Escalation:** Slack `#incidents` → Engineering Lead → CTO
- **War Room:** Zoom link pinned in `#incidents`

---

## Runbook: Platform Down (SEV-1)

### Symptoms
- Health check endpoint returns non-200
- Grafana `skillconnect_requests_total` drops to 0
- Multiple user reports via Sentry

### Response Steps
1. **Acknowledge** PagerDuty alert → post in `#incidents`: "Investigating platform outage"
2. Check Kubernetes pod health:
   ```bash
   kubectl get pods -n skillconnect
   kubectl logs -n skillconnect deployment/backend --previous --tail=100
   ```
3. Check database connectivity:
   ```bash
   kubectl exec -n skillconnect deployment/backend -- node -e "require('./src/config/database').query('SELECT 1')"
   ```
4. Check Redis:
   ```bash
   kubectl exec -n skillconnect deployment/redis -- redis-cli ping
   ```
5. If pods are crash-looping: **rollback** to last stable image:
   ```bash
   kubectl rollout undo deployment/backend -n skillconnect
   kubectl rollout undo deployment/frontend -n skillconnect
   ```
6. Check Sentry for error spikes: `https://sentry.io/organizations/skillconnect`
7. Once resolved: post RCA draft in `#incidents` within 1 hour

---

## Runbook: Payment Gateway Failure (SEV-1)

### Symptoms
- `POST /api/payments` returning errors
- Sentry alerts for Razorpay webhook failures

### Response Steps
1. Check Razorpay status: https://status.razorpay.com
2. Check webhook logs:
   ```bash
   kubectl logs -n skillconnect deployment/backend | grep "webhook"
   ```
3. If Razorpay is up but webhooks failing — verify `RAZORPAY_WEBHOOK_SECRET` env var
4. Enable payment retry for affected bookings via admin API
5. Notify affected customers via email blast (Support team)

---

## Runbook: Database Overload (SEV-2)

### Symptoms
- Grafana `skillconnect_db_query_duration_seconds` p99 > 5s
- Backend logs show "too many connections" errors

### Response Steps
1. Check PgBouncer pool stats:
   ```bash
   kubectl exec -n skillconnect -c pgbouncer deployment/backend -- psql -h localhost -p 6432 pgbouncer -c "SHOW POOLS;"
   ```
2. Check slow query log in PostgreSQL:
   ```sql
   SELECT query, total_exec_time, calls FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
   ```
3. If connection storm: increase PgBouncer `pool_size` temporarily
4. Identify and kill long-running queries if blocking:
   ```sql
   SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE duration > interval '5 minutes';
   ```
5. If disk full: trigger immediate backup and run `VACUUM ANALYZE`

---

## Runbook: Data Breach Suspected (SEV-1)

1. **Isolate**: Revoke all active sessions via Redis flush (coordinate with team first)
2. **Preserve evidence**: Take snapshot of logs before any changes
3. **Notify DPO within 72 hours** (DPDPA 2023 §7)
4. **Assess scope**: Which tables? PII involved? Volume?
5. **Patch** the vulnerability before bringing system back online
6. **Notify affected users** via email if PII was accessed
7. **File report** with CERT-In if personal data of >500 users affected

---

## Post-Incident RCA Template

```
## Incident: [Title]
- **Date/Time:** 
- **Duration:**
- **Severity:** SEV-X
- **Impact:** X users affected

## Timeline
- HH:MM — Alert received
- HH:MM — Investigation started
- HH:MM — Root cause identified
- HH:MM — Fix deployed
- HH:MM — Resolved

## Root Cause
[What caused the incident]

## Contributing Factors
[What made it worse or harder to detect]

## Resolution
[What fixed it]

## Action Items
- [ ] Owner: Task to prevent recurrence
- [ ] Owner: Task to improve detection
```

---

## Useful Commands Quick Reference

```bash
# View all pods
kubectl get pods -n skillconnect -o wide

# Tail backend logs
kubectl logs -f -n skillconnect deployment/backend

# Force pod restart
kubectl rollout restart deployment/backend -n skillconnect

# Scale backend replicas
kubectl scale deployment/backend --replicas=5 -n skillconnect

# Run DB migration manually
kubectl exec -n skillconnect deployment/backend -- psql $DATABASE_URL -f /app/database/migrations/013_gaps_completion.sql

# Flush Redis cache (emergency only)
kubectl exec -n skillconnect deployment/redis -- redis-cli FLUSHDB

# Trigger manual pg_dump
kubectl create job --from=cronjob/postgres-backup manual-backup-$(date +%s) -n skillconnect
```
