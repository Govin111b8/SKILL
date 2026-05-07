# Tech Supplement §I — Observability & Incident Response
## Implementation Plan (Pin-to-Pin)

> **Reference:** SkillConnect_Technical_Supplement_v1.0.docx §I  
> **Current Score:** 6 / 10  
> **Target Score:** 9 / 10  
> **Sprint:** Sprint 4

---

## Three Pillars of Observability Status (§I.1)

### Metrics
| Requirement | Status |
|---|---|
| Prometheus-format metrics from all services | ✅ `/metrics` endpoint in backend |
| Business metrics: DAU, MAU, contact conversions, subscription revenue | ⚠️ Technical metrics ✅; business KPIs not in Prometheus |
| Technical metrics: API latency (P50/P95/P99), error rate, DB pool usage | ✅ HTTP histograms implemented |
| Cache hit rate (Redis) | ⚠️ May not be tracked |
| Kafka consumer lag | ❌ No Kafka (BullMQ queue depth tracked instead) |
| Grafana dashboard | ✅ Pre-built dashboard in k8s/monitoring |

### Logs
| Requirement | Status |
|---|---|
| Structured JSON logging | ✅ Pino logger |
| Log levels: ERROR/WARN/INFO/DEBUG | ✅ |
| PII masking (phone, email, name → [MASKED]) | ❌ Not confirmed in current Pino config |
| Log retention: ERROR/WARN 1 year; INFO 90 days | ❌ Not configured (depends on cloud setup) |
| traceId propagated across requests | ⚠️ requestId middleware exists; not traceId |
| Shipped to CloudWatch Logs + S3 archive | ❌ Local logs only |

### Traces
| Requirement | Status |
|---|---|
| AWS X-Ray distributed tracing | ❌ Not implemented |
| traceId on every request | ⚠️ requestId exists; not X-Ray trace |
| Trace sampling: 100% errors, 10% success, 1% search | ❌ Not configured |
| Slow trace alerting > 2s → Slack | ❌ Not configured |

---

## Alerting & On-Call (§I.2)

| Alert | Condition | Severity | Status |
|---|---|---|---|
| API 5xx rate > 1% for 2 min | P1 Critical | Prometheus alert rule | ⚠️ Alert rules in k8s/monitoring/prometheus.yaml ✅; PagerDuty ❌ |
| Database connections > 90% for 5 min | P1 Critical | Alert rule | ⚠️ Alert may exist; PagerDuty ❌ |
| Payment service down | P1 Critical | Alert rule | ❌ Not configured |
| Identity verification SLA > 24h (>50 pending) | P2 High | Alert rule | ❌ Not configured |
| Complaint SLA breach (open > 48h) | P2 High | Alert rule | ❌ Not configured |
| Search latency spike P95 > 1s | P2 High | Alert rule | ❌ Not configured |
| Cache miss spike > 30% | P3 Medium | Alert rule | ❌ Not configured |
| BullMQ queue depth > 10K | P3 Medium | Alert rule | ❌ Not configured |
| Security alert (failed login burst) | P1 Critical | Alert rule | ❌ Not configured |

---

## Runbooks Status (§I.3)

| Runbook | Status |
|---|---|
| Search returns no results | ❌ Not documented |
| Payment gateway failure | ❌ Not documented |
| Verification queue backlog | ❌ Not documented |
| Spike in fake registrations | ❌ Not documented |

---

## Gap Analysis

### Gap 1 — PII Masking in Pino Logger
**File:** `backend/src/config/logger.js`  
**Fix:** Add Pino `redact` configuration:
```javascript
const logger = pino({
  redact: {
    paths: ['phone', 'email', 'name', 'full_name', 'govt_id_encrypted'],
    censor: '[MASKED]'
  }
});
```

### Gap 2 — Business KPIs Not in Prometheus
**File:** `backend/src/config/metrics.js`  
**Fix:** Add custom Prometheus gauges:
- `skillconnect_dau_total` — daily active users (updated every 15 min)
- `skillconnect_verification_queue_depth` — pending KYC count
- `skillconnect_open_complaints_total` — open complaint count
- `skillconnect_subscription_revenue_today_inr` — today's subscription revenue

### Gap 3 — Missing Alert Rules
**File:** `k8s/monitoring/prometheus.yaml`  
**Fix:** Add alert rules for:
- KYC queue depth > 50 for > 1 hour → P2 alert
- Complaint open > 48 hours → P2 alert
- BullMQ queue depth metric > 1000 (when BullMQ added) → P3 alert
- Search P95 > 1s (5 min) → P2 alert

### Gap 4 — No PagerDuty Integration
**Fix:**
1. Create PagerDuty account; create service for SkillConnect
2. Add `pagerduty_routing_key` to secrets
3. Configure Alertmanager in Prometheus to route P1 alerts to PagerDuty, P2/P3 to Slack
4. `k8s/monitoring/alertmanager.yaml` — create this file

### Gap 5 — No Slack Alerting
**Fix:** Create `k8s/monitoring/alertmanager.yaml`:
```yaml
route:
  group_wait: 30s
  receiver: slack-alerts
receivers:
  - name: slack-alerts
    slack_configs:
      - api_url: $SLACK_WEBHOOK_URL
        channel: '#alerts'
        text: '{{ .CommonAnnotations.summary }}'
```

### Gap 6 — Runbooks Not Created
**Fix:** Create `RUNBOOKS.md` with procedures for all 4 scenarios specified in Tech Supplement §I.3.

### Gap 7 — No Distributed Tracing
**Phase 2 Fix:** Add OpenTelemetry SDK:
```bash
npm install @opentelemetry/sdk-node @opentelemetry/exporter-otlp-http
```
Configure tracing in `backend/src/config/tracing.js`. Export to Jaeger or AWS X-Ray.

---

## Implementation Tasks (Sprint 4)

### Logging
- [ ] **T1** Add PII redaction to Pino logger config
- [ ] **T2** Add `traceId` header middleware (replace requestId with W3C Trace Context format)
- [ ] **T3** Configure log shipping to CloudWatch (when deployed to AWS)

### Metrics
- [ ] **T4** Add business KPI gauges to `/metrics` endpoint
- [ ] **T5** Add BullMQ queue depth metric to Prometheus (when BullMQ added)
- [ ] **T6** Add Redis cache hit/miss rate metrics

### Alerting
- [ ] **T7** Add missing alert rules to `k8s/monitoring/prometheus.yaml`
- [ ] **T8** Create `k8s/monitoring/alertmanager.yaml` with Slack routing
- [ ] **T9** Configure PagerDuty receiver for P1 alerts in alertmanager

### Documentation
- [ ] **T10** Create `RUNBOOKS.md` with 4 incident response procedures

---

## Acceptance Criteria
- [ ] Pino logs contain `[MASKED]` for all phone, email, name fields
- [ ] Prometheus `/metrics` includes KYC queue depth, open complaints, DAU
- [ ] Slack receives alert when API 5xx rate > 1% for 2 minutes (test in staging)
- [ ] PagerDuty receives P1 alert on critical threshold breach
- [ ] RUNBOOKS.md covers all 4 incident scenarios with step-by-step procedures
