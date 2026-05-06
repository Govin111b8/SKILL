# SkillConnect — Implementation Plan (claude.md)

> **Purpose:** Guide for next Copilot/Claude sessions to continue implementation  
> **Last Updated:** 2026-05-04  
> **Context:** Platform is CLIENT DEMO READY. Auth & Payments are handled separately.

---

## Current State

- **Frontend:** 30+ pages, React 19, Vite, responsive, WebSocket chat
- **Backend:** 75+ endpoints, Express 5, 11 test suites, fraud middleware
- **Mobile:** Flutter 3.8, 22+ screens, offline-first, i18n (EN/HI/TE)
- **Database:** PostgreSQL 16, 8 tables, seed data, migrations
- **DevOps:** Docker Compose (local), Dockerfiles, build.sh

---

## Phase 1: Core Feature Completion (Priority: HIGH)

### 1.1 Warranties Module — Complete the Flow
- [x] Verify `warrantyController.js` has full CRUD + claim workflow
- [x] Add warranty status transitions (active → claimed → resolved → expired)
- [x] Professional warranty view (`GET /warranties/professional`)
- [x] Professional resolve endpoint (`POST /warranties/:id/resolve`)
- [x] Connect frontend `Warranties.jsx` to real API with role-based view
- [x] Add backend test: `warranties.test.js`

### 1.2 Referrals Module — Wire Reward Logic
- [x] Referral code generation in backend (`POST /referrals/generate`)
- [x] Track referral signups and completions (`POST /referrals/apply`)
- [x] Reward crediting via `completeReferral()` called on booking completion
- [x] Connect frontend `Referrals.jsx` to live API
- [x] Add test coverage: `referrals.test.js`

### 1.3 Emergency Module — Real Dispatch
- [x] Emergency types (urgent service request + SOS worker safety)
- [x] Push notification to nearby professionals (DB + WebSocket broadcast)
- [x] WebSocket real-time broadcast for emergency alerts
- [x] Connect frontend `Emergency.jsx` to real flow
- [x] Add resolve endpoint (`POST /emergency/:id/resolve`)
- [x] Add test coverage: `emergency.test.js`

### 1.4 Analytics Module — Event Pipeline
- [x] Analytics events schema (`analytics_events`, `analytics_sessions` tables)
- [x] Event ingestion endpoint (`POST /analytics/events`)
- [x] Aggregation queries for professional dashboard (`GET /analytics`)
- [x] Connect frontend `Analytics.jsx` to real data
- [x] Add test coverage: `analytics.test.js`

### 1.5 Agent System — Full Commission Logic
- [x] Agent roles and commission tiers (`reward_config` table)
- [x] Agent-professional linking via `agent_onboarded_users`
- [x] Wallet balance tracking (`agent_wallet_transactions`)
- [x] Leaderboard ranking algorithm
- [x] Fix `validate` middleware bug in agent routes
- [x] Add "Become Agent" registration flow in frontend
- [x] Connect all 4 agent frontend pages to live API
- [x] Add test coverage: `agents.test.js`

---

## Phase 2: Infrastructure Hardening (Priority: HIGH for Production)

### 2.1 Cloud Storage
- [x] Integrate AWS S3 / Cloudflare R2 — `backend/src/services/storage.js`
- [x] Update `uploadController.js` to use cloud SDK (memory → pipe to S3/local)
- [x] Signed URL generation for private files
- [x] Local Multer storage replaced by configurable provider

### 2.2 Redis Integration
- [x] Redis in docker-compose (redis:7-alpine)
- [x] Cache middleware uses Redis (ioredis) with in-memory fallback
- [x] Rate-limiting store (express-rate-limit)
- [x] Redis pub/sub pattern ready (single-instance; upgrade to Redis Cluster for multi-instance)

### 2.3 Email & SMS Services
- [x] SendGrid integration — `backend/src/services/email.js`
- [x] MSG91 / Twilio SMS — `backend/src/services/sms.js`
- [x] Email templates: welcome, booking confirmation, OTP, subscription expiry
- [x] SMS templates: OTP, booking alerts

### 2.4 Push Notifications
- [x] FCM (Firebase Cloud Messaging) — `backend/src/services/pushNotification.js`
- [x] Device token register/deregister endpoints
- [x] Stale token auto-deactivation (weekly cron)
- [x] Notification triggers for key events

### 2.5 Job Queue
- [x] In-memory job queue with retry logic — `backend/src/services/jobQueue.js`
- [x] 6 background cron jobs — `backend/src/workers/cron.js`
- [x] Queued: email, SMS, push, analytics, search index, image processing hooks
- [ ] Upgrade to BullMQ + Redis for multi-instance support (tracked for scale-up)

---

## Phase 3: Production Deployment (Priority: MEDIUM)

### 3.1 SSL/TLS & Domain
- [x] nginx production config with Let's Encrypt — `nginx/skillconnect.conf`
- [x] HTTP → HTTPS redirect
- [x] HSTS header enabled in frontend nginx.conf
- [x] Grafana subdomain config

