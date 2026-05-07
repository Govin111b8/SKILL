# Tech Supplement §B — Complete System Architecture
## Implementation Plan (Pin-to-Pin)

> **Reference:** SkillConnect_Technical_Supplement_v1.0.docx §B  
> **Current Score:** 4 / 10  
> **Target Score:** 7 / 10 (full microservices deferred to Phase 3)  
> **Sprint:** Sprint 5

---

## Architecture Diagram (Specified vs Actual)

### Specified (Tech Supplement §B.1)
```
Client Layer → Cloudflare CDN/WAF → API Gateway (Kong + AWS API Gateway)
→ Microservices (Auth, Search, Profile, Review, Notification, Payment, Moderation, Media, Analytics, Identity, Admin)
→ Kafka Message Bus
→ PostgreSQL + Redis + Elasticsearch + S3 + SQS + CloudWatch
```

### Actual (Current Build)
```
Client (React SPA + Flutter) → nginx → Express.js monolith
→ PostgreSQL + Redis + In-Memory Job Queue + Local/S3 Storage
→ Prometheus + Grafana monitoring
```

---

## Architecture Gaps

### Gap 1 — No API Gateway
**Specified:** Kong + AWS API Gateway for rate limiting, auth, routing  
**Actual:** Express middleware handles all concerns  
**Impact:** Cannot independently scale services; no plugin ecosystem; no API analytics  
**Phase 1 Fix:** Accept Express middleware for Phase 1. Document API Gateway as Phase 2 upgrade.  
**Phase 2 Fix:**
- Deploy Kong in Docker Compose (development)
- Add Kong in K8s as ingress controller
- Migrate rate limiting and auth validation to Kong plugins

### Gap 2 — Monolith vs Microservices
**Specified:** 11 separate services  
**Actual:** Single Express app with modular controllers  
**Phase 1 Fix:** Accept monolith. Ensure modules are isolated (no circular dependencies between controller files).  
**Phase 3 Fix (when to decompose):**
- Extract Search Service when search queries exceed 100K/day
- Extract Notification Service when notification volume exceeds 10K/min
- Extract Identity Verification when KYC queue exceeds 1K/day

### Gap 3 — Kafka Event Bus Missing
**See:** TECH_C_Microservices.md  
**Impact:** Events (CONTACT_MADE, REVIEW_SUBMITTED, etc.) processed synchronously in request cycle, adding latency.  
**Phase 2 Fix:** BullMQ + Redis replaces Kafka for Phase 2 scale.

### Gap 4 — No Cloudflare CDN/WAF
**Specified:** Cloudflare for L3/L4 DDoS and WAF  
**Actual:** nginx only  
**Fix:** Put domain behind Cloudflare (free tier for CDN; Pro for WAF). Update DNS to point to Cloudflare. Enable:
- DDoS protection (automatic)
- WAF rules for common attacks
- Cache profile photos and portfolio images at edge
- "Under Attack Mode" for DDoS scenarios

### Gap 5 — No Read Replica Routing
**Specified:** GET requests → read replica; writes → primary  
**Actual:** All queries to single primary  
**Fix:**
1. Add `DB_READ_HOST` env var pointing to RDS read replica
2. In `backend/src/config/database.js`: create separate read pool
3. Route all `SELECT` queries in search/profile controllers to read pool

### Gap 6 — Service Decomposition Data Flow (PRD §B.3)
**10-step data flow for customer finding a professional:**  
Steps 7–9 require Kafka (emit events to analytics, notification). Currently done synchronously.  
**Fix (BullMQ replacement):**
- Step 7: After contact logged → emit job to `contact_events` queue
- Step 8: Notification worker consumes → sends FCM push to professional  
- Step 9: Analytics worker consumes → records event in analytics_events table

---

## Implementation Tasks (Sprint 5)

### Phase 1 Fixes (Now)
- [ ] **T1** Add `DB_READ_HOST` read replica routing in `database.js`
- [ ] **T2** Point domain to Cloudflare; enable CDN for static assets
- [ ] **T3** Enable Cloudflare WAF (Pro plan or self-managed rules)
- [ ] **T4** Verify all controller files have no circular imports
- [ ] **T5** Document service decomposition trigger points in `ARCHITECTURE.md`

### Phase 2 Fixes (BullMQ)
- [ ] **T6** Replace in-memory job queue with BullMQ + Redis (see TECH_C)
- [ ] **T7** Emit contact events to `contact_events` BullMQ queue
- [ ] **T8** Notification worker: consume contact events → FCM push
- [ ] **T9** Analytics worker: consume events → analytics_events table

### Documentation
- [ ] **T10** Create `ARCHITECTURE.md`: current architecture diagram + Phase 2/3 evolution plan
- [ ] **T11** Document Kong API Gateway migration plan in ARCHITECTURE.md

---

## Acceptance Criteria
- [ ] Domain served through Cloudflare CDN; portfolio images cached at edge
- [ ] Read replica configured; search queries use read connection pool
- [ ] Contact events processed via BullMQ queue (async, not in request cycle)
- [ ] ARCHITECTURE.md documents current + target architecture with migration paths
- [ ] No circular dependencies between backend controller modules
