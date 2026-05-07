# SkillConnect Architecture Overview

> **Version:** 2.0 | **Updated:** May 2026

## System Overview

SkillConnect is a hyperlocal services marketplace for the Indian market. The platform connects customers with verified professionals across 50+ service categories.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SkillConnect Platform                              │
│                                                                               │
│  ┌────────────┐   ┌────────────┐   ┌──────────────────────────────────────┐ │
│  │  React Web │   │  Flutter   │   │         Express.js API                │ │
│  │  (Vite 6)  │   │  Mobile    │   │         (Node 20, Express 5)          │ │
│  │  30+ pages │   │  22+ scrns │   │         75+ endpoints                 │ │
│  └────────────┘   └────────────┘   └──────────────────────────────────────┘ │
│         │                │                        │                          │
│         └────────────────┴────────────────────────┘                         │
│                                    │                                          │
│                              REST + WebSocket                                │
│                                    │                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                          Backend Services                                ││
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ ││
│  │  │ Express  │  │   Auth   │  │  Search  │  │ Payment  │  │ WebSocket│ ││
│  │  │ Routes   │  │  JWT+OTP │  │  (SQL)   │  │ Razorpay │  │  Hub(ws) │ ││
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘ ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                    │                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                          Data Layer                                      ││
│  │  ┌──────────────────────┐  ┌───────────┐  ┌────────────────────────┐   ││
│  │  │ PostgreSQL 16        │  │  Redis 7  │  │    AWS S3 / R2        │   ││
│  │  │ (via PgBouncer)      │  │  (cache,  │  │    (uploads, backups)  │   ││
│  │  │ 20+ tables           │  │  sessions)│  │                        │   ││
│  │  └──────────────────────┘  └───────────┘  └────────────────────────┘   ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### Frontend (Web)
- **Framework:** React 19 + Vite 6
- **Routing:** React Router v6
- **State:** Context API (AuthContext, WebSocketContext)
- **SEO:** react-helmet-async with per-page meta tags + JSON-LD
- **PWA:** Service Worker (sw.js), App Install Banner
- **i18n:** Not yet (frontend) — handled in mobile only
- **Key pages:** Home, Search, Profile, Booking, Chat, Admin (8 screens), Agent (4 screens), Legal (6 pages)

### Backend (API)
- **Runtime:** Node.js 20 LTS
- **Framework:** Express 5 (promise-based error handling)
- **Auth:** JWT (15min access) + refresh tokens (7d) + account lockout after 5 failures
- **Database:** PostgreSQL 16 via `pg` (parameterized queries, no ORM)
- **Cache:** Redis 7 (ioredis) with in-memory fallback
- **Real-time:** WebSocket (`ws` library) with per-user channels, heartbeat, presence
- **Job Queue:** In-memory + node-cron (8 background jobs)
- **Storage:** AWS S3 / Cloudflare R2 (configurable via `STORAGE_PROVIDER` env var)
- **Notifications:** FCM (push) + SendGrid (email) + MSG91/Twilio (SMS)
- **Monitoring:** Prometheus metrics (`/metrics`) + Sentry error tracking

### Mobile (Flutter)
- **Framework:** Flutter 3.8
- **State:** Provider
- **i18n:** ARB files (EN/HI/TE) + Flutter Localizations
- **Storage:** Hive + SharedPreferences (offline-first)
- **22+ screens:** onboarding, search, profile, booking, chat, emergency, referrals, etc.

### Database
- **Engine:** PostgreSQL 16
- **Connection pooling:** PgBouncer (sidecar in K8s, service in Docker Compose)
- **Migrations:** 013 sequential SQL files in `database/migrations/`
- **Key tables:** users, professionals, bookings, contacts, reviews, payments, subscriptions, warranties, complaints, appeals, waitlist, featured_slots, category_requests, supported_cities, audit_log
- **Trust Index:** Nightly recalculation via cron — 0-100 score based on 7 weighted factors

## Trust Index Formula (PRD §13.4)

```
Trust Index = 
  avg_rating         (0-5 → 0-30)   × 0.30
  + recent_rating    (0-5 → 0-20)   × 0.20
  + completed_jobs   (log scale)    × 0.15
  + repeat_cust_rate (0-100% → 0-15) × 0.15
  + response_rate    (0-100% → 0-10) × 0.10
  + completeness     (0-100 → 0-5)  × 0.05
  + verification_bonus              + 5
  - per_verified_complaint          × 15
```

## Security Architecture

| Layer | Control |
|---|---|
| Auth | JWT RS256 + refresh token family revocation |
| Account protection | 5-attempt lockout (Redis-backed) |
| API | Rate limiting (express-rate-limit) + idempotency keys |
| Uploads | Multer file type validation + ClamAV (planned) |
| Secrets | AWS Secrets Manager / environment variables |
| CI | Gitleaks + Semgrep SAST + Trivy container scan |
| Logging | PII masking in Pino (phone, email, govt_id masked at all nesting levels) |
| DPDPA 2023 | Data export endpoint, soft delete (30d), consent records, KYC doc retention (12m) |

## Infrastructure

```
docker compose up --build    # Local development (PostgreSQL + Redis + PgBouncer + Prometheus + Grafana)
k8s/base/                    # Kubernetes base manifests (Deployment, HPA, PDB, Ingress, Service)
k8s/base/backup-cronjob.yaml # Automated pg_dump every 6h + Redis backup hourly → S3
k8s/monitoring/              # Prometheus + Grafana with pre-built dashboards
.github/workflows/ci.yml     # 8-stage CI/CD: Lint → Test → Build → Audit → Semgrep → Docker → Trivy → Deploy
```

## Key APIs

| Category | Endpoints |
|---|---|
| Auth | POST /auth/register, /auth/login, /auth/refresh, /auth/logout |
| Search | GET /search, /search/suggestions, /search/history |
| Professionals | GET /professionals, /professionals/:id, /professionals/:id/similar |
| Contacts | POST /contacts, GET /contacts, /contacts/block-customer/:id |
| Reviews | POST /reviews, PUT /reviews/:id (24h edit), POST /reviews/:id/helpful |
| Bookings | Full FSM: pending → accepted → in_progress → completed |
| Payments | POST /payments (Razorpay escrow), GET /invoices/:id |
| Growth | POST /waitlist, GET /categories/trending, GET /users/recently-viewed |
| Compliance | GET /users/export-data, DELETE /users/account |
| Admin | KYC queue, disputes, complaints, featured slots, appeals, category requests |
| Monitoring | GET /metrics (Prometheus), GET /health |

## Development Setup

```bash
# Full stack
docker compose up --build

# Backend only
cd backend && npm install && npm run dev

# Frontend only
cd frontend && npm install && npm run dev

# Run tests
cd backend && npm test      # jest (11 test suites)
cd frontend && npm test     # vitest

# Load tests
k6 run tests/load/api.load.js
```
