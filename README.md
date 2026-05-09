<div align="center">

# SkillConnect

### Professional Services Marketplace & Business Platform

**Build your professional business online — book trusted local service professionals with confidence.**

[![CI/CD Pipeline](https://github.com/Govin111b8/SKILL/actions/workflows/ci.yml/badge.svg)](https://github.com/Govin111b8/SKILL/actions)
![Node.js](https://img.shields.io/badge/Node.js-22.x-339933?logo=node.js)
![Express](https://img.shields.io/badge/Express-5.2.1-000000?logo=express)
![React](https://img.shields.io/badge/React-19.2.5-61DAFB?logo=react)
![Vite](https://img.shields.io/badge/Vite-8.0.10-646CFF?logo=vite)
![Flutter](https://img.shields.io/badge/Flutter-3.8-02569B?logo=flutter)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql)
![Redis](https://img.shields.io/badge/Redis-7-DC382D?logo=redis)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)
![License](https://img.shields.io/badge/License-ISC-blue)

</div>

---

## Codebase at a Glance

| Component | Count | Details |
|-----------|-------|---------|
| **Backend Routes** | 38 | Express 5 route files |
| **Backend Controllers** | 37 | Business logic handlers |
| **Backend Middleware** | 8 | Auth, cache, fraud, logging, etc. |
| **Backend Services** | 9 | AI, email, SMS, storage, payments, etc. |
| **Backend Test Suites** | 16 | ~150 tests (Jest + Supertest) |
| **Frontend Pages** | 54 | React 19 page components |
| **Frontend Components** | 23 | Shared UI components |
| **Mobile Screens** | 47 | Flutter screen files |
| **Mobile Services** | 19 | API, auth, offline, analytics, etc. |
| **Mobile Widgets** | 10 | Reusable UI widgets |
| **Database Tables** | 82 | PostgreSQL 16 schema |
| **DB Migrations** | 17 | Incremental schema changes |
| **Cron Jobs** | 6 | Scheduled background workers |
| **Docker Services** | 7 | Full-stack Docker Compose |
| **i18n Languages** | 3 | English, Hindi, Telugu |

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Booking State Machine](#booking-state-machine)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Backend API Reference](#backend-api-reference)
- [Frontend Pages](#frontend-pages)
- [Frontend Components](#frontend-components)
- [Mobile App](#mobile-app)
- [Database Schema](#database-schema)
- [Middleware Pipeline](#middleware-pipeline)
- [Services](#services)
- [Cron Jobs](#cron-jobs)
- [Testing](#testing)
- [Deployment](#deployment)
- [Monitoring & Observability](#monitoring--observability)
- [Security & Compliance](#security--compliance)
- [Internationalization](#internationalization)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

### Problem Statement

Finding and booking reliable local service professionals is fragmented, trust-deficient, and inefficient. Customers rely on word-of-mouth with no quality guarantees, while skilled professionals lack tools to build their online presence, manage bookings, and grow their business.

### Solution

SkillConnect is a full-stack professional services marketplace that connects customers with verified local service professionals. The platform provides:

- **For Customers** — Discovery, booking, real-time chat, reviews, and trust verification for local service professionals
- **For Professionals** — A customizable storefront, portfolio management, booking pipeline, earnings tracking, and business growth tools
- **For Agents** — A referral and onboarding system with commission tracking, wallet management, and leaderboards
- **For Admins** — KYC verification, dispute resolution, analytics, content moderation, and platform management

---

## Key Features

### Customer Features
- **Smart Search & Discovery** — Location-based search, category browsing, trending/new/responsive professional discovery
- **Reels & Stories** — Short-form video feed and 24-hour ephemeral professional stories
- **Professional Storefronts** — Themed profiles with portfolios, service packages, before/after galleries, and trust badges
- **Conversational Booking** — Step-by-step booking wizard (What → When → Where → Confirm)
- **Real-time Chat** — WebSocket-powered messaging with professionals
- **Reviews & Ratings** — Star ratings with text reviews and review replies
- **Collections** — Save professionals and services into named collections (Pinterest-style)
- **Follow System** — Follow professionals, get activity feeds
- **Community Feed** — Professional tips, guides, and category-tagged content
- **Emergency Services** — Urgent service requests with real-time dispatch
- **Referral Program** — Referral codes with reward tracking
- **Warranties** — Service warranty claims and tracking

### Professional Features
- **Customizable Storefront** — 8 themes, brand colors, custom layouts, reorderable sections
- **Portfolio & Media** — Photo/video galleries, reels, before/after sliders, story highlights
- **Service Packages** — Tiered pricing (Basic / Standard / Premium) with features lists
- **Business Dashboard** — Earnings, bookings, analytics, and performance metrics
- **Trust Badges** — Auto-calculated badges (Rising Pro, Fast Responder, Customer Favorite, Top Rated, Elite Professional)
- **Schedule Management** — Working hours, time slots, blocked dates
- **Earnings & Payouts** — Revenue tracking with payout management
- **Growth Tools** — Promo codes, featured slots, SEO optimization

### Admin Features
- **KYC Verification** — Document verification with face matching
- **Dispute Resolution** — Customer-professional dispute management with appeals
- **Content Moderation** — User management, category requests, featured slot management
- **Analytics Dashboard** — Platform-wide metrics and performance data
- **Notification Management** — Push notifications, email, and SMS

### Agent Features
- **Agent Onboarding** — Register professionals and earn commissions
- **Wallet & Commissions** — Track earnings, wallet transactions, reward tiers
- **Leaderboard** — Agent performance rankings

---

## System Architecture

```
+---------------------------------------------------------------------+
|                         Client Layer                                |
|  +--------------+  +------------------+  +-----------------------+  |
|  | React 19 SPA |  | Flutter Mobile   |  | Admin Dashboard       |  |
|  | Vite 8       |  | iOS / Android    |  | (React)               |  |
|  | 54 pages     |  | 47 screens       |  |                       |  |
|  +------+-------+  +--------+---------+  +-----------+-----------+  |
+---------+------------------+-------------------------+--------------+
          |                  |                         |
          v                  v                         v
+---------------------------------------------------------------------+
|                      nginx Reverse Proxy                            |
|                   SSL/TLS + HSTS + Rate Limiting                    |
+-----------------------------+---------------------------------------+
                              |
                              v
+---------------------------------------------------------------------+
|                      Backend (Node.js + Express 5)                  |
|  +------------+  +------------+  +-------------+  +------------+   |
|  | 38 Routes  |  | 37 Ctrlers |  | 8 Middleware |  | 9 Services |   |
|  +------------+  +------------+  +-------------+  +------------+   |
|  +------------+  +------------+  +-------------+                    |
|  | WebSocket  |  | Cron Jobs  |  | Feature     |                    |
|  | Hub (ws)   |  | (6 jobs)   |  | Flags       |                    |
|  +------------+  +------------+  +-------------+                    |
+----------+------------------------------+---------------------------+
           |                              |
     +-----+-----+                  +-----+-----+
     v           v                  v           v
+---------+ +---------+      +---------+ +----------+
| Postgres| |  Redis  |      |   S3    | | SendGrid |
|   16    | |    7    |      | Storage | | SMS/Push |
+---------+ +---------+      +---------+ +----------+
     |
     v
+----------+
| PgBouncer|
|  1.22.1  |
+----------+

+---------------------------------------------------------------------+
|                     Monitoring Layer                                 |
|  +------------------+  +------------------+  +------------------+   |
|  | Prometheus v2.51 |  | Grafana 10.4     |  | Sentry           |   |
|  | Metrics + Alerts |  | Dashboards       |  | Error Tracking   |   |
|  +------------------+  +------------------+  +------------------+   |
+---------------------------------------------------------------------+
```

---

## Booking State Machine

Bookings follow a finite state machine with humanized status labels:

```
                    +------------------+
                    |    requested     |  "Request Sent"
                    |  (Customer asks) |
                    +--------+---------+
                             |
                    +--------v---------+
                    |     quoted       |  "Quote Received"
                    | (Pro sends price)|
                    +--------+---------+
                             |
                    +--------v---------+
                    |    accepted      |  "Professional Confirmed"
                    |(Customer accepts)|
                    +--------+---------+
                             |
                    +--------v---------+
                    |   in_progress    |  "Work Started"
                    |  (Pro starts)    |
                    +--------+---------+
                             |
                    +--------v---------+
                    |    completed     |  "Job Completed"
                    |   (Pro marks)    |
                    +------------------+

      Any state ---------> cancelled  "Cancelled"
```

Valid transitions:
- `requested` → `quoted` | `cancelled`
- `quoted` → `accepted` | `cancelled`
- `accepted` → `in_progress` | `cancelled`
- `in_progress` → `completed` | `cancelled`

---

## Tech Stack

### Backend

| Technology | Version | Purpose |
|-----------|---------|---------|
| Node.js | 22.x | Runtime |
| Express | 5.2.1 | Web framework |
| PostgreSQL | 16 | Primary database |
| Redis | 7 | Caching, rate limiting, pub/sub |
| `pg` | 8.20.0 | PostgreSQL client |
| `ioredis` | 5.10.1 | Redis client |
| `ws` | 8.20.0 | WebSocket server |
| `jsonwebtoken` | 9.0.3 | JWT authentication |
| `bcryptjs` | 3.0.3 | Password hashing |
| `pino` | 10.3.1 | Structured logging |
| `prom-client` | 15.1.3 | Prometheus metrics |
| `@sentry/node` | 10.51.0 | Error tracking |
| `helmet` | 8.1.0 | Security headers |
| `express-rate-limit` | 8.4.1 | Rate limiting |
| `express-validator` | 7.3.2 | Input validation |
| `multer` | 2.1.1 | File uploads |
| `node-cron` | 4.2.1 | Scheduled jobs |
| `pdfkit` | 0.18.0 | PDF generation (invoices) |
| `cors` | 2.8.6 | CORS middleware |
| `compression` | 1.8.1 | Response compression |
| `morgan` | 1.10.1 | HTTP request logging |
| `uuid` | 14.0.0 | UUID generation |
| `dotenv` | 17.4.2 | Environment variables |

**Dev Dependencies:** Jest 30.3.0, Supertest 7.2.2, ESLint 10.2.1, Nodemon 3.1.14

### Frontend

| Technology | Version | Purpose |
|-----------|---------|---------|
| React | 19.2.5 | UI library |
| Vite | 8.0.10 | Build tool + dev server |
| React Router DOM | 7.14.2 | Client-side routing |
| React Helmet Async | 3.0.0 | SEO meta tags |
| React Icons | 5.6.0 | Icon library |

**Dev Dependencies:** Vitest 4.1.5, Testing Library (React 16.3.2, Jest-DOM 6.9.1, User Event 14.6.1), jsdom 29.1.0

### Mobile

| Technology | Version | Purpose |
|-----------|---------|---------|
| Flutter | 3.8 | Cross-platform framework |
| Dart | 3.x | Programming language |
| Provider | — | State management |
| Hive | — | Local storage / offline cache |
| Geolocator | — | Location services |
| WebSocket Channel | — | Real-time messaging |
| Speech to Text | — | Voice search |
| Connectivity Plus | — | Network monitoring |

### Infrastructure

| Technology | Version | Purpose |
|-----------|---------|---------|
| Docker Compose | — | Local orchestration (7 services) |
| Kubernetes | — | Production orchestration |
| nginx | — | Reverse proxy + static files |
| PgBouncer | 1.22.1 | Connection pooling |
| Prometheus | 2.51.2 | Metrics collection |
| Grafana | 10.4.2 | Metrics visualization |
| Sentry | — | Error tracking |
| k6 | — | Load testing |

---

## Project Structure

```
SKILL/
├── README.md                          # This file
├── ARCHITECTURE.md                    # System architecture documentation
├── INCIDENT_RESPONSE.md               # Incident response procedures
├── PLATFORM_CHANGE_RECORD.md          # Platform change log
├── RUNBOOKS.md                        # Operational runbooks
├── SECRETS.md                         # Secrets management guide
├── THREAT_MODEL.md                    # Security threat model
├── claude.md                          # AI assistant implementation guide
├── ready.md                           # Readiness checklist
├── docker-compose.yml                 # 7-service Docker Compose
├── build.sh                           # 7-step build pipeline
├── .gitignore
│
├── backend/
│   ├── package.json
│   ├── .env.example
│   └── src/
│       ├── server.js                  # Entry point (HTTP + WebSocket)
│       ├── app.js                     # Express app setup + route registration
│       ├── routes/                    # 38 route files
│       ├── controllers/               # 37 controller files
│       ├── middleware/                 # 8 middleware files
│       ├── services/                  # 9 service integrations
│       ├── config/                    # 6 config files
│       │   ├── database.js            # PostgreSQL pool
│       │   ├── index.js               # Config aggregator
│       │   ├── logger.js              # Pino logger
│       │   ├── metrics.js             # Prometheus metrics
│       │   ├── redis.js               # Redis client
│       │   └── sentry.js              # Sentry init
│       ├── realtime/
│       │   └── hub.js                 # WebSocket server (ws library)
│       └── workers/
│           └── cron.js                # 6 scheduled cron jobs
│
├── frontend/
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   ├── public/
│   └── src/
│       ├── App.jsx                    # Router + 47+ routes
│       ├── main.jsx                   # Entry point
│       ├── index.css                  # Global styles
│       ├── pages/                     # 54 page components
│       │   └── admin/                 # 6 admin pages
│       ├── components/                # 23 shared components
│       ├── context/                   # AuthContext, WebSocketContext
│       └── api/
│           └── client.js              # API client
│
├── mobile/skillconnect/
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart                  # App entry point
│       ├── screens/                   # 47 screen files (15 directories)
│       ├── services/                  # 19 service files
│       ├── widgets/                   # 10 widget files
│       ├── l10n/                      # i18n (EN, HI, TE)
│       └── models/                    # Data models
│
├── database/
│   ├── schema.sql                     # Base schema
│   ├── seed.sql                       # Demo/seed data
│   └── migrations/                    # 17 migration files (001–015)
│
├── k8s/
│   ├── base/                          # Core K8s manifests
│   │   ├── backend-deployment.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── statefulsets.yaml          # PostgreSQL + Redis
│   │   ├── hpa.yaml                   # Horizontal Pod Autoscaler
│   │   ├── ingress.yaml               # Ingress rules
│   │   ├── configmap.yaml
│   │   ├── secret-template.yaml
│   │   ├── namespace.yaml
│   │   ├── backup-cronjob.yaml
│   │   └── kustomization.yaml
│   └── monitoring/
│       ├── prometheus.yaml
│       └── grafana.yaml
│
├── monitoring/
│   ├── prometheus.yml                 # Prometheus config
│   ├── alerts.yml                     # Alert rules
│   └── grafana/provisioning/
│       ├── dashboards/provider.yaml
│       └── datasources/prometheus.yaml
│
├── nginx/
│   └── skillconnect.conf              # nginx configuration
│
├── tests/load/
│   ├── api.load.js                    # k6 API load tests
│   └── websocket.load.js             # k6 WebSocket load tests
│
├── plans/                             # 30 planning documents
│   ├── 00_MASTER_ANALYSIS.md
│   ├── PRD_SEC01.md – PRD_SEC20.md    # Product requirement docs
│   └── TECH_A.md – TECH_J.md         # Technical supplements
│
└── .github/workflows/
    └── ci.yml                         # CI/CD pipeline
```

---

## Quick Start

### Prerequisites

- **Docker** & **Docker Compose** (recommended)
- OR: Node.js 22+, PostgreSQL 16, Redis 7

### Option 1: Docker Compose (Recommended)

```bash
# Clone the repository
git clone https://github.com/Govin111b8/SKILL.git
cd SKILL

# Start all 7 services
docker compose up --build

# Services will be available at:
# Frontend:    http://localhost:3000
# Backend API: http://localhost:5000
# Grafana:     http://localhost:3001
# Prometheus:  http://localhost:9090
```

### Option 2: Manual Setup

```bash
# 1. Database
# Start PostgreSQL 16 and Redis 7, then:
psql -U postgres -f database/schema.sql
psql -U postgres -f database/seed.sql
# Run migrations in order:
for f in database/migrations/*.sql; do psql -U postgres -f "$f"; done

# 2. Backend
cd backend
cp .env.example .env    # Configure environment variables
npm install
npm run dev             # Starts on port 5000

# 3. Frontend
cd frontend
npm install
npm run dev             # Starts on port 5173 (Vite dev server)

# 4. Mobile (optional)
cd mobile/skillconnect
flutter pub get
flutter run
```

### Environment Variables

The backend requires a `.env` file. See `backend/.env.example` for all variables. Key settings:

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |
| `JWT_SECRET` | Secret for JWT signing |
| `PORT` | Backend server port (default: 5000) |
| `SENDGRID_API_KEY` | Email service API key |
| `RAZORPAY_KEY_ID` | Payment gateway key |
| `S3_BUCKET` | Cloud storage bucket |
| `SENTRY_DSN` | Sentry error tracking DSN |
| `FCM_SERVER_KEY` | Firebase push notification key |

### Build Pipeline

The `build.sh` script runs a 7-step pipeline:

1. Run database migrations
2. Restart backend
3. Run Jest test suites
4. Smoke-test API endpoints
5. Flutter analyze
6. Build Flutter web
7. Build Flutter APK

---

## Backend API Reference

All routes are registered in `backend/src/app.js`. Feature-flagged routes are gated by the `featureFlags` middleware.

### Core Routes

| Route Prefix | File | Description |
|-------------|------|-------------|
| `/api/auth` | `auth.js` | Registration, login, JWT tokens, password reset |
| `/api/professionals` | `professionals.js` | Professional profiles, verification status |
| `/api/categories` | `categories.js` | Service categories CRUD |
| `/api/search` | `search.js` | Location-based search with filters |
| `/api/portfolio` | `portfolio.js` | Professional portfolio items |
| `/api/reviews` | `reviews.js` | Ratings, reviews, review replies |
| `/api/contacts` | `contacts.js` | Contact/inquiry management |
| `/api/complaints` | `complaints.js` | Customer complaints |
| `/api/dashboard` | `dashboard.js` | Dashboard data aggregation |
| `/api/users` | `users.js` | User profile management |
| `/api/kyc` | `kyc.js` | KYC document upload + verification |

### Feature-Flagged Routes

| Route Prefix | Feature Flag | File | Description |
|-------------|-------------|------|-------------|
| `/api/bookings` | `BOOKINGS` | `bookings.js` | Booking lifecycle (FSM transitions) |
| `/api/messages` | `CHAT` | `messages.js` | Real-time messaging threads |
| `/api/disputes` | `DISPUTES` | `disputes.js` | Dispute filing + resolution |
| `/api/warranties` | `WARRANTIES` | `warranties.js` | Service warranty claims |
| `/api/emergency` | `EMERGENCIES` | `emergency.js` | Emergency service dispatch |
| `/api/agents` | `AGENTS` | `agents.js` | Agent system + commissions |

### Platform Routes

| Route Prefix | File | Description |
|-------------|------|-------------|
| `/api/notifications` | `notifications.js` | Push, email, SMS notifications |
| `/api/upload` | `uploads.js` | File upload (multer) |
| `/api/favorites` | `favorites.js` | Favorite/bookmark professionals |
| `/api/analytics` | `analytics.js` | Event tracking + analytics |
| `/api/payments` | `payments.js` | Payment processing (Razorpay) |
| `/api/schedule` | `schedule.js` | Professional scheduling + time slots |
| `/api/referrals` | `referrals.js` | Referral codes + rewards |
| `/api/admin` | `admin.js` | Admin operations |
| `/api/webhooks` | `webhooks.js` | Payment/service webhooks |
| `/api/storefront` | `storefront.js` | Storefront CRUD, themes, media, packages |
| `/api/match` | `matching.js` | Professional matching/recommendations |

### Social & Discovery Routes

| Route Prefix | File | Description |
|-------------|------|-------------|
| `/api/social` | `social.js` | Follow/unfollow, activity feed |
| `/api/stories` | `stories.js` | 24-hour ephemeral stories |
| `/api/trust` | `trust.js` | Trust badges, timeline, explainability |
| `/api/discover` | `discover.js` | Trending, new, responsive professionals |
| `/api/collections` | `collections.js` | Save collections (Pinterest-style) |
| `/api/community` | `community.js` | Community posts, likes |
| `/api/reels` | `reels.js` | Short video feed |

### SEO & Growth Routes

| Route Prefix | File | Description |
|-------------|------|-------------|
| `/sitemap.xml` | `seo.js` | Dynamic sitemap |
| `/robots.txt` | `seo.js` | Robots.txt |
| `/api/seo` | `seo.js` | SEO metadata |
| `/api/growth` | `growth.js` | Growth events, promo codes |
| `/api/ai` | `ai.js` | AI-powered features |

### System Routes

| Route | Description |
|-------|-------------|
| `/api/health` | Health check (DB + Redis connectivity) |
| `/metrics` | Prometheus metrics endpoint |
| `/uploads` | Static file serving |

---

## Frontend Pages

54 page components in `frontend/src/pages/`.

### Public Pages

| Page Component | Route | Description |
|---------------|-------|-------------|
| `Home` | `/` | Landing page with discovery carousels |
| `Login` | `/login` | General login |
| `Register` | `/register` | General registration |
| `CustomerLogin` | `/customer/login` | Customer-specific login |
| `CustomerRegister` | `/customer/register` | Customer registration |
| `ProfessionalLogin` | `/professional/login` | Professional login |
| `ProfessionalRegister` | `/professional/register` | Professional registration |
| `AgentLogin` | `/agent/login` | Agent login |
| `AgentRegister` | `/agent/register` | Agent registration |
| `AdminLogin` | `/admin/login` | Admin login |
| `Categories` | `/categories` | Service category listing |
| `CategoryDetail` | `/categories/:id` | Category detail with professionals |
| `SearchResults` | `/search` | Search results page |
| `Storefront` | `/professionals/:id` | Professional storefront page |
| `CommunityFeed` | `/community` | Community posts and tips |
| `ReelsFeed` | `/reels` | Short video feed |
| `TermsOfService` | `/terms` | Terms of service |
| `PrivacyPolicy` | `/privacy` | Privacy policy |
| `RefundPolicy` | `/refund-policy` | Refund policy |
| `CookiePolicy` | `/cookie-policy` | Cookie policy |
| `ProfessionalTerms` | `/professional-terms` | Professional terms |
| `ContentModerationPolicy` | `/content-moderation` | Content moderation policy |
| `NotFound` | `*` | 404 page |

### Protected Pages (Authenticated)

| Page Component | Route | Description |
|---------------|-------|-------------|
| `Dashboard` | `/dashboard` | User dashboard |
| `Bookings` | `/bookings` | Booking list |
| `BookingDetail` | `/bookings/:id` | Booking detail with status timeline |
| `CreateBooking` | `/book/:professionalId` | Multi-step booking wizard |
| `Messages` | `/messages` | Message threads |
| `Chat` | `/chat/:threadId` | Real-time chat |
| `Settings` | `/settings` | User settings |
| `Favorites` | `/favorites` | Favorited professionals |
| `Collections` | `/collections` | Saved collections |
| `Notifications` | `/notifications` | Notification center |
| `Payment` | `/payment/:bookingId` | Payment flow |
| `Earnings` | `/earnings` | Professional earnings |
| `Schedule` | `/schedule` | Schedule management |
| `ProfessionalProfile` | `/professional/profile` | Professional profile editing |
| `StorefrontSetup` | `/storefront/setup` | Storefront theme + content editor |
| `Referrals` | `/referrals` | Referral code + tracking |
| `Disputes` | `/disputes` | Dispute management |
| `Warranties` | `/warranties` | Warranty tracking |
| `Emergency` | `/emergency` | Emergency service requests |
| `Analytics` | `/analytics` | Analytics dashboard |

### Admin Pages (`/admin/*`)

| Page Component | Route | Description |
|---------------|-------|-------------|
| `AdminDashboard` | `/admin/dashboard` | Admin overview |
| `AdminUsers` | `/admin/users` | User management |
| `AdminKYC` | `/admin/kyc` | KYC verification queue |
| `AdminDisputes` | `/admin/disputes` | Dispute resolution |
| `AdminAppeals` | `/admin/appeals` | Appeal management |
| `AdminCategoryRequests` | `/admin/categories` | Category requests |
| `AdminFeaturedSlots` | `/admin/featured` | Featured slot management |

### Agent Pages (`/agent/*`)

| Page Component | Route | Description |
|---------------|-------|-------------|
| `AgentDashboard` | `/agent/dashboard` | Agent overview |
| `AgentOnboard` | `/agent/onboard` | Onboard new professionals |
| `AgentWallet` | `/agent/wallet` | Wallet + commissions |
| `AgentLeaderboard` | `/agent/leaderboard` | Agent rankings |

---

## Frontend Components

23 shared components in `frontend/src/components/`:

| Component | Description |
|-----------|-------------|
| `AnnouncementBar` | Top banner for announcements |
| `AppInstallBanner` | Mobile app install prompt |
| `BottomNav` | Mobile bottom navigation bar |
| `CategoryCard` | Category display card |
| `CookieConsent` | Cookie consent banner |
| `ErrorBoundary` | React error boundary wrapper |
| `Footer` | Site footer |
| `InviteEarn` | Referral invitation CTA |
| `LoadingSpinner` | Loading indicator |
| `Navbar` | Top navigation bar |
| `OnlineIndicator` | Online/offline status dot |
| `ProfessionalCard` | Professional listing card |
| `ProtectedRoute` | Auth-gated route wrapper |
| `ReviewCard` | Review display card |
| `SEOMeta` | SEO meta tag manager |
| `SaveToCollectionModal` | Save-to-collection modal dialog |
| `SearchBar` | Search input with autocomplete |
| `ShareButton` | Social sharing button |
| `Skeleton` | Skeleton loading placeholder |
| `StarRating` | Star rating display/input |
| `Toast` | Toast notification |
| `TrustSection` | Trust signals display section |
| `TrustTimeline` | Visual trust milestone timeline |

**Context Providers:**
- `AuthContext.jsx` — Authentication state, JWT management, user roles
- `WebSocketContext.jsx` — WebSocket connection management for real-time features

---

## Mobile App

### Screens (47 files across 15 directories)

| Directory | Screens | Description |
|-----------|---------|-------------|
| `auth/` | `LoginScreen`, `RegisterScreen`, `RoleSelectionScreen` | Authentication flow |
| `bookings/` | `BookingDetailScreen`, `BookingsScreen`, `CreateBookingScreen`, `TrackBookingScreen`, `BookingConfirmationScreen` | Booking lifecycle |
| `contacts/` | `ContactsScreen` | Contact management |
| `disputes/` | `DisputeScreen` | Dispute filing |
| `earnings/` | `EarningsScreen` | Professional earnings |
| `emergency/` | `EmergencyScreen` | Emergency requests |
| `favorites/` | `FavoritesScreen` | Saved favorites |
| `home/` | `HomeScreen`, `AdminHomeScreen`, `AgentHomeScreen`, `ProfessionalHomeScreen` + 4 section widgets | Role-based home screens |
| `kyc/` | `KYCScreen` | KYC document submission |
| `messages/` | `ChatScreen`, `MessagesScreen` | Real-time messaging |
| `notifications/` | `NotificationsScreen`, `NotificationSettingsScreen` | Notification management |
| `payments/` | `PaymentScreen` | Payment processing |
| `portfolio/` | `PortfolioScreen` | Portfolio management |
| `profile/` | `ProfileScreen`, `EditProfileScreen` | Profile viewing/editing |
| `report/` | `ReportScreen` | Report issues |
| `reviews/` | `ReviewsScreen` | Review management |
| `schedule/` | `ScheduleScreen` | Schedule management |
| `search/` | `SearchScreen`, `SearchResultsScreen` | Search + results |
| `settings/` | `SettingsScreen` | App settings |
| `splash/` | `SplashScreen` | App launch screen |
| `storefront/` | `StorefrontScreen`, `StorefrontSetupScreen` + 8 widgets | Professional storefront |
| `tracking/` | `TrackingScreen` | Service tracking |
| `warranty/` | `WarrantyScreen` | Warranty claims |

### Services (19 files)

| Service | Description |
|---------|-------------|
| `api_service` | Core HTTP API client |
| `api_config` | API endpoint configuration |
| `auth_service` | Authentication + JWT management |
| `booking_service` | Booking operations |
| `analytics_service` | Event tracking |
| `mobile_client` | Mobile-specific HTTP client |
| `web_client` | Web-specific HTTP client |
| `network_simulator` | Network condition simulator (dev) |
| `performance_monitor` | Performance metrics tracking |
| `push_notification_service` | FCM push notifications |
| `realtime_service` | WebSocket real-time connection |
| `smart_location_service` | GPS + geocoding |
| `storefront_service` | Storefront API operations |
| `theme_service` | App theming |
| `upload_service` | File/image upload |
| `connectivity_service` | Network connectivity monitoring (offline) |
| `local_cache_service` | Hive local data caching (offline) |
| `offline_queue_service` | Offline action queue + sync (offline) |
| `offline_services` | Offline service coordinator (offline) |

### Widgets (10 files)

| Widget | Description |
|--------|-------------|
| `availability_toggle` | Professional availability switch |
| `book_now_sheet` | Bottom sheet booking CTA |
| `connectivity_banner` | Offline/online status banner |
| `nearby_providers_section` | Nearby professionals list |
| `professional_card` | Professional listing card |
| `review_prompt` | Review request prompt |
| `skeleton_loader` | Skeleton loading animation |
| `trust_badge` | Trust badge display |
| `voice_note_widget` | Voice message recording |
| `voice_search_button` | Voice-powered search |

### User Roles

The mobile app supports 4 user roles with role-specific home screens:
- **Customer** — Default home with search, categories, bookings
- **Professional** — Dashboard with earnings, bookings, storefront management
- **Agent** — Onboarding tools, commissions, leaderboard
- **Admin** — Platform management, KYC queue, disputes

---

## Database Schema

**82 tables** across PostgreSQL 16, organized by domain.

### Users & Identity

| Table | Description |
|-------|-------------|
| `users` | Core user accounts (all roles) |
| `professionals` | Professional profile extensions |
| `professional_categories` | Professional-to-category mappings |
| `professional_languages` | Professional language capabilities |
| `verifications` | KYC verification records |
| `verification_audit` | KYC audit trail |
| `email_verifications` | Email verification tokens |
| `password_resets` | Password reset tokens |
| `refresh_token_blacklist` | Revoked JWT refresh tokens |
| `blocked_users` | User blocking records |
| `banned_phones` | Banned phone numbers |
| `banned_govt_ids` | Banned government IDs |
| `consent_records` | User consent tracking |

### Bookings & Services

| Table | Description |
|-------|-------------|
| `bookings` | Service bookings (FSM states) |
| `booking_status_log` | Booking state transition history |
| `service_packages` | Tiered pricing packages |
| `service_areas` | Professional service areas |
| `certifications` | Professional certifications |
| `service_warranties` | Warranty records |
| `time_slots` | Available booking time slots |
| `worker_schedule` | Professional working hours |
| `worker_blocked_dates` | Professional unavailable dates |
| `professional_hours` | Operating hours |

### Communication

| Table | Description |
|-------|-------------|
| `message_threads` | Chat thread metadata |
| `messages` | Individual messages |
| `notifications` | User notifications |
| `device_tokens` | Push notification device tokens |
| `push_subscriptions` | Web push subscriptions |
| `contacts` | Contact/inquiry records |
| `complaints` | Customer complaints |

### Financial

| Table | Description |
|-------|-------------|
| `payments` | Payment records |
| `payouts` | Professional payout records |
| `payout_log` | Payout audit trail |
| `invoices` | Service invoices |
| `gst_invoices` | GST-compliant invoices (India) |
| `subscriptions` | Professional subscriptions |
| `loyalty_points` | Customer loyalty points |

### Reviews & Trust

| Table | Description |
|-------|-------------|
| `reviews` | Customer reviews + ratings |
| `review_replies` | Professional replies to reviews |
| `professional_badges` | Earned trust badges |
| `disputes` | Customer-professional disputes |
| `appeals` | Dispute appeals |

### Social & Engagement

| Table | Description |
|-------|-------------|
| `follows` | Follow relationships |
| `favorites` | Favorited professionals |
| `collections` | Named save collections |
| `collection_items` | Items within collections |
| `stories` | 24-hour ephemeral stories |
| `community_posts` | Professional tips/articles |
| `community_post_likes` | Post likes |
| `user_interactions` | User action tracking |
| `user_points` | Gamification points |

### Storefront

| Table | Description |
|-------|-------------|
| `storefront_media` | Reels, before/after, highlights, gallery |
| `storefront_themes` | Theme, colors, layout, section order |
| `portfolio_items` | Professional portfolio entries |

### Search & Analytics

| Table | Description |
|-------|-------------|
| `search_history` | User search history |
| `analytics_events` | Analytics event pipeline |
| `analytics_sessions` | User session tracking |
| `performance_metrics` | System performance data |
| `categories` | Service categories |

### Agent System

| Table | Description |
|-------|-------------|
| `agents` | Agent profiles |
| `agent_rewards` | Agent reward records |
| `agent_wallet_transactions` | Wallet transaction log |
| `agent_onboarded_users` | Professional onboarding records |
| `reward_config` | Reward tier configuration |
| `zones` | Geographic zones for agents |

### Growth & Marketing

| Table | Description |
|-------|-------------|
| `referral_codes` | Referral code records |
| `referrals` | Referral tracking |
| `promo_codes` | Promotional codes |
| `promo_usage` | Promo code usage tracking |
| `growth_events` | Growth event tracking |
| `newsletter_subscribers` | Newsletter signups |
| `waitlist` | Waitlist registrations |
| `featured_slots` | Featured professional slots |
| `category_requests` | New category requests |

### System & Audit

| Table | Description |
|-------|-------------|
| `admin_audit_log` | Admin action audit trail |
| `audit_log` | General audit trail |
| `otp_log` | OTP verification log |
| `soft_deletes_log` | Soft deletion records |
| `ab_experiments` | A/B experiment configuration |
| `supported_cities` | Supported city list |
| `emergency_requests` | Emergency service requests |
| `safety_alerts` | Safety alert records |

### Migration Files (17)

| File | Description |
|------|-------------|
| `001_kyc.sql` | KYC verification tables |
| `002_bookings_chat.sql` | Bookings + messaging |
| `003_review_by_booking.sql` | Review-booking linkage |
| `004_seed_geo.sql` | Geographic seed data |
| `005_reputation_trigger.sql` | Reputation calculation triggers |
| `006_phase1_features.sql` | Phase 1 feature tables |
| `006_storefront_fields.sql` | Storefront additional fields |
| `007_auth_admin_services.sql` | Auth + admin extensions |
| `007_provider_type.sql` | Provider type differentiation |
| `008_analytics_and_chat_images.sql` | Analytics + chat media |
| `009_agent_system.sql` | Agent tables + rewards |
| `010_growth_acquisition.sql` | Growth + acquisition tracking |
| `011_warranty_enhancements.sql` | Warranty system extensions |
| `012_schema_completion.sql` | Schema gap filling |
| `013_gaps_completion.sql` | Additional schema gaps |
| `014_phase4_storefront_social_trust.sql` | Storefront, social, trust tables |
| `015_collections_points.sql` | Collections + points system |

---

## Middleware Pipeline

8 middleware files in `backend/src/middleware/`:

| Middleware | File | Description |
|-----------|------|-------------|
| **Authentication** | `auth.js` | JWT verification, role-based access (customer, professional, admin, agent) |
| **Cache** | `cache.js` | Redis response caching with configurable TTL |
| **Error Handler** | `errorHandler.js` | Centralized error handling with Sentry integration |
| **Feature Flags** | `featureFlags.js` | Toggle feature availability (BOOKINGS, CHAT, DISPUTES, WARRANTIES, EMERGENCIES, AGENTS) |
| **Fraud Prevention** | `fraudPrevention.js` | Suspicious activity detection and blocking |
| **HTTP Logger** | `httpLogger.js` | Structured request logging via Pino |
| **Request ID** | `requestId.js` | UUID request correlation IDs |
| **Validation** | `validate.js` | Input validation via express-validator |

---

## Services

9 service integrations in `backend/src/services/`:

| Service | File | Description |
|---------|------|-------------|
| **AI** | `ai.js` | AI-powered features (content generation, matching) |
| **Email** | `email.js` | SendGrid transactional emails with templates |
| **Face Match** | `faceMatch.js` | Face verification for KYC |
| **GST Invoice** | `gstInvoice.js` | GST-compliant PDF invoice generation (PDFKit) |
| **Job Queue** | `jobQueue.js` | In-memory job queue with retry logic |
| **Push Notifications** | `pushNotification.js` | Firebase Cloud Messaging (FCM) |
| **Razorpay** | `razorpay.js` | Payment gateway integration |
| **SMS** | `sms.js` | SMS notifications (MSG91/Twilio) |
| **Storage** | `storage.js` | S3/R2 cloud storage with signed URLs |

---

## Cron Jobs

6 scheduled jobs in `backend/src/workers/cron.js`:

| Job | Schedule | Description |
|-----|----------|-------------|
| **Reputation Score Recalculation** | Daily 02:00 IST | Recalculates professional reputation scores |
| **Subscription Expiry Checker** | Daily 09:00 IST | Checks for expired subscriptions |
| **Subscription Grace Enforcer** | Daily 00:05 IST | Enforces subscription grace periods |
| **Inactive Profile Checker** | Weekly (Sun 03:00 IST) | Flags inactive professional profiles |
| **Review Velocity Detector** | Every 5 minutes | Detects suspicious review patterns |
| **Stale Device Token Cleaner** | Weekly (Mon 04:00 IST) | Removes stale FCM device tokens |

---

## Testing

### Backend Tests (16 suites, ~150 tests)

Test files in `backend/tests/` using **Jest 30.3** + **Supertest 7.2**:

| Suite | File | Covers |
|-------|------|--------|
| Agents | `agents.test.js` | Agent registration, onboarding, wallet, leaderboard |
| Analytics | `analytics.test.js` | Event ingestion, aggregation |
| Auth | `auth.test.js` | Registration, login, JWT, password reset |
| Bookings | `bookings.test.js` | Booking CRUD, state transitions |
| Categories | `categories.test.js` | Category listing, details |
| Dashboard | `dashboard.test.js` | Dashboard data aggregation |
| Disputes | `disputes.test.js` | Dispute filing, resolution |
| Emergency | `emergency.test.js` | Emergency request dispatch |
| KYC | `kyc.test.js` | Document upload, verification |
| Messages | `messages.test.js` | Thread creation, messaging |
| Referrals | `referrals.test.js` | Referral codes, rewards |
| Reviews | `reviews.test.js` | Review creation, replies |
| Schedule | `schedule.test.js` | Time slots, availability |
| Search | `search.test.js` | Location search, filters |
| Storefront | `storefront.test.js` | Storefront CRUD, themes, media |
| Warranties | `warranties.test.js` | Warranty creation, claims |

```bash
# Run all backend tests
cd backend && npm test

# Run with coverage
cd backend && npm run test:coverage
```

### Frontend Tests

Using **Vitest 4.1** + **Testing Library**:

```bash
cd frontend && npm test
```

### Load Tests

Using **k6** for load/stress testing:

| Test | File | Description |
|------|------|-------------|
| API Load | `tests/load/api.load.js` | HTTP endpoint load testing |
| WebSocket Load | `tests/load/websocket.load.js` | WebSocket connection stress testing |

```bash
k6 run tests/load/api.load.js
k6 run tests/load/websocket.load.js
```

---

## Deployment

### Docker Compose (7 Services)

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| `postgres` | `postgres:16-alpine` | 5432 | Primary database |
| `redis` | `redis:7-alpine` | 6379 | Cache + rate limiting |
| `backend` | Custom (Node.js) | 5000 | API server |
| `frontend` | Custom (React/nginx) | 3000 | Web application |
| `pgbouncer` | `bitnami/pgbouncer:1.22.1` | 6432 | Connection pooling |
| `prometheus` | `prom/prometheus:v2.51.2` | 9090 | Metrics collection |
| `grafana` | `grafana/grafana:10.4.2` | 3001 | Metrics dashboards |

### Kubernetes

K8s manifests in `k8s/base/` with Kustomize:

- **Deployments** — Backend + Frontend with resource limits
- **StatefulSets** — PostgreSQL + Redis with persistent volumes
- **HPA** — Horizontal Pod Autoscaler for backend
- **Ingress** — nginx ingress with TLS
- **CronJob** — Database backup job
- **ConfigMap** — Application configuration
- **Secrets** — Template for sensitive values

```bash
# Deploy to Kubernetes
kubectl apply -k k8s/base/
```

### CI/CD Pipeline

GitHub Actions workflow in `.github/workflows/ci.yml`:

- Triggered on push to `main` and `develop` branches
- Runs linting, testing, and build steps

---

## Monitoring & Observability

### Prometheus

- **Config:** `monitoring/prometheus.yml`
- **Alert Rules:** `monitoring/alerts.yml`
- **Metrics Endpoint:** `/metrics` on the backend
- **Custom Metrics:** Request duration, active connections, booking counts, error rates via `prom-client`

### Grafana

- **Provisioned Dashboards:** `monitoring/grafana/provisioning/dashboards/`
- **Data Source:** Prometheus auto-configured via `monitoring/grafana/provisioning/datasources/prometheus.yaml`

### Sentry

- **Integration:** `@sentry/node` in backend via `backend/src/config/sentry.js`
- **Error Tracking:** Automatic exception capture with request context

### Logging

- **Library:** Pino (structured JSON logging)
- **HTTP Logging:** Morgan + custom `httpLogger` middleware
- **Request Correlation:** UUID request IDs via `requestId` middleware

---

## Security & Compliance

### Authentication & Authorization
- JWT-based authentication with access + refresh tokens
- Role-based access control (customer, professional, admin, agent)
- Refresh token blacklisting
- OTP verification logging

### Security Headers
- **Helmet** — CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- **CORS** — Configurable origin whitelist
- **Rate Limiting** — Per-endpoint rate limits via `express-rate-limit`

### Data Protection
- Password hashing with bcryptjs
- Input validation on all endpoints via express-validator
- Fraud prevention middleware
- Banned phone/government ID tracking
- Consent record management
- Soft delete audit logging

### Infrastructure Security
- SSL/TLS termination at nginx
- PgBouncer connection pooling (prevents connection exhaustion)
- Redis-backed rate limiting
- Security headers (HSTS, CSP)

### Compliance Documentation
- `THREAT_MODEL.md` — Security threat analysis
- `SECRETS.md` — Secrets management procedures
- `INCIDENT_RESPONSE.md` — Incident response playbook

---

## Internationalization

The mobile app supports 3 languages via Flutter's `l10n` system:

| Language | Code | File |
|----------|------|------|
| English | `en` | `mobile/skillconnect/lib/l10n/app_en.arb` |
| Hindi | `hi` | `mobile/skillconnect/lib/l10n/app_hi.arb` |
| Telugu | `te` | `mobile/skillconnect/lib/l10n/app_te.arb` |

---

## Documentation

| File | Description |
|------|-------------|
| `README.md` | This file — comprehensive project documentation |
| `ARCHITECTURE.md` | System architecture, design decisions, component interactions |
| `INCIDENT_RESPONSE.md` | Incident classification, response procedures, escalation paths |
| `PLATFORM_CHANGE_RECORD.md` | Log of platform changes and deployments |
| `RUNBOOKS.md` | Operational runbooks for common tasks and incidents |
| `SECRETS.md` | Secrets management — rotation, storage, access policies |
| `THREAT_MODEL.md` | Security threat model — attack surfaces, mitigations |
| `claude.md` | AI assistant guide for implementation sessions |
| `ready.md` | Platform readiness checklist |
| `plans/` | 30 planning documents (PRD sections + technical supplements) |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Run tests (`cd backend && npm test && cd ../frontend && npm test`)
5. Run linting (`cd backend && npm run lint`)
6. Commit your changes (`git commit -m 'Add your feature'`)
7. Push to the branch (`git push origin feature/your-feature`)
8. Open a Pull Request

### Development Commands

```bash
# Backend
cd backend
npm install          # Install dependencies
npm run dev          # Start dev server (nodemon)
npm test             # Run Jest tests
npm run test:coverage # Tests with coverage
npm run lint         # ESLint
npm run lint:fix     # ESLint auto-fix

# Frontend
cd frontend
npm install          # Install dependencies
npm run dev          # Start Vite dev server
npm run build        # Production build
npm run preview      # Preview production build
npm test             # Run Vitest

# Mobile
cd mobile/skillconnect
flutter pub get      # Install dependencies
flutter run          # Run on device/emulator
flutter analyze      # Static analysis
flutter test         # Run tests

# Full Stack
docker compose up --build  # Start everything
```

---

## License

ISC
