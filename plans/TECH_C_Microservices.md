# Tech Supplement §C — Microservices & Event-Driven Design
## Implementation Plan (Pin-to-Pin)

> **Reference:** SkillConnect_Technical_Supplement_v1.0.docx §C  
> **Current Score:** 2 / 10  
> **Target Score:** 6 / 10 (full Kafka deferred; BullMQ replaces for Phase 2)  
> **Sprint:** Sprint 5

---

## What Tech Supplement §C Specifies

### Event-Driven Architecture (Kafka)
| Event | Publisher | Consumers | Status |
|---|---|---|---|
| CONTACT_MADE | Profile Service | Notification Service, Analytics Service | ❌ Synchronous |
| REVIEW_SUBMITTED | Review Service | Analytics, Notification | ❌ Synchronous |
| KYC_APPROVED | Identity Service | Notification Service | ❌ Synchronous |
| SUBSCRIPTION_PURCHASED | Payment Service | Analytics, Notification | ❌ Synchronous |
| PROFILE_UPDATED | Profile Service | Search Index Sync | ❌ Synchronous |
| COMPLAINT_FILED | Moderation Service | Notification, Admin | ❌ Synchronous |

### Kafka Topics Required
- `interaction_events` — contact, quote request, interaction complete
- `review_events` — review submitted, review flagged, review approved
- `notification_jobs` — FCM push, SMS, email tasks
- `analytics_events` — all user actions for KPI computation
- `search_index_updates` — profile changes that need FTS re-index
- `moderation_queue` — complaints, appeals, auto-flags

### Redis Pub/Sub (Lightweight Real-Time)
| Use Case | Status |
|---|---|
| WebSocket message delivery (multi-instance) | ⚠️ Single-instance hub only |
| Cache invalidation broadcast | ❌ Not implemented |
| Live search_index invalidation | ❌ Not implemented |

---

## Why This Matters

Currently all operations happen **synchronously inside the HTTP request cycle**:
- User POSTs a review → controller inserts review → updates rating (trigger) → returns response
- Email, SMS, push notifications either don't fire or slow down the response

This works at Phase 1 scale but will cause:
- **P95 > 300ms** responses when email/SMS APIs are called inline
- **Data loss** on crash (in-memory queue lost on restart)
- **No fan-out** — same event can't trigger multiple consumers

---

## Gap Analysis

### Gap 1 — In-Memory Job Queue Lost on Restart
**File:** `backend/src/services/jobQueue.js`  
**Fix:** Replace with BullMQ + Redis backend (not Kafka — simpler, sufficient for Phase 2)

### Gap 2 — All Notifications Fired Synchronously
**Files:** All controllers that should fire notifications  
**Fix:** After performing DB operation, enqueue job instead of calling notification service directly:
```javascript
// Instead of:
await pushNotification.send(userId, 'New review received');

// Do:
await jobQueue.add('send-push', { userId, title: 'New review received' });
```

### Gap 3 — WebSocket Hub Not Multi-Instance Safe
**File:** `backend/src/realtime/hub.js`  
**Issue:** WebSocket connections are stored in memory. In a multi-instance K8s deployment, a message sent to instance A cannot reach a client connected to instance B.  
**Fix:**
1. Add Redis pub/sub to WebSocket hub
2. On message: publish to Redis channel `ws:message:${roomId}`
3. All instances subscribe to relevant channels; deliver to local connections
4. Use `ioredis` (already installed) for pub/sub

### Gap 4 — Search Index Not Updated Asynchronously
**File:** `database/migrations/` → search_index trigger  
**Issue:** If the trigger is synchronous on UPDATE, it adds latency to every profile update.  
**Fix:** Queue `update-search-index` job on profile update; worker updates search_index table asynchronously. Target: < 15 seconds from profile change to search index updated.

---

## BullMQ Migration Plan (Phase 2 — Sprint 5)

### Job Types to Migrate
| Job | Queue | Retry | Priority |
|---|---|---|---|
| send-email | email-queue | 3x with backoff | HIGH |
| send-sms | sms-queue | 3x with backoff | HIGH |
| send-push | push-queue | 3x with backoff | HIGH |
| update-analytics | analytics-queue | 1x | NORMAL |
| update-search-index | search-queue | 2x | NORMAL |
| process-image | media-queue | 2x | LOW |
| send-daily-digest | digest-queue | 1x | LOW |

### Implementation Steps
1. `npm install bullmq`
2. Create `backend/src/services/queue.js` — BullMQ queue factory
3. Create `backend/src/workers/email.worker.js`, `sms.worker.js`, `push.worker.js`
4. Replace all inline `email.js`/`sms.js`/`pushNotification.js` calls with `queue.add()`
5. Add Bull Board admin UI: `npm install @bull-board/express`
6. Mount at `/admin/queues` (admin-only)

---

## Implementation Tasks (Sprint 5)

- [ ] **T1** Install BullMQ: `cd backend && npm install bullmq @bull-board/express`
- [ ] **T2** Create `backend/src/services/queue.js` with BullMQ factory
- [ ] **T3** Create email, SMS, push workers in `backend/src/workers/`
- [ ] **T4** Migrate all notification calls to queue.add() across all controllers
- [ ] **T5** Add `QUEUE_BACKEND=redis|memory` env for dev/prod switching
- [ ] **T6** Add Redis pub/sub to WebSocket hub for multi-instance message delivery
- [ ] **T7** Move search index update to async queue job
- [ ] **T8** Add Bull Board admin UI at `/admin/queues`
- [ ] **T9** Add queue depth to Prometheus metrics (workers: `/metrics`)

---

## Acceptance Criteria
- [ ] POST /reviews returns in < 100ms (notification enqueued, not sent inline)
- [ ] Push notification delivered < 5 seconds after review submission
- [ ] BullMQ queue persists across backend restart (jobs not lost)
- [ ] Dead-letter queue captures failed jobs; admin can retry from Bull Board
- [ ] WebSocket messages delivered to clients across multiple backend instances
- [ ] Search index updated within 15 seconds of profile change
