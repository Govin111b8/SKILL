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
- [ ] Verify `warrantyController.js` has full CRUD + claim workflow
- [ ] Add warranty status transitions (active → claimed → resolved → expired)
- [ ] Connect frontend `Warranties.jsx` to real API (not mock data)
- [ ] Add backend test: `warranties.test.js`

### 1.2 Referrals Module — Wire Reward Logic
- [ ] Implement referral code generation in backend
- [ ] Track referral signups and completions
- [ ] Implement reward crediting (credits/wallet balance)
- [ ] Connect frontend `Referrals.jsx` to live API
- [ ] Add test coverage

### 1.3 Emergency Module — Real Dispatch
- [ ] Define emergency types (SOS, urgent service needed)
- [ ] Implement push notification to nearby professionals
- [ ] Add WebSocket broadcast for emergency alerts
- [ ] Connect frontend `Emergency.jsx` to real flow
- [ ] Add test coverage

### 1.4 Analytics Module — Event Pipeline
- [ ] Define analytics events schema (views, clicks, bookings, revenue)
- [ ] Implement event ingestion endpoint
- [ ] Build aggregation queries for dashboard
- [ ] Connect frontend `Analytics.jsx` to real data
- [ ] Add test coverage

### 1.5 Agent System — Full Commission Logic
- [ ] Define agent roles and commission tiers
- [ ] Implement agent-professional linking
- [ ] Build wallet balance tracking
- [ ] Implement leaderboard ranking algorithm
- [ ] Connect all 4 agent frontend pages to live API
- [ ] Add test coverage

---

## Phase 2: Infrastructure Hardening (Priority: HIGH for Production)

### 2.1 Cloud Storage
- [ ] Integrate AWS S3 or GCS for file uploads
- [ ] Update `uploadController.js` to use cloud SDK
- [ ] Add signed URL generation for private files
- [ ] Migrate from local Multer storage

### 2.2 Redis Integration
- [ ] Add Redis to docker-compose
- [ ] Replace in-memory cache middleware with Redis
- [ ] Move rate-limiting store to Redis
- [ ] Add Redis for WebSocket pub/sub (multi-instance support)

### 2.3 Email & SMS Services
- [ ] Integrate real email provider (SendGrid/SES)
- [ ] Integrate real SMS provider (Twilio/MSG91)
- [ ] Add email templates (welcome, booking confirmation, OTP)
- [ ] Add SMS templates (OTP, booking alerts)

### 2.4 Push Notifications
- [ ] Configure FCM (Firebase Cloud Messaging) for mobile
- [ ] Configure Web Push for frontend
- [ ] Implement notification triggers for key events
- [ ] Test on real devices

### 2.5 Job Queue
- [ ] Implement BullMQ or similar for async tasks
- [ ] Queue: email sending, SMS, push notifications
- [ ] Queue: analytics event processing
- [ ] Queue: image processing/thumbnails
- [ ] Add worker process to docker-compose

---

## Phase 3: Production Deployment (Priority: MEDIUM)

### 3.1 SSL/TLS & Domain
- [ ] Configure nginx for HTTPS with Let's Encrypt
- [ ] Set up domain DNS
- [ ] Add HSTS headers

### 3.2 Container Orchestration
- [ ] Create Kubernetes manifests OR AWS ECS task definitions
- [ ] Configure auto-scaling
- [ ] Set up health checks and readiness probes
- [ ] Add resource limits

### 3.3 CI/CD Pipeline
- [ ] GitHub Actions: lint → test → build → push image → deploy
- [ ] Add staging environment
- [ ] Add production deployment with approval gates
- [ ] Add database migration automation

### 3.4 Monitoring & Observability
- [ ] Add Prometheus metrics endpoint
- [ ] Set up Grafana dashboards
- [ ] Add distributed tracing (OpenTelemetry)
- [ ] Set up alerting (PagerDuty/Slack)
- [ ] Add error tracking (Sentry)

### 3.5 Database Production Readiness
- [ ] Set up automated backups (pg_dump or WAL archiving)
- [ ] Add connection pooling (PgBouncer)
- [ ] Plan read replicas for scaling
- [ ] Add database monitoring

### 3.6 Security Hardening
- [ ] Secrets management (AWS Secrets Manager / Vault)
- [ ] Environment-specific configs
- [ ] Security headers audit
- [ ] Dependency vulnerability scanning (npm audit, Snyk)
- [ ] Penetration testing

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