### 3.2 Container Orchestration
- [x] Kubernetes base manifests — `k8s/base/`
  - [x] Namespace, ConfigMap, Secret template
  - [x] Backend Deployment + PgBouncer sidecar
  - [x] Frontend Deployment
  - [x] PostgreSQL StatefulSet + Redis Deployment
  - [x] Ingress with cert-manager + Let's Encrypt annotations
  - [x] HPA (backend 2–10 replicas, frontend 2–6 replicas)
  - [x] PodDisruptionBudgets
- [ ] Overlays: staging / production (Kustomize)
- [ ] ECS task definitions (alternative to K8s)

### 3.3 CI/CD Pipeline
- [x] 7-stage GitHub Actions pipeline — `.github/workflows/ci.yml`
- [x] Lint → Tests (Redis service) → Frontend build → npm audit (critical) → Docker build+push → Trivy container scan → Staging auto-deploy → Production blue/green with manual approval

### 3.4 Monitoring & Observability
- [x] Prometheus metrics endpoint `/metrics` — `backend/src/config/metrics.js`
- [x] HTTP duration/count histograms, WS gauge, job queue depth, DB query latency
- [x] Prometheus deployment + alert rules — `k8s/monitoring/prometheus.yaml`
- [x] Grafana deployment + pre-built dashboard — `k8s/monitoring/grafana.yaml`
- [x] docker-compose: Prometheus + Grafana services — `monitoring/`
- [x] Sentry error tracking — `backend/src/config/sentry.js`
- [ ] OpenTelemetry distributed tracing
- [ ] PagerDuty / Slack alerting (configure in Prometheus AlertManager)

### 3.5 Database Production Readiness
- [x] PgBouncer connection pooler (sidecar in K8s, service in docker-compose)
- [ ] Automated pg_dump backups (CronJob in K8s)
- [ ] Read replicas (RDS Multi-AZ)

### 3.6 Security Hardening
- [x] Secrets management guide — `SECRETS.md`
- [x] Kubernetes Secret template + External Secrets Operator docs
- [x] npm audit in CI (fail on critical)
- [x] Trivy container image scanning with SARIF upload to GitHub Security tab
- [x] Gitleaks secret scanning in CI
- [x] Security headers (HSTS, CSP, X-Frame-Options, Referrer-Policy)
- [ ] AWS Secrets Manager / Vault integration (implementation guide in SECRETS.md)

---

## Phase 4: AI & Advanced Features (Priority: LOW)

### 4.1 AI Matching
- [ ] Define matching algorithm (skills, location, ratings, availability)
- [ ] Implement scoring system
- [ ] Add A/B testing for match quality
- [ ] Consider ML model for recommendations

### 4.2 Voice Search (Mobile)
- [ ] Integrate speech-to-text (Google/Azure)
- [ ] Support Hindi and Telugu voice input
- [ ] Convert to search queries

### 4.3 GPS Tracking
- [ ] Real-time professional location sharing (during active booking)
- [ ] ETA calculation
- [ ] Geofencing for arrival detection

### 4.4 SEO & Growth
- [ ] Server-side rendering or pre-rendering for public pages
- [ ] Structured data (JSON-LD) for services
- [ ] Sitemap generation
- [ ] Social meta tags

---

## Quick Reference — Commands

```bash
# Full local setup
docker compose up --build

# Frontend only (dev)
cd frontend && npm install && npm run dev

# Backend only (dev)
cd backend && npm install && npm run dev

# Run tests
cd frontend && npm test        # vitest
cd backend && npm test         # jest

# Lint
cd backend && npm run lint

# Build frontend
cd frontend && npm run build
```

---

## File Structure (Key Paths)

```
SKILL/
├── frontend/src/
│   ├── pages/          # 30+ page components
│   ├── components/     # Shared UI components
│   ├── context/        # AuthContext, WebSocketContext
│   └── api/client.js   # API client
├── backend/src/
│   ├── routes/         # 31 route files
│   ├── controllers/    # 29 controllers
│   ├── middleware/     # 7 middleware files
│   ├── services/       # External integrations
│   ├── realtime/hub.js # WebSocket server
│   └── config/         # DB, logger config
├── mobile/skillconnect/lib/
│   ├── screens/        # 22+ screen directories
│   ├── services/       # API, auth, booking, etc.
│   └── l10n/           # Internationalization
├── database/
│   ├── schema.sql      # Full schema
│   ├── seed.sql        # Demo data
│   └── migrations/     # DB migrations
└── docker-compose.yml  # One-command setup
```

---

## Session Notes for Next Agent

1. **Auth & Payments are separate tracks** — don't touch unless specifically asked
2. **11 backend test files exist** — always run `npm test` after changes
3. **Frontend uses Vite** — fast HMR, build with `npm run build`
4. **Mobile is Flutter** — analyze with `flutter analyze`, test with `flutter test`
5. **Docker Compose works** — use it for integration testing
6. **Express 5** — note: Express 5 uses promise-based error handling
7. **PostgreSQL 16** — uses `gen_random_uuid()`, no separate uuid extension needed
8. **WebSocket via `ws` library** — not Socket.IO; simpler but no auto-reconnect

---

*Start with Phase 1 items for next demo improvements, Phase 2 for production push.*
