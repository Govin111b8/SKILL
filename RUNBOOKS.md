# SkillConnect — Operations Runbooks

> **Audience:** Backend engineers, on-call staff
> **Updated:** May 2026

---

## Runbook Index

1. [Deploy to Production](#1-deploy-to-production)
2. [Database Migrations](#2-database-migrations)
3. [Cache Management (Redis)](#3-cache-management-redis)
4. [Subscription Management](#4-subscription-management)
5. [Trust Index Recalculation](#5-trust-index-recalculation)
6. [Backup & Restore](#6-backup--restore)
7. [Scaling](#7-scaling)
8. [KYC Queue Management](#8-kyc-queue-management)
9. [Featured Slots](#9-featured-slots)

---

## 1. Deploy to Production

### Automated (CI/CD)
Push to `main` triggers the full CI/CD pipeline:
1. Lint → Tests → Build → npm audit → Semgrep → Docker build+push → Trivy scan → Staging deploy → Production (manual approval)

### Manual Rollback
```bash
# Rollback to previous deployment
kubectl rollout undo deployment/backend -n skillconnect
kubectl rollout undo deployment/frontend -n skillconnect

# Check rollout status
kubectl rollout status deployment/backend -n skillconnect

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=3 -n skillconnect
```

---

## 2. Database Migrations

### Apply Next Migration
```bash
# Check current migration state
kubectl exec -n skillconnect deployment/backend -- \
  psql $DATABASE_URL -c "SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 5;"

# Apply new migration
kubectl exec -n skillconnect deployment/backend -- \
  psql $DATABASE_URL -f database/migrations/013_gaps_completion.sql

# Verify
kubectl exec -n skillconnect deployment/backend -- \
  psql $DATABASE_URL -c "\dt" | grep -E "waitlist|featured_slots|appeals"
```

### Rollback Migration
Migrations should include a rollback section or be applied with a transaction. For DDL changes, take a DB snapshot before applying to production.

---

## 3. Cache Management (Redis)

### Flush Stale Cache Patterns
```bash
# Flush all search caches (after bulk professional updates)
kubectl exec -n skillconnect deployment/redis -- \
  redis-cli --scan --pattern "cache:search:*" | xargs redis-cli DEL

# Flush trending category cache
kubectl exec -n skillconnect deployment/redis -- \
  redis-cli DEL "trending_cats:bangalore" "trending_cats:hyderabad"

# Flush profile cache for a specific professional
kubectl exec -n skillconnect deployment/redis -- \
  redis-cli DEL "cache:profile:${PROFESSIONAL_ID}"

# Check cache hit rate
kubectl exec -n skillconnect deployment/redis -- \
  redis-cli INFO stats | grep keyspace
```

### Monitor Redis Memory
```bash
kubectl exec -n skillconnect deployment/redis -- redis-cli INFO memory | grep -E "used_memory_human|maxmemory_human"
```

---

## 4. Subscription Management

### View Expiring Subscriptions
```bash
kubectl exec -n skillconnect deployment/backend -- \
  psql $DATABASE_URL -c "
  SELECT p.id, u.name, u.email, p.subscription_plan, p.subscription_expires_at
  FROM professionals p JOIN users u ON u.id = p.user_id
  WHERE p.subscription_plan != 'basic'
    AND p.subscription_expires_at < NOW() + INTERVAL '7 days'
  ORDER BY p.subscription_expires_at;"
```

### Manual Subscription Extension (Support)
```bash
kubectl exec -n skillconnect deployment/backend -- psql $DATABASE_URL -c "
  UPDATE professionals SET
    subscription_expires_at = subscription_expires_at + INTERVAL '30 days'
  WHERE id = '${PROFESSIONAL_ID}'
  RETURNING id, subscription_plan, subscription_expires_at;"
```

---

## 5. Trust Index Recalculation

The Trust Index is recalculated nightly at 02:00 IST by the `recalcReputationScores` cron job.

### Trigger Manual Recalculation
```bash
# Via admin API
curl -X POST https://api.skillconnect.in/api/admin/trigger-recalc \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"

# Or directly in pod
kubectl exec -n skillconnect deployment/backend -- \
  node -e "require('./src/workers/cron').recalcReputationScores().then(() => process.exit(0))"
```

### Check Trust Index Distribution
```bash
kubectl exec -n skillconnect deployment/backend -- psql $DATABASE_URL -c "
  SELECT 
    CASE WHEN trust_index >= 80 THEN '80-100 (Excellent)'
         WHEN trust_index >= 60 THEN '60-79 (Good)'
         WHEN trust_index >= 40 THEN '40-59 (Fair)'
         ELSE '0-39 (Needs Work)'
    END as range,
    COUNT(*) as professionals
  FROM professionals
  GROUP BY 1 ORDER BY 1;"
```

---

## 6. Backup & Restore

### Manual pg_dump (Emergency)
```bash
kubectl create job --from=cronjob/postgres-backup manual-backup-$(date +%s) -n skillconnect
```

### List Available Backups
```bash
aws s3 ls s3://${S3_BUCKET}/postgres-backups/ --human-readable --summarize
```

### Restore from Backup
```bash
# Download backup
aws s3 cp s3://${S3_BUCKET}/postgres-backups/skillconnect_20260101_020000.dump ./restore.dump

# Restore (WARNING: this overwrites existing data)
pg_restore -d $DATABASE_URL --clean --if-exists ./restore.dump

# Verify
psql $DATABASE_URL -c "SELECT COUNT(*) FROM users;"
```

---

## 7. Scaling

### Scale Backend Replicas
```bash
kubectl scale deployment/backend --replicas=6 -n skillconnect
# HPA handles auto-scaling: 2-10 replicas based on CPU (70% threshold)
```

### Check HPA Status
```bash
kubectl get hpa -n skillconnect
kubectl describe hpa backend-hpa -n skillconnect
```

---

## 8. KYC Queue Management

### View Pending KYC Verifications
```bash
# Via API
curl https://api.skillconnect.in/api/admin/kyc?status=submitted \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq '.data | length'
```

### Bulk Reject Stale KYC (>30 days without review)
```bash
psql $DATABASE_URL -c "
  UPDATE verifications SET status = 'expired'
  WHERE status = 'submitted'
    AND created_at < NOW() - INTERVAL '30 days'
  RETURNING user_id;"
```

---

## 9. Featured Slots

### Add Featured Slot via Admin API
```bash
curl -X PUT https://api.skillconnect.in/api/admin/featured-slots \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "professional_id": "${PROFESSIONAL_ID}",
    "slot_type": "home",
    "city": "Bangalore",
    "start_date": "2026-05-01",
    "end_date": "2026-05-31"
  }'
```

### View Active Featured Slots
```bash
psql $DATABASE_URL -c "
  SELECT fs.*, u.name FROM featured_slots fs
  JOIN professionals p ON p.id = fs.professional_id
  JOIN users u ON u.id = p.user_id
  WHERE fs.status = 'active' AND fs.end_date >= NOW()::date
  ORDER BY fs.end_date;"
```

---

## Environment Variables Reference

Key environment variables required for production:

```
DATABASE_URL                 PostgreSQL connection string
REDIS_URL                    Redis connection string
JWT_SECRET                   JWT signing secret (min 64 chars)
RAZORPAY_KEY_ID              Razorpay public key
RAZORPAY_KEY_SECRET          Razorpay private key
RAZORPAY_WEBHOOK_SECRET      Webhook signature verification
SENDGRID_API_KEY             Email service
MSG91_API_KEY                SMS service (India)
FCM_SERVER_KEY               Firebase push notifications
AWS_ACCESS_KEY_ID            S3 uploads
AWS_SECRET_ACCESS_KEY        S3 uploads
S3_BUCKET                    Upload bucket name
SENTRY_DSN                   Error tracking
```

See `SECRETS.md` for full secret management guide.
