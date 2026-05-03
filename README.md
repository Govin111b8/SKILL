<div align="center">

# 🛠️ SkillConnect

### *India's Premier Hyperlocal Service Marketplace Platform*

[![Node.js](https://img.shields.io/badge/Node.js-22+-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![React](https://img.shields.io/badge/React-19-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.8-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org/)
[![Express](https://img.shields.io/badge/Express-5-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com/)

<br/>

> **A production-grade, full-stack marketplace connecting customers with KYC-verified skilled professionals — featuring real-time tracking, integrated payments, multilingual support, voice search, offline-first mobile, and enterprise-grade security.**

<br/>

[🚀 Quick Start](#-quick-start) •
[📱 Mobile App](#-mobile-app-flutter) •
[🔌 API Reference](#-api-reference) •
[🏗️ Architecture](#%EF%B8%8F-system-architecture) •
[🧪 Testing](#-testing) •
[📦 Deployment](#-deployment)

---

</div>

## 📋 Table of Contents

<details>
<summary><strong>Click to expand full navigation</strong></summary>

- [Overview](#-overview)
- [Key Features](#-key-features)
- [System Architecture](#️-system-architecture)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [Backend API Server](#-backend-api-server)
- [Frontend Web App](#-frontend-web-app-react)
- [Mobile App (Flutter)](#-mobile-app-flutter)
- [Database](#-database)
- [API Reference](#-api-reference)
- [Security & Compliance](#-security--compliance)
- [Real-Time Features](#-real-time-features)
- [Payment Integration](#-payment-integration)
- [Internationalization](#-internationalization-i18n)
- [Offline-First Architecture](#-offline-first-architecture)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Project Structure](#-project-structure)
- [Performance & Scalability](#-performance--scalability)
- [Contributing](#-contributing)
- [Roadmap](#-roadmap)
- [License](#-license)

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

## 🖥️ Backend API Server

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

---

## ⚡ Real-Time Features

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

## 🧪 Testing

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
- [x] Category-based search with geo-filtering
- [x] Booking FSM with role-gated transitions
- [x] Real-time chat (WebSocket)
- [x] Live GPS tracking (Swiggy-style)
- [x] Razorpay payment integration
- [x] KYC verification pipeline
- [x] Dispute resolution system
- [x] Warranty claims
- [x] Emergency service dispatch
- [x] Referral program
- [x] Multilingual (EN/HI/TE)
- [x] Voice search
- [x] Offline-first mobile
- [x] Push notifications
- [x] Admin dashboard
- [x] Analytics engine
- [x] Fraud prevention
- [x] Docker deployment

### 🔜 Planned (v2.0)

- [ ] AI-powered service matching
- [ ] Video consultations
- [ ] Subscription plans for professionals
- [ ] Multi-city expansion with geo-fencing
- [ ] Integration with Google Maps SDK
- [ ] Payment split (platform fee automation)
- [ ] Machine learning fraud detection
- [ ] iOS App Store deployment
- [ ] Automated testing CI/CD pipeline
- [ ] Redis caching layer
- [ ] Elasticsearch for full-text search
- [ ] Service-level SLA tracking

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

This project is licensed under the **ISC License**.

---

<div align="center">

### Built with ❤️ for India's Service Economy

**SkillConnect** — *Connecting skills with opportunities, one booking at a time.*

<br/>

[![Made with Node.js](https://img.shields.io/badge/Made%20with-Node.js-339933?style=flat-square&logo=node.js)](https://nodejs.org/)
[![Made with React](https://img.shields.io/badge/Made%20with-React-61DAFB?style=flat-square&logo=react)](https://react.dev/)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
[![Made with PostgreSQL](https://img.shields.io/badge/Made%20with-PostgreSQL-4169E1?style=flat-square&logo=postgresql)](https://postgresql.org/)

<br/>

⭐ **Star this repo** if you find it useful!

</div>