<div align="center">

<!-- ═══════════════════════════════════════════════════════════════
     SkillConnect — World-Class README Documentation
     Inspired by: React, Next.js, Flutter, Supabase, Stripe
     ═══════════════════════════════════════════════════════════════ -->

<img src="https://img.shields.io/badge/🛠️_SkillConnect-India's_Premier_Hyperlocal_Service_Marketplace-blue?style=for-the-badge&labelColor=1a1a2e&color=16213e" alt="SkillConnect" width="800"/>

<br/><br/>

# 🛠️ SkillConnect

### *India's Premier Hyperlocal Service Marketplace Platform*

<br/>

[![Node.js](https://img.shields.io/badge/Node.js-22+-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![React](https://img.shields.io/badge/React-19-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.8-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org/)
[![Express](https://img.shields.io/badge/Express-5-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com/)
[![Razorpay](https://img.shields.io/badge/Razorpay-Integrated-528FF0?style=for-the-badge&logo=razorpay&logoColor=white)](https://razorpay.com/)
[![WebSocket](https://img.shields.io/badge/WebSocket-Real--time-010101?style=for-the-badge&logo=socketdotio&logoColor=white)](#-real-time-features)

<br/>

[![License: ISC](https://img.shields.io/badge/License-ISC-green?style=flat-square)](https://opensource.org/licenses/ISC)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)](http://makeapullrequest.com)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow?style=flat-square)](https://conventionalcommits.org)
[![Code Style: ESLint](https://img.shields.io/badge/Code%20Style-ESLint-4B32C3?style=flat-square&logo=eslint)](https://eslint.org)
[![Test Coverage: 50%+](https://img.shields.io/badge/Coverage-50%25+-brightgreen?style=flat-square)](#-testing)
[![API Endpoints: 75+](https://img.shields.io/badge/API_Endpoints-75+-blue?style=flat-square)](#-api-reference)
[![Languages: EN|HI|TE](https://img.shields.io/badge/Languages-EN%20|%20HI%20|%20TE-orange?style=flat-square)](#-internationalization-i18n)

<br/>

> **A production-grade, full-stack marketplace connecting customers with KYC-verified skilled professionals — featuring real-time GPS tracking, integrated Razorpay payments, multilingual voice search, offline-first mobile, dispute resolution, warranty protection, and enterprise-grade security across 50+ service categories.**

<br/>

[🚀 Quick Start](#-quick-start) •
[📱 Mobile App](#-mobile-app-flutter) •
[🔌 API Reference](#-api-reference) •
[🏗️ Architecture](#%EF%B8%8F-system-architecture) •
[🧪 Testing](#-testing) •
[📦 Deployment](#-deployment) •
[🔒 Security](#-security--compliance) •
[❓ FAQ](#-frequently-asked-questions)

---

**📈 Codebase at a Glance**

| 📦 Components | 📊 Metrics | 🧪 Quality |
|:---:|:---:|:---:|
| 3 platforms (Web + Mobile + API) | 267+ source files | 50%+ test coverage |
| 29 backend controllers | 75+ API endpoints | ESLint + Flutter Lints |
| 30+ frontend pages | 20+ database tables | 11 backend test suites |
| 22+ mobile screens | 14,460 LOC (Dart) | Conventional Commits |

**📋 Implementation Status (vs PRD v1.0 + Technical Supplement v1.0)**

| Document | Score | Status |
|:---:|:---:|:---:|
| PRD v1.0 (Features) | **7.1 / 10** | ⚠️ Sprint plans in `plans/` |
| Technical Supplement (Architecture) | **5.0 / 10** | ⚠️ Sprint plans in `plans/` |
| **Combined** | **6.1 / 10** | 🚀 Sprints 1–7 planned |

> 📂 See [`plans/00_MASTER_ANALYSIS.md`](./plans/00_MASTER_ANALYSIS.md) for the full deep-dive rating and [`plans/`](./plans/) for per-section sprint plans.

---

</div>

## 📋 Table of Contents

<details>
<summary><strong>🗂️ Click to expand full navigation (30+ sections)</strong></summary>

**Fundamentals**
- [Overview](#-overview)
- [Key Features](#-key-features)
- [Competitor Comparison](#-competitor-comparison)
- [System Architecture](#️-system-architecture)
- [Tech Stack](#-tech-stack)

**Getting Started**
- [Quick Start](#-quick-start)
- [Backend API Server](#-backend-api-server)
- [Frontend Web App](#-frontend-web-app-react)
- [Mobile App (Flutter)](#-mobile-app-flutter)
- [Environment Configuration](#-environment-configuration)

**Database**
- [Database Schema & ER Diagram](#-database)
- [Data Models Reference](#-data-models-reference)

**API**
- [API Reference](#-api-reference)
- [API Usage Examples (curl)](#-api-usage-examples)
- [Error Handling & Response Format](#-error-handling--response-format)
- [WebSocket Protocol Reference](#-websocket-protocol-reference)

**Core Systems**
- [Booking State Machine (FSM)](#-booking-state-machine-deep-dive)
- [Reputation Algorithm](#-reputation-algorithm)
- [Security & Compliance](#-security--compliance)
- [Real-Time Features](#-real-time-features)
- [Payment Integration](#-payment-integration)
- [Fraud Prevention System](#-fraud-prevention-system)
- [KYC Verification Pipeline](#-kyc-verification-pipeline)

**Mobile**
- [Internationalization (i18n)](#-internationalization-i18n)
- [Offline-First Architecture](#-offline-first-architecture)
- [Voice Search System](#-voice-search-system)

**Operations**
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Monitoring & Observability](#-monitoring--observability)
- [Troubleshooting](#-troubleshooting)

**Reference**
- [Project Structure](#-project-structure)
- [Service Categories](#-service-categories)
- [Performance & Scalability](#-performance--scalability)
- [Accessibility](#-accessibility)
- [Contributing](#-contributing)
- [Roadmap](#-roadmap)
- [AI Integration](#-ai-integration-new)
- [FAQ](#-frequently-asked-questions)
- [Acknowledgments & Inspiration](#-acknowledgments--inspiration)
- [License](#-license)

**Implementation Analysis**
- [Master Analysis — plans/00_MASTER_ANALYSIS.md](./plans/00_MASTER_ANALYSIS.md)
- [PRD §6.1 Registration — plans/PRD_SEC01_Registration.md](./plans/PRD_SEC01_Registration.md)
- [PRD §6.2 Profile — plans/PRD_SEC02_Profile.md](./plans/PRD_SEC02_Profile.md)
- [PRD §6.3 Categories — plans/PRD_SEC03_Categories.md](./plans/PRD_SEC03_Categories.md)
- [PRD §6.4 Search — plans/PRD_SEC04_Search.md](./plans/PRD_SEC04_Search.md)
- [PRD §6.5 Portfolio — plans/PRD_SEC05_Portfolio.md](./plans/PRD_SEC05_Portfolio.md)
- [PRD §6.6 Reputation — plans/PRD_SEC06_Reputation.md](./plans/PRD_SEC06_Reputation.md)
- [PRD §6.7 Contact — plans/PRD_SEC07_Contact.md](./plans/PRD_SEC07_Contact.md)
- [PRD §8 Database — plans/PRD_SEC08_Database.md](./plans/PRD_SEC08_Database.md)
- [PRD §9 API Design — plans/PRD_SEC09_API.md](./plans/PRD_SEC09_API.md)
- [PRD §10 Architecture — plans/PRD_SEC10_Architecture.md](./plans/PRD_SEC10_Architecture.md)
- [PRD §11 Security — plans/PRD_SEC11_Security.md](./plans/PRD_SEC11_Security.md)
- [PRD §12 Notifications — plans/PRD_SEC12_Notifications.md](./plans/PRD_SEC12_Notifications.md)
- [PRD §13 Moderation — plans/PRD_SEC13_Moderation.md](./plans/PRD_SEC13_Moderation.md)
- [PRD §14 Monetisation — plans/PRD_SEC14_Monetisation.md](./plans/PRD_SEC14_Monetisation.md)
- [PRD §15 Go-to-Market — plans/PRD_SEC15_GoToMarket.md](./plans/PRD_SEC15_GoToMarket.md)
- [PRD §16 UI/UX — plans/PRD_SEC16_UIUX.md](./plans/PRD_SEC16_UIUX.md)
- [PRD §19 Compliance — plans/PRD_SEC19_Compliance.md](./plans/PRD_SEC19_Compliance.md)
- [PRD §20 Roadmap — plans/PRD_SEC20_Roadmap.md](./plans/PRD_SEC20_Roadmap.md)
- [Tech Supplement §A DB Gaps — plans/TECH_A_DatabaseGaps.md](./plans/TECH_A_DatabaseGaps.md)
- [Tech Supplement §B Architecture — plans/TECH_B_SystemArchitecture.md](./plans/TECH_B_SystemArchitecture.md)
- [Tech Supplement §C Microservices — plans/TECH_C_Microservices.md](./plans/TECH_C_Microservices.md)
- [Tech Supplement §D DevOps — plans/TECH_D_DevOps.md](./plans/TECH_D_DevOps.md)
- [Tech Supplement §E Design System — plans/TECH_E_UIDesignSystem.md](./plans/TECH_E_UIDesignSystem.md)
- [Tech Supplement §F Components — plans/TECH_F_ComponentLibrary.md](./plans/TECH_F_ComponentLibrary.md)
- [Tech Supplement §G Security — plans/TECH_G_Security.md](./plans/TECH_G_Security.md)
- [Tech Supplement §H Performance — plans/TECH_H_Performance.md](./plans/TECH_H_Performance.md)
- [Tech Supplement §I Observability — plans/TECH_I_Observability.md](./plans/TECH_I_Observability.md)
- [Tech Supplement §J DR — plans/TECH_J_DisasterRecovery.md](./plans/TECH_J_DisasterRecovery.md)

</details>

---

## 🌟 Overview

**SkillConnect** is a comprehensive hyperlocal services marketplace designed for the Indian market — think **Urban Company meets Swiggy** for skilled services. It empowers customers to discover, book, track, and pay verified professionals across 50+ service categories while giving professionals tools to manage their business, schedule, earnings, and reputation.

### 🎯 Problem Statement

In India, finding reliable skilled professionals (plumbers, electricians, beauticians, tutors) remains fragmented and trust-deficient. Customers struggle with:
- ❌ No verification of skills or identity
- ❌ Opaque pricing and hidden charges
- ❌ No accountability for service quality
- ❌ Language barriers in tier-2/3 cities
- ❌ Cash-only transactions with no digital trail

### ✅ Our Solution

SkillConnect provides a **trust-first, mobile-native platform** with:
- ✅ KYC-verified professionals (Aadhaar + selfie + government ID)
- ✅ Transparent pricing with upfront quotes
- ✅ Real-time GPS tracking during service delivery
- ✅ Integrated Razorpay payments with warranty protection
- ✅ Multilingual support (English, Hindi, Telugu)
- ✅ Offline-first mobile app for low-connectivity areas
- ✅ AI-powered fraud prevention and dispute resolution

---

## 🏆 Key Features

### 👥 For Customers

| Feature | Description |
|---------|-------------|
| 🔍 **Smart Search** | Location-based discovery with radius, rating, price, and availability filters |
| 📍 **Live Tracking** | Real-time GPS tracking of professional en route (Swiggy-style) |
| 💳 **Secure Payments** | Razorpay integration with escrow-like booking deposits |
| ⭐ **Verified Reviews** | Only customers who completed bookings can review |
| 🛡️ **Warranty Protection** | Post-service warranty claims with automated re-booking |
| 🚨 **Emergency Services** | Priority dispatch for urgent requests (plumbing leaks, electrical faults) |
| 🎙️ **Voice Search** | Speech-to-text search in Hindi, Telugu, and English |
| ❤️ **Favorites** | Save and quickly rebook trusted professionals |
| 📱 **Offline Mode** | Browse cached data, queue bookings when connectivity returns |
| 🎁 **Referral Rewards** | Earn credits by referring friends |

### 👷 For Professionals

| Feature | Description |
|---------|-------------|
| 📊 **Business Dashboard** | Earnings analytics, booking pipeline, performance metrics |
| 📅 **Schedule Manager** | Weekly availability slots, blocked dates, auto-conflict detection |
| 🏅 **Trust Badges** | KYC verified, top-rated, fast-responder badges |
| 💼 **Portfolio Builder** | Upload photos, videos, certificates to showcase work |
| 💰 **Earnings Tracker** | Daily/weekly/monthly breakdown with payout history |
| 🔔 **Smart Notifications** | New booking alerts, payment confirmations, review prompts |
| 📈 **Reputation Score** | Weighted algorithm (ratings × jobs × response time × complaints) |
| 🆘 **Emergency Toggle** | Opt-in to receive high-priority emergency requests |

### 🔧 For Administrators

| Feature | Description |
|---------|-------------|
| 👁️ **Admin Dashboard** | Platform-wide analytics, user management, content moderation |
| ⚖️ **Dispute Resolution** | Review evidence, mediate conflicts, issue refunds |
| 🚫 **Fraud Prevention** | Automated bot detection, duplicate booking prevention, suspicious pattern flagging |
| 📋 **KYC Management** | Approve/reject professional verification documents |
| 📊 **Analytics Engine** | User acquisition funnels, retention metrics, revenue dashboards |

---

## 🏆 Competitor Comparison

<div align="center">

| Feature | SkillConnect | Urban Company | Sulekha | Justdial | Housejoy |
|---------|:---:|:---:|:---:|:---:|:---:|
| KYC-Verified Professionals | ✅ | ✅ | ❌ | ❌ | ✅ |
| Real-time GPS Tracking | ✅ | ✅ | ❌ | ❌ | ❌ |
| Booking State Machine (FSM) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Integrated Payments (Razorpay) | ✅ | ✅ | ❌ | ❌ | ✅ |
| Dispute Resolution System | ✅ | ✅ | ❌ | ❌ | ❌ |
| Warranty Protection | ✅ | ✅ | ❌ | ❌ | ❌ |
| Emergency Service Dispatch | ✅ | ❌ | ❌ | ❌ | ❌ |
| Voice Search (Regional) | ✅ Hindi/Telugu | ❌ | ❌ | ❌ | ❌ |
| Offline-First Mobile | ✅ | ❌ | ❌ | ❌ | ❌ |
| Multilingual (3 languages) | ✅ EN/HI/TE | Partial | ❌ | ❌ | ❌ |
| Open Source | ✅ | ❌ | ❌ | ❌ | ❌ |
| Voice Notes in Chat | ✅ | ❌ | ❌ | ❌ | ❌ |
| Reputation Algorithm | ✅ Weighted | Basic | ❌ | Basic | ❌ |
| Referral Program | ✅ | ✅ | ❌ | ❌ | ❌ |
| 50+ Service Categories | ✅ | ✅ | ✅ | ✅ | ❌ |
| Fraud Prevention (Automated) | ✅ | ✅ | ❌ | ❌ | ❌ |
| WebSocket Real-time Chat | ✅ | ✅ | ❌ | ❌ | ❌ |
| Self-Hosted / On-Premise | ✅ | ❌ | ❌ | ❌ | ❌ |

</div>

> **What makes SkillConnect unique:** Fully open-source, self-hostable, offline-first mobile with regional voice search (Hindi/Telugu), combined with enterprise features like FSM-driven bookings, automated fraud prevention, and warranty protection — all in a single deployable stack.

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CLIENT APPLICATIONS                               │
├───────────────────┬───────────────────────┬─────────────────────────────────┤
│   📱 Flutter App  │   🌐 React Web App    │   🔧 Admin Portal               │
│   (Android/iOS)   │   (Customer Portal)   │   (Internal Dashboard)          │
│   • Offline-first │   • SPA with Vite     │   • User management             │
│   • Voice search  │   • Real-time chat    │   • KYC approvals               │
│   • GPS tracking  │   • Responsive UI     │   • Dispute handling            │
│   • Push notifs   │   • Bottom navigation │   • Analytics                   │
└────────┬──────────┴───────────┬───────────┴──────────────────┬──────────────┘
         │                      │                               │
         │              ┌───────▼───────────────────────────────▼───┐
         │              │          🔀 NGINX Reverse Proxy            │
         │              │    (SSL termination, static serving)       │
         │              └───────────────────┬───────────────────────┘
         │                                  │
         ▼                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          🖥️ BACKEND API SERVER                               │
│                          Node.js + Express 5                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   🔐 Auth    │  │  📦 Booking  │  │  💬 Message  │  │  💳 Payment  │   │
│  │   Module     │  │   FSM Engine │  │   Hub (WS)   │  │   Gateway    │   │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤   │
│  │ JWT + Refresh│  │ State Machine│  │ WebSocket RT │  │  Razorpay    │   │
│  │ bcrypt hash  │  │ Role gating  │  │ Typing/read  │  │  Orders      │   │
│  │ Rate limit   │  │ Auto-notify  │  │ Media share  │  │  Refunds     │   │
│  │ Lockout      │  │ FSM guards   │  │ Voice notes  │  │  Webhooks    │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  🔍 Search   │  │  📊 Analytics│  │  🛡️ Security │  │  📍 Location │   │
│  │   Engine     │  │   Engine     │  │   Layer      │  │   Services   │   │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤   │
│  │ Geo-spatial  │  │ Event track  │  │ Fraud detect │  │  Haversine   │   │
│  │ Full-text    │  │ Funnels      │  │ CORS strict  │  │  Radius calc │   │
│  │ Multi-filter │  │ Dashboards   │  │ Helmet CSP   │  │  Proximity   │   │
│  │ Pagination   │  │ Retention    │  │ Input valid  │  │  Emergency   │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│  Middleware: requestId → httpLogger → helmet → compression → cors →         │
│             rateLimit → auth → validate → fraudPrevention → cache           │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         🗄️ DATA & SERVICES LAYER                             │
├──────────────────────────┬──────────────────────────────────────────────────┤
│   PostgreSQL 16          │   External Services                               │
│   ├── users              │   ├── Razorpay (payments)                        │
│   ├── professionals      │   ├── SMS Gateway (OTP)                          │
│   ├── bookings (FSM)     │   ├── Email Service (notifications)              │
│   ├── message_threads    │   ├── Push Notifications (FCM)                   │
│   ├── payments           │   ├── Cloud Storage (uploads)                    │
│   ├── disputes           │   └── Job Queue (async tasks)                    │
│   ├── warranties         │                                                   │
│   ├── emergency_requests │                                                   │
│   ├── analytics_events   │                                                   │
│   └── 20+ more tables    │                                                   │
└──────────────────────────┴──────────────────────────────────────────────────┘
```

### 🔄 Booking State Machine (FSM)

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
    ※ Role-gated transitions (PRO_ONLY / CUSTOMER_ONLY)
```

### 🔄 Booking State Machine Deep Dive

The booking controller implements a **server-enforced finite state machine** with role-gated transitions:

```javascript
// Allowed transitions (from bookingController.js)
const FSM = {
  requested:   ['quoted', 'cancelled'],
  quoted:      ['accepted', 'cancelled'],
  accepted:    ['scheduled', 'cancelled'],
  scheduled:   ['in_progress', 'cancelled'],
  in_progress: ['completed', 'disputed', 'cancelled'],
  completed:   ['disputed', 'refunded'],
  disputed:    ['refunded', 'completed'],
  cancelled:   [],      // Terminal state
  refunded:    [],      // Terminal state
};

// Role gating
const PRO_ONLY = ['quoted', 'in_progress', 'completed'];
const CUSTOMER_ONLY = ['accepted'];
```

<details>
<summary><strong>📋 Detailed State Transition Rules</strong></summary>

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

Every transition:
1. ✅ Validates via FSM lookup
2. ✅ Checks role authorization (PRO_ONLY / CUSTOMER_ONLY)
3. ✅ Logs to `booking_status_log` with actor + timestamp
4. ✅ Sends real-time WebSocket notification to both parties
5. ✅ Triggers push notification via `notifier.js`

</details>

---

## 💻 Tech Stack

### Core Technologies

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Mobile** | Flutter / Dart | 3.8+ | Cross-platform native app (Android + iOS + Web) |
| **Frontend** | React | 19.2 | Customer-facing web SPA |
| **Bundler** | Vite | 8.0 | Lightning-fast HMR and builds |
| **Routing** | React Router | 7.x | Client-side navigation |
| **Backend** | Node.js + Express | 5.2 | RESTful API server |
| **Database** | PostgreSQL | 16 | Relational data with geo-spatial queries |
| **Real-time** | WebSocket (ws) | 8.x | Live chat, tracking, notifications |
| **Auth** | JWT + bcrypt | - | Stateless auth with refresh tokens |

### Backend Dependencies

| Package | Purpose |
|---------|---------|
| `express` | HTTP framework with async error handling |
| `pg` | PostgreSQL client with connection pooling |
| `jsonwebtoken` | JWT token generation and verification |
| `bcryptjs` | Password hashing (10 salt rounds) |
| `helmet` | Security headers (CSP, HSTS, XSS protection) |
| `express-rate-limit` | Brute-force and DDoS protection |
| `express-validator` | Request body/query validation |
| `multer` | Multipart file upload handling |
| `ws` | WebSocket server for real-time features |
| `pino` | Structured JSON logging (production-grade) |
| `compression` | Gzip response compression |
| `uuid` | UUID v4 generation for entities |
| `cors` | Cross-Origin Resource Sharing |

### Mobile Dependencies (Flutter)

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `http` | REST API client |
| `web_socket_channel` | Real-time WebSocket communication |
| `geolocator` | GPS location services |
| `speech_to_text` | Voice search (Hindi/Telugu/English) |
| `hive` + `hive_flutter` | Offline-first local storage |
| `connectivity_plus` | Network state monitoring |
| `cached_network_image` | Image caching with placeholders |
| `image_picker` | Camera/gallery media selection |
| `record` + `audioplayers` | Voice note recording and playback |
| `table_calendar` | Schedule visualization |
| `share_plus` | Native sharing |
| `url_launcher` | Phone calls, maps, external links |
| `flutter_rating_bar` | Star rating input |
| `shared_preferences` | Lightweight key-value persistence |
| `intl` | Date/number formatting + i18n |

### DevOps & Testing

| Tool | Purpose |
|------|---------|
| Docker + Docker Compose | Containerized local development |
| Jest + Supertest | Backend unit & integration tests |
| Vitest + Testing Library | Frontend component tests |
| Flutter Test | Mobile widget and integration tests |
| ESLint | JavaScript/Node.js linting |
| flutter_lints | Dart static analysis |

---

## 🚀 Quick Start

### Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Node.js | 18+ | Backend + Frontend build |
| PostgreSQL | 14+ | Primary datastore |
| Flutter SDK | 3.8+ | Mobile app development |
| Docker | 24+ | *(Optional)* Containerized setup |

### ⚡ One-Command Setup (Docker)

```bash
# Clone the repository
git clone https://github.com/Govin111b8/SKILL.git
cd SKILL

# Start all services (PostgreSQL + Backend + Frontend)
docker-compose up --build

# 🎉 Services available at:
#   Backend API  → http://localhost:5000
#   Frontend     → http://localhost:3000
#   Database     → localhost:5432
```

### 🔧 Manual Setup

<details>
<summary><strong>Step-by-step manual installation</strong></summary>

#### 1️⃣ Database Setup

```bash
# Create database
createdb skillconnect

# Apply schema (creates all tables, enums, indexes)
psql skillconnect < database/schema.sql

# Apply migrations (bookings, KYC, analytics, etc.)
for f in database/migrations/*.sql; do psql skillconnect < "$f"; done

# Seed categories and sample data
psql skillconnect < database/seed.sql
```

#### 2️⃣ Backend Setup

```bash
cd backend

# Configure environment
cp .env.example .env
# Edit .env with your database credentials, JWT secret, etc.

# Install dependencies
npm install

# Start development server (with hot-reload)
npm run dev

# ✅ API running at http://localhost:5000
# ✅ Health check: GET http://localhost:5000/api/health
```

#### 3️⃣ Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start dev server (Vite HMR)
npm run dev

# ✅ App running at http://localhost:5173
```

#### 4️⃣ Mobile App Setup

```bash
cd mobile/skillconnect

# Get Flutter dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run on connected device/emulator
flutter run

# Build release APK
flutter build apk --release
```

</details>

---

## ⚙️ Environment Configuration

<details>
<summary><strong>📋 Complete Environment Variable Reference</strong></summary>

The backend uses centralized config (`backend/src/config/index.js`) with **fail-fast validation** in production:

```javascript
// Production startup will THROW if these are missing:
const requiredInProduction = ['JWT_SECRET', 'DB_HOST', 'DB_PASSWORD'];
// JWT_SECRET must be ≥ 32 characters in production
```

#### Core Server

| Variable | Default | Required | Description |
|----------|---------|:--------:|-------------|
| `NODE_ENV` | `development` | ❌ | `development` / `production` / `test` |
| `PORT` | `5000` | ❌ | HTTP server port |

#### Database (PostgreSQL)

| Variable | Default | Required | Description |
|----------|---------|:--------:|-------------|
| `DB_HOST` | `localhost` | 🔴 prod | PostgreSQL hostname |
| `DB_PORT` | `5432` | ❌ | PostgreSQL port |
| `DB_NAME` | `skillconnect` | ❌ | Database name |
| `DB_USER` | `postgres` | ❌ | Database username |
| `DB_PASSWORD` | `password` | 🔴 prod | Database password |
| `DB_MAX_CONNECTIONS` | `20` | ❌ | Connection pool max size |
| `DB_IDLE_TIMEOUT` | `30000` | ❌ | Idle connection timeout (ms) |
| `DB_CONNECTION_TIMEOUT` | `5000` | ❌ | Connection attempt timeout (ms) |

#### Authentication (JWT)

| Variable | Default | Required | Description |
|----------|---------|:--------:|-------------|
| `JWT_SECRET` | `dev-secret-change-me` | 🔴 prod | Signing key (min 32 chars in prod) |
| `JWT_EXPIRES_IN` | `15m` | ❌ | Access token TTL |
| `JWT_REFRESH_EXPIRES_IN` | `7d` | ❌ | Refresh token TTL |

#### Security & Rate Limiting

| Variable | Default | Required | Description |
|----------|---------|:--------:|-------------|
| `CORS_ORIGINS` | *(empty)* | ❌ | Comma-separated allowed origins |
| `RATE_LIMIT_AUTH_MAX` | `30` | ❌ | Auth attempts per 15-min window |
| `RATE_LIMIT_API_MAX` | `200` | ❌ | API calls per 1-min window |
| `MAX_LOGIN_ATTEMPTS` | `5` | ❌ | Failed logins before lockout |
| `LOCKOUT_DURATION_MIN` | `15` | ❌ | Account lockout duration (min) |

#### Payment Gateway (Razorpay)

| Variable | Default | Required | Description |
|----------|---------|:--------:|-------------|
| `RAZORPAY_KEY_ID` | *(empty)* | ⚡ for payments | Razorpay API key |
| `RAZORPAY_KEY_SECRET` | *(empty)* | ⚡ for payments | Razorpay secret key |
| `RAZORPAY_WEBHOOK_SECRET` | *(empty)* | ⚡ for webhooks | Webhook signature verification |

#### External Services

| Variable | Default | Required | Description |
|----------|---------|:--------:|-------------|
| `SENDGRID_API_KEY` | *(empty)* | ⚡ for email | SendGrid email delivery |
| `EMAIL_FROM` | `noreply@skillconnect.in` | ❌ | Sender email address |
| `SMS_PROVIDER` | `none` | ⚡ for SMS | SMS provider (`none`/`twilio`/etc) |
| `STORAGE_PROVIDER` | `local` | ❌ | File storage (`local`/`s3`) |
| `S3_BUCKET` | *(empty)* | ⚡ for S3 | AWS S3 bucket name |
| `AWS_REGION` | `ap-south-1` | ❌ | AWS region |
| `FCM_SERVER_KEY` | *(empty)* | ⚡ for push | Firebase Cloud Messaging key |
| `FCM_PROJECT_ID` | *(empty)* | ⚡ for push | Firebase project ID |
| `APP_URL` | `http://localhost:3000` | ❌ | Frontend URL for email links |
| `LOG_LEVEL` | `debug` (dev) / `info` (prod) | ❌ | Pino log level |

> 🔴 = Required in production | ⚡ = Required for specific feature | ❌ = Optional with sensible default

</details>

---

## 🖥️ Backend API Server

### Detailed Architecture Explanation

The backend is a **monolithic but modular** Node.js application following a layered architecture pattern. Each layer has a specific responsibility:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        REQUEST LIFECYCLE                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. HTTP Request arrives at Express                                      │
│     └─ Assigned UUID via requestId middleware                           │
│                                                                          │
│  2. Global Middleware Pipeline (order matters!)                          │
│     ├─ requestId    → Generate X-Request-Id header                      │
│     ├─ httpLogger   → Log method, URL, user-agent (Pino structured)    │
│     ├─ helmet       → Set security headers (CSP, HSTS, X-Frame)        │
│     ├─ compression  → Gzip responses (saves 60-80% bandwidth)          │
│     ├─ cors         → Validate Origin header against whitelist         │
│     ├─ rateLimit    → Token bucket algorithm (IP + user based)         │
│     └─ express.json → Parse JSON body (100kb limit)                    │
│                                                                          │
│  3. Route Matching                                                       │
│     └─ Express Router finds matching route definition                   │
│                                                                          │
│  4. Route-Level Middleware                                               │
│     ├─ authenticate → JWT verification + user extraction               │
│     ├─ authorize    → Role-based access control (RBAC)                 │
│     ├─ validate     → express-validator schema enforcement             │
│     ├─ fraudCheck   → Bot detection, idempotency, patterns             │
│     └─ cache        → LRU cache check (GET requests only)              │
│                                                                          │
│  5. Controller Logic                                                     │
│     ├─ Business logic execution                                         │
│     ├─ Database queries (parameterized SQL via pg)                      │
│     ├─ External service calls (Razorpay, SMS, Email)                   │
│     └─ WebSocket notifications (real-time hub)                          │
│                                                                          │
│  6. Response                                                             │
│     ├─ Standard envelope: { success, data, pagination }                │
│     ├─ Cache storage (for GET 2xx responses)                           │
│     └─ Response logging (status code, duration)                        │
│                                                                          │
│  7. Error Handling (if any step throws)                                  │
│     ├─ errorHandler catches all thrown errors                           │
│     ├─ 4xx → logger.warn + client-friendly message                     │
│     ├─ 5xx → logger.error + sanitized message (production)             │
│     └─ Stack trace included only in development mode                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Authentication System — Deep Dive

The auth system uses a **dual-token strategy** for security:

```
┌─────────────────────────────────────────────────────────────────┐
│                   TOKEN LIFECYCLE                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  LOGIN                                                           │
│  ├─ Client sends email + password                               │
│  ├─ Server checks account lockout status                        │
│  │   └─ If locked: 429 "Account temporarily locked"             │
│  ├─ Server retrieves user from DB by email                      │
│  ├─ bcrypt.compare(password, hash) — 10 salt rounds             │
│  │   ├─ If mismatch: increment failed_login_count               │
│  │   │   └─ If count >= 5: lock for 15 minutes                 │
│  │   └─ If match: reset failed_login_count to 0                │
│  └─ Generate tokens:                                            │
│      ├─ Access Token  (15 min TTL, type: "access")             │
│      │   payload: { id, email, role, iat, exp }                │
│      └─ Refresh Token (7 day TTL, type: "refresh")             │
│          payload: { id, type: "refresh", iat, exp }            │
│                                                                  │
│  AUTHENTICATED REQUEST                                           │
│  ├─ Client sends: Authorization: Bearer <access_token>          │
│  ├─ auth.js middleware:                                         │
│  │   ├─ Extract token from header                              │
│  │   ├─ jwt.verify(token, JWT_SECRET)                          │
│  │   ├─ REJECT if token.type === "refresh"                     │
│  │   │   (prevents refresh token misuse as access token)       │
│  │   ├─ Enrich with is_admin flag from DB (best-effort)        │
│  │   └─ Attach decoded payload to req.user                     │
│  └─ Controller can access req.user.id, req.user.role           │
│                                                                  │
│  TOKEN REFRESH                                                   │
│  ├─ Client sends refresh token in body                          │
│  ├─ Server verifies token.type === "refresh"                   │
│  ├─ Server looks up user by decoded.id                         │
│  └─ Issues new access + refresh token pair                     │
│                                                                  │
│  OPTIONAL AUTH (for search, public profiles)                    │
│  ├─ optionalAuth middleware: same as authenticate               │
│  ├─ But does NOT reject if token is missing                    │
│  └─ Just sets req.user = null (allows search history saving)   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Security Decisions:**
- **Why bcrypt with 10 rounds?** Balances security vs response time (~100ms hash time). Higher rounds for military-grade, lower for high-traffic APIs.
- **Why reject refresh tokens in auth middleware?** Prevents XSS-stolen refresh tokens from granting API access.
- **Why best-effort admin flag?** If DB is temporarily unreachable, regular users still authenticate — just admin endpoints fail gracefully.

### Search Engine — Deep Dive

The search system implements **multi-criteria filtering with Haversine geo-distance**:

```sql
-- The actual search query (simplified from searchController.js):

SELECT 
  p.*, 
  u.name, u.location, u.government_id_verified,
  COALESCE(AVG(r.rating), 0) as average_rating,
  COUNT(DISTINCT r.id) as review_count,
  -- Haversine formula for great-circle distance (Earth = 6371 km)
  (6371 * acos(
    cos(radians($lat)) * cos(radians(p.latitude)) * 
    cos(radians(p.longitude) - radians($lng)) + 
    sin(radians($lat)) * sin(radians(p.latitude))
  )) AS distance
FROM professionals p
JOIN users u ON p.user_id = u.id
LEFT JOIN reviews r ON p.id = r.professional_id
-- Category filter (optional)
JOIN professional_categories pc ON p.id = pc.professional_id
WHERE 
  pc.category_id = $category_id              -- Category filter
  AND (u.name ILIKE '%query%' OR p.headline ILIKE '%query%')  -- Text search
  AND p.pricing_estimate <= $max_price       -- Price filter
  AND p.availability_status = $availability  -- Status filter
GROUP BY p.id, u.id
HAVING COALESCE(AVG(r.rating), 0) >= $min_rating  -- Rating filter
  AND distance <= $radius_km                       -- Geo filter
ORDER BY 
  CASE $sort_by
    WHEN 'reputation' THEN p.reputation_score
    WHEN 'distance' THEN distance
    WHEN 'experience' THEN p.years_of_experience
  END DESC
LIMIT $limit OFFSET $offset;
```

**How the search pipeline works:**

1. **Input Sanitization** — `q.replace(/[%_\\]/g, '\\$&')` escapes LIKE wildcards to prevent pattern injection
2. **Search History** — If user is authenticated, saves query to `search_history` (fire-and-forget, doesn't block response)
3. **Dynamic Query Building** — Conditions are added only if the corresponding filter is provided (no useless WHERE clauses)
4. **Haversine Calculation** — Computes distance in km between user's coordinates and each professional's stored lat/lng
5. **Radius Filtering** — `HAVING distance <= radius_km` removes results outside the search area
6. **Caching** — Results are cached in LRU cache for 60 seconds (cache key = full URL with params)

### LRU Cache System — Deep Dive

The backend implements a **custom LRU (Least Recently Used) cache** for high-read endpoints:

```
┌─────────────────────────────────────────────────────────────────┐
│                   CACHE ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Three independent cache instances:                              │
│                                                                  │
│  ┌───────────────────┐  ┌───────────────────┐                  │
│  │  searchCache       │  │  categoryCache     │                  │
│  │  • max: 200 items │  │  • max: 50 items   │                  │
│  │  • TTL: 60s       │  │  • TTL: 10 min     │                  │
│  │  • For: /search   │  │  • For: /categories │                  │
│  └───────────────────┘  └───────────────────┘                  │
│                                                                  │
│  ┌───────────────────┐                                          │
│  │  providerCache     │                                          │
│  │  • max: 300 items │                                          │
│  │  • TTL: 2 min     │                                          │
│  │  • For: /pro/:id  │                                          │
│  └───────────────────┘                                          │
│                                                                  │
│  How LRU works:                                                  │
│  1. GET → If key exists and not expired → return (HIT)          │
│  2. GET → Move key to "most recently used" position             │
│  3. SET → If at capacity → evict oldest (least recently used)   │
│  4. TTL → Expired entries are garbage-collected on next access  │
│                                                                  │
│  Cache headers:                                                  │
│  • X-Cache: HIT  → Response served from cache                  │
│  • X-Cache: MISS → Response from database (and cached)          │
│                                                                  │
│  Invalidation triggers:                                         │
│  • New booking created → invalidate provider cache              │
│  • Review submitted → invalidate search + provider cache        │
│  • Profile updated → invalidate provider cache                  │
│  • Category changed → invalidate category cache                 │
│                                                                  │
│  Production scaling note:                                       │
│  • Current: handles ~5K concurrent users                       │
│  • At scale: replace with Redis (multi-instance support)        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Job Queue System — Deep Dive

The backend uses an **in-memory priority job queue** for background tasks:

```
┌─────────────────────────────────────────────────────────────────┐
│                   JOB QUEUE ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Queue Properties:                                               │
│  • Concurrency: 3 (max simultaneous jobs)                       │
│  • Max retries: 3 per job (with exponential backoff)           │
│  • Priority: Higher priority jobs execute first                 │
│  • Retry delay: 1000ms × attempt² (1s, 4s, 9s)               │
│                                                                  │
│  Job Types:                                                      │
│  ┌──────────────────┬────────────────────────────────────────┐  │
│  │ notification      │ Push notification via FCM               │  │
│  │ email             │ Transactional email via SendGrid        │  │
│  │ sms               │ OTP/alert via SMS gateway              │  │
│  │ emergency_broadcast│ Notify 10 nearby pros (high priority) │  │
│  │ analytics         │ Event tracking (low priority)          │  │
│  │ reputation_update │ Recalculate pro score                  │  │
│  └──────────────────┴────────────────────────────────────────┘  │
│                                                                  │
│  Flow:                                                           │
│  1. Controller calls queue.add('notification', data)            │
│  2. Job is inserted by priority (higher = sooner execution)     │
│  3. Worker picks up job when concurrency slot available         │
│  4. Handler executes (e.g., send FCM push)                     │
│  5. On failure: retry with backoff (max 3 attempts)            │
│  6. On permanent failure: log error + mark as 'failed'         │
│                                                                  │
│  Batch Processing:                                               │
│  queue.addBulk('notification', [user1, user2, ...])            │
│  → Inserts N jobs at once (e.g., emergency broadcast to 10)    │
│                                                                  │
│  Production Note:                                                │
│  Replace with Bull/BullMQ + Redis for:                          │
│  • Multi-instance worker support                                │
│  • Job persistence across restarts                              │
│  • Dead letter queue                                            │
│  • Job scheduling (delayed execution)                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Emergency Services — Deep Dive

The emergency system implements **priority-based professional dispatch**:

```
┌─────────────────────────────────────────────────────────────────┐
│              EMERGENCY DISPATCH FLOW                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. CUSTOMER creates emergency request                          │
│     POST /api/emergency                                         │
│     Body: { category_id, description, lat, lng, address }       │
│                                                                  │
│  2. SYSTEM finds nearby professionals                           │
│     SQL query with conditions:                                  │
│     • accepts_emergency = TRUE (opted in)                       │
│     • availability_status = 'available' (not busy)              │
│     • category matches (e.g., plumbers for pipe leak)           │
│     • Sorted by Haversine distance (nearest first)             │
│     • LIMIT 10 (top 10 nearest available)                      │
│                                                                  │
│  3. SYSTEM notifies all 10 professionals                        │
│     • Database notification record (for in-app)                │
│     • Job queue: push notification (FCM)                       │
│     • WebSocket: real-time alert (if online)                   │
│     • Special emoji: 🚨 "Emergency Request Nearby"             │
│                                                                  │
│  4. FIRST professional to respond wins                          │
│     PUT /api/emergency/:id/respond                              │
│     • Sets status = 'assigned'                                 │
│     • Records responded_at timestamp                           │
│     • Rejects further responses (404 "already assigned")       │
│     • Notifies customer: "Help is on the way!"                 │
│                                                                  │
│  5. BOOKING auto-created from emergency                         │
│     • Status = 'in_progress' (skips quote/accept flow)         │
│     • GPS tracking activated immediately                       │
│     • Customer sees live location of professional              │
│                                                                  │
│  Race Condition Handling:                                        │
│  • SQL: WHERE status = 'active' (atomic check-and-update)      │
│  • Only first UPDATE succeeds (PostgreSQL row-level locking)    │
│  • Others get "not found or already assigned"                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Warranty System — Deep Dive

```
┌─────────────────────────────────────────────────────────────────┐
│              WARRANTY LIFECYCLE                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. BOOKING COMPLETES → Warranty auto-created                   │
│     • Duration: category.default_warranty_days (default 7)      │
│     • starts_at = booking.completed_at                          │
│     • expires_at = starts_at + warranty_days                    │
│     • Duplicate check: one warranty per booking                 │
│                                                                  │
│  2. WITHIN WARRANTY PERIOD → Customer can claim                 │
│     POST /api/warranties/:id/claim                              │
│     Body: { reason: "Pipe is leaking again" }                  │
│     • Validates: status = 'active' AND expires_at > NOW()      │
│     • Sets status = 'claimed', claimed_at = NOW()              │
│                                                                  │
│  3. CLAIM → Creates re-service booking                          │
│     • Same professional assigned                                │
│     • No additional charge to customer                         │
│     • Status = 'scheduled' (skips quote flow)                  │
│     • Professional notified of warranty claim                  │
│                                                                  │
│  4. RESOLUTION                                                   │
│     • Professional completes re-service → warranty fulfilled   │
│     • If professional declines → admin escalation              │
│     • If expired → customer must create new paid booking       │
│                                                                  │
│  Category-Specific Warranty Periods:                            │
│  ├── Plumbing: 7 days                                          │
│  ├── Electrical: 14 days                                       │
│  ├── Painting: 30 days                                         │
│  ├── Appliance Repair: 7 days                                  │
│  └── Default: 7 days                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Configuration

All configuration is managed via environment variables (`.env`):

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_ENV` | `development` | Environment mode |
| `PORT` | `5000` | Server listen port |
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `skillconnect` | Database name |
| `DB_USER` | `postgres` | Database user |
| `DB_PASSWORD` | - | Database password |
| `DB_MAX_CONNECTIONS` | `20` | Connection pool size |
| `JWT_SECRET` | - | JWT signing secret (min 32 chars) |
| `JWT_EXPIRES_IN` | `15m` | Access token TTL |
| `JWT_REFRESH_EXPIRES_IN` | `7d` | Refresh token TTL |
| `CORS_ORIGINS` | - | Comma-separated allowed origins |
| `RATE_LIMIT_AUTH_MAX` | `30` | Max auth attempts per window |
| `RATE_LIMIT_API_MAX` | `200` | Max API calls per window |
| `MAX_LOGIN_ATTEMPTS` | `5` | Before account lockout |
| `LOCKOUT_DURATION_MIN` | `15` | Lockout duration |
| `RAZORPAY_KEY_ID` | - | Payment gateway key |
| `RAZORPAY_KEY_SECRET` | - | Payment gateway secret |
| `RAZORPAY_WEBHOOK_SECRET` | - | Webhook signature verification |
| `LOG_LEVEL` | `debug` | Pino log level |

### Middleware Pipeline

Requests flow through this middleware stack in order:

```
Request → requestId → httpLogger → helmet → compression → cors → rateLimit
        → express.json → [route handler] → auth → validate → controller
        → errorHandler → Response
```

| Middleware | File | Purpose |
|-----------|------|---------|
| `requestId` | `middleware/requestId.js` | Assigns UUID to each request for tracing |
| `httpLogger` | `middleware/httpLogger.js` | Structured Pino request/response logging |
| `helmet` | Built-in | Security headers (CSP, HSTS, X-Frame) |
| `compression` | Built-in | Gzip/Brotli response compression |
| `cors` | `app.js` | Origin validation with dev-mode bypass |
| `rateLimit` | `app.js` | Brute-force protection (auth: 30/15min, API: 200/15min) |
| `auth` | `middleware/auth.js` | JWT verification, user extraction |
| `validate` | `middleware/validate.js` | express-validator integration |
| `fraudPrevention` | `middleware/fraudPrevention.js` | Bot detection, idempotency, patterns |
| `cache` | `middleware/cache.js` | Response caching for read-heavy endpoints |
| `errorHandler` | `middleware/errorHandler.js` | Centralized error formatting |

---

## 🌐 Frontend Web App (React)

### Frontend Architecture — Deep Dive

The frontend is a **Single Page Application (SPA)** built with React 19 and Vite:

```
┌─────────────────────────────────────────────────────────────────┐
│             FRONTEND ARCHITECTURE                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ENTRY POINT                                                     │
│  main.jsx → wraps App in AuthContext Provider                   │
│  App.jsx  → React Router v7 with route definitions              │
│                                                                  │
│  STATE MANAGEMENT                                                │
│  ├── AuthContext (React Context + useReducer)                   │
│  │   ├── user object (name, email, role, token)                │
│  │   ├── login/logout/register actions                         │
│  │   ├── Auto token refresh on 401                             │
│  │   └── Persisted to localStorage                             │
│  └── Component-local state (useState/useEffect)                │
│                                                                  │
│  API CLIENT (api/client.js)                                      │
│  ├── Axios-like fetch wrapper                                   │
│  ├── Auto-attaches Authorization: Bearer header                │
│  ├── Intercepts 401 → tries token refresh                      │
│  ├── Intercepts 429 → shows "rate limited" toast               │
│  └── Returns { success, data, error } envelope                 │
│                                                                  │
│  ROUTING (React Router v7)                                       │
│  ├── Public routes: /, /login, /register, /search              │
│  ├── Protected routes: wrapped in <ProtectedRoute>             │
│  │   └── Redirects to /login if no auth token                 │
│  ├── Admin routes: /admin/* (protected + role check)           │
│  └── 404 catch-all: <NotFound /> component                    │
│                                                                  │
│  REAL-TIME (WebSocket)                                           │
│  ├── Connected after login (ws://...?token=JWT)                │
│  ├── Listens for: new_message, booking, notification           │
│  ├── Triggers toast notifications for real-time events         │
│  └── Auto-reconnect with exponential backoff                   │
│                                                                  │
│  BUILD (Vite)                                                    │
│  ├── Development: HMR (Hot Module Replacement) ~50ms           │
│  ├── Production: Tree-shaking + code splitting                 │
│  ├── Output: dist/ folder (served by NGINX in Docker)          │
│  └── Environment: VITE_API_URL for backend endpoint            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Pages & Components

| Page | Route | Description |
|------|-------|-------------|
| Home | `/` | Category grid, featured professionals, search |
| Search Results | `/search` | Filtered results with map integration |
| Professional Profile | `/professional/:id` | Full profile, portfolio, reviews, booking |
| Categories | `/categories` | Browse all service categories |
| Category Detail | `/category/:id` | Professionals in category |
| Create Booking | `/booking/new` | Multi-step booking flow |
| My Bookings | `/bookings` | Customer/pro booking management |
| Booking Detail | `/booking/:id` | Full booking lifecycle view |
| Messages | `/messages` | Thread list |
| Chat | `/chat/:threadId` | Real-time messaging |
| Dashboard | `/dashboard` | Pro earnings, stats, bookings |
| Schedule | `/schedule` | Weekly availability manager |
| Earnings | `/earnings` | Revenue analytics |
| Disputes | `/disputes` | Dispute management |
| Warranties | `/warranties` | Warranty tracking |
| Emergency | `/emergency` | Emergency service request |
| Referrals | `/referrals` | Referral program |
| Favorites | `/favorites` | Saved professionals |
| Notifications | `/notifications` | All notifications |
| Settings | `/settings` | Profile, preferences |
| Analytics | `/analytics` | Usage analytics |
| Payment | `/payment/:id` | Payment checkout |
| Login | `/login` | Authentication |
| Register | `/register` | New account creation |
| Admin | `/admin/*` | Admin panel (protected) |

### Reusable Components

| Component | Purpose |
|-----------|---------|
| `Navbar` | App header with search, auth state |
| `BottomNav` | Mobile-optimized navigation |
| `SearchBar` | Autocomplete search input |
| `ProfessionalCard` | Provider info card |
| `CategoryCard` | Category with icon |
| `ReviewCard` | Rating display |
| `StarRating` | Interactive star input |
| `Toast` | Notification toasts |
| `Skeleton` | Loading placeholders |
| `LoadingSpinner` | Centered spinner |
| `ErrorBoundary` | Graceful error recovery |
| `ProtectedRoute` | Auth-gated routing |
| `OnlineIndicator` | Real-time online status |

---

## 📱 Mobile App (Flutter)

### Architecture — Detailed Explanation

The mobile app follows a **Provider-based MVVM architecture** with offline-first capabilities. Here's how each layer works:

```
┌─────────────────────────────────────────────────────────────────┐
│             FLUTTER APP ARCHITECTURE LAYERS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PRESENTATION LAYER (Screens + Widgets)                         │
│  ├── StatelessWidget / StatefulWidget                           │
│  ├── Consumes data from Providers via context.watch/read        │
│  ├── Triggers actions via service methods                       │
│  └── Never contains business logic or API calls                 │
│                                                                  │
│  STATE MANAGEMENT LAYER (Provider + ChangeNotifier)             │
│  ├── AuthService — login state, token storage, auto-refresh     │
│  ├── BookingService — booking CRUD, status updates              │
│  ├── RealtimeService — WebSocket connection lifecycle           │
│  ├── ThemeService — dark/light mode persistence                 │
│  └── SmartLocationService — GPS, nearby providers              │
│                                                                  │
│  BUSINESS LOGIC LAYER (Services)                                │
│  ├── ApiService — HTTP client with auth headers, error parsing  │
│  ├── OfflineQueueService — action queue for offline mode        │
│  ├── ConnectivityService — network state monitoring             │
│  ├── LocalCacheService — Hive local database                   │
│  ├── AnalyticsService — event tracking                         │
│  ├── PushNotificationService — FCM integration                 │
│  └── PerformanceMonitor — frame rate, memory tracking          │
│                                                                  │
│  DATA LAYER                                                      │
│  ├── Models (models.dart) — User, Professional, Booking, etc.  │
│  ├── API responses parsed into typed Dart objects               │
│  ├── Hive boxes for offline storage (typed adapters)            │
│  └── SharedPreferences for lightweight key-value (theme, lang)  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Smart Location Service — Deep Dive

The location system implements **battery-aware GPS tracking with auto-refresh**:

```
┌─────────────────────────────────────────────────────────────────┐
│           SMART LOCATION LIFECYCLE                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  INITIALIZATION (app startup)                                    │
│  1. Check location services enabled                             │
│  2. Request permission (if not granted)                         │
│  3. Get current position (high accuracy, 100m distance filter)  │
│  4. Start 60-second refresh timer for nearby providers          │
│                                                                  │
│  PERMISSION HANDLING                                             │
│  ├── Denied → Show "Location needed" message                   │
│  ├── Denied Forever → Show settings redirect button            │
│  └── Granted → Proceed with GPS                                │
│                                                                  │
│  DISTANCE FILTER: 100 meters                                    │
│  • Only updates position when user moves >100m                 │
│  • Saves battery on stationary users                           │
│  • During active tracking: reduced to 10m (high precision)     │
│                                                                  │
│  NEARBY PROVIDERS REFRESH                                        │
│  • Every 60 seconds: GET /api/search?lat=X&lng=Y&radius=10    │
│  • Radius configurable by user (5-50 km)                       │
│  • Results cached in memory (avoid redundant API calls)         │
│                                                                  │
│  BACKGROUND TRACKING (during active bookings)                    │
│  • Stream subscription: continuous GPS updates                  │
│  • Sent to server via WebSocket (5-second intervals)           │
│  • Customer sees live movement on map                          │
│  • Auto-stops when booking status = 'completed'                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Offline Queue Service — Deep Dive

The offline queue implements **reliable action replay with retry logic**:

```dart
// How offline actions work (from offline_queue_service.dart):

class OfflineAction {
  final String id;       // Unique action identifier
  final String type;     // 'booking', 'message', 'image_upload'
  final String method;   // 'POST', 'PUT'
  final String path;     // API endpoint path
  final Map body;        // Request body (serialized to JSON)
  final DateTime createdAt;
  int retryCount;        // Incremented on each failed sync attempt
}
```

```
┌─────────────────────────────────────────────────────────────────┐
│           OFFLINE QUEUE FLOW                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. USER ACTION (while offline)                                  │
│     ├── User creates booking / sends message / posts review     │
│     ├── ConnectivityService reports: offline                    │
│     ├── Action serialized → Hive box ('offline_queue')          │
│     └── UI shows: "Queued — will sync when online"              │
│                                                                  │
│  2. CONNECTIVITY RESTORED                                        │
│     ├── ConnectivityService fires: NetworkStatus.online          │
│     ├── OfflineQueueService.syncAll() triggered                 │
│     └── Also: periodic retry every 30 seconds                  │
│                                                                  │
│  3. SYNC PROCESS                                                 │
│     For each queued action (FIFO order):                        │
│     ├── Make HTTP request (method + path + body)                │
│     ├── If 2xx: Remove from queue ✅                            │
│     ├── If 4xx: Remove (permanent failure, show error toast) ❌ │
│     ├── If 5xx/network: Increment retryCount                   │
│     │   ├── retryCount < 5: Keep in queue (retry later)        │
│     │   └── retryCount >= 5: Remove + show "sync failed" ❌    │
│     └── Emit pendingCountStream (UI updates badge count)        │
│                                                                  │
│  4. PERSISTENCE                                                  │
│     • Queue stored in Hive (local NoSQL DB on device)           │
│     • Survives app restart, device reboot                       │
│     • Actions have creation timestamp (for ordering)            │
│                                                                  │
│  5. CONFLICT RESOLUTION                                          │
│     • Booking creation: server rejects if professional busy    │
│     • Messages: always succeed (append-only)                   │
│     • Reviews: server rejects if booking not completed         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Architecture

The mobile app follows a **Provider-based MVVM architecture** with offline-first capabilities:

```
lib/
├── main.dart                    # App entry point, theme, routing
├── models/models.dart           # Data models (User, Booking, etc.)
├── services/                    # Business logic layer
│   ├── api_service.dart         # HTTP client with auth headers
│   ├── auth_service.dart        # Login, register, token management
│   ├── booking_service.dart     # Booking CRUD operations
│   ├── realtime_service.dart    # WebSocket connection manager
│   ├── analytics_service.dart   # Event tracking
│   ├── push_notification_service.dart  # FCM push notifications
│   ├── smart_location_service.dart     # GPS with battery optimization
│   ├── upload_service.dart      # File upload with progress
│   ├── theme_service.dart       # Dark/light mode management
│   ├── performance_monitor.dart # Frame rate & memory tracking
│   ├── network_simulator.dart   # Dev: simulate slow networks
│   └── offline/                 # Offline-first services
│       ├── connectivity_service.dart   # Network state monitoring
│       ├── local_cache_service.dart    # Hive local storage
│       ├── offline_queue_service.dart  # Action queue (sync later)
│       └── offline_services.dart      # Combined offline manager
├── screens/                     # UI screens (22+ screens)
│   ├── auth/                    # Login, Register, Welcome
│   ├── home/                    # Home feed, categories
│   ├── search/                  # Search with filters
│   ├── bookings/                # Booking list, detail, create
│   ├── tracking/                # Live GPS tracking
│   ├── messages/                # Chat threads
│   ├── payments/                # Payment flow
│   ├── profile/                 # User/pro profile
│   ├── portfolio/               # Portfolio management
│   ├── reviews/                 # Review list, create
│   ├── schedule/                # Weekly schedule
│   ├── earnings/                # Earnings dashboard
│   ├── disputes/                # Dispute management
│   ├── warranty/                # Warranty claims
│   ├── emergency/               # Emergency requests
│   ├── favorites/               # Saved professionals
│   ├── notifications/           # Notification center
│   ├── settings/                # App settings
│   ├── kyc/                     # KYC verification flow
│   └── contacts/                # Contact management
├── widgets/                     # Shared UI components
│   ├── professional_card.dart   # Provider card
│   ├── trust_badge.dart         # Verification badges
│   ├── book_now_sheet.dart      # Bottom sheet booking
│   ├── skeleton_loader.dart     # Shimmer loading
│   ├── connectivity_banner.dart # Offline indicator
│   ├── availability_toggle.dart # Online/offline switch
│   ├── nearby_providers_section.dart  # Geo-based list
│   ├── review_prompt.dart       # Post-service review nudge
│   ├── voice_search_button.dart # Voice input trigger
│   └── voice/voice_note_widget.dart   # Audio recording UI
└── l10n/                        # Localization (EN, HI, TE)
```

### Key Mobile Features

#### 🔄 Offline-First Architecture
- **Hive local database** for caching profiles, categories, bookings
- **Action queue** — bookings/reviews created offline are auto-synced when connectivity returns
- **Connectivity banner** — visual indicator of network state
- **Graceful degradation** — app remains functional without internet

#### 🎙️ Voice Search (Regional Languages)
- **speech_to_text** integration for Hindi, Telugu, and English
- Voice-triggered professional search
- Accessibility-first design for tier-2/3 city users

#### 📍 Live Tracking
- Real-time provider location via WebSocket
- ETA calculations
- Status progression (assigned → on_the_way → arrived → in_progress → completed)
- Call/message provider directly from tracking screen

#### 🔔 Push Notifications
- FCM-based push notifications
- Booking status updates
- New message alerts
- Payment confirmations
- Emergency broadcasts

---

## 🗄️ Database

### Design Philosophy & Decisions

The database design follows these principles:
- **UUID primary keys** — Prevents sequential ID enumeration attacks (no `user/1`, `user/2`)
- **Timestamps on everything** — `created_at` / `updated_at` for audit trail
- **Enum constraints** — Database-level type safety (not just application-level)
- **Referential integrity** — Foreign keys with `ON DELETE CASCADE` where appropriate
- **Haversine-ready** — Lat/Lng stored as DECIMAL(9,6) for geo queries
- **pgcrypto** — UUID generation at the database level (`gen_random_uuid()`)

### Migration Strategy

Migrations are **numbered sequentially** and designed to be **idempotent** (safe to run multiple times):

```
┌─────────────────────────────────────────────────────────────────┐
│              MIGRATION DEPENDENCY CHAIN                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  schema.sql (base)                                              │
│  └── Creates: users, professionals, categories,                 │
│      professional_categories, contacts, reviews,                │
│      portfolio_items, complaints                                │
│                                                                  │
│  001_kyc.sql                                                     │
│  └── Creates: kyc_documents (FK → users)                        │
│      Adds: government_id_verified, selfie_verified to users     │
│                                                                  │
│  002_bookings_chat.sql                                           │
│  └── Creates: bookings (with FSM status enum),                  │
│      message_threads, messages, booking_status_log              │
│      Creates: booking status enum type                          │
│                                                                  │
│  003_review_by_booking.sql                                       │
│  └── Adds: booking_id FK to reviews table                       │
│      Enforces: only completed-booking customers can review      │
│                                                                  │
│  004_seed_geo.sql                                                │
│  └── Seeds: 50+ categories (5 parent, 46 subcategories)        │
│      Seeds: sample professionals with lat/lng                   │
│                                                                  │
│  005_reputation_trigger.sql                                      │
│  └── Creates: trigger function to auto-compute                  │
│      reputation_score on review/booking changes                 │
│      Formula: (rating×0.4) + (jobs×0.2) + (response×0.2)      │
│              - (complaints×0.2)                                  │
│                                                                  │
│  006_phase1_features.sql                                         │
│  └── Creates: favorites, analytics_events,                      │
│      worker_schedule, worker_blocked_dates, time_slots          │
│                                                                  │
│  007_auth_admin_services.sql                                     │
│  └── Creates: referrals, emergency_requests,                    │
│      service_warranties, notifications                          │
│      Adds: is_admin to users, search_history                   │
│                                                                  │
│  008_analytics_and_chat_images.sql                               │
│  └── Adds: type + media_url columns to messages                │
│      Creates: analytics funnel tracking views                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Schema Overview

The database uses **PostgreSQL 16** with the `pgcrypto` extension for UUID generation. The schema consists of **20+ tables** with full referential integrity:

```sql
-- Core Entities
users                    -- Base accounts (customer/professional)
professionals            -- Extended professional profiles
categories               -- Hierarchical service taxonomy
professional_categories  -- M:N category assignments

-- Marketplace Operations
bookings                 -- Service bookings (FSM-driven)
time_slots               -- Professional schedule slots
worker_schedule          -- Weekly recurring availability
worker_blocked_dates     -- Date-based unavailability

-- Communication
message_threads          -- Chat thread metadata
messages                 -- Individual messages (text/image/voice)
notifications            -- Push/in-app notifications

-- Trust & Safety
reviews                  -- Verified ratings (1-5 stars)
complaints               -- Fraud/harassment reports
disputes                 -- Booking dispute cases
kyc_documents            -- Identity verification uploads

-- Financial
payments                 -- Razorpay payment records
warranties               -- Post-service warranty tracking
referrals                -- Referral program tracking

-- Discovery
contacts                 -- Contact requests (call/message/quote)
favorites                -- Saved professionals
portfolio_items          -- Professional portfolio media

-- Emergency
emergency_requests       -- Urgent service requests

-- Analytics
analytics_events         -- User behavior tracking
```

### Enum Types

```sql
user_role          → 'customer' | 'professional'
availability_status → 'available' | 'busy' | 'offline'
subscription_plan  → 'basic' | 'premium' | 'featured'
media_type         → 'image' | 'video' | 'certificate'
contact_type       → 'call' | 'message' | 'quote_request'
contact_status     → 'pending' | 'accepted' | 'declined'
complaint_type     → 'fraud' | 'harassment' | 'poor_service' | 'fake_profile'
complaint_status   → 'pending' | 'warning_issued' | 'suspended' | 'banned' | 'resolved'
```

### Migrations

```
database/migrations/
├── 001_kyc.sql                      # KYC documents table
├── 002_bookings_chat.sql            # Bookings + messaging tables
├── 003_review_by_booking.sql        # Booking-based reviews
├── 004_seed_geo.sql                 # Geographic seed data
├── 005_reputation_trigger.sql       # Auto-compute reputation scores
├── 006_phase1_features.sql          # Favorites, analytics, schedule
├── 007_auth_admin_services.sql      # Admin, referrals, emergency
└── 008_analytics_and_chat_images.sql # Analytics events, media messages
```

### Key Indexes

```sql
-- Performance-critical indexes
idx_professionals_reputation_score   -- DESC for top-rated sorting
idx_professionals_location           -- Lat/Lng for geo queries
idx_users_email                      -- Login lookups
idx_users_phone                      -- Phone verification
idx_reviews_professional_id          -- Review aggregation
idx_contacts_customer_id             -- Customer history
idx_contacts_professional_id         -- Professional inbox
idx_categories_parent_id             -- Category hierarchy
```

---

## 🔌 API Reference

### Authentication & Users

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/auth/register` | ❌ | Register new user (customer/professional) |
| `POST` | `/api/auth/login` | ❌ | Login → returns access + refresh tokens |
| `POST` | `/api/auth/refresh` | 🔄 | Refresh expired access token |
| `GET` | `/api/users/me` | ✅ | Get current user profile |
| `PUT` | `/api/users/me` | ✅ | Update profile (name, phone, avatar) |

### Professional Profiles

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/professionals` | ✅ | Create professional profile |
| `GET` | `/api/professionals/:id` | ❌ | Get professional by ID |
| `PUT` | `/api/professionals/:id` | ✅ | Update bio, pricing, location |
| `GET` | `/api/professionals/:id/stats` | ✅ | Detailed performance metrics |

### Search & Discovery

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/search` | ❌ | Search professionals with filters |
| `GET` | `/api/categories` | ❌ | List all categories (tree) |
| `GET` | `/api/categories/:id` | ❌ | Category detail with subcategories |

#### Search Query Parameters

| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `q` | string | `"plumber"` | Full-text search (name, headline) |
| `category_id` | integer | `3` | Filter by category |
| `min_rating` | number | `4.0` | Minimum average rating |
| `max_price` | number | `5000` | Maximum price estimate (₹) |
| `latitude` | number | `12.9716` | User latitude |
| `longitude` | number | `77.5946` | User longitude |
| `radius_km` | number | `10` | Search radius |
| `availability` | string | `"available"` | Availability filter |
| `sort_by` | string | `"reputation"` | Sort: reputation/distance/experience |
| `page` | integer | `1` | Page number |
| `limit` | integer | `20` | Results per page (max 100) |

### Bookings

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/bookings` | ✅ | Create new booking |
| `GET` | `/api/bookings` | ✅ | List user's bookings |
| `GET` | `/api/bookings/:id` | ✅ | Get booking details |
| `PUT` | `/api/bookings/:id/status` | ✅ | Transition booking state (FSM) |
| `PUT` | `/api/bookings/:id/quote` | ✅ | Professional sends quote |

### Messaging

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/messages/threads` | ✅ | List all chat threads |
| `GET` | `/api/messages/threads/:id` | ✅ | Get messages in thread |
| `POST` | `/api/messages/threads/:id` | ✅ | Send message (text/image/voice) |
| `POST` | `/api/messages/thread` | ✅ | Get or create thread |

### Payments

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/payments/create` | ✅ | Create Razorpay payment order |
| `POST` | `/api/payments/verify` | ✅ | Verify payment signature |
| `GET` | `/api/payments` | ✅ | List payment history |
| `POST` | `/api/webhooks/razorpay` | ❌ | Razorpay webhook handler |

### Schedule Management

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/schedule` | ✅ | Get weekly schedule |
| `PUT` | `/api/schedule` | ✅ | Set/update weekly slots |
| `GET` | `/api/schedule/available` | ❌ | Get available slots for date |
| `POST` | `/api/schedule/book-slot` | ✅ | Book a specific time slot |
| `POST` | `/api/schedule/block` | ✅ | Block dates |
| `DELETE` | `/api/schedule/block` | ✅ | Unblock dates |

### Disputes & Warranties

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/disputes` | ✅ | Raise dispute with evidence |
| `GET` | `/api/disputes` | ✅ | List disputes |
| `GET` | `/api/disputes/:id` | ✅ | Dispute details |
| `POST` | `/api/disputes/:id/evidence` | ✅ | Add evidence |
| `GET` | `/api/warranties` | ✅ | List warranties |
| `POST` | `/api/warranties/:id/claim` | ✅ | Claim warranty |

### Emergency Services

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/emergency` | ✅ | Create emergency request |
| `GET` | `/api/emergency` | ✅ | List emergency requests |
| `PUT` | `/api/emergency/:id/respond` | ✅ | Professional responds |

### Reviews & Portfolio

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/reviews` | ✅ | Create review (booking-verified) |
| `GET` | `/api/reviews/:professionalId` | ❌ | Get professional's reviews |
| `POST` | `/api/portfolio` | ✅ | Upload portfolio item |
| `GET` | `/api/portfolio/:professionalId` | ❌ | List portfolio items |
| `DELETE` | `/api/portfolio/:id` | ✅ | Delete portfolio item |

### KYC Verification

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/kyc/upload` | ✅ | Upload KYC documents |
| `GET` | `/api/kyc/status` | ✅ | Check verification status |
| `PUT` | `/api/kyc/:id/approve` | ✅👑 | Admin: approve KYC |
| `PUT` | `/api/kyc/:id/reject` | ✅👑 | Admin: reject KYC |

### Favorites & Referrals

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/favorites` | ✅ | Add to favorites |
| `GET` | `/api/favorites` | ✅ | List favorites |
| `DELETE` | `/api/favorites/:id` | ✅ | Remove from favorites |
| `POST` | `/api/referrals` | ✅ | Create referral code |
| `POST` | `/api/referrals/redeem` | ✅ | Redeem referral code |

### Notifications & Analytics

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/notifications` | ✅ | List notifications |
| `PUT` | `/api/notifications/:id/read` | ✅ | Mark as read |
| `POST` | `/api/analytics/events` | ✅ | Track analytics event |
| `GET` | `/api/analytics/dashboard` | ✅👑 | Admin analytics |

### File Upload

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/upload` | ✅ | Upload file (image/video/doc) |
| `GET` | `/api/download/apk` | ❌ | Download Android APK |

### Admin Operations

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/admin/users` | ✅👑 | List all users |
| `PUT` | `/api/admin/users/:id/ban` | ✅👑 | Ban user |
| `GET` | `/api/admin/complaints` | ✅👑 | Review complaints |
| `GET` | `/api/admin/stats` | ✅👑 | Platform statistics |

### Health Check

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/health` | ❌ | Server + DB connectivity check |

---

## 📝 API Usage Examples

<details>
<summary><strong>🔐 Authentication Flow (curl)</strong></summary>

```bash
# ═══════════════════════════════════════════════════
# 1. Register a new customer
# ═══════════════════════════════════════════════════
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Priya Sharma",
    "email": "priya@example.com",
    "password": "SecurePass123!",
    "phone": "+919876543210",
    "role": "customer",
    "location": "Mumbai, Maharashtra"
  }'

# Response:
# {
#   "success": true,
#   "data": {
#     "user": { "id": "uuid", "name": "Priya Sharma", "role": "customer" },
#     "token": "eyJhbGciOiJIUzI1NiIs...",
#     "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
#   }
# }

# ═══════════════════════════════════════════════════
# 2. Login
# ═══════════════════════════════════════════════════
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "priya@example.com", "password": "SecurePass123!"}'

# ═══════════════════════════════════════════════════
# 3. Refresh expired token
# ═══════════════════════════════════════════════════
curl -X POST http://localhost:5000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "eyJhbGciOiJIUzI1NiIs..."}'
```

</details>

<details>
<summary><strong>🔍 Search Professionals (curl)</strong></summary>

```bash
# ═══════════════════════════════════════════════════
# Search nearby plumbers in Mumbai (10 km radius)
# ═══════════════════════════════════════════════════
curl "http://localhost:5000/api/search?\
q=plumber&\
category_id=6&\
latitude=19.0760&\
longitude=72.8777&\
radius_km=10&\
min_rating=4.0&\
availability=available&\
sort_by=reputation&\
page=1&\
limit=20"

# Response:
# {
#   "success": true,
#   "data": [
#     {
#       "id": "uuid",
#       "name": "Rajesh Kumar",
#       "headline": "Expert Plumber — 15 years",
#       "reputation_score": 4.72,
#       "average_rating": 4.8,
#       "review_count": 127,
#       "pricing_estimate": "₹500-2000",
#       "distance": 3.42,
#       "availability_status": "available",
#       "government_id_verified": true
#     }
#   ],
#   "pagination": { "page": 1, "limit": 20, "total": 15 }
# }
```

</details>

<details>
<summary><strong>📦 Complete Booking Flow (curl)</strong></summary>

```bash
# Store your token
TOKEN="your_jwt_access_token"

# ═══════════════════════════════════════════════════
# Step 1: Create booking
# ═══════════════════════════════════════════════════
curl -X POST http://localhost:5000/api/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Idempotency-Key: booking-$(date +%s)" \
  -d '{
    "professional_id": "pro-uuid",
    "category_id": 6,
    "title": "Kitchen pipe repair",
    "description": "Leaking pipe under kitchen sink",
    "service_address": "Mumbai, Andheri West",
    "service_lat": 19.1334,
    "service_lng": 72.8273,
    "preferred_date": "2026-05-10T10:00:00Z"
  }'

# → Status: "requested"
# → Professional receives WebSocket + push notification

# ═══════════════════════════════════════════════════
# Step 2: Professional sends quote (PRO_ONLY)
# ═══════════════════════════════════════════════════
curl -X PUT "http://localhost:5000/api/bookings/$BOOKING_ID/quote" \
  -H "Authorization: Bearer $PRO_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"quoted_amount": 1500, "note": "Includes pipe + labor"}'

# → Status: "quoted"

# ═══════════════════════════════════════════════════
# Step 3: Customer accepts quote (CUSTOMER_ONLY)
# ═══════════════════════════════════════════════════
curl -X PUT "http://localhost:5000/api/bookings/$BOOKING_ID/status" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "accepted"}'

# → Status: "accepted"

# ═══════════════════════════════════════════════════
# Step 4: Professional starts work (PRO_ONLY)
# ═══════════════════════════════════════════════════
# Status transitions: scheduled → in_progress → completed
```

</details>

<details>
<summary><strong>💬 Messaging (curl)</strong></summary>

```bash
# ═══════════════════════════════════════════════════
# Get or create chat thread with professional
# ═══════════════════════════════════════════════════
curl -X POST http://localhost:5000/api/messages/thread \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"professional_id": "pro-uuid"}'

# ═══════════════════════════════════════════════════
# Send a message
# ═══════════════════════════════════════════════════
curl -X POST "http://localhost:5000/api/messages/threads/$THREAD_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"body": "Hi, when can you visit?", "type": "text"}'

# ═══════════════════════════════════════════════════
# Send image message
# ═══════════════════════════════════════════════════
curl -X POST "http://localhost:5000/api/messages/threads/$THREAD_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"body": "Photo of the issue", "type": "image", "media_url": "/uploads/leak.jpg"}'
```

</details>

<details>
<summary><strong>💳 Payment Flow (curl)</strong></summary>

```bash
# ═══════════════════════════════════════════════════
# Create payment order (before Razorpay checkout)
# ═══════════════════════════════════════════════════
curl -X POST http://localhost:5000/api/payments/create \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"booking_id": "booking-uuid", "amount": 1500}'

# Response:
# {
#   "success": true,
#   "data": {
#     "razorpay_order_id": "order_xxxxx",
#     "amount": 150000,  ← Amount in paise (₹1500)
#     "currency": "INR",
#     "key_id": "rzp_test_xxxxx"
#   }
# }

# ═══════════════════════════════════════════════════
# Verify payment (after Razorpay checkout succeeds)
# ═══════════════════════════════════════════════════
curl -X POST http://localhost:5000/api/payments/verify \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "razorpay_order_id": "order_xxxxx",
    "razorpay_payment_id": "pay_xxxxx",
    "razorpay_signature": "hmac_sha256_hex_signature"
  }'
```

</details>

---

## ⚠️ Error Handling & Response Format

### Standard Response Envelope

Every API response follows a consistent format:

```json
// ✅ Success Response
{
  "success": true,
  "data": { /* resource data */ },
  "pagination": { "page": 1, "limit": 20, "total": 42 }  // lists only
}

// ❌ Error Response
{
  "success": false,
  "message": "Human-readable error description",
  "requestId": "uuid-for-tracing"           // Always included
  // Development only:
  "stack": "Error: ...\n    at ..."         // Stack trace (dev mode)
}
```

### HTTP Status Codes

| Code | Meaning | When Used |
|------|---------|-----------|
| `200` | OK | Successful GET/PUT |
| `201` | Created | Successful POST (resource created) |
| `400` | Bad Request | Validation failed, missing fields |
| `401` | Unauthorized | Missing/expired/invalid JWT |
| `403` | Forbidden | Role mismatch (customer vs professional vs admin) |
| `404` | Not Found | Resource doesn't exist |
| `409` | Conflict | Duplicate booking (idempotency check) |
| `429` | Too Many Requests | Rate limit / fraud prevention triggered |
| `500` | Internal Error | Unhandled server error (sanitized in production) |
| `503` | Service Unavailable | Database unreachable (health check) |

### Error Handler Implementation

```javascript
// Production: Never exposes raw DB or internal errors
// Development: Includes full stack trace + error message
// Always: Includes requestId for correlation

// Structured Pino logging for all errors:
// - 5xx → logger.error() with full context
// - 4xx → logger.warn() with request metadata
```

### Validation Errors

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "field": "email", "message": "Must be a valid email address" },
    { "field": "password", "message": "Must be at least 8 characters" }
  ]
}
```

---

## 🔌 WebSocket Protocol Reference

### Connection

```
ws://localhost:5000/ws?token=<JWT_ACCESS_TOKEN>
wss://yourdomain.com/ws?token=<JWT_ACCESS_TOKEN>  (production)
```

### Authentication

The WebSocket server validates the JWT token from the query parameter on connection. Invalid/expired tokens receive a close frame:

| Close Code | Reason | Action |
|-----------|--------|--------|
| `4001` | `no token` | Send JWT as `?token=` param |
| `4002` | `bad token` | Refresh token and reconnect |

### On Connection (Server → Client)

```json
{ "type": "hello", "userId": "uuid", "ts": 1714700000000 }
```

### Client → Server Messages

| Type | Payload | Description |
|------|---------|-------------|
| `ping` | `{}` | Keep-alive heartbeat |
| `typing` | `{ "threadId": "uuid", "to": "userId", "typing": true }` | Typing indicator |
| `read_receipt` | `{ "threadId": "uuid" }` | Mark all messages as read |
| `presence` | `{ "status": "online" \| "away" \| "offline" }` | Update presence status |

### Server → Client Messages

| Type | Payload | Trigger |
|------|---------|---------|
| `pong` | `{ "t": timestamp }` | Response to ping |
| `typing` | `{ "threadId", "userId", "typing" }` | Other user typing |
| `messages_read` | `{ "threadId", "by", "at" }` | Messages marked read |
| `new_message` | `{ "threadId", "message": {...} }` | New chat message |
| `booking` | `{ "action": "created\|updated", "data": {...} }` | Booking state change |
| `notification` | `{ "type", "title", "body", "data" }` | Push event |
| `tracking` | `{ "bookingId", "lat", "lng", "eta", "status" }` | GPS location |

### Heartbeat Protocol

```
Server sends WS ping every 30 seconds
Client must respond with pong
If no pong received → connection terminated
Client can also send { "type": "ping" } → receives { "type": "pong" }
```

### Presence System

```
Connected → status: "online" (automatic)
No activity for 5 min → status: "away" (client-driven)
Disconnected → status: "offline" (automatic, lastSeen recorded)
```

### Multi-Device Support

Multiple WebSocket connections per user are supported. Messages are broadcast to **all** active connections for the same `userId`.

---

## 📐 Data Models Reference

### User Model

```
┌──────────────────────────────────────┐
│               users                   │
├──────────────────────────────────────┤
│ id           UUID PK                  │
│ email        VARCHAR(255) UNIQUE      │
│ password_hash TEXT                     │
│ name         VARCHAR(255)             │
│ phone        VARCHAR(20)              │
│ role         ENUM(customer|professional) │
│ location     TEXT                      │
│ phone_verified        BOOLEAN         │
│ government_id_verified BOOLEAN        │
│ selfie_verified       BOOLEAN         │
│ avatar_url   TEXT                      │
│ created_at   TIMESTAMPTZ              │
│ updated_at   TIMESTAMPTZ              │
└──────────────────────────────────────┘
```

### Professional Model

```
┌──────────────────────────────────────┐
│           professionals               │
├──────────────────────────────────────┤
│ id           UUID PK                  │
│ user_id      UUID FK → users          │
│ headline     TEXT                      │
│ bio          TEXT                      │
│ years_of_experience  INTEGER          │
│ pricing_estimate     TEXT             │
│ service_location_radius_km INTEGER    │
│ latitude     DECIMAL(9,6)             │
│ longitude    DECIMAL(9,6)             │
│ availability_status ENUM              │
│ reputation_score    DECIMAL(3,2)      │
│ completed_jobs      INTEGER           │
│ response_time_hours DECIMAL(5,2)      │
│ subscription_plan   ENUM              │
│ subscription_expires_at TIMESTAMPTZ   │
│ accepts_emergency   BOOLEAN           │
│ created_at   TIMESTAMPTZ              │
│ updated_at   TIMESTAMPTZ              │
└──────────────────────────────────────┘
```

### Entity Relationship Diagram

```
  users ─────────┐
    │             │
    │ 1:1         │ 1:N
    ▼             ▼
professionals   contacts ◄──── reviews
    │              │               │
    │ M:N          │ 1:1           │
    ▼              ▼               │
categories   portfolio_items       │
    │                              │
    │ (self-ref)                   │
    ▼                              │
categories ◄──────────────────────┘
  (parent)

  professionals ──────┐
       │              │
       │ 1:N          │ 1:N
       ▼              ▼
    bookings      message_threads
       │              │
       │ 1:N          │ 1:N
       ▼              ▼
  payments         messages
  disputes
  warranties
  booking_status_log
```

### Mobile Data Model (Dart)

```dart
class User {
  final String id, name, email, phone, role;
  final String? location, avatarUrl;
}

class Professional {
  final String id, name;
  final double averageRating, reputationScore;
  final int reviewCount, completedJobs, yearsOfExperience;
  final String? headline, bio, pricingEstimate, availabilityStatus;
  final bool governmentIdVerified;
  final double? distance;
}

class Booking {
  final String id, title, status;
  final String customerId, professionalId;
  final double? quotedAmount, finalAmount;
  final DateTime createdAt, updatedAt;
}

class Category {
  final int id;
  final String name;
  final int? parentId;
  final List<Category> children;
}
```

---

## 🧮 Reputation Algorithm

The reputation score is a **weighted composite score** (0.00–5.00) calculated from multiple trust signals:

### Formula

```
reputation = (rating × 0.4) + (jobs × 0.2) + (response × 0.2) - (complaints × 0.2)
```

### Component Breakdown

| Component | Weight | Calculation | Range |
|-----------|:------:|-------------|:-----:|
| **Average Rating** | 40% | Direct from reviews (1-5 stars) | 0–5 |
| **Completed Jobs** | 20% | `min(completedJobs / 100, 1) × 5` | 0–5 |
| **Response Time** | 20% | `max(5 - (hours / 48) × 5, 0)` | 0–5 |
| **Complaint Penalty** | -20% | `min(complaints × 1.0, 5)` | 0–5 |

### Scoring Examples

| Professional | Rating | Jobs | Response | Complaints | **Score** |
|-------------|:------:|:----:|:--------:|:----------:|:---------:|
| Top Performer | 4.9 | 150 | 2h | 0 | **4.92** |
| Good Average | 4.2 | 50 | 8h | 1 | **3.35** |
| New Professional | 5.0 | 3 | 1h | 0 | **2.23** |
| Low Performer | 2.5 | 20 | 36h | 3 | **0.88** |

### Implementation

```javascript
// backend/src/utils/reputationScore.js
const calculateReputationScore = ({ averageRating, completedJobs, responseTime, complaintsAgainst }) => {
  const ratingScore = Math.min(averageRating, 5);
  const jobsScore = Math.min((completedJobs / 100) * 5, 5);
  const responseScore = Math.max(5 - (responseTime / 48) * 5, 0);
  const complaintPenalty = Math.min(complaintsAgainst * 1.0, 5);

  const score = ratingScore * 0.4 + jobsScore * 0.2 + responseScore * 0.2 - complaintPenalty * 0.2;
  return Math.round(Math.max(0, Math.min(5, score)) * 100) / 100;
};
```

### Auto-Refresh Triggers

The reputation score is automatically recalculated via database trigger (`005_reputation_trigger.sql`) whenever:
- ✅ A new review is submitted
- ✅ A booking reaches `completed` status
- ✅ A complaint status changes
- ✅ Response time is updated

---

## 🛡️ Fraud Prevention System

### Multi-Layer Detection

```
              Request Flow
                  │
    ┌─────────────▼─────────────────┐
    │  Layer 1: Rate Limiting       │
    │  (express-rate-limit)         │
    │  Auth: 30/15min, API: 200/min │
    └─────────────┬─────────────────┘
                  │
    ┌─────────────▼─────────────────┐
    │  Layer 2: Idempotency Check   │
    │  (X-Idempotency-Key header)   │
    │  Prevents duplicate payments  │
    └─────────────┬─────────────────┘
                  │
    ┌─────────────▼─────────────────┐
    │  Layer 3: Action Rate Limit   │
    │  Per-user, per-action counters│
    │  (booking: 5/min, payment: 3) │
    └─────────────┬─────────────────┘
                  │
    ┌─────────────▼─────────────────┐
    │  Layer 4: Pattern Detection   │
    │  • 10+ bookings/hour → block  │
    │  • Duplicate booking → 409    │
    │  • Same provider+time → warn  │
    └─────────────┬─────────────────┘
                  │
    ┌─────────────▼─────────────────┐
    │  Layer 5: Account Takeover    │
    │  • Multiple password changes  │
    │  • IP/UA anomaly detection    │
    │  • Log-only (security review) │
    └─────────────┬─────────────────┘
                  │
                  ▼
            ✅ Request Proceeds
```

### Idempotency Implementation

```bash
# Client sends unique key to prevent accidental duplicate bookings/payments:
curl -X POST /api/bookings \
  -H "X-Idempotency-Key: user123-booking-1714700000" \
  -H "Authorization: Bearer $TOKEN"

# If same key sent again → returns cached original response (no duplicate created)
# Keys expire after 24 hours
```

### Bot Detection Rules

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Rapid bookings | 10+ in 1 hour | `429` — Booking limit reached |
| Duplicate booking | Same pro + date + 5 min window | `409` — Already exists |
| Auth brute force | 5 failed logins | 15-min account lockout |
| API flooding | 200+ requests/minute | `429` — Rate limited |
| Payment spam | 3+ payment attempts/minute | Action rate limited |

---

## 🔐 KYC Verification Pipeline

---

## 🔒 Security & Compliance

### Authentication Flow

```
┌─────────┐         ┌─────────┐         ┌──────────┐
│  Client  │──Login──▶│ Backend │──Verify──▶│ Database │
│          │◀─Tokens─│         │◀─User────│          │
└─────────┘         └─────────┘         └──────────┘

Tokens:
  • Access Token  (15 min TTL) — sent in Authorization header
  • Refresh Token (7 day TTL) — used to get new access tokens
```

### Security Measures

| Layer | Protection |
|-------|-----------|
| **Transport** | HTTPS enforcement, HSTS headers |
| **Headers** | Helmet.js (CSP, X-Frame-Options, X-XSS-Protection) |
| **Authentication** | JWT with short-lived access + long-lived refresh tokens |
| **Password** | bcryptjs with 10 salt rounds |
| **Rate Limiting** | 30 attempts/15min (auth), 200 requests/15min (API) |
| **Account Lockout** | 5 failed logins → 15-minute lockout |
| **Input Validation** | express-validator on all endpoints |
| **SQL Injection** | Parameterized queries only (pg library) |
| **XSS** | Content-Security-Policy headers |
| **CORS** | Strict origin validation in production |
| **File Upload** | Type validation, size limits (multer) |
| **Fraud Prevention** | Bot detection, idempotency keys, pattern analysis |
| **Request Tracing** | UUID per request for audit trail |
| **Structured Logging** | Pino JSON logs for security monitoring |

### KYC Verification Pipeline

```
Professional Registration
        │
        ▼
┌──────────────────┐
│ Upload Documents │
│ • Government ID  │
│ • Selfie photo   │
│ • Address proof  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Admin Review    │
│  (Manual QA)     │
└────────┬─────────┘
         │
    ┌────▼────┐
    │Approved?│
    └────┬────┘
    Yes  │  No
    ▼    │  ▼
 ✅ Badge   📧 Rejection + reason
```

### KYC Document Types & Validation

```javascript
// backend/src/utils/kycValidators.js validates:
// - Government ID (Aadhaar, PAN, Driving License, Voter ID)
// - Selfie photo (face verification)
// - Address proof (utility bill, bank statement)
```

| Document | Accepted Formats | Max Size | Validation |
|----------|-----------------|----------|------------|
| Government ID | JPG, PNG, PDF | 5 MB | Uploaded, admin-reviewed |
| Selfie Photo | JPG, PNG | 3 MB | Face visible, clear |
| Address Proof | JPG, PNG, PDF | 5 MB | Name + address match |

### Post-Verification Trust Badges

| Badge | Requirement | Visual |
|-------|-------------|--------|
| 🆔 **ID Verified** | Government ID approved | Blue shield |
| 📸 **Selfie Verified** | Selfie photo approved | Green checkmark |
| ⭐ **Top Rated** | 4.5+ avg rating, 50+ reviews | Gold star |
| ⚡ **Fast Responder** | < 2 hour avg response time | Lightning bolt |
| 🏆 **Elite Pro** | All badges + 100+ completed jobs | Diamond badge |

---

## ⚡ Real-Time Features

### WebSocket Architecture — Deep Dive

The real-time system is built on the **native WebSocket protocol** (not Socket.io) for minimal overhead:

```
┌─────────────────────────────────────────────────────────────────┐
│           WEBSOCKET HUB INTERNALS                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  DATA STRUCTURES (hub.js):                                       │
│  const sockets = new Map();   // userId → Set<WebSocket>        │
│  const presence = new Map();  // userId → { lastSeen, status }  │
│                                                                  │
│  CONNECTION LIFECYCLE:                                            │
│  1. Client connects: ws://server/ws?token=JWT                   │
│  2. Server extracts token from URL params                       │
│  3. jwt.verify(token, secret) → userId                         │
│  4. Add ws to sockets.get(userId) Set                          │
│  5. Update presence: { lastSeen: now, status: 'online' }       │
│  6. Send welcome: { type: 'hello', userId, ts }                │
│                                                                  │
│  MULTI-DEVICE SUPPORT:                                           │
│  • sockets Map: userId → Set of connections (not single ws)    │
│  • User on phone + laptop = 2 connections in the Set           │
│  • sendTo(userId) broadcasts to ALL connections for that user  │
│  • Disconnect one device → only that ws removed from Set       │
│  • Last device disconnects → presence = 'offline'              │
│                                                                  │
│  HEARTBEAT (30-second sweep):                                    │
│  • Server iterates all clients every 30s                       │
│  • Sends WebSocket-level ping frame                            │
│  • If no pong received → ws.terminate() (dead connection)      │
│  • Prevents zombie connections consuming memory                │
│                                                                  │
│  MESSAGE TYPES HANDLED:                                          │
│  ├── 'ping'          → respond with { type: 'pong', t }       │
│  ├── 'typing'        → forward to msg.to userId               │
│  ├── 'read_receipt'  → update DB + notify other party         │
│  └── 'presence'      → update in-memory presence status       │
│                                                                  │
│  READ RECEIPT FLOW:                                              │
│  1. Client sends: { type: 'read_receipt', threadId }           │
│  2. Server: UPDATE messages SET read_at = NOW()                │
│     WHERE thread_id = $1 AND sender_id <> $2 AND read_at NULL  │
│  3. Server: UPDATE message_threads SET unread = 0              │
│  4. Server: notify other party { type: 'messages_read' }       │
│                                                                  │
│  WHY NOT SOCKET.IO?                                              │
│  • Native ws library: 0 dependencies, ~20KB vs Socket.io ~200KB│
│  • No polling fallback needed (all modern clients support WS)  │
│  • Direct control over heartbeat, close codes, binary frames   │
│  • Flutter web_socket_channel works with raw WS (not Socket.io)│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Notification Dispatch System

The platform uses a **multi-channel notification strategy**:

```
┌─────────────────────────────────────────────────────────────────┐
│           NOTIFICATION CHANNELS                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  When an event occurs (new booking, message, etc.):             │
│                                                                  │
│  ┌─────────────────┐                                            │
│  │  notifier.js    │── dispatches to all channels:             │
│  └────────┬────────┘                                            │
│           │                                                      │
│  ┌────────▼────────┐  1. IN-APP NOTIFICATION                   │
│  │  Database       │  INSERT INTO notifications (...)           │
│  │  notifications  │  • Appears in /notifications page         │
│  │  table          │  • Badge count on bell icon               │
│  └────────┬────────┘                                            │
│           │                                                      │
│  ┌────────▼────────┐  2. REAL-TIME WEBSOCKET                   │
│  │  hub.sendTo()   │  • If user is online → instant delivery  │
│  │  WebSocket      │  • Shows as toast / chat bubble           │
│  │  broadcast      │  • Typing indicators, read receipts       │
│  └────────┬────────┘                                            │
│           │                                                      │
│  ┌────────▼────────┐  3. PUSH NOTIFICATION (FCM)               │
│  │  Job Queue      │  • If user is OFFLINE → device push      │
│  │  → FCM API     │  • Queued via jobQueue (async, retried)   │
│  │                 │  • Falls back to no-op if FCM not config  │
│  └────────┬────────┘                                            │
│           │                                                      │
│  ┌────────▼────────┐  4. EMAIL (transactional)                  │
│  │  Job Queue      │  • Booking confirmations                  │
│  │  → SendGrid    │  • Payment receipts                       │
│  │                 │  • KYC approval/rejection                 │
│  └────────┬────────┘                                            │
│           │                                                      │
│  ┌────────▼────────┐  5. SMS (OTP / critical alerts)           │
│  │  Job Queue      │  • OTP for phone verification             │
│  │  → SMS Gateway │  • Emergency broadcasts                   │
│  └─────────────────┘                                            │
│                                                                  │
│  GRACEFUL DEGRADATION:                                          │
│  • If SendGrid not configured → email logged only (simulated)  │
│  • If FCM not configured → push skipped silently              │
│  • If SMS not configured → OTP logged to console              │
│  • Core functionality NEVER blocked by notification failure    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### WebSocket Architecture

The platform uses native WebSocket (`ws` library) for real-time communication:

| Channel | Purpose | Payload |
|---------|---------|---------|
| `chat:{threadId}` | Message delivery | `{ type, body, sender, timestamp }` |
| `tracking:{bookingId}` | GPS location stream | `{ lat, lng, eta, status }` |
| `notifications:{userId}` | Push events | `{ type, title, body, data }` |
| `typing:{threadId}` | Typing indicators | `{ userId, isTyping }` |

### Real-Time Hub (`backend/src/realtime/hub.js`)

```javascript
// Server-side: emit to specific user
hub.emitToUser(userId, 'new_message', payload);

// Client-side: subscribe to events
ws.onmessage = (event) => handleRealtimeEvent(JSON.parse(event.data));
```

### Live Tracking Flow

```
Professional (Mobile)          Server               Customer (App)
       │                         │                        │
       │──GPS update (5s)──────▶│                        │
       │                         │──broadcast location──▶│
       │                         │                        │──update map
       │──status: arrived──────▶│                        │
       │                         │──status change───────▶│
       │                         │                        │──show "Arrived"
```

---

## 💳 Payment Integration

### Razorpay Integration — Deep Dive

SkillConnect uses **Razorpay** (India's leading payment gateway) with a **server-to-server order creation** flow that ensures security:

```
┌─────────────────────────────────────────────────────────────────┐
│           PAYMENT SECURITY MODEL                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  WHY SERVER-SIDE ORDER CREATION?                                │
│  • Amount is set by SERVER (not client) → prevents tampering    │
│  • Order ID is generated by Razorpay → ensures uniqueness       │
│  • Client never sees KEY_SECRET → only KEY_ID (public)          │
│  • Signature verification uses HMAC-SHA256 → cannot be forged   │
│                                                                  │
│  SIMULATED MODE (development without Razorpay keys)             │
│  • If RAZORPAY_KEY_ID not set → all orders are "simulated"     │
│  • Returns { simulated: true, order_id: "sim_xxxx" }           │
│  • Signature verification always passes                        │
│  • No real money charged                                       │
│  • Full end-to-end flow testable without Razorpay account      │
│                                                                  │
│  WEBHOOK HANDLING                                                │
│  • POST /api/webhooks/razorpay (no auth — Razorpay calls it)  │
│  • Signature verified: HMAC-SHA256(body, WEBHOOK_SECRET)        │
│  • Events handled: payment.captured, payment.failed             │
│  • Idempotent: won't process same event twice                  │
│                                                                  │
│  REFUND FLOW                                                     │
│  • Admin resolves dispute → triggers Razorpay refund API       │
│  • Partial/full refund supported                               │
│  • Refund status tracked in payments table                     │
│  • Customer notified via push + in-app                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Amount conversion:** Razorpay uses **paise** (1 INR = 100 paise). The service handles conversion:
```javascript
amount: Math.round(amount * 100)  // ₹1500 → 150000 paise
```

### Razorpay Flow

```
Customer                  Backend                 Razorpay
   │                        │                        │
   │──Create payment order─▶│                        │
   │                        │──POST /orders─────────▶│
   │                        │◀─order_id + amount─────│
   │◀─order details─────────│                        │
   │                        │                        │
   │──Open Razorpay modal──▶│                        │
   │                        │                        │
   │──Payment success──────▶│                        │
   │  (razorpay_payment_id) │                        │
   │                        │──Verify signature─────▶│
   │                        │◀─Confirmed─────────────│
   │◀─Booking confirmed─────│                        │
   │                        │                        │
   │                        │◀─Webhook: captured─────│
   │                        │──Update payment status │
```

### Supported Payment Methods
- 💳 Credit/Debit Cards (Visa, Mastercard, RuPay)
- 🏦 Net Banking (all major Indian banks)
- 📱 UPI (Google Pay, PhonePe, Paytm)
- 💰 Wallets (Paytm, Freecharge, Ola Money)

---

## 🌍 Internationalization (i18n)

### Supported Languages

| Code | Language | Script | Coverage |
|------|----------|--------|----------|
| `en` | English | Latin | Full (100%) |
| `hi` | Hindi | Devanagari | Full (100%) |
| `te` | Telugu | Telugu | Full (100%) |

### Implementation

- **Mobile**: Flutter's `intl` + ARB files with `flutter_localizations`
- **Voice Input**: `speech_to_text` configured for `hi-IN`, `te-IN`, `en-IN`
- **Dynamic switching**: Language can be changed at runtime without restart

### Sample ARB Structure

```json
// app_hi.arb
{
  "searchProfessionals": "पेशेवरों को खोजें",
  "bookNow": "अभी बुक करें",
  "myBookings": "मेरी बुकिंग",
  "raiseDispute": "विवाद दर्ज करें"
}
```

---

## 📴 Offline-First Architecture

### Design Principles

```
┌─────────────────────────────────────┐
│         MOBILE APP (Flutter)         │
├─────────────────────────────────────┤
│                                      │
│  ┌─────────────┐  ┌──────────────┐  │
│  │  API Client │  │ Offline Queue│  │
│  │  (Online)   │  │  (Hive DB)   │  │
│  └──────┬──────┘  └──────┬───────┘  │
│         │                 │          │
│         ▼                 ▼          │
│  ┌─────────────────────────────────┐ │
│  │      Connectivity Service       │ │
│  │  (monitors network state)       │ │
│  └──────────────┬──────────────────┘ │
│                 │                     │
│    Online? ─────┼───── Offline?      │
│       │         │         │          │
│       ▼         │         ▼          │
│  API calls      │    Queue actions   │
│  + cache        │    Show cached     │
│  responses      │    Show banner     │
│                 │                     │
│         ┌───────▼────────┐           │
│         │  Sync Manager  │           │
│         │ (retry queued  │           │
│         │  actions when  │           │
│         │  back online)  │           │
│         └────────────────┘           │
└─────────────────────────────────────┘
```

### Offline Capabilities

| Feature | Offline Behavior |
|---------|-----------------|
| Browse professionals | Cached profiles shown |
| View bookings | Local copy available |
| Send messages | Queued, sent when online |
| Create booking | Queued, synced on reconnect |
| Submit review | Queued, synced on reconnect |
| Voice search | Requires connectivity |
| Live tracking | Requires connectivity |
| Payments | Requires connectivity |

---

## 🎙️ Voice Search System

### Supported Languages & Locales

| Language | Locale Code | Speech Recognition | Example Query |
|----------|------------|-------------------:|---------------|
| English | `en-IN` | ✅ Active | *"Find plumber near me"* |
| Hindi | `hi-IN` | ✅ Active | *"प्लंबर ढूंढो"* |
| Telugu | `te-IN` | ✅ Active | *"ప్లంబర్ కనుగొనండి"* |

### Implementation Architecture

```
User presses 🎤 → speech_to_text SDK activates
         │
         ▼
  OS-level speech recognition
  (Google Speech / Apple Siri)
         │
         ▼
  Recognized text returned
         │
         ▼
  Populate search bar → trigger API search
         │
         ▼
  GET /api/search?q={recognized_text}&latitude=...
```

### Widget Integration

```dart
// widgets/voice_search_button.dart
// - Animated microphone icon
// - Visual feedback during listening
// - Auto-populates search field
// - Falls back to text input if no microphone permission
```

---

## 🧪 Testing

### Testing Strategy — Deep Dive

```
┌─────────────────────────────────────────────────────────────────┐
│           TESTING PYRAMID                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                    ╱╲                                            │
│                   ╱  ╲    E2E Tests (Manual QA)                  │
│                  ╱────╲   • Full booking flow                   │
│                 ╱      ╲  • Payment processing                  │
│                ╱________╲ • Multi-device sync                   │
│               ╱          ╲                                      │
│              ╱  Integration╲  Backend Tests (Jest + Supertest)   │
│             ╱    Tests      ╲ • API endpoint testing            │
│            ╱                 ╲• Database integration             │
│           ╱___________________╲• Auth flow validation            │
│          ╱                     ╲                                │
│         ╱    Unit Tests         ╲ Widget Tests (Flutter)         │
│        ╱    Component Tests      ╲ Component Tests (Vitest)     │
│       ╱___________________________╲                             │
│                                                                  │
│  BACKEND TEST APPROACH (10 test files, Jest + Supertest)        │
│  ├── Each test file targets one domain (auth, bookings, etc.)  │
│  ├── Uses Supertest for HTTP-level testing (real Express app)  │
│  ├── Database: real PostgreSQL (test database, not mocked)     │
│  ├── Cleanup: transactions rolled back after each test         │
│  ├── Fixtures: test users, categories created in beforeAll     │
│  └── Coverage enforced: 50% minimum (branches, lines, funcs)  │
│                                                                  │
│  FRONTEND TEST APPROACH (Vitest + Testing Library)              │
│  ├── Component rendering tests                                 │
│  ├── User interaction simulation (click, type, submit)         │
│  ├── API mocking (MSW or manual fetch mocks)                  │
│  └── Accessibility: ARIA role verification                     │
│                                                                  │
│  MOBILE TEST APPROACH (Flutter test)                            │
│  ├── Widget tests: verify UI renders correctly                 │
│  ├── Golden tests: screenshot comparison                       │
│  ├── Integration tests: full screen flows                      │
│  └── Service tests: mock API responses                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Backend Tests (Jest + Supertest)

```bash
cd backend

# Run all tests
npm test

# Run with coverage report
npm run test:coverage

# Run specific test file
npx jest tests/bookings.test.js
```

| Test File | Coverage Area |
|-----------|--------------|
| `auth.test.js` | Registration, login, JWT refresh, lockout |
| `bookings.test.js` | FSM transitions, role gating, state validation |
| `categories.test.js` | Category CRUD, hierarchy, search |
| `dashboard.test.js` | Pro dashboard stats, earnings |
| `disputes.test.js` | Dispute creation, access control, evidence |
| `kyc.test.js` | Document upload, approval flow |
| `messages.test.js` | Thread creation, message sending |
| `reviews.test.js` | Verified reviews, rating calculation |
| `schedule.test.js` | Weekly slots, availability, blocking |
| `search.test.js` | Geo search, filters, pagination |

**Coverage Thresholds** (enforced in CI):
```
Branches:   50%
Functions:  50%
Lines:      50%
Statements: 50%
```

### Frontend Tests (Vitest + Testing Library)

```bash
cd frontend

# Run all tests
npm test

# Run in watch mode
npx vitest
```

| Test File | Coverage Area |
|-----------|--------------|
| `App.test.jsx` | Root component rendering, routing |
| `SearchBar.test.jsx` | Search input, autocomplete |

### Mobile Tests (Flutter)

```bash
cd mobile/skillconnect

# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Linting

```bash
# Backend (ESLint)
cd backend && npm run lint
cd backend && npm run lint:fix   # Auto-fix

# Frontend (Vite build checks)
cd frontend && npm run build

# Mobile (Dart analysis)
cd mobile/skillconnect && flutter analyze
```

---

## 📦 Deployment

### Deployment Architecture — Deep Dive

```
┌─────────────────────────────────────────────────────────────────┐
│           DOCKER COMPOSE ORCHESTRATION                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  docker-compose.yml defines 3 services:                         │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  SERVICE: db (PostgreSQL 16 Alpine)                      │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  • Image: postgres:16-alpine                            │    │
│  │  • Port: 5432 (exposed to other containers)             │    │
│  │  • Volume: postgres_data (persistent across restarts)   │    │
│  │  • Health check: pg_isready (every 5s)                  │    │
│  │  • Auto-creates database on first run                   │    │
│  │  • Environment: POSTGRES_DB, POSTGRES_USER, PASSWORD    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  SERVICE: backend (Node.js API)                          │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  • Build: ./backend/Dockerfile                          │    │
│  │  • Base: node:22-alpine (minimal ~40MB image)           │    │
│  │  • Port: 5000                                           │    │
│  │  • depends_on: db (waits for health check)              │    │
│  │  • Restart: always (auto-restart on crash)              │    │
│  │  • Runs schema + migrations on startup                  │    │
│  │  • Serves: /api/*, /ws, /uploads/*, /app/              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  SERVICE: frontend (NGINX + React build)                 │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  • Build: multi-stage (npm build → nginx serve)         │    │
│  │  • Base: nginx:alpine (~5MB image)                      │    │
│  │  • Port: 80 (HTTP) / 443 (HTTPS with SSL)             │    │
│  │  • Serves: static React build (dist/)                   │    │
│  │  • Reverse proxy: /api → backend:5000                  │    │
│  │  • SPA fallback: all routes → index.html               │    │
│  │  • Gzip: enabled for JS/CSS/HTML                       │    │
│  │  • Cache headers: 1 year for hashed assets             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  STARTUP ORDER:                                                  │
│  1. PostgreSQL starts → becomes healthy (pg_isready)            │
│  2. Backend starts → connects to DB, runs migrations            │
│  3. Frontend starts → serves static files + proxies API         │
│                                                                  │
│  SCALING:                                                        │
│  docker-compose up -d --scale backend=3                         │
│  • Creates 3 backend instances behind NGINX round-robin         │
│  • Requires: shared session (Redis) or stateless auth (JWT ✅) │
│  • WebSocket: sticky sessions needed (or separate WS gateway)  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Docker Compose (Production-Ready)

```yaml
# docker-compose.yml provides:
services:
  db:        # PostgreSQL 16 Alpine with health checks
  backend:   # Node.js API with auto-restart
  frontend:  # NGINX serving React build
```

```bash
# Production deployment
docker-compose up -d --build

# View logs
docker-compose logs -f backend

# Scale backend (if behind load balancer)
docker-compose up -d --scale backend=3
```

### Individual Dockerfiles

| Service | Base Image | Exposed Port |
|---------|-----------|-------------|
| Backend | `node:22-alpine` | 5000 |
| Frontend | `nginx:alpine` | 80 |
| Database | `postgres:16-alpine` | 5432 |

### Environment-Specific Configs

| Environment | Features |
|-------------|----------|
| **Development** | Hot-reload, CORS permissive, debug logging, source maps |
| **Production** | Helmet strict CSP, compressed responses, error-only logging |

### Build Commands

```bash
# Backend — no build needed (Node.js)
npm start

# Frontend — Vite production build
cd frontend && npm run build
# Output: frontend/dist/

# Mobile — Release APK
cd mobile/skillconnect && flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Mobile — Web build (served by backend at /app/)
cd mobile/skillconnect && flutter build web
# Output: build/web/
```

### APK Download

The backend serves the compiled APK at:
```
GET /api/download/apk → Downloads SkillConnect.apk
```

---

## 📁 Project Structure

```
SKILL/
├── 📄 README.md                          # This file
├── 📄 docker-compose.yml                 # Multi-service orchestration
├── 📄 build.sh                           # Build automation script
├── 📄 .gitignore                         # Git ignore rules
├── 📄 SkillConnect_PRD_v1.0.docx         # Product Requirements Document
├── 📄 SkillConnect_Technical_Supplement_v1.0.docx  # Technical Specs
│
├── 🖥️ backend/                            # Node.js API Server
│   ├── src/
│   │   ├── app.js                        # Express app config + routes
│   │   ├── server.js                     # HTTP + WebSocket server
│   │   ├── config/
│   │   │   ├── database.js              # PostgreSQL connection pool
│   │   │   ├── index.js                 # Centralized config
│   │   │   └── logger.js               # Pino structured logging
│   │   ├── middleware/
│   │   │   ├── auth.js                  # JWT verification
│   │   │   ├── validate.js             # Input validation
│   │   │   ├── errorHandler.js         # Global error handler
│   │   │   ├── fraudPrevention.js      # Bot/fraud detection
│   │   │   ├── cache.js                # Response caching
│   │   │   ├── httpLogger.js           # Request logging
│   │   │   └── requestId.js           # Correlation IDs
│   │   ├── controllers/                 # 25 controllers
│   │   │   ├── authController.js       # Register, login, refresh
│   │   │   ├── bookingController.js    # FSM engine + transitions
│   │   │   ├── messageController.js    # Chat threads + messages
│   │   │   ├── paymentController.js    # Razorpay integration
│   │   │   ├── searchController.js     # Geo + text search
│   │   │   ├── scheduleController.js   # Availability management
│   │   │   ├── disputeController.js    # Dispute resolution
│   │   │   ├── warrantyController.js   # Warranty claims
│   │   │   ├── emergencyController.js  # Emergency dispatch
│   │   │   ├── analyticsController.js  # Event tracking
│   │   │   ├── kycController.js        # KYC document flow
│   │   │   ├── referralController.js   # Referral program
│   │   │   └── ... (13 more)
│   │   ├── routes/                      # 25 route modules
│   │   ├── services/
│   │   │   ├── razorpay.js             # Payment gateway
│   │   │   ├── sms.js                  # OTP/SMS delivery
│   │   │   ├── email.js                # Email notifications
│   │   │   ├── pushNotification.js     # FCM push
│   │   │   ├── storage.js             # File storage (cloud)
│   │   │   └── jobQueue.js            # Async job processing
│   │   ├── realtime/
│   │   │   └── hub.js                  # WebSocket event hub
│   │   └── utils/
│   │       ├── reputationScore.js      # Weighted reputation algo
│   │       ├── kycValidators.js        # Document validation
│   │       └── notifier.js            # Notification dispatch
│   ├── tests/                           # 10 test files
│   ├── public/                          # Static assets (app/, pro/)
│   ├── Dockerfile                       # Production container
│   ├── .env.example                     # Environment template
│   ├── .eslintrc.json                   # Lint rules
│   └── package.json
│
├── 🌐 frontend/                           # React Web Application
│   ├── src/
│   │   ├── App.jsx                      # Root + React Router config
│   │   ├── main.jsx                     # Entry point
│   │   ├── api/client.js               # Axios-like API client
│   │   ├── context/AuthContext.jsx     # Global auth state (Provider)
│   │   ├── pages/                       # 30+ page components
│   │   │   ├── Home.jsx                # Landing + category grid
│   │   │   ├── SearchResults.jsx       # Search with filters
│   │   │   ├── Bookings.jsx           # Booking management
│   │   │   ├── Chat.jsx               # Real-time messaging
│   │   │   ├── Dashboard.jsx          # Pro dashboard
│   │   │   ├── Schedule.jsx           # Availability editor
│   │   │   ├── Earnings.jsx           # Revenue tracker
│   │   │   ├── Emergency.jsx          # Emergency requests
│   │   │   ├── Payment.jsx            # Razorpay checkout
│   │   │   └── admin/                 # Admin panel pages
│   │   ├── components/                  # 23 reusable components
│   │   │   ├── Navbar.jsx             # Navigation header
│   │   │   ├── BottomNav.jsx          # Mobile tab bar
│   │   │   ├── SearchBar.jsx          # Search with suggestions
│   │   │   ├── ProfessionalCard.jsx   # Provider card
│   │   │   ├── StarRating.jsx         # Rating input/display
│   │   │   ├── Toast.jsx              # Notification toasts
│   │   │   ├── Skeleton.jsx           # Loading shimmer
│   │   │   └── ErrorBoundary.jsx      # Error recovery
│   │   ├── data/                        # Static data/configs
│   │   └── tests/                       # Component tests
│   ├── index.html                       # SPA entry
│   ├── vite.config.js                   # Vite configuration
│   ├── vitest.config.js                 # Test configuration
│   ├── nginx.conf                       # Production NGINX config
│   ├── Dockerfile                       # Production container
│   └── package.json
│
├── 📱 mobile/skillconnect/               # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart                    # App entry, theme, routing
│   │   ├── models/models.dart          # Data models
│   │   ├── services/                    # 15+ service classes
│   │   ├── screens/                     # 22+ screen modules
│   │   ├── widgets/                     # 10+ custom widgets
│   │   └── l10n/                       # Localization (EN/HI/TE)
│   ├── assets/l10n/                     # ARB translation files
│   ├── android/                         # Android platform config
│   ├── ios/                             # iOS platform config
│   ├── web/                             # Web platform config
│   ├── test/                            # Widget tests
│   ├── pubspec.yaml                     # Dependencies
│   └── analysis_options.yaml           # Lint rules
│
└── 🗄️ database/                           # Database Scripts
    ├── schema.sql                       # Core schema (8 tables)
    ├── seed.sql                         # Category seed data
    └── migrations/                      # 8 incremental migrations
        ├── 001_kyc.sql
        ├── 002_bookings_chat.sql
        ├── 003_review_by_booking.sql
        ├── 004_seed_geo.sql
        ├── 005_reputation_trigger.sql
        ├── 006_phase1_features.sql
        ├── 007_auth_admin_services.sql
        └── 008_analytics_and_chat_images.sql
```

---

## ⚙️ Performance & Scalability

### Backend Optimizations

| Optimization | Implementation |
|-------------|---------------|
| **Connection Pooling** | `pg` pool with 20 max connections, idle timeout |
| **Response Compression** | Gzip/Brotli via `compression` middleware |
| **Index-Driven Queries** | Composite indexes on frequent filter combinations |
| **Pagination** | Cursor/offset pagination on all list endpoints |
| **Rate Limiting** | Token bucket per-IP and per-user |
| **Static Caching** | 7-day max-age for uploaded files |
| **Request Correlation** | UUID tracking for distributed tracing |
| **Structured Logging** | Pino (30x faster than Winston) |

### Mobile Optimizations

| Optimization | Implementation |
|-------------|---------------|
| **Image Caching** | `cached_network_image` with disk cache |
| **Lazy Loading** | Screens loaded on navigation only |
| **Skeleton UI** | Shimmer loading states (no layout shift) |
| **Offline Queue** | Hive DB for queued actions |
| **Battery-Aware GPS** | Smart location with power modes |
| **Memory Monitoring** | Performance monitor for frame drops |

### Database Optimizations

| Optimization | Implementation |
|-------------|---------------|
| **Haversine Indexing** | Lat/Lng composite index for geo queries |
| **Reputation Trigger** | Auto-computed on review/booking changes |
| **Partial Indexes** | Active bookings only for schedule conflicts |
| **UUID Primary Keys** | No sequential ID guessing attacks |
| **Enum Constraints** | Database-level type safety |

---

## 🤝 Contributing

### Development Workflow

```bash
# 1. Fork and clone
git clone https://github.com/<your-username>/SKILL.git

# 2. Create feature branch
git checkout -b feature/your-feature-name

# 3. Make changes and test
npm test                    # Backend
npm run lint                # Lint check
cd frontend && npm test     # Frontend

# 4. Commit with conventional format
git commit -m "feat(bookings): add recurring booking support"

# 5. Push and create PR
git push origin feature/your-feature-name
```

### Commit Convention

| Prefix | Use Case |
|--------|----------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code restructuring |
| `test` | Adding/fixing tests |
| `chore` | Build/config changes |

### Code Standards

- **Backend**: ESLint with Node.js rules, async/await style
- **Frontend**: React hooks, functional components only
- **Mobile**: Flutter lints, Provider pattern, named routes
- **Database**: Snake_case naming, UUID primary keys, created_at/updated_at

---

## 🗺️ Roadmap

### ✅ Completed (v1.0)

- [x] User authentication (JWT + refresh tokens)
- [x] Professional profiles with portfolio
- [x] Category-based search with geo-filtering (6-factor PRD ranking algorithm)
- [x] Booking FSM with role-gated transitions
- [x] Real-time chat (WebSocket)
- [x] Razorpay payment integration
- [x] KYC verification pipeline (triple-layer: OTP + Govt ID + Selfie)
- [x] Dispute resolution system
- [x] Warranty claims
- [x] Emergency service dispatch
- [x] Referral program
- [x] Multilingual (EN/HI/TE)
- [x] Offline-first mobile
- [x] Push notifications (FCM service)
- [x] Email (SendGrid) + SMS (MSG91/Twilio) services
- [x] Admin dashboard (KYC queue, dispute management, user management)
- [x] Analytics engine (event ingestion + professional dashboard)
- [x] Fraud prevention (idempotency, action rate limiting, suspicious detection)
- [x] Docker Compose local setup + Kubernetes base manifests
- [x] 7-stage GitHub Actions CI/CD (lint → test → build → audit → docker → scan → deploy)
- [x] Prometheus + Grafana monitoring stack
- [x] Sentry error tracking
- [x] AWS S3/R2 cloud storage (configurable)
- [x] Redis caching with in-memory fallback
- [x] PgBouncer connection pooling
- [x] GST invoice generation service
- [x] Agent commission system

### 🔜 Sprint 1 — Core Feature Completion

> See [`plans/PRD_SEC06_Reputation.md`](./plans/PRD_SEC06_Reputation.md), [`plans/PRD_SEC12_Notifications.md`](./plans/PRD_SEC12_Notifications.md), [`plans/PRD_SEC05_Portfolio.md`](./plans/PRD_SEC05_Portfolio.md)

- [ ] Trust Index 0–100 nightly recalculation (7-factor PRD §13.4 formula)
- [ ] Wire notification triggers to all events (review, contact, KYC, complaint, suspension)
- [ ] Review edit window (24h), velocity detection, profanity filter
- [ ] Portfolio upload limits enforced per subscription tier
- [ ] Image auto-compression to WebP/1080px (Sharp)
- [ ] Video thumbnail generation (ffmpeg)
- [ ] Sticky Contact CTA on professional profile
- [ ] Profile completeness meter + onboarding nudge banner
- [ ] Recently-viewed professionals on home screen
- [ ] City location selector on home screen
- [ ] Customer duplicate contact limit (3 per 30 days)

### 🔜 Sprint 2 — Database & API Gaps

> See [`plans/PRD_SEC09_API.md`](./plans/PRD_SEC09_API.md), [`plans/PRD_SEC08_Database.md`](./plans/PRD_SEC08_Database.md)

- [ ] 18 missing API endpoints (suggestions, similar, block-customer, trending, waitlist, invoices, DPDPA export, account deletion)
- [ ] Migration 013: 5 missing tables (blocked_users, featured_slots, category_requests, professional_languages, soft_deletes_log, ab_experiments, waitlist)
- [ ] Annual subscription billing (33% discount)
- [ ] Subscription grace period (3-day with reminders)
- [ ] Category request system (professional submits → admin approves)
- [ ] Trending categories endpoint
- [ ] Featured slots admin management (category page + home screen)

### 🔜 Sprint 3 — Security Hardening

> See [`plans/PRD_SEC11_Security.md`](./plans/PRD_SEC11_Security.md), [`plans/TECH_G_Security.md`](./plans/TECH_G_Security.md)

- [ ] Account lockout after 5 failed login attempts
- [ ] JWT refresh token reuse detection (family-based revocation)
- [ ] ClamAV antivirus on file uploads
- [ ] Semgrep SAST in CI pipeline
- [ ] Cosign Docker image signing
- [ ] PII masking in Pino logger
- [ ] Liveness detection integration (HyperVerge)
- [ ] Device fingerprint tracking
- [ ] THREAT_MODEL.md creation

### 🔜 Sprint 4 — Performance & Observability

> See [`plans/TECH_H_Performance.md`](./plans/TECH_H_Performance.md), [`plans/TECH_I_Observability.md`](./plans/TECH_I_Observability.md)

- [ ] k6 load testing scripts + CI smoke test
- [ ] Hot profile Redis cache (top 1000 per city)
- [ ] Cursor-based pagination (replace OFFSET)
- [ ] Missing Prometheus alert rules (KYC SLA, complaint SLA, search latency)
- [ ] Slack + PagerDuty alerting (Alertmanager)
- [ ] Business KPI gauges in Prometheus metrics
- [ ] Kustomize staging + production overlays
- [ ] pg_dump CronJob (every 6h to S3)

### 🔜 Sprint 5 — Architecture Evolution

> See [`plans/TECH_B_SystemArchitecture.md`](./plans/TECH_B_SystemArchitecture.md), [`plans/TECH_C_Microservices.md`](./plans/TECH_C_Microservices.md)

- [ ] BullMQ job queue (replace in-memory; Redis-backed; persistent)
- [ ] WebSocket multi-instance support (Redis pub/sub)
- [ ] Read replica routing in database.js
- [ ] Cloudflare CDN + WAF setup
- [ ] SEO: React Helmet + og: meta tags on profile/category pages
- [ ] JSON-LD structured data on professional profiles
- [ ] GET /sitemap.xml endpoint
- [ ] CSS design token system (tokens.css)

### 🔜 Sprint 6 — Compliance & Growth

> See [`plans/PRD_SEC19_Compliance.md`](./plans/PRD_SEC19_Compliance.md), [`plans/PRD_SEC15_GoToMarket.md`](./plans/PRD_SEC15_GoToMarket.md)

- [ ] 6 legal content pages (ToS, Privacy Policy, Professional Terms, Cookie, Content Moderation, Refund Policy)
- [ ] DPDPA data export endpoint
- [ ] Account deletion (30-day soft delete) + 90-day purge cron
- [ ] Consent management system
- [ ] KYC document retention policy (12-month auto-purge)
- [ ] Waitlist system + city activation flow
- [ ] SkillPoints customer referral rewards
- [ ] Admin: Category requests, Appeals, Featured Slots, Waitlist management screens

### 🔜 Sprint 7 — Disaster Recovery

> See [`plans/TECH_J_DisasterRecovery.md`](./plans/TECH_J_DisasterRecovery.md)

- [ ] Automated pg_dump backups every 6h
- [ ] Redis RDB persistence + hourly S3 backup
- [ ] S3 cross-region replication (ap-south-1 → ap-southeast-1)
- [ ] RDS Multi-AZ (production AWS)
- [ ] INCIDENT_RESPONSE.md
- [ ] DR drill: RTO < 30 minutes verified

---

## 🤖 AI Integration (NEW)

SkillConnect now includes a production-ready **AI integration layer** that enhances the platform with intelligent features. The system is **provider-agnostic** (supports OpenAI, Google Gemini, or local rule-based fallback) and designed for **graceful degradation** — if no AI API key is configured, all features fall back to deterministic rule-based logic.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Service Layer                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   OpenAI     │  │   Gemini     │  │  Local/Fallback  │  │
│  │  (GPT-4o)    │  │  (2.0 Flash) │  │  (Rule-based)    │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                  │                    │            │
│         └──────────────────┼────────────────────┘            │
│                            │                                 │
│                    ┌───────▼───────┐                         │
│                    │  AI Provider  │                         │
│                    │  Abstraction  │                         │
│                    └───────┬───────┘                         │
│                            │                                 │
│  ┌─────────┬──────────┬───┼────┬───────────┬────────────┐   │
│  │         │          │   │    │           │            │   │
│  ▼         ▼          ▼   ▼    ▼           ▼            ▼   │
│ Search  Recommend  Sentiment  Categorize  Pricing  Chatbot  │
│ Intent  -ations    Analysis              Suggest           │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│              In-Memory Cache (TTL-based)                     │
└─────────────────────────────────────────────────────────────┘
```

### AI Features

#### 1. 🔍 Smart Search Intent Parsing

Converts natural language queries into structured search parameters.

```
Input:  "I need a plumber near Koramangala who can fix a leaking pipe tomorrow"
Output: {
  "category": "Plumbing",
  "location": "Koramangala",
  "urgency": "high",
  "keywords": ["leaking", "pipe"],
  "timeframe": "tomorrow"
}
```

**API Endpoint:** `POST /api/ai/search-intent`

```json
// Request
{ "q": "urgent electrician for short circuit in HSR Layout" }

// Response
{
  "success": true,
  "data": {
    "category": "Electrical",
    "location": "HSR Layout",
    "urgency": "high",
    "keywords": ["short circuit"],
    "timeframe": null,
    "budget_hint": null,
    "language_detected": "en"
  }
}
```

#### 2. 🎯 Personalized Recommendations

Context-aware service suggestions based on user's booking history, favorites, location, and seasonal patterns.

**API Endpoint:** `POST /api/ai/recommendations` (requires auth)

```json
// Response
{
  "success": true,
  "data": [
    { "category": "AC Repair", "reason": "Summer maintenance season", "confidence": 0.85 },
    { "category": "Pest Control", "reason": "Based on your recent cleaning booking", "confidence": 0.72 },
    { "category": "Painting", "reason": "Festival home refresh", "confidence": 0.68 }
  ]
}
```

**Recommendation Factors:**
- Recent booking history (last 10 bookings)
- Favorite professionals' categories
- Seasonal demand patterns (summer → AC, festivals → cleaning/painting)
- Day of week and time of day
- Related service cross-sell (plumbing → bathroom renovation)

#### 3. 💬 Review Sentiment Analysis

Analyzes review text to extract sentiment, confidence score, and key themes.

**API Endpoint:** `POST /api/ai/sentiment`

```json
// Request
{ "text": "Excellent work! Very punctual and professional. Fair pricing too." }

// Response
{
  "success": true,
  "data": {
    "sentiment": "positive",
    "score": 0.92,
    "themes": ["punctuality", "quality", "pricing"],
    "summary": "Highly positive review highlighting timeliness and fair rates"
  }
}
```

**Theme Categories Detected:**
- `punctuality` — time-related mentions
- `quality` — work quality references
- `pricing` — cost/value mentions
- `cleanliness` — tidiness mentions
- `behavior` — politeness/rudeness

#### 4. 🏷️ Auto-Categorization

Automatically suggests the correct service category for free-text descriptions.

**API Endpoint:** `POST /api/ai/categorize`

```json
// Request
{ "description": "My kitchen sink is clogged and water isn't draining" }

// Response
{
  "success": true,
  "data": {
    "category": "Plumbing",
    "subcategory": "Drain Cleaning",
    "confidence": 0.91
  }
}
```

#### 5. 💰 Smart Pricing Suggestions

Market-data-informed pricing recommendations for professionals.

**API Endpoint:** `POST /api/ai/pricing`

```json
// Request
{ "category": "Plumbing", "location": "Bangalore", "complexity": "medium" }

// Response
{
  "success": true,
  "data": {
    "min_price": 300,
    "max_price": 2000,
    "recommended": 800,
    "factors": ["metro_city", "medium_complexity", "market_average"]
  }
}
```

#### 6. 🤖 AI Chatbot (SkillBot)

Conversational customer support with booking context awareness.

**API Endpoint:** `POST /api/ai/chat` (optional auth)

```json
// Request
{ "message": "How do I cancel my booking?" }

// Response
{
  "success": true,
  "data": {
    "response": "To cancel a booking, go to My Bookings > Select the booking > Tap Cancel. Note: cancellation policies may apply depending on the timing.",
    "source": "rules"
  }
}
```

**SkillBot Capabilities:**
- Booking guidance (search, create, cancel)
- Payment information (methods, refunds, disputes)
- Platform FAQ (how-to, policies, support)
- Context-aware responses (uses user's recent bookings)
- Multilingual support (responds in same language as user)

#### 7. 🛡️ Enhanced Fraud Scoring

AI-enhanced risk assessment for transactions and user activities.

```json
// Internal scoring output
{
  "score": 45,
  "risk": "medium",
  "flags": ["rapid_actions", "unusual_location"],
  "action": "review"
}
```

**Risk Factors Evaluated:**
| Factor | Weight | Description |
|--------|--------|-------------|
| `rapid_actions` | +30 | More than 10 actions in quick succession |
| `new_account_high_value` | +20 | New account making expensive bookings |
| `payment_failures` | +25 | 3+ failed payment attempts |
| `unusual_location` | +15 | Activity from unexpected geography |
| `suspicious_pattern` | +20 | Bot-like behavior patterns |

**Actions:** `allow` (score ≤ 40) → `review` (40-70) → `block` (70+)

### Configuration

Set these environment variables to enable AI features:

```bash
# AI Provider (openai | gemini | local)
AI_PROVIDER=openai

# OpenAI Configuration
OPENAI_API_KEY=sk-...your-key-here
AI_MODEL=gpt-4o-mini

# OR Google Gemini Configuration
# AI_PROVIDER=gemini
# GEMINI_API_KEY=AI...your-key-here

# Cache settings
AI_CACHE_TTL=3600  # seconds
```

> **Note:** Without any API key configured, ALL AI features still work using built-in rule-based logic. No external dependencies required for baseline functionality.

### What Can Be Improved (Future AI Enhancements)

| # | Improvement | Description | Impact |
|---|-------------|-------------|--------|
| 1 | **RAG-based FAQ** | Use Retrieval-Augmented Generation with platform docs for accurate chatbot responses | High |
| 2 | **Image Quality Scoring** | Computer vision to rate portfolio photo quality and suggest improvements | Medium |
| 3 | **Voice-to-Booking** | End-to-end voice command processing: "Book a plumber for tomorrow 3 PM" | High |
| 4 | **Demand Forecasting** | Predict service demand by area/time using historical booking data | High |
| 5 | **Dynamic Pricing** | Real-time price adjustment based on supply/demand, weather, events | Medium |
| 6 | **Auto-Scheduling** | ML-optimized schedule suggestions for professionals | Medium |
| 7 | **Review Summarization** | Auto-generate pro/con summaries from all reviews for a professional | Low |
| 8 | **Skill Gap Analysis** | Identify underserved categories in a location and suggest to professionals | Medium |
| 9 | **Churn Prediction** | Predict which users/pros might leave and trigger retention campaigns | High |
| 10 | **Smart Notifications** | AI-optimized notification timing for maximum engagement | Medium |
| 11 | **Quality Assurance** | Automated post-service quality verification via photo analysis | Medium |
| 12 | **Language Translation** | Real-time chat translation between customer and professional | High |
| 13 | **Route Optimization** | Optimal travel route suggestions for professionals with multiple bookings | Medium |
| 14 | **Conversational Booking** | Full booking flow via natural language conversation | High |
| 15 | **Professional Coaching** | AI tips for professionals to improve ratings and earnings | Low |
| 16 | **Anomaly Detection** | Detect unusual review patterns (fake reviews, review bombing) | High |
| 17 | **Content Moderation** | AI-based moderation of messages, reviews, and portfolio uploads | Medium |
| 18 | **Embedding Search** | Vector similarity search for finding professionals by description | High |
| 19 | **Predictive Maintenance** | Remind customers about recurring services before they need them | Medium |
| 20 | **A/B Test Optimization** | AI-driven experiment allocation and early stopping | Low |

---

## 📊 Monitoring & Observability

### Structured Logging (Pino)

All backend logs are JSON-structured via [Pino](https://getpino.io/) — **30x faster than Winston**:

```json
{
  "level": 30,
  "time": 1714700000000,
  "msg": "POST /api/bookings 201 45ms",
  "requestId": "a3f7c...",
  "method": "POST",
  "url": "/api/bookings",
  "statusCode": 201,
  "responseTime": 45,
  "userId": "user-uuid"
}
```

### Request Tracing

Every request is assigned a **UUID correlation ID** via `middleware/requestId.js`:

```
Request → X-Request-Id: a3f7c-... → All logs include requestId → Response header
```

This enables end-to-end tracing across:
- HTTP logs
- Database queries
- WebSocket events
- Error reports

### Health Check Endpoint

```
GET /api/health → 200 (healthy) or 503 (degraded)

Response:
{
  "success": true,
  "message": "All systems operational",
  "checks": {
    "server": "ok",
    "database": "ok"
  },
  "uptime": 86400.123,
  "timestamp": "2026-05-03T06:00:00Z"
}
```

### Log Levels

| Level | Usage | Production |
|-------|-------|:----------:|
| `fatal` | Unrecoverable errors | ✅ |
| `error` | 5xx errors, DB failures | ✅ |
| `warn` | 4xx errors, CORS blocks, rate limits | ✅ |
| `info` | Request/response, state changes | ✅ |
| `debug` | Query details, auth checks | ❌ |
| `trace` | Verbose internal state | ❌ |

---

## 🗂️ Service Categories

SkillConnect supports **5 parent categories** with **46 subcategories** covering India's most-demanded services:

<details>
<summary><strong>🏠 Home Services (10 subcategories)</strong></summary>

| # | Subcategory | Description | Icon |
|---|------------|-------------|------|
| 1 | Plumbing | Pipe repair, installation, maintenance | 🔧 |
| 2 | Electrical | Wiring, repair, installation | ⚡ |
| 3 | Carpentry | Woodwork, furniture, custom builds | 🪚 |
| 4 | Painting | Interior/exterior painting | 🎨 |
| 5 | Cleaning | Home and office deep cleaning | 🧹 |
| 6 | Landscaping | Garden maintenance, lawn care | 🌿 |
| 7 | Pest Control | Pest removal and prevention | 🐛 |
| 8 | HVAC | AC, heating, ventilation | ❄️ |
| 9 | Roofing | Roof repair and replacement | 🏠 |
| 10 | Appliance Repair | Home appliance fixes | 🔌 |

</details>

<details>
<summary><strong>🎉 Event Services (8 subcategories)</strong></summary>

| # | Subcategory | Description | Icon |
|---|------------|-------------|------|
| 1 | Catering | Food & beverage for events | 🍽️ |
| 2 | Photography | Event & portrait photography | 📸 |
| 3 | Videography | Video recording & production | 🎥 |
| 4 | DJ & Music | Music entertainment | 🎵 |
| 5 | Event Planning | Full event coordination | 📋 |
| 6 | Decoration | Event styling | 🎀 |
| 7 | MC & Hosting | Event hosting | 🎤 |
| 8 | Venue Rental | Venue sourcing | 🏛️ |

</details>

<details>
<summary><strong>👤 Personal Services (8 subcategories)</strong></summary>

| # | Subcategory | Description | Icon |
|---|------------|-------------|------|
| 1 | Tutoring | Academic coaching | 📚 |
| 2 | Fitness Training | Personal fitness | 🏋️ |
| 3 | Beauty & Makeup | Beauty treatments | 💄 |
| 4 | Hair Styling | Haircuts & treatments | 💇 |
| 5 | Massage Therapy | Therapeutic massage | 💆 |
| 6 | Nutrition & Diet | Dietary advice | 🥗 |
| 7 | Life Coaching | Personal development | 🎯 |
| 8 | Pet Care | Pet sitting & grooming | 🐕 |

</details>

<details>
<summary><strong>💻 Technical Services (8 subcategories)</strong></summary>

| # | Subcategory | Description | Icon |
|---|------------|-------------|------|
| 1 | IT Support | Computer troubleshooting | 🖥️ |
| 2 | Web Development | Website design | 🌐 |
| 3 | Mobile App Dev | iOS/Android apps | 📱 |
| 4 | Data Recovery | Data backup & recovery | 💾 |
| 5 | CCTV & Security | Security cameras | 📹 |
| 6 | Phone Repair | Smartphone fixes | 📞 |
| 7 | Networking | Network setup | 🔗 |
| 8 | Software Training | Software workshops | 🎓 |

</details>

<details>
<summary><strong>🎨 Creative Services (8 subcategories)</strong></summary>

| # | Subcategory | Description | Icon |
|---|------------|-------------|------|
| 1 | Graphic Design | Logo & branding | 🖌️ |
| 2 | Interior Design | Space planning | 🏡 |
| 3 | Content Writing | Copywriting & blogs | ✍️ |
| 4 | Video Editing | Post-production | 🎬 |
| 5 | Animation | 2D & 3D animation | 🎞️ |
| 6 | Music Production | Composition | 🎹 |
| 7 | Voice Over | Professional VO | 🗣️ |
| 8 | Illustration | Custom artwork | 🖼️ |

</details>

---

## ♿ Accessibility

### Web (React)

| Feature | Implementation |
|---------|---------------|
| Semantic HTML | `<nav>`, `<main>`, `<footer>`, `<article>` |
| Keyboard navigation | Tab-focusable UI elements |
| ARIA labels | Search bar, forms, buttons |
| Loading states | Skeleton placeholders (no layout shift) |
| Error messages | Inline validation with `role="alert"` |
| Color contrast | WCAG 2.1 AA compliant |

### Mobile (Flutter)

| Feature | Implementation |
|---------|---------------|
| Screen reader | Semantics widgets throughout |
| Voice search | Alternative to typing for accessibility |
| Large touch targets | Minimum 48dp touch targets |
| Regional language | Hindi/Telugu native support |
| Offline mode | Works without internet for low-connectivity users |
| Dark mode | System-aware theme switching |

---

## 🔧 Troubleshooting

<details>
<summary><strong>❌ Backend won't start</strong></summary>

```bash
# Check if port 5000 is in use
lsof -i :5000

# Verify PostgreSQL is running
pg_isready

# Check database exists
psql -l | grep skillconnect

# Check environment variables
cat backend/.env

# Check logs
tail -f /tmp/backend.log
```

Common issues:
- **`ECONNREFUSED`**: PostgreSQL isn't running or wrong `DB_HOST`
- **`EADDRINUSE`**: Port 5000 already in use (change in `.env`)
- **`Missing required environment variables`**: Set `JWT_SECRET`, `DB_PASSWORD` in production

</details>

<details>
<summary><strong>❌ Database migrations fail</strong></summary>

```bash
# Run migrations in order
for f in database/migrations/*.sql; do
  echo "Running: $f"
  psql skillconnect < "$f"
done

# If a migration fails, check which ones have been applied:
psql skillconnect -c "\dt"  # List all tables

# Re-run specific migration
psql skillconnect < database/migrations/002_bookings_chat.sql
```

</details>

<details>
<summary><strong>❌ Frontend can't reach backend</strong></summary>

```bash
# Check backend is running
curl http://localhost:5000/api/health

# Check Vite proxy (vite.config.js should proxy /api to :5000)
cat frontend/vite.config.js

# Check CORS (in development, all origins allowed)
# In production: set CORS_ORIGINS env var
```

</details>

<details>
<summary><strong>❌ WebSocket connection fails</strong></summary>

```bash
# Test WebSocket connection
npx wscat -c "ws://localhost:5000/ws?token=$JWT_TOKEN"

# Common issues:
# - Token expired → refresh and retry
# - Close code 4001 → missing token
# - Close code 4002 → invalid/expired token
```

</details>

<details>
<summary><strong>❌ Flutter build fails</strong></summary>

```bash
# Clean and rebuild
cd mobile/skillconnect
flutter clean
flutter pub get
flutter gen-l10n
flutter run

# If l10n errors:
flutter gen-l10n --template-arb-file=app_en.arb

# Check Dart SDK version
flutter --version  # Needs 3.8+
```

</details>

<details>
<summary><strong>❌ Razorpay payments not working</strong></summary>

```bash
# Check if Razorpay keys are configured
echo $RAZORPAY_KEY_ID
echo $RAZORPAY_KEY_SECRET

# Without keys: payments run in SIMULATED MODE
# → Orders return { "simulated": true }
# → Signatures always verify
# → No real money charged

# For testing: use Razorpay test keys from dashboard.razorpay.com
```

</details>

---

## ❓ Frequently Asked Questions

<details>
<summary><strong>Q: What's the minimum hardware to run SkillConnect?</strong></summary>

**Development:** Any machine with 4GB RAM, 2 CPU cores, 2GB disk space.

**Production (small):** 2 vCPU, 4GB RAM, 20GB SSD (handles ~500 concurrent users).

**Production (scaled):** 4 vCPU, 8GB RAM, 50GB SSD + managed PostgreSQL + Redis (handles ~5000 concurrent users).

</details>

<details>
<summary><strong>Q: Can I use MySQL instead of PostgreSQL?</strong></summary>

No. The schema uses PostgreSQL-specific features:
- `pgcrypto` extension for UUID generation
- `ENUM` types
- `INTERVAL` arithmetic in queries
- Haversine distance calculations
- `FILTER` clause in aggregations

Migration to MySQL would require rewriting ~30% of the SQL.

</details>

<details>
<summary><strong>Q: How do payments work without Razorpay keys?</strong></summary>

The payment service runs in **simulated mode** — orders are created with `{ "simulated": true }`, signatures always verify, and no real transactions occur. This allows full end-to-end testing without a Razorpay account.

</details>

<details>
<summary><strong>Q: Can I add more languages to the mobile app?</strong></summary>

Yes! Add a new ARB file:

```bash
# 1. Copy template
cp mobile/skillconnect/assets/l10n/app_en.arb assets/l10n/app_ta.arb

# 2. Translate all strings in app_ta.arb

# 3. Regenerate
flutter gen-l10n

# 4. Add locale in main.dart's supportedLocales
```

</details>

<details>
<summary><strong>Q: How do I add a new service category?</strong></summary>

```sql
-- Add as subcategory under existing parent
INSERT INTO categories (name, parent_id, description, icon)
VALUES ('Solar Panel Installation',
        (SELECT id FROM categories WHERE name = 'Home Services'),
        'Solar panel setup and maintenance',
        'solar');
```

</details>

<details>
<summary><strong>Q: Is SkillConnect production-ready?</strong></summary>

Yes, with these production checklist items:

- [x] JWT auth with refresh tokens
- [x] Rate limiting and account lockout
- [x] Input validation on all endpoints
- [x] SQL injection prevention (parameterized queries)
- [x] CORS, Helmet, CSP headers
- [x] Structured logging with request tracing
- [x] Docker deployment
- [x] Health check endpoint
- [ ] Add Redis for multi-instance rate limiting
- [ ] Add Elasticsearch for full-text search
- [ ] Add CI/CD pipeline
- [ ] Add SSL certificate management

</details>

<details>
<summary><strong>Q: How does the offline queue work?</strong></summary>

When the mobile app detects no internet:

1. **Actions are serialized** to Hive local database (booking creates, messages, reviews)
2. **Connectivity banner** shows "Offline" in the UI
3. When internet returns, **OfflineQueueService** replays each action via API
4. Actions include retry count (max 3 retries before abandonment)
5. Failed syncs show user-visible error toast

</details>

---

## 🙏 Acknowledgments & Inspiration

### Open-Source Projects Referenced

This project's architecture and documentation are inspired by world-class open-source repositories:

| Project | Inspiration Taken |
|---------|------------------|
| [**React**](https://github.com/facebook/react) | Component architecture, hooks pattern |
| [**Next.js**](https://github.com/vercel/next.js) | README structure, deployment docs |
| [**Supabase**](https://github.com/supabase/supabase) | API documentation style, badge design |
| [**Stripe**](https://stripe.com/docs/api) | API reference format, curl examples |
| [**Flutter**](https://github.com/flutter/flutter) | Mobile architecture, widget patterns |
| [**Express.js**](https://github.com/expressjs/express) | Middleware pattern, error handling |
| [**Swagger/OpenAPI**](https://swagger.io/) | API endpoint documentation format |
| [**Urban Company**](https://www.urbancompany.com/) | Business model, service categories |
| [**Swiggy**](https://www.swiggy.com/) | Real-time tracking UX, delivery FSM |
| [**Razorpay**](https://razorpay.com/docs/) | Payment integration patterns |

### Technologies & Libraries

Special thanks to the maintainers of all open-source packages used in this project — see `backend/package.json`, `frontend/package.json`, and `mobile/skillconnect/pubspec.yaml` for the full list.

---

## 📊 Project Statistics

| Metric | Count |
|--------|-------|
| **Total Source Files** | 267+ |
| **Dart (Mobile)** | 74 files / 14,460 LOC |
| **JavaScript (Backend)** | 96 files / 7,639 LOC |
| **React (Frontend)** | 49 JSX files |
| **CSS Stylesheets** | 38 files |
| **SQL Migrations** | 10 files / 235 LOC |
| **API Endpoints** | 75+ |
| **Database Tables** | 20+ |
| **Backend Controllers** | 25 |
| **Mobile Screens** | 22+ |
| **Test Files** | 15+ |
| **Supported Languages** | 3 (EN, HI, TE) |

---

## 📝 License

This project is licensed under the **ISC License** — see the [ISC License](https://opensource.org/licenses/ISC) for details.

```
Copyright (c) 2025 SkillConnect Contributors

Permission to use, copy, modify, and/or distribute this software
for any purpose with or without fee is hereby granted, provided
that the above copyright notice and this permission notice appear
in all copies.
```

---

<div align="center">

### Built with ❤️ for India's Service Economy

**SkillConnect** — *Connecting skills with opportunities, one booking at a time.*

<br/>

```
 ╔═══════════════════════════════════════════════════════╗
 ║                                                       ║
 ║    🛠️  SkillConnect                                    ║
 ║    ━━━━━━━━━━━━━━━━                                   ║
 ║                                                       ║
 ║    Customers  →  Search  →  Book  →  Track  →  Pay    ║
 ║                                                       ║
 ║    Professionals  →  Profile  →  Accept  →  Earn      ║
 ║                                                       ║
 ║    50+ Categories  •  3 Languages  •  Offline-First   ║
 ║                                                       ║
 ╚═══════════════════════════════════════════════════════╝
```

<br/>

[![Made with Node.js](https://img.shields.io/badge/Made%20with-Node.js-339933?style=flat-square&logo=node.js)](https://nodejs.org/)
[![Made with React](https://img.shields.io/badge/Made%20with-React-61DAFB?style=flat-square&logo=react)](https://react.dev/)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
[![Made with PostgreSQL](https://img.shields.io/badge/Made%20with-PostgreSQL-4169E1?style=flat-square&logo=postgresql)](https://postgresql.org/)
[![Made with Express](https://img.shields.io/badge/Made%20with-Express-000000?style=flat-square&logo=express)](https://expressjs.com/)
[![Made with Docker](https://img.shields.io/badge/Made%20with-Docker-2496ED?style=flat-square&logo=docker)](https://docker.com/)

<br/>

⭐ **Star this repo** if you find it useful! | 🍴 **Fork** to build your own marketplace

<br/>

[![GitHub stars](https://img.shields.io/github/stars/Govin111b8/SKILL?style=social)](https://github.com/Govin111b8/SKILL/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/Govin111b8/SKILL?style=social)](https://github.com/Govin111b8/SKILL/network/members)

<br/>

---

*Last updated: May 2026 • [Back to top](#%EF%B8%8F-skillconnect)*

</div>
