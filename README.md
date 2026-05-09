<div align="center">

<!-- ═══════════════════════════════════════════════════════════════
     SkillConnect — Production-Grade README
     Last verified: May 2026
     ═══════════════════════════════════════════════════════════════ -->

<img src="https://img.shields.io/badge/🛠️_SkillConnect-India's_Premier_Hyperlocal_Service_Marketplace-blue?style=for-the-badge&labelColor=1a1a2e&color=16213e" alt="SkillConnect" width="800"/>

<br/><br/>

# 🛠️ SkillConnect

### *India's Premier Hyperlocal Service Marketplace Platform*

<br/>

[![Node.js](https://img.shields.io/badge/Node.js-22+-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![React](https://img.shields.io/badge/React-19.2-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.8-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org/)
[![Express](https://img.shields.io/badge/Express-5.2-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com/)
[![Vite](https://img.shields.io/badge/Vite-8.0-646CFF?style=for-the-badge&logo=vite&logoColor=white)](https://vitejs.dev/)
[![WebSocket](https://img.shields.io/badge/WebSocket-Real--time-010101?style=for-the-badge&logo=socketdotio&logoColor=white)](#-real-time--websocket)

<br/>

[![License: ISC](https://img.shields.io/badge/License-ISC-green?style=flat-square)](https://opensource.org/licenses/ISC)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)](http://makeapullrequest.com)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow?style=flat-square)](https://conventionalcommits.org)
[![Code Style: ESLint](https://img.shields.io/badge/Code%20Style-ESLint-4B32C3?style=flat-square&logo=eslint)](https://eslint.org)

<br/>

> **A production-grade, full-stack marketplace connecting customers with KYC-verified skilled professionals — featuring branded storefronts with 8 themes, social follow & stories, reels video feed, trust badges, real-time WebSocket chat, integrated Razorpay payments, multilingual voice search, offline-first mobile, dispute resolution, warranty protection, and enterprise-grade security across 50+ service categories.**

<br/>

[🚀 Quick Start](#-quick-start) •
[📁 Project Structure](#-project-structure) •
[🔌 API Reference](#-api-reference) •
[��️ Architecture](#%EF%B8%8F-system-architecture) •
[🧪 Testing](#-testing) •
[📦 Deployment](#-deployment) •
[🔒 Security](#-security--compliance)

---

### 📈 Codebase at a Glance

| 📦 Component | 📊 Count | 📂 Location |
|:---|:---:|:---|
| Backend Route Files | **38** | `backend/src/routes/` |
| Backend Controllers | **37** | `backend/src/controllers/` |
| Backend Middleware | **8** | `backend/src/middleware/` |
| Backend Services | **9** | `backend/src/services/` |
| Backend Config | **6** | `backend/src/config/` |
| Backend Test Suites | **16** (150 tests) | `backend/tests/` |
| Frontend Pages | **54** | `frontend/src/pages/` |
| Frontend Components | **23** | `frontend/src/components/` |
| Frontend Contexts | **2** | `frontend/src/context/` |
| Mobile Screens | **47** | `mobile/skillconnect/lib/screens/` |
| Mobile Services | **19** | `mobile/skillconnect/lib/services/` |
| Mobile Widgets | **10** | `mobile/skillconnect/lib/widgets/` |
| Database Tables | **82** | `database/schema.sql` + `database/migrations/` |
| Database Migrations | **17** | `database/migrations/` |
| Kubernetes Manifests | **12** | `k8s/` |
| Cron Jobs | **6** | `backend/src/workers/cron.js` |
| Docker Compose Services | **7** | `docker-compose.yml` |
| Plan/Analysis Documents | **30** | `plans/` |
| Load Test Files | **2** | `tests/load/` |

</div>

---

## 📋 Table of Contents

<details>
<summary><strong>��️ Click to expand full navigation</strong></summary>

- [Overview](#-overview)
- [Key Features](#-key-features)
- [System Architecture](#%EF%B8%8F-system-architecture)
- [Booking State Machine](#-booking-state-machine-fsm)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Quick Start](#-quick-start)
- [Backend API Reference](#-api-reference)
- [Frontend Pages & Routes](#-frontend-pages--routes)
- [Frontend Components](#-frontend-components)
- [Mobile App (Flutter)](#-mobile-app-flutter)
- [Database Schema](#-database-schema-82-tables)
- [Middleware Pipeline](#-middleware-pipeline)
- [Backend Services](#-backend-services)
- [Cron Jobs](#-cron-jobs)
- [Real-time & WebSocket](#-real-time--websocket)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Monitoring & Observability](#-monitoring--observability)
- [Security & Compliance](#-security--compliance)
- [Internationalization (i18n)](#-internationalization-i18n)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

</details>

---

## 🌟 Overview

**SkillConnect** is a comprehensive hyperlocal services marketplace designed for the Indian market. It empowers customers to discover, book, track, and pay verified professionals across 50+ service categories while giving professionals tools to manage their business, schedule, earnings, and reputation.

### 🎯 Problem Statement

Finding reliable skilled professionals in India remains fragmented and trust-deficient:
- ❌ No verification of skills or identity
- ❌ Opaque pricing and hidden charges
- ❌ No accountability for service quality
- ❌ Language barriers in tier-2/3 cities
- ❌ Cash-only transactions with no digital trail

### ✅ Solution

A **trust-first, mobile-native platform** with:
- ✅ KYC-verified professionals (Aadhaar + selfie + government ID)
- ✅ Transparent pricing with upfront quotes and tiered service packages
- ✅ Real-time GPS tracking during service delivery
- ✅ Integrated Razorpay payments with warranty protection
- ✅ Multilingual support (English, Hindi, Telugu)
- ✅ Offline-first mobile app for low-connectivity areas
- ✅ Automated fraud prevention and dispute resolution
- ✅ Branded professional storefronts with 8 customizable themes
- ✅ Social engagement — follow, stories, reels, community posts, collections
- ✅ 5-tier trust badge system with timeline and explainability
- ✅ Discovery engine — trending, newly verified, and highly responsive professionals

---

## 🏆 Key Features

### 👥 For Customers

| Feature | Description |
|---------|-------------|
| 🔍 **Smart Search** | Full-text + geo-spatial search with radius, rating, price, availability filters |
| 📍 **Live Tracking** | Real-time GPS tracking of professional en route |
| 💳 **Secure Payments** | Razorpay integration with escrow hold and subscriptions |
| ⭐ **Verified Reviews** | Timing window (1h–60d), velocity detection, edit within 24h, helpful votes |
| 🛡️ **Warranty Protection** | Post-service warranty claims with automated re-booking |
| 🚨 **Emergency Services** | Priority dispatch for urgent requests |
| 🎙️ **Voice Search** | Speech-to-text in Hindi, Telugu, and English |
| ❤️ **Favorites** | Save and quickly rebook trusted professionals |
| 📱 **Offline Mode** | Browse cached data, queue bookings when connectivity returns |
| 🎁 **Referral Rewards** | Earn SkillPoints by referring friends |
| 👤 **Follow Professionals** | Follow favorite pros and get activity feed updates |
| 📌 **Save Collections** | Pinterest-style boards to save professionals and services |
| 🎬 **Reels Feed** | Discover professionals through short video feed |
| 📖 **Community Tips** | Browse expert advice from professionals |
| 🔥 **Trending Discovery** | Discover trending, newly verified, and highly responsive professionals |
| 🛡️ **Trust Explainer** | See why a professional is trusted — verification, response speed, reviews |

### 👷 For Professionals

| Feature | Description |
|---------|-------------|
| 📊 **Business Dashboard** | Earnings analytics, booking pipeline, performance metrics |
| 📅 **Schedule Manager** | Weekly availability slots, blocked dates, auto-conflict detection |
| 🏅 **Trust Badges** | 5-tier system: Rising Pro → Fast Responder → Customer Favorite → Top Rated → Elite Professional |
| 💼 **Portfolio Builder** | Tier-based limits with before/after sliders, video reels, story highlights |
| 💰 **Earnings Tracker** | Daily/weekly/monthly breakdown with payout history + GST invoices |
| 🏪 **Storefront** | Branded landing page with 8 themes, brand colors, custom layouts |
| 📦 **Service Packages** | Tiered pricing cards (Basic / Standard / Premium) with features list |
| 📢 **Stories** | Post 24-hour ephemeral updates (availability, current project, offers) |
| 📊 **Trust Timeline** | Visual milestone journey from join to elite status |
| 📝 **Community Posts** | Share tips and expertise, category-tagged for discovery |
| 👥 **Follower System** | Build audience — follower count displayed as social proof |

### 🔧 For Administrators

| Feature | Description |
|---------|-------------|
| ��️ **Admin Dashboard** | Platform-wide analytics, user management, content moderation |
| ⚖️ **Dispute Resolution** | Review evidence, mediate conflicts, issue refunds |
| 📋 **KYC Management** | Approve/reject professional verification documents |
| 🌟 **Featured Slots** | Control featured placements with date ranges |
| 📁 **Category Requests** | Review & approve user-submitted category suggestions |
| ⚖️ **Appeals** | Manage ban appeals with review notes |
| 🧪 **A/B Experiments** | Track experiments for feature rollouts |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CLIENT APPLICATIONS                              │
├───────────────────┬───────────────────────┬─────────────────────────────────┤
│   📱 Flutter App  │   🌐 React Web App    │   🔧 Admin Portal               │
│   (Android/iOS)   │   (54 pages, Vite 8)  │   (7 admin pages)               │
│   47 screens      │   23 components       │   KYC, disputes, users          │
│   19 services     │   2 context providers  │   Featured slots, appeals      │
│   10 widgets      │   React Router 7.x    │   Category requests             │
│   3 languages     │   react-helmet-async   │   A/B experiments              │
└────────┬──────────┴───────────┬───────────┴──────────────────┬──────────────┘
         │                      │                               │
         │              ┌───────▼───────────────────────────────▼───┐
         │              │          🔀 NGINX Reverse Proxy            │
         │              │    (SSL termination, static serving)       │
         │              └───────────────────┬───────────────────────┘
         │                                  │
         ▼                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      🖥️ BACKEND API SERVER (Express 5.2)                    │
│                      38 route files · 37 controllers · 8 middleware         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   🔐 Auth    │  │  📦 Booking  │  │  💬 Message  │  │  💳 Payment  │   │
│  │   Module     │  │   FSM Engine │  │   Hub (WS)   │  │   Gateway    │   │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤   │
│  │ JWT + Refresh│  │ State Machine│  │ WebSocket RT │  │  Razorpay    │   │
│  │ bcrypt hash  │  │ Role gating  │  │ Typing/read  │  │  Escrow      │   │
│  │ Rate limit   │  │ Auto-notify  │  │ Media share  │  │  Refunds     │   │
│  │ 4 user roles │  │ Status log   │  │ Voice notes  │  │  Webhooks    │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  🔍 Search   │  │  🏪 Store-   │  │  🛡️ Trust    │  │  👥 Social   │   │
│  │   Engine     │  │   front      │  │   System     │  │   Layer      │   │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤   │
│  │ Geo-spatial  │  │ 8 themes     │  │ 5-tier badges│  │  Follow/Feed │   │
│  │ Full-text    │  │ Media gallery│  │ Trust Index  │  │  Stories 24h │   │
│  │ Multi-filter │  │ Packages     │  │ Timeline     │  │  Collections │   │
│  │ Trending     │  │ Brand colors │  │ Explainer    │  │  Community   │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  Middleware: requestId → httpLogger → helmet → compression → cors →        │
│             rateLimit → auth → validate → fraudPrevention → cache          │
│             featureFlags                                                    │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────────┐
│  PostgreSQL 16   │  │   Redis 7        │  │   External Services          │
│  82 tables       │  │   Cache + Pub/Sub│  │   ├── Razorpay (payments)    │
│  17 migrations   │  │   Rate limiting  │  │   ├── FCM (push notifs)      │
│  pgcrypto ext    │  │   LRU eviction   │  │   ├── SendGrid (email)       │
│  PgBouncer pool  │  │   AOF persist    │  │   ├── SMS (MSG91/Twilio)     │
└──────────────────┘  └──────────────────┘  │   ├── S3/R2 (storage)        │
                                             │   ├── Sentry (errors)        │
                                             │   └── Prom+Grafana (metrics) │
                                             └──────────────────────────────┘
```

---

## 🔄 Booking State Machine (FSM)

The booking controller implements a **server-enforced finite state machine** with role-gated transitions:

```
                    ┌─────────────┐
                    │  requested  │ ← Customer creates booking
                    └──────┬──────┘
                           │ Pro sends quote
                    ┌──────▼──────┐
                    │   quoted    │
                    └──────┬──────┘
                           │ Customer accepts
                    ┌──────▼──────┐
                    │  accepted   │
                    └──────┬──────┘
                           │ Date/time confirmed
                    ┌──────▼──────┐
                    │  scheduled  │
                    └──────┬──────┘
                           │ Pro starts work
                    ┌──────▼──────┐
                    │ in_progress │
                    └──────┬──────┘
                           │ Work done
         ┌─────────────────▼─────────────────┐
         │             completed              │
         └─────────────────┬─────────────────┘
                           │ Issue raised
                    ┌──────▼──────┐
                    │  disputed   │ → Resolution → refunded
                    └─────────────┘

    ※ Cancellation allowed at any pre-completion state
    ※ PRO_ONLY transitions: quoted, in_progress, completed
    ※ CUSTOMER_ONLY transitions: accepted
```

| Current State | Next States | Who Can Transition | Side Effects |
|--------------|-------------|-------------------|-------------|
| `requested` | `quoted`, `cancelled` | PRO: quote / ANY: cancel | Notification → Professional |
| `quoted` | `accepted`, `cancelled` | CUSTOMER: accept / ANY: cancel | Shows quote to customer |
| `accepted` | `scheduled`, `cancelled` | PRO: schedule / ANY: cancel | Confirms time slot |
| `scheduled` | `in_progress`, `cancelled` | PRO: start / ANY: cancel | GPS tracking begins |
| `in_progress` | `completed`, `disputed`, `cancelled` | PRO: complete / ANY: dispute | Service delivery |
| `completed` | `disputed`, `refunded` | ANY: dispute / ADMIN: refund | Triggers review prompt |
| `disputed` | `refunded`, `completed` | ADMIN: resolve | Evidence collection |
| `cancelled` | *(terminal)* | — | Refund if payment exists |
| `refunded` | *(terminal)* | — | Payment reversed |

Every transition: validates via FSM → checks role → logs to `booking_status_log` → sends WebSocket notification → triggers push notification.

---

## 💻 Tech Stack

### Core Technologies

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Mobile** | Flutter / Dart | 3.8 | Cross-platform native app (Android + iOS + Web) |
| **Frontend** | React | 19.2.5 | Customer-facing web SPA |
| **Bundler** | Vite | 8.0.10 | Build tool with HMR |
| **Routing** | React Router | 7.14.2 | Client-side navigation |
| **Backend** | Express | 5.2.1 | RESTful API server |
| **Database** | PostgreSQL | 16 | Relational data with geo-spatial queries |
| **Cache** | Redis | 7 | Caching, rate limiting, pub/sub |
| **Realtime** | ws | 8.20.0 | WebSocket server for chat & notifications |
| **Payments** | Razorpay | — | Payment gateway integration |
| **Monitoring** | Prometheus + Grafana | 2.51.2 / 10.4.2 | Metrics collection and dashboards |
| **Error Tracking** | Sentry | 10.51.0 | Error monitoring |
| **Connection Pool** | PgBouncer | 1.22.1 | PostgreSQL connection pooling |

### Backend Dependencies (21 production)

| Package | Version | Purpose |
|---------|---------|---------|
| express | 5.2.1 | Web framework |
| pg | 8.20.0 | PostgreSQL client |
| jsonwebtoken | 9.0.3 | JWT authentication |
| bcryptjs | 3.0.3 | Password hashing |
| ws | 8.20.0 | WebSocket server |
| ioredis | 5.10.1 | Redis client |
| pino / pino-pretty | 10.3.1 / 13.1.3 | Structured logging |
| node-cron | 4.2.1 | Scheduled jobs |
| multer | 2.1.1 | File upload handling |
| prom-client | 15.1.3 | Prometheus metrics |
| pdfkit | 0.18.0 | PDF generation (GST invoices) |
| @sentry/node | 10.51.0 | Error tracking |
| helmet | 8.1.0 | Security headers |
| express-rate-limit | 8.4.1 | Rate limiting |
| express-validator | 7.3.2 | Input validation |
| cors | 2.8.6 | CORS middleware |
| compression | 1.8.1 | Gzip compression |
| dotenv | 17.4.2 | Environment variables |
| uuid | 14.0.0 | UUID generation |
| morgan | 1.10.1 | HTTP logging |
| @types/node | 25.6.0 | Type definitions |

### Backend Dev Dependencies (4)

| Package | Version | Purpose |
|---------|---------|---------|
| jest | 30.3.0 | Testing framework |
| supertest | 7.2.2 | HTTP assertion library |
| eslint | 10.2.1 | Code linting |
| nodemon | 3.1.14 | Development auto-reload |

### Frontend Dependencies (5 production)

| Package | Version | Purpose |
|---------|---------|---------|
| react | 19.2.5 | UI library |
| react-dom | 19.2.5 | DOM rendering |
| react-router-dom | 7.14.2 | Client-side routing |
| react-helmet-async | 3.0.0 | SEO meta tag management |
| react-icons | 5.6.0 | Icon library |

### Frontend Dev Dependencies (7)

| Package | Version | Purpose |
|---------|---------|---------|
| vite | 8.0.10 | Build tool |
| @vitejs/plugin-react | 6.0.1 | React plugin for Vite |
| vitest | 4.1.5 | Testing framework |
| jsdom | 29.1.0 | DOM implementation for tests |
| @testing-library/react | 16.3.2 | React testing utilities |
| @testing-library/jest-dom | 6.9.1 | DOM matchers |
| @testing-library/user-event | 14.6.1 | User interaction simulation |

### Mobile Dependencies (20+ packages)

| Package | Version | Purpose |
|---------|---------|---------|
| http | 1.2.1 | HTTP client |
| provider | 6.1.2 | State management |
| shared_preferences | 2.2.3 | Local key-value storage |
| cached_network_image | 3.3.1 | Image caching |
| flutter_rating_bar | 4.0.1 | Rating widget |
| web_socket_channel | 2.4.5 | WebSocket client |
| geolocator | 12.0.0 | GPS/location services |
| table_calendar | 3.1.3 | Calendar widget |
| image_picker | 1.0.7 | Camera/gallery image selection |
| hive / hive_flutter | 2.2.3 / 1.1.0 | Local NoSQL database (offline) |
| connectivity_plus | 6.1.4 | Network state monitoring |
| speech_to_text | 7.0.0 | Voice recognition |
| url_launcher | 6.2.5 | URL opening |
| share_plus | 10.0.0 | Share intent |
| intl | 0.19.0 | Internationalization |
| path_provider | 2.1.5 | File system paths |
| audioplayers | 6.1.0 | Audio playback |
| record | 5.1.3 | Voice recording |
| uuid | 4.5.1 | UUID generation |

---

## 📁 Project Structure

```
SKILL/
├── .github/
│   └── workflows/
│       └── ci.yml                          # CI/CD pipeline
│
├── backend/                                # Node.js + Express 5 API
│   ├── package.json                        # Dependencies & scripts
│   ├── Dockerfile                          # Container build
│   ├── src/
│   │   ├── server.js                       # Entry point (HTTP + WebSocket)
│   │   ├── app.js                          # Express app (38 route registrations)
│   │   │
│   │   ├── config/                         # 6 configuration files
│   │   │   ├── index.js                    # Central config (env vars)
│   │   │   ├── database.js                 # PostgreSQL pool (pg)
│   │   │   ├── redis.js                    # Redis client (ioredis)
│   │   │   ├── logger.js                   # Pino structured logger
│   │   │   ├── metrics.js                  # Prometheus metrics (prom-client)
│   │   │   └── sentry.js                   # Sentry error tracking
│   │   │
│   │   ├── middleware/                     # 8 middleware files
│   │   │   ├── auth.js                     # JWT verification + role checking
│   │   │   ├── cache.js                    # Redis response caching
│   │   │   ├── errorHandler.js             # Global error handler
│   │   │   ├── featureFlags.js             # Feature flag gating
│   │   │   ├── fraudPrevention.js          # Fraud detection middleware
│   │   │   ├── httpLogger.js               # Structured HTTP request logging
│   │   │   ├── requestId.js                # Request correlation IDs
│   │   │   └── validate.js                 # Input validation (express-validator)
│   │   │
│   │   ├── routes/                         # 38 route files
│   │   │   ├── admin.js                    # Admin management endpoints
│   │   │   ├── agents.js                   # Agent system (feature-flagged)
│   │   │   ├── ai.js                       # AI endpoints
│   │   │   ├── analytics.js                # Analytics event tracking
│   │   │   ├── auth.js                     # Authentication (login/register/refresh)
│   │   │   ├── bookings.js                 # Booking CRUD + FSM (feature-flagged)
│   │   │   ├── categories.js               # Service categories
│   │   │   ├── collections.js              # Save collections (Pinterest-style)
│   │   │   ├── community.js                # Community posts & tips
│   │   │   ├── complaints.js               # Complaint filing
│   │   │   ├── contacts.js                 # Contact requests
│   │   │   ├── dashboard.js                # Dashboard analytics
│   │   │   ├── discover.js                 # Discovery (trending/new/responsive)
│   │   │   ├── disputes.js                 # Dispute resolution (feature-flagged)
│   │   │   ├── emergency.js                # Emergency dispatch (feature-flagged)
│   │   │   ├── favorites.js                # Favorite professionals
│   │   │   ├── growth.js                   # Growth & waitlist
│   │   │   ├── kyc.js                      # KYC verification
│   │   │   ├── matching.js                 # Professional matching
│   │   │   ├── messages.js                 # Chat messages (feature-flagged)
│   │   │   ├── notifications.js            # Notification management
│   │   │   ├── payments.js                 # Payment processing
│   │   │   ├── portfolio.js                # Portfolio management
│   │   │   ├── professionals.js            # Professional profiles
│   │   │   ├── reels.js                    # Reels video feed
│   │   │   ├── referrals.js                # Referral system
│   │   │   ├── reviews.js                  # Review CRUD + moderation
│   │   │   ├── schedule.js                 # Schedule management
│   │   │   ├── search.js                   # Search (geo + full-text)
│   │   │   ├── seo.js                      # SEO (sitemap, robots.txt)
│   │   │   ├── social.js                   # Follow/unfollow + feed
│   │   │   ├── storefront.js               # Storefront CRUD + media + themes
│   │   │   ├── stories.js                  # 24h ephemeral stories
│   │   │   ├── trust.js                    # Trust badges/timeline/explainer
│   │   │   ├── uploads.js                  # File uploads
│   │   │   ├── users.js                    # User management + DPDPA export
│   │   │   ├── warranties.js               # Warranty claims (feature-flagged)
│   │   │   └── webhooks.js                 # Payment webhooks (Razorpay)
│   │   │
│   │   ├── controllers/                    # 37 controller files
│   │   │   ├── adminController.js
│   │   │   ├── agentController.js
│   │   │   ├── aiController.js
│   │   │   ├── analyticsController.js
│   │   │   ├── analyticsEventsController.js
│   │   │   ├── authController.js
│   │   │   ├── bookingController.js        # FSM engine
│   │   │   ├── categoryController.js
│   │   │   ├── collectionsController.js
│   │   │   ├── communityController.js
│   │   │   ├── complaintController.js
│   │   │   ├── contactController.js
│   │   │   ├── dashboardController.js
│   │   │   ├── discoverController.js
│   │   │   ├── disputeController.js
│   │   │   ├── emergencyController.js
│   │   │   ├── favoriteController.js
│   │   │   ├── growthController.js
│   │   │   ├── kycController.js
│   │   │   ├── matchingController.js
│   │   │   ├── messageController.js
│   │   │   ├── notificationController.js
│   │   │   ├── paymentController.js
│   │   │   ├── portfolioController.js
│   │   │   ├── professionalController.js
│   │   │   ├── reelsController.js
│   │   │   ├── referralController.js
│   │   │   ├── reviewController.js
│   │   │   ├── scheduleController.js
│   │   │   ├── searchController.js
│   │   │   ├── socialController.js
│   │   │   ├── storefrontController.js
│   │   │   ├── storyController.js
│   │   │   ├── trustController.js
│   │   │   ├── uploadController.js
│   │   │   ├── userController.js
│   │   │   └── warrantyController.js
│   │   │
│   │   ├── services/                       # 9 external integrations
│   │   │   ├── ai.js                       # AI service integration
│   │   │   ├── email.js                    # SendGrid email service
│   │   │   ├── faceMatch.js                # Face matching for KYC
│   │   │   ├── gstInvoice.js               # GST invoice PDF generation
│   │   │   ├── jobQueue.js                 # In-memory job queue with retry
│   │   │   ├── pushNotification.js         # FCM push notifications
│   │   │   ├── razorpay.js                 # Razorpay payment gateway
│   │   │   ├── sms.js                      # SMS (MSG91/Twilio)
│   │   │   └── storage.js                  # S3/R2/local file storage
│   │   │
│   │   ├── workers/
│   │   │   └── cron.js                     # 6 scheduled background jobs
│   │   │
│   │   └── realtime/
│   │       └── hub.js                      # WebSocket server (ws library)
│   │
│   └── tests/                              # 16 test suites (150 tests)
│       ├── setup.js                        # Test configuration
│       ├── agents.test.js
│       ├── analytics.test.js
│       ├── auth.test.js
│       ├── bookings.test.js
│       ├── categories.test.js
│       ├── dashboard.test.js
│       ├── disputes.test.js
│       ├── emergency.test.js
│       ├── kyc.test.js
│       ├── messages.test.js
│       ├── referrals.test.js
│       ├── reviews.test.js
│       ├── schedule.test.js
│       ├── search.test.js
│       ├── storefront.test.js
│       └── warranties.test.js
│
├── frontend/                               # React 19 + Vite 8 Web App
│   ├── package.json
│   ├── Dockerfile
│   ├── vite.config.js
│   ├── index.html
│   ├── src/
│   │   ├── App.jsx                         # Root component (47+ routes)
│   │   ├── App.css                         # Global styles
│   │   ├── main.jsx                        # Entry point
│   │   │
│   │   ├── api/
│   │   │   └── client.js                   # Axios-like API client
│   │   │
│   │   ├── context/                        # 2 React contexts
│   │   │   ├── AuthContext.jsx             # Auth state + JWT management
│   │   │   └── WebSocketContext.jsx        # WebSocket connection manager
│   │   │
│   │   ├── components/                     # 23 shared components
│   │   │   ├── AnnouncementBar.jsx         # Top announcement banner
│   │   │   ├── AppInstallBanner.jsx        # PWA install prompt
│   │   │   ├── BottomNav.jsx               # Mobile bottom navigation
│   │   │   ├── CategoryCard.jsx            # Category display card
│   │   │   ├── CookieConsent.jsx           # GDPR cookie consent
│   │   │   ├── ErrorBoundary.jsx           # Error boundary with fallback UI
│   │   │   ├── Footer.jsx                  # Site footer
│   │   │   ├── InviteEarn.jsx              # Referral invitation widget
│   │   │   ├── LoadingSpinner.jsx          # Loading indicator
│   │   │   ├── Navbar.jsx                  # Top navigation bar
│   │   │   ├── OnlineIndicator.jsx         # User online status
│   │   │   ├── ProfessionalCard.jsx        # Professional listing card
│   │   │   ├── ProtectedRoute.jsx          # Auth-gated route wrapper
│   │   │   ├── ReviewCard.jsx              # Review display card
│   │   │   ├── SEOMeta.jsx                 # SEO meta tags (react-helmet-async)
│   │   │   ├── SaveToCollectionModal.jsx   # Save to collection dialog
│   │   │   ├── SearchBar.jsx               # Search input with autocomplete
│   │   │   ├── ShareButton.jsx             # Social share button
│   │   │   ├── Skeleton.jsx                # Loading skeletons (Page/Stats/Card/Profile)
│   │   │   ├── StarRating.jsx              # Star rating display
│   │   │   ├── Toast.jsx                   # Toast notification system
│   │   │   ├── TrustSection.jsx            # Trust indicators section
│   │   │   └── TrustTimeline.jsx           # Trust milestone timeline
│   │   │
│   │   └── pages/                          # 54 page components
│   │       ├── Home.jsx                    # Landing page with discovery
│   │       ├── Login.jsx                   # Role selection landing
│   │       ├── CustomerLogin.jsx           # Customer login
│   │       ├── ProfessionalLogin.jsx       # Professional login
│   │       ├── AgentLogin.jsx              # Agent login
│   │       ├── AdminLogin.jsx              # Admin login
│   │       ├── Register.jsx                # Registration landing
│   │       ├── CustomerRegister.jsx        # Customer registration
│   │       ├── ProfessionalRegister.jsx    # Professional registration
│   │       ├── AgentRegister.jsx           # Agent registration
│   │       ├── SearchResults.jsx           # Search results page
│   │       ├── Categories.jsx              # Category browser
│   │       ├── CategoryDetail.jsx          # Single category detail
│   │       ├── ProfessionalProfile.jsx     # Professional public profile
│   │       ├── Storefront.jsx              # Branded professional storefront
│   │       ├── StorefrontSetup.jsx         # Storefront editor (themes/media)
│   │       ├── Dashboard.jsx               # User dashboard
│   │       ├── Settings.jsx                # User settings
│   │       ├── Bookings.jsx                # Booking list
│   │       ├── BookingDetail.jsx           # Single booking detail + timeline
│   │       ├── CreateBooking.jsx           # Multi-step booking wizard
│   │       ├── Messages.jsx                # Message thread list
│   │       ├── Chat.jsx                    # Real-time chat
│   │       ├── Notifications.jsx           # Notifications
│   │       ├── Payment.jsx                 # Payment processing
│   │       ├── Favorites.jsx               # Saved favorites
│   │       ├── Earnings.jsx                # Professional earnings
│   │       ├── Schedule.jsx                # Schedule management
│   │       ├── Emergency.jsx               # Emergency requests
│   │       ├── Referrals.jsx               # Referral management
│   │       ├── Disputes.jsx                # Dispute management
│   │       ├── Warranties.jsx              # Warranty claims
│   │       ├── Analytics.jsx               # Analytics dashboard
│   │       ├── Collections.jsx             # Saved collections
│   │       ├── CommunityFeed.jsx           # Community posts feed
│   │       ├── ReelsFeed.jsx               # Reels video feed
│   │       ├── AgentDashboard.jsx          # Agent overview
│   │       ├── AgentOnboard.jsx            # Agent onboarding flow
│   │       ├── AgentWallet.jsx             # Agent wallet/earnings
│   │       ├── AgentLeaderboard.jsx        # Agent leaderboard
│   │       ├── TermsOfService.jsx          # Terms of service page
│   │       ├── PrivacyPolicy.jsx           # Privacy policy (DPDPA)
│   │       ├── RefundPolicy.jsx            # Refund policy
│   │       ├── CookiePolicy.jsx            # Cookie policy
│   │       ├── ProfessionalTerms.jsx       # Professional terms
│   │       ├── ContentModerationPolicy.jsx # Content moderation policy
│   │       ├── NotFound.jsx                # 404 page
│   │       └── admin/                      # 7 admin pages
│   │           ├── AdminDashboard.jsx      # Platform analytics
│   │           ├── AdminUsers.jsx          # User management
│   │           ├── AdminKYC.jsx            # KYC queue
│   │           ├── AdminDisputes.jsx       # Dispute management
│   │           ├── AdminCategoryRequests.jsx # Category request review
│   │           ├── AdminFeaturedSlots.jsx   # Featured slot management
│   │           └── AdminAppeals.jsx        # Ban appeal management
│
├── mobile/                                 # Flutter 3.8 Mobile App
│   └── skillconnect/
│       ├── pubspec.yaml                    # Dependencies
│       └── lib/
│           ├── main.dart                   # Entry point + MainShell
│           │
│           ├── screens/                    # 47 screen files
│           │   ├── splash_screen.dart
│           │   ├── auth/                   # 3 screens
│           │   │   ├── welcome_screen.dart
│           │   │   ├── login_screen.dart   # 4-role login (customer/pro/agent/admin)
│           │   │   └── register_screen.dart
│           │   ├── home/                   # 8 screens
│           │   │   ├── home_screen.dart
│           │   │   ├── dashboard_screen.dart
│           │   │   ├── categories_screen.dart
│           │   │   ├── category_detail_screen.dart
│           │   │   ├── pro_home_screen.dart
│           │   │   ├── agent_home_screen.dart
│           │   │   ├── admin_home_screen.dart
│           │   │   └── service_hub_screen.dart
│           │   ├── bookings/               # 5 screens
│           │   │   ├── bookings_list_screen.dart
│           │   │   ├── booking_detail_screen.dart
│           │   │   ├── booking_calendar_screen.dart
│           │   │   ├── rebooking_sheet.dart
│           │   │   └── service_history_screen.dart
│           │   ├── search/                 # 2 screens
│           │   │   ├── search_screen.dart
│           │   │   └── instant_quote_screen.dart
│           │   ├── messages/               # 2 screens
│           │   │   ├── threads_screen.dart
│           │   │   └── chat_screen.dart
│           │   ├── notifications/          # 2 screens
│           │   │   ├── notifications_screen.dart
│           │   │   └── notification_preferences_screen.dart
│           │   ├── profile/                # 2 screens
│           │   │   ├── professional_profile_screen.dart
│           │   │   └── edit_professional_profile_screen.dart
│           │   ├── storefront/             # 2 screens + 8 widgets
│           │   │   ├── storefront_screen.dart
│           │   │   ├── storefront_setup_screen.dart
│           │   │   └── widgets/
│           │   │       ├── about_section.dart
│           │   │       ├── announcement_banner.dart
│           │   │       ├── contact_buttons_row.dart
│           │   │       ├── hero_banner.dart
│           │   │       ├── portfolio_grid.dart
│           │   │       ├── reviews_section.dart
│           │   │       ├── service_info_card.dart
│           │   │       └── trust_badges_row.dart
│           │   ├── contacts/               # 1 screen
│           │   │   └── my_contacts_screen.dart
│           │   ├── disputes/               # 1 screen
│           │   │   └── dispute_screen.dart
│           │   ├── earnings/               # 1 screen
│           │   │   └── earnings_screen.dart
│           │   ├── emergency/              # 1 screen
│           │   │   └── emergency_booking_screen.dart
│           │   ├── favorites/              # 1 screen
│           │   │   └── favorites_screen.dart
│           │   ├── kyc/                    # 1 screen
│           │   │   └── kyc_screen.dart
│           │   ├── payments/               # 1 screen
│           │   │   └── payment_screen.dart
│           │   ├── portfolio/              # 1 screen
│           │   │   └── portfolio_screen.dart
│           │   ├── report/                 # 1 screen
│           │   │   └── report_screen.dart
│           │   ├── reviews/                # 1 screen
│           │   │   └── write_review_screen.dart
│           │   ├── schedule/               # 1 screen
│           │   │   └── schedule_management_screen.dart
│           │   ├── settings/               # 1 screen
│           │   │   └── settings_screen.dart
│           │   ├── tracking/               # 1 screen
│           │   │   └── live_tracking_screen.dart
│           │   └── warranty/               # 1 screen
│           │       └── warranty_screen.dart
│           │
│           ├── services/                   # 19 service files
│           │   ├── api_config.dart         # API base URL + headers
│           │   ├── api_service.dart        # REST API client
│           │   ├── auth_service.dart       # Auth (login/register/token/roles)
│           │   ├── booking_service.dart    # Booking CRUD
│           │   ├── storefront_service.dart # Storefront API
│           │   ├── upload_service.dart     # File upload
│           │   ├── analytics_service.dart  # Event tracking
│           │   ├── mobile_client.dart      # Mobile HTTP client
│           │   ├── web_client.dart         # Web HTTP client
│           │   ├── network_simulator.dart  # Network condition simulator
│           │   ├── performance_monitor.dart # Performance tracking
│           │   ├── push_notification_service.dart  # FCM push
│           │   ├── realtime_service.dart   # WebSocket connection
│           │   ├── smart_location_service.dart     # GPS + geocoding
│           │   ├── theme_service.dart      # Theme management
│           │   └── offline/               # 4 offline-first services
│           │       ├── connectivity_service.dart   # Network monitoring
│           │       ├── local_cache_service.dart    # Hive cache
│           │       ├── offline_queue_service.dart  # Request queuing
│           │       └── offline_services.dart       # Offline orchestrator
│           │
│           ├── widgets/                    # 10 shared widgets
│           │   ├── availability_toggle.dart
│           │   ├── book_now_sheet.dart
│           │   ├── connectivity_banner.dart
│           │   ├── nearby_providers_section.dart
│           │   ├── professional_card.dart
│           │   ├── review_prompt.dart
│           │   ├── skeleton_loader.dart
│           │   ├── trust_badge.dart
│           │   ├── voice_search_button.dart
│           │   └── voice/
│           │       └── voice_note_widget.dart
│           │
│           └── l10n/                       # Internationalization
│               ├── app_en.arb             # English
│               ├── app_hi.arb             # Hindi
│               └── app_te.arb             # Telugu
│
├── database/                               # PostgreSQL 16 Schema
│   ├── schema.sql                          # Base schema (8 tables, enums)
│   ├── seed.sql                            # Demo seed data
│   └── migrations/                         # 17 migration files
│       ├── 001_kyc.sql                     # KYC verification tables
│       ├── 002_bookings_chat.sql           # Bookings + messaging
│       ├── 003_review_by_booking.sql       # Review foreign key update
│       ├── 004_seed_geo.sql                # Geographic seed data
│       ├── 005_reputation_trigger.sql      # Reputation calculation trigger
│       ├── 006_phase1_features.sql         # Payments, disputes, warranties, referrals, emergency
│       ├── 006_storefront_fields.sql       # Storefront column additions
│       ├── 007_auth_admin_services.sql     # Auth tables, admin audit, invoices
│       ├── 007_provider_type.sql           # Provider type enum
│       ├── 008_analytics_and_chat_images.sql # Analytics + chat media
│       ├── 009_agent_system.sql            # Agent tables
│       ├── 010_growth_acquisition.sql      # Growth, promos, waitlist
│       ├── 011_warranty_enhancements.sql   # Warranty improvements
│       ├── 012_schema_completion.sql       # Subscriptions, certifications, service areas
│       ├── 013_gaps_completion.sql         # Appeals, bans, consent, audit
│       ├── 014_phase4_storefront_social_trust.sql  # Storefront media, follows, stories, badges
│       └── 015_collections_points.sql      # Collections + user points
│
├── k8s/                                    # Kubernetes manifests
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── secret-template.yaml
│   │   ├── backend-deployment.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── statefulsets.yaml               # PostgreSQL + Redis
│   │   ├── hpa.yaml                        # Horizontal Pod Autoscaler
│   │   ├── ingress.yaml                    # Ingress with TLS
│   │   └── backup-cronjob.yaml             # Automated DB backups
│   └── monitoring/
│       ├── prometheus.yaml
│       └── grafana.yaml
│
├── monitoring/                             # Observability config
│   ├── prometheus.yml                      # Scrape config
│   ├── alerts.yml                          # Alert rules
│   └── grafana/
│       └── provisioning/
│           ├── dashboards/provider.yaml
│           └── datasources/prometheus.yaml
│
├── nginx/
│   └── skillconnect.conf                   # Reverse proxy config
│
├── tests/
│   └── load/
│       ├── api.load.js                     # k6 API load test
│       └── websocket.load.js               # k6 WebSocket load test
│
├── plans/                                  # 30 analysis documents
│   ├── 00_MASTER_ANALYSIS.md
│   ├── PRD_SEC01_Registration.md – PRD_SEC20_Roadmap.md (16 files)
│   └── TECH_A_DatabaseGaps.md – TECH_J_DisasterRecovery.md (10 files)
│
├── docker-compose.yml                      # 7-service local dev stack
├── build.sh                                # 7-step build pipeline
├── ARCHITECTURE.md                         # System architecture document
├── INCIDENT_RESPONSE.md                    # Incident response playbook
├── PLATFORM_CHANGE_RECORD.md               # Change log
├── RUNBOOKS.md                             # Operational runbooks
├── SECRETS.md                              # Secrets management guide
├── THREAT_MODEL.md                         # STRIDE threat model
├── claude.md                               # AI agent implementation guide
└── ready.md                                # Production readiness checklist
```

---

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Clone and start all 7 services
git clone https://github.com/Govin111b8/SKILL.git
cd SKILL
docker compose up --build

# Services:
#   PostgreSQL 16  → localhost:5432
#   Redis 7        → localhost:6379
#   Backend API    → localhost:5000
#   Frontend       → localhost:3000
#   PgBouncer      → localhost:6432
#   Prometheus     → localhost:9090
#   Grafana        → localhost:3001
```

### Option 2: Manual Setup

```bash
# 1. Database
# Start PostgreSQL 16 and create the database:
psql -U postgres -c "CREATE DATABASE skillconnect;"
psql -U postgres -d skillconnect -f database/schema.sql
psql -U postgres -d skillconnect -f database/seed.sql
for f in database/migrations/*.sql; do psql -U postgres -d skillconnect -f "$f"; done

# 2. Backend
cd backend
npm install
cp .env.example .env    # Configure environment variables
npm run dev             # Starts on port 5000 (nodemon)

# 3. Frontend
cd frontend
npm install
npm run dev             # Starts on port 5173 (Vite HMR)

# 4. Mobile
cd mobile/skillconnect
flutter pub get
flutter run             # Android/iOS/Web
```

### Environment Variables (Backend)

| Variable | Required | Description |
|----------|----------|-------------|
| `PORT` | Yes | Server port (default: 5000) |
| `DB_HOST` | Yes | PostgreSQL host |
| `DB_PORT` | Yes | PostgreSQL port (5432) |
| `DB_NAME` | Yes | Database name (skillconnect) |
| `DB_USER` | Yes | Database user |
| `DB_PASSWORD` | Yes | Database password |
| `JWT_SECRET` | Yes | JWT signing secret (32+ chars) |
| `JWT_EXPIRES_IN` | Yes | JWT expiry (e.g., 15m) |
| `JWT_REFRESH_EXPIRES_IN` | Yes | Refresh token expiry (e.g., 7d) |
| `CORS_ORIGINS` | Yes | Allowed origins (comma-separated) |
| `REDIS_HOST` | No | Redis host (enables caching) |
| `REDIS_PORT` | No | Redis port (6379) |
| `ENABLE_CRON` | No | Enable cron jobs (true/false) |
| `STORAGE_PROVIDER` | No | File storage (local/s3) |
| `SMS_PROVIDER` | No | SMS service (none/msg91/twilio) |
| `FACE_MATCH_PROVIDER` | No | KYC face match (mock/hyperverge/rekognition) |
| `ENCRYPTION_KEY` | No | PII encryption key (64-char hex) |

---

## 🔌 API Reference

All endpoints are prefixed with `/api/`. Feature-flagged routes are gated via the `featureFlags` middleware.

### API Route Map (38 Route Groups)

| Route Prefix | Controller | Feature Flag | Description |
|-------------|------------|:---:|-------------|
| `/api/auth` | authController | — | Login, register, refresh, logout, forgot/reset password |
| `/api/professionals` | professionalController | — | Professional profiles CRUD, listing |
| `/api/categories` | categoryController | — | Service categories (hierarchical) |
| `/api/search` | searchController | — | Full-text + geo-spatial search with filters |
| `/api/portfolio` | portfolioController | — | Portfolio items CRUD (images/videos) |
| `/api/reviews` | reviewController | — | Reviews with timing window, velocity detection, helpful votes |
| `/api/contacts` | contactController | — | Contact requests (call/message/quote) |
| `/api/complaints` | complaintController | — | Complaint filing and tracking |
| `/api/dashboard` | dashboardController | — | Analytics dashboard (earnings, pipeline, conversion) |
| `/api/users` | userController | — | Profile, preferences, DPDPA data export, soft delete |
| `/api/kyc` | kycController | — | KYC document upload, face match, admin approval |
| `/api/bookings` | bookingController | `BOOKINGS` | Booking CRUD + FSM state transitions |
| `/api/messages` | messageController | `CHAT` | Message threads, send/receive, media attachments |
| `/api/notifications` | notificationController | — | Notification list, mark read, preferences |
| `/api/upload` | uploadController | — | File upload (multer + S3/local storage) |
| `/api/favorites` | favoriteController | — | Add/remove/list favorite professionals |
| `/api/analytics` | analyticsController | — | Event tracking, session management, metrics |
| `/api/payments` | paymentController | — | Razorpay orders, verify, refund, subscription billing |
| `/api/schedule` | scheduleController | — | Availability slots, blocked dates, time slots |
| `/api/disputes` | disputeController | `DISPUTES` | Dispute creation, evidence upload, admin resolution |
| `/api/warranties` | warrantyController | `WARRANTIES` | Warranty claims CRUD, status tracking |
| `/api/emergency` | emergencyController | `EMERGENCIES` | Emergency request dispatch and resolution |
| `/api/referrals` | referralController | — | Referral code generation, tracking, reward crediting |
| `/api/admin` | adminController | — | Admin-only: user mgmt, KYC queue, disputes, complaints |
| `/api/webhooks` | — | — | Razorpay payment webhooks |
| `/api/storefront` | storefrontController | — | Storefront CRUD, media upload, themes, packages |
| `/api/agents` | agentController | `AGENTS` | Agent registration, commissions, wallet, leaderboard |
| `/api/match` | matchingController | — | Professional matching algorithm |
| `/api/social` | socialController | — | Follow/unfollow, follower count, activity feed |
| `/api/stories` | storyController | — | Create/view 24h ephemeral stories, auto-expire |
| `/api/trust` | trustController | — | Trust badges, timeline, explainability |
| `/api/discover` | discoverController | — | Trending, newly verified, highly responsive professionals |
| `/api/collections` | collectionsController | — | Collection CRUD, add/remove items |
| `/api/community` | communityController | — | Community posts, like, category-filtered feed |
| `/api/reels` | reelsController | — | Reels video feed with engagement actions |
| `/api/seo` | — | — | sitemap.xml, robots.txt generation |
| `/api/growth` | growthController | — | Waitlist, newsletter, promo codes |
| `/api/ai` | aiController | — | AI-powered features |

### Special Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Health check (DB + Redis connectivity) |
| `/metrics` | GET | Prometheus metrics (localhost-only in production) |
| `/sitemap.xml` | GET | Dynamic SEO sitemap |
| `/robots.txt` | GET | Search engine directives |
| `/uploads/*` | GET | Static file serving (7-day cache) |

---

## 🖥️ Frontend Pages & Routes

### Public Routes (no auth required)

| Route | Component | Description |
|-------|-----------|-------------|
| `/` | `Home.jsx` | Landing page with discovery carousels |
| `/login` | `Login.jsx` | Role selection (Customer/Professional/Agent/Admin) |
| `/login/customer` | `CustomerLogin.jsx` | Customer login with demo button |
| `/login/professional` | `ProfessionalLogin.jsx` | Professional login with demo button |
| `/login/agent` | `AgentLogin.jsx` | Agent login |
| `/login/admin` | `AdminLogin.jsx` | Admin login |
| `/register` | `Register.jsx` | Registration landing |
| `/register/customer` | `CustomerRegister.jsx` | Customer registration |
| `/register/professional` | `ProfessionalRegister.jsx` | Professional registration |
| `/register/agent` | `AgentRegister.jsx` | Agent registration |
| `/search` | `SearchResults.jsx` | Search results with filters |
| `/professionals/:id` | `ProfessionalProfile.jsx` | Professional public profile |
| `/professionals/:id/storefront` | `Storefront.jsx` | Branded storefront page |
| `/categories` | `Categories.jsx` | Category browser |
| `/categories/:slug` | `CategoryDetail.jsx` | Category detail page |
| `/community` | `CommunityFeed.jsx` | Community posts feed |
| `/reels` | `ReelsFeed.jsx` | Reels video feed |
| `/terms` | `TermsOfService.jsx` | Terms of service |
| `/privacy` | `PrivacyPolicy.jsx` | Privacy policy (DPDPA compliant) |
| `/refund-policy` | `RefundPolicy.jsx` | Refund policy |
| `/cookie-policy` | `CookiePolicy.jsx` | Cookie policy |
| `/professional-terms` | `ProfessionalTerms.jsx` | Professional terms |
| `/content-moderation` | `ContentModerationPolicy.jsx` | Content moderation policy |
| `*` | `NotFound.jsx` | 404 page |

### Protected Routes (auth required)

| Route | Component | Description |
|-------|-----------|-------------|
| `/dashboard` | `Dashboard.jsx` | User dashboard |
| `/dashboard/storefront` | `StorefrontSetup.jsx` | Storefront editor (themes/media/packages) |
| `/settings` | `Settings.jsx` | User settings & preferences |
| `/bookings` | `Bookings.jsx` | Booking list |
| `/bookings/create` | `CreateBooking.jsx` | Multi-step booking wizard |
| `/bookings/:id/pay` | `Payment.jsx` | Payment processing |
| `/bookings/:id` | `BookingDetail.jsx` | Booking detail + status timeline |
| `/messages` | `Messages.jsx` | Message thread list |
| `/messages/:threadId` | `Chat.jsx` | Real-time chat |
| `/notifications` | `Notifications.jsx` | Notifications |
| `/favorites` | `Favorites.jsx` | Saved favorites |
| `/earnings` | `Earnings.jsx` | Professional earnings |
| `/schedule` | `Schedule.jsx` | Schedule management |
| `/emergency` | `Emergency.jsx` | Emergency requests |
| `/referrals` | `Referrals.jsx` | Referral management |
| `/disputes` | `Disputes.jsx` | Dispute management |
| `/warranties` | `Warranties.jsx` | Warranty claims |
| `/analytics` | `Analytics.jsx` | Analytics dashboard |
| `/collections` | `Collections.jsx` | Saved collections |

### Admin Routes (auth required)

| Route | Component | Description |
|-------|-----------|-------------|
| `/admin` | `AdminDashboard.jsx` | Platform analytics overview |
| `/admin/users` | `AdminUsers.jsx` | User management |
| `/admin/kyc` | `AdminKYC.jsx` | KYC approval queue |
| `/admin/disputes` | `AdminDisputes.jsx` | Dispute management |
| `/admin/category-requests` | `AdminCategoryRequests.jsx` | Category request review |
| `/admin/featured-slots` | `AdminFeaturedSlots.jsx` | Featured slot management |
| `/admin/appeals` | `AdminAppeals.jsx` | Ban appeal management |

### Agent Routes (auth required)

| Route | Component | Description |
|-------|-----------|-------------|
| `/agent/dashboard` | `AgentDashboard.jsx` | Agent overview |
| `/agent/onboard/:type` | `AgentOnboard.jsx` | Agent onboarding flow |
| `/agent/wallet` | `AgentWallet.jsx` | Agent wallet/earnings |
| `/agent/leaderboard` | `AgentLeaderboard.jsx` | Agent leaderboard |

### Global Components (rendered on every page)

| Component | Description |
|-----------|-------------|
| `Navbar` | Top navigation with search, auth, role-aware links |
| `Footer` | Site footer with links |
| `BottomNav` | Mobile bottom navigation bar |
| `Toast` | Toast notification system |
| `CookieConsent` | GDPR cookie consent banner |
| `AppInstallBanner` | PWA install prompt |
| `AnnouncementBar` | Top announcement banner |

---

## 📱 Mobile App (Flutter)

### 4 User Roles
The mobile app supports 4 distinct roles with role-specific UIs: **Customer**, **Professional**, **Agent**, **Admin**.

### Screens by Module (47 screens)

| Module | Screens | Description |
|--------|---------|-------------|
| **Auth** | welcome, login, register | Role-aware login with gradients, icons, demo login |
| **Home** | home, dashboard, categories, category_detail, pro_home, agent_home, admin_home, service_hub | Role-specific home screens |
| **Bookings** | bookings_list, booking_detail, booking_calendar, rebooking_sheet, service_history | Full booking lifecycle |
| **Search** | search, instant_quote | Search with voice + instant quote |
| **Messages** | threads, chat | Real-time WebSocket chat |
| **Notifications** | notifications, notification_preferences | Push notification management |
| **Profile** | professional_profile, edit_professional_profile | Professional profile CRUD |
| **Storefront** | storefront, storefront_setup + 8 widgets (hero_banner, about_section, portfolio_grid, reviews_section, service_info_card, trust_badges_row, contact_buttons_row, announcement_banner) | Branded professional storefront |
| **Other** | contacts, disputes, earnings, emergency, favorites, kyc, payments, portfolio, report, reviews, schedule, settings, splash, tracking, warranty | Individual feature screens |

### Offline-First Architecture

```
┌─────────────────────────────┐
│      connectivity_service    │  Monitors network state
├─────────────────────────────┤
│      local_cache_service     │  Hive local database
├─────────────────────────────┤
│      offline_queue_service   │  Queues requests when offline
├─────────────────────────────┤
│      offline_services        │  Orchestrates sync on reconnect
└─────────────────────────────┘
```

### Voice Search
- `voice_search_button.dart` — speech-to-text in English, Hindi, Telugu
- `voice/voice_note_widget.dart` — voice note recording and playback

---

## 🗄️ Database Schema (82 Tables)

### Tables by Domain

<details>
<summary><strong>👤 Users & Auth (12 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `users` | Base user accounts (email, password_hash, role, location) |
| `professionals` | Professional profiles (bio, hourly_rate, rating, trust_score) |
| `professional_categories` | Professional ↔ category mapping |
| `professional_languages` | Languages spoken by professional |
| `professional_hours` | Working hours |
| `verifications` | KYC verification records |
| `verification_audit` | KYC audit trail |
| `email_verifications` | Email verification tokens |
| `password_resets` | Password reset tokens |
| `refresh_token_blacklist` | Revoked refresh tokens |
| `device_tokens` | FCM push notification tokens |
| `consent_records` | DPDPA consent tracking |

</details>

<details>
<summary><strong>📦 Bookings & Payments (9 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `bookings` | Booking records with FSM status |
| `booking_status_log` | Status transition audit trail |
| `payments` | Payment records |
| `payouts` | Professional payout records |
| `payout_log` | Payout audit trail |
| `invoices` | Booking invoices |
| `gst_invoices` | GST tax invoices |
| `subscriptions` | Professional subscription plans |
| `service_warranties` | Warranty claims |

</details>

<details>
<summary><strong>💬 Communication (4 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `message_threads` | Chat thread metadata |
| `messages` | Individual messages |
| `notifications` | User notifications |
| `contacts` | Contact requests (call/message/quote) |

</details>

<details>
<summary><strong>⭐ Reviews & Trust (5 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `reviews` | User reviews with moderation status |
| `review_replies` | Professional replies to reviews |
| `complaints` | User complaints |
| `disputes` | Dispute records |
| `professional_badges` | Earned trust badges |

</details>

<details>
<summary><strong>🏪 Storefront & Portfolio (4 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `portfolio_items` | Portfolio images/videos |
| `storefront_media` | Storefront media (reels, before/after, highlights) |
| `storefront_themes` | Theme settings (colors, layout, intro) |
| `service_packages` | Tiered pricing packages |

</details>

<details>
<summary><strong>👥 Social (6 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `follows` | Follow relationships |
| `favorites` | Favorited professionals |
| `stories` | 24h ephemeral stories |
| `community_posts` | Community tips and content |
| `community_post_likes` | Post likes |
| `collections` + `collection_items` | Save boards |

</details>

<details>
<summary><strong>👨‍💼 Agent System (6 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `agents` | Agent profiles |
| `agent_rewards` | Agent reward records |
| `agent_wallet_transactions` | Wallet transactions |
| `agent_onboarded_users` | Users onboarded by agent |
| `reward_config` | Reward configuration |
| `zones` | Agent zones |

</details>

<details>
<summary><strong>📊 Analytics & Growth (9 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `analytics_events` | Event tracking |
| `analytics_sessions` | User sessions |
| `performance_metrics` | Performance data |
| `user_interactions` | User interaction tracking |
| `growth_events` | Growth funnel events |
| `newsletter_subscribers` | Email subscribers |
| `waitlist` | City waitlist |
| `promo_codes` + `promo_usage` | Promotional codes |

</details>

<details>
<summary><strong>🔧 Platform & Admin (15 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `categories` | Service categories (hierarchical) |
| `category_requests` | User-submitted category requests |
| `featured_slots` | Featured placement management |
| `ab_experiments` | A/B experiment tracking |
| `admin_audit_log` | Admin action audit trail |
| `audit_log` | General audit log |
| `appeals` | Ban appeals |
| `blocked_users` | Blocked user relationships |
| `banned_phones` | Banned phone numbers |
| `banned_govt_ids` | Banned government IDs |
| `soft_deletes_log` | Soft deletion records |
| `supported_cities` | Supported city list |
| `search_history` | Search history |
| `push_subscriptions` | Web push subscriptions |
| `otp_log` | OTP send log |

</details>

<details>
<summary><strong>💰 Referrals & Rewards (5 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `referral_codes` | Referral code records |
| `referrals` | Referral tracking |
| `loyalty_points` | Loyalty point balances |
| `user_points` | User point system |
| `safety_alerts` | Safety alert records |

</details>

<details>
<summary><strong>📅 Schedule (3 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `worker_schedule` | Weekly availability |
| `time_slots` | Available time slots |
| `worker_blocked_dates` | Blocked date ranges |

</details>

<details>
<summary><strong>🚨 Emergency & Safety (2 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `emergency_requests` | Emergency dispatch records |
| `safety_alerts` | Safety alert notifications |

</details>

<details>
<summary><strong>📜 Other (2 tables)</strong></summary>

| Table | Description |
|-------|-------------|
| `certifications` | Professional certifications |
| `service_areas` | Professional service areas |

</details>

---

## 🔒 Middleware Pipeline

Requests flow through 8 middleware layers (in order):

| # | Middleware | File | Description |
|---|-----------|------|-------------|
| 1 | **Request ID** | `requestId.js` | Adds unique correlation ID to every request |
| 2 | **Metrics** | `config/metrics.js` | Records HTTP duration/count per route (Prometheus) |
| 3 | **Helmet** | (express middleware) | Sets security headers (CSP, HSTS, X-Frame-Options) |
| 4 | **Compression** | (express middleware) | Gzip compression for all responses |
| 5 | **CORS** | (express middleware) | Origin validation (strict in production) |
| 6 | **HTTP Logger** | `httpLogger.js` | Structured request logging (Pino) |
| 7 | **Rate Limiter** | (express-rate-limit) | Auth: stricter limits / API: general limits |
| 8 | **Feature Flags** | `featureFlags.js` | Gates routes behind feature toggles |

Per-route middleware (applied selectively):
- **Auth** (`auth.js`) — JWT verification + role checking
- **Validate** (`validate.js`) — Input validation (express-validator)
- **Fraud Prevention** (`fraudPrevention.js`) — Transaction velocity, suspicious patterns
- **Cache** (`cache.js`) — Redis response caching
- **Error Handler** (`errorHandler.js`) — Global error handler (catches all)

---

## ⚙️ Backend Services

| Service | File | Description |
|---------|------|-------------|
| **Email** | `email.js` | SendGrid email service (booking confirmations, KYC, etc.) |
| **SMS** | `sms.js` | SMS via MSG91 or Twilio (OTP, booking updates) |
| **Push Notifications** | `pushNotification.js` | FCM push notifications + device token management |
| **Payments** | `razorpay.js` | Razorpay integration (orders, verify, refund, subscriptions) |
| **Storage** | `storage.js` | File storage (S3/R2 for production, local for dev) |
| **Face Match** | `faceMatch.js` | KYC face matching (HyperVerge/Rekognition/mock) |
| **GST Invoice** | `gstInvoice.js` | PDF invoice generation (PDFKit) |
| **AI** | `ai.js` | AI-powered features |
| **Job Queue** | `jobQueue.js` | In-memory async job queue with retry logic |

---

## ⏰ Cron Jobs

All scheduled jobs run from `backend/src/workers/cron.js`:

| Job | Schedule | Description |
|-----|----------|-------------|
| `reputation_score_recalc` | Nightly 02:00 IST | Recalculates Trust Index (0-100) for all professionals using 7-factor weighted formula |
| `subscription_expiry_checker` | Daily 09:00 IST | Checks for expiring subscriptions, sends warnings |
| `subscription_grace_enforcer` | Daily 00:05 IST | Enforces grace period expiry, downgrades expired subscriptions |
| `inactive_profile_checker` | Weekly Sunday 03:00 IST | Flags inactive professional profiles |
| `review_velocity_detector` | Every 5 minutes | Detects suspicious review patterns (velocity-based fraud detection) |
| `stale_device_token_cleaner` | Weekly Monday 04:00 IST | Removes stale/expired FCM device tokens |

---

## 🔄 Real-time & WebSocket

The WebSocket server (`backend/src/realtime/hub.js`) uses the `ws` library (not Socket.IO):

- **Protocol:** Raw WebSocket (lighter than Socket.IO, no auto-reconnect)
- **Authentication:** JWT token passed as query parameter
- **Features:**
  - Real-time chat messaging
  - Typing indicators
  - Read receipts
  - Booking status updates
  - Emergency broadcasts
  - Live GPS tracking coordinates
- **Client connections:** React (`WebSocketContext.jsx`) and Flutter (`realtime_service.dart`)

---

## 🧪 Testing

### Backend Tests (16 suites, 150 tests)

```bash
cd backend
npm test                           # Jest with --forceExit --detectOpenHandles
npm run test:coverage              # With coverage report
```

| Test Suite | File | Coverage |
|-----------|------|----------|
| Auth | `auth.test.js` | Login, register, refresh, logout |
| Bookings | `bookings.test.js` | CRUD, FSM transitions, role gating |
| Categories | `categories.test.js` | List, hierarchy, search |
| Reviews | `reviews.test.js` | Create, edit, delete, moderation |
| Search | `search.test.js` | Text search, geo-spatial, filters |
| Messages | `messages.test.js` | Threads, send, receive |
| KYC | `kyc.test.js` | Upload, approve, reject |
| Dashboard | `dashboard.test.js` | Analytics, metrics |
| Disputes | `disputes.test.js` | Create, resolve, evidence |
| Emergency | `emergency.test.js` | Dispatch, status updates |
| Warranties | `warranties.test.js` | Claim, track, resolve |
| Referrals | `referrals.test.js` | Generate, track, reward |
| Schedule | `schedule.test.js` | Availability, blocked dates |
| Agents | `agents.test.js` | Registration, commission, wallet |
| Analytics | `analytics.test.js` | Event tracking, aggregation |
| Storefront | `storefront.test.js` | CRUD, media, themes |

### Frontend Tests

```bash
cd frontend
npm test                           # Vitest
```

### Load Tests (k6)

```bash
# API load test
k6 run tests/load/api.load.js

# WebSocket load test
k6 run tests/load/websocket.load.js
```

### Build Verification

```bash
# Backend syntax check
cd backend && node -c src/app.js

# Frontend build
cd frontend && npm run build

# Full build pipeline (7 steps)
./build.sh
```

---

## 📦 Deployment

### Docker Compose (7 Services)

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| `db` | `postgres:16-alpine` | 5432 | PostgreSQL with auto-init from migrations |
| `redis` | `redis:7-alpine` | 6379 | Redis with AOF persistence, 256MB LRU |
| `backend` | Custom (Node.js) | 5000 | Express API server |
| `frontend` | Custom (nginx) | 3000 | React SPA (nginx serving) |
| `pgbouncer` | `bitnami/pgbouncer:1.22.1` | 6432 | Connection pooling (transaction mode, 500 max) |
| `prometheus` | `prom/prometheus:v2.51.2` | 9090 | Metrics with 7-day retention |
| `grafana` | `grafana/grafana:10.4.2` | 3001 | Dashboards (admin/skillconnect_local) |

### Kubernetes

Kubernetes manifests in `k8s/base/`:

- **Deployments:** Backend + Frontend with resource limits
- **StatefulSets:** PostgreSQL + Redis with persistent volumes
- **HPA:** Horizontal Pod Autoscaler (CPU/memory-based)
- **Ingress:** TLS-terminated ingress
- **CronJob:** Automated database backups
- **ConfigMap:** Application configuration
- **Secret:** Credentials template

### CI/CD

`.github/workflows/ci.yml` — Automated pipeline for linting, testing, and building.

### Build Pipeline (`build.sh`)

7-step pipeline:
1. Apply database migrations
2. Restart backend server
3. Run Jest test suites
4. Smoke-test API endpoints (auth, bookings, messages, search, dashboard)
5. Flutter analyze
6. Build Flutter web
7. Build Flutter APK

---

## 📊 Monitoring & Observability

### Prometheus Metrics

- HTTP request duration (histogram, per route)
- HTTP request count (counter, per status code)
- Custom business metrics via `prom-client`
- Endpoint: `/metrics` (localhost-only in production)

### Grafana Dashboards

- Auto-provisioned datasource (Prometheus)
- Auto-provisioned dashboard provider
- Access: `localhost:3001` (admin / skillconnect_local)

### Alerting

Alert rules defined in `monitoring/alerts.yml`:
- High error rate
- Slow response times
- Database connectivity issues
- Service health degradation

### Structured Logging

- **Pino** logger with JSON output
- Request correlation IDs (every log line traceable)
- PII redaction in logs
- HTTP request/response logging via `httpLogger.js`

### Error Tracking

- **Sentry** integration (`@sentry/node`)
- Automatic error capture with context
- Performance monitoring

---

## 🔒 Security & Compliance

### Authentication

- JWT access tokens (configurable expiry)
- Refresh token rotation with blacklist
- bcrypt password hashing
- Rate limiting on auth endpoints (express-rate-limit)
- 4 user roles: `customer`, `professional`, `agent`, `admin`

### Security Headers

- Helmet.js (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)
- CORS with strict origin validation in production
- Request correlation IDs for audit trail

### Fraud Prevention

- Transaction velocity checks
- Duplicate booking prevention
- Suspicious pattern detection
- Review velocity detection (cron, every 5 min)
- IP-based and behavior-based flagging

### Data Protection (DPDPA 2023)

- User data export endpoint (DPDPA §11)
- Account soft deletion with grace period
- PII encryption (AES-256, optional)
- Consent tracking (`consent_records` table)
- Audit logging (`audit_log`, `admin_audit_log`)
- Banned phone/ID tracking

### Legal Pages (6 published)

1. Terms of Service (`/terms`)
2. Privacy Policy — DPDPA compliant (`/privacy`)
3. Refund Policy (`/refund-policy`)
4. Cookie Policy (`/cookie-policy`)
5. Professional Terms (`/professional-terms`)
6. Content Moderation Policy (`/content-moderation`)

### Operational Security Documents

- `THREAT_MODEL.md` — STRIDE threat analysis
- `INCIDENT_RESPONSE.md` — Incident response playbook
- `SECRETS.md` — Secrets management guide
- `RUNBOOKS.md` — Operational runbooks
- `ARCHITECTURE.md` — System architecture document

---

## 🌍 Internationalization (i18n)

### Mobile (3 languages)

| Language | File | Status |
|----------|------|--------|
| English | `l10n/app_en.arb` | ✅ Complete |
| Hindi | `l10n/app_hi.arb` | ✅ Complete |
| Telugu | `l10n/app_te.arb` | ✅ Complete |

### Voice Search

Speech-to-text support for all 3 languages via `speech_to_text` package (mobile only).

### Frontend

English only. Backend is localization-ready (string externalization).

---

## 📚 Documentation

### Root-Level Documents

| File | Description |
|------|-------------|
| `README.md` | This file — comprehensive project documentation |
| `ARCHITECTURE.md` | System architecture and design decisions |
| `INCIDENT_RESPONSE.md` | Incident response procedures |
| `RUNBOOKS.md` | Operational runbooks for common tasks |
| `THREAT_MODEL.md` | STRIDE-based threat model |
| `SECRETS.md` | Secrets management guide |
| `PLATFORM_CHANGE_RECORD.md` | Platform change log |
| `claude.md` | AI agent implementation guide (phases 4-12) |
| `ready.md` | Production readiness checklist |

### Analysis Documents (30 files in `plans/`)

| Category | Files | Description |
|----------|-------|-------------|
| Master Analysis | `00_MASTER_ANALYSIS.md` | Overall codebase analysis |
| PRD Sections | `PRD_SEC01` – `PRD_SEC20` (16 files) | Product requirement analysis per section |
| Tech Supplements | `TECH_A` – `TECH_J` (10 files) | Technical deep-dives (DB, architecture, security, etc.) |

---

## 🤝 Contributing

```bash
# 1. Fork the repository
# 2. Create your feature branch
git checkout -b feature/your-feature

# 3. Make changes and test
cd backend && npm test
cd frontend && npm run build

# 4. Commit with conventional commits
git commit -m "feat: add new feature"

# 5. Push and create PR
git push origin feature/your-feature
```

### Development Commands

```bash
# Backend
cd backend
npm run dev              # Start with nodemon (auto-reload)
npm test                 # Run all 150 tests
npm run test:coverage    # Tests with coverage report
npm run lint             # ESLint check
npm run lint:fix         # ESLint auto-fix

# Frontend
cd frontend
npm run dev              # Vite dev server (HMR)
npm run build            # Production build
npm run preview          # Preview production build
npm test                 # Vitest

# Mobile
cd mobile/skillconnect
flutter pub get          # Install dependencies
flutter run              # Run on device/emulator
flutter analyze          # Static analysis
flutter test             # Run tests

# Full stack
docker compose up --build    # Start all 7 services
./build.sh                   # Full 7-step build pipeline
```

---

## 📄 License

This project is licensed under the **ISC License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with ❤️ for India's skilled professionals**

*SkillConnect — Build your professional business online*

</div>
