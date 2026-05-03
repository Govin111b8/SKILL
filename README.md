<div align="center">

<!-- ═══════════════════════════════════════════════════════════════════════════
     SkillConnect — World-Class README Documentation
     Inspired by: React, Next.js, Flutter, Supabase, Stripe, Vercel
     ═══════════════════════════════════════════════════════════════════════════ -->

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
[![Test Coverage: 50%+](https://img.shields.io/badge/Coverage-50%25+-brightgreen?style=flat-square)](#-testing--quality-assurance)
[![API Endpoints: 75+](https://img.shields.io/badge/API_Endpoints-75+-blue?style=flat-square)](#-api-reference--endpoints)
[![Languages: EN|HI|TE](https://img.shields.io/badge/Languages-EN%20|%20HI%20|%20TE-orange?style=flat-square)](#-internationalization--localization-i18n)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-One%20Command-2496ED?style=flat-square&logo=docker)](#-docker-deployment)

<br/>

> **A production-grade, full-stack marketplace connecting customers with KYC-verified skilled professionals — featuring real-time GPS tracking, integrated Razorpay payments, multilingual voice search, offline-first mobile, AI-powered matching, dispute resolution, warranty protection, and enterprise-grade security across 50+ service categories.**

<br/>

[🚀 Quick Start](#-quick-start) •
[📱 Mobile App](#-mobile-application-flutter) •
[🔌 API Reference](#-api-reference--endpoints) •
[🏗️ Architecture](#%EF%B8%8F-system-architecture) •
[🧪 Testing](#-testing--quality-assurance) •
[📦 Deployment](#-deployment--devops) •
[🔒 Security](#-security--compliance) •
[🤝 Contributing](#-contributing) •
[❓ FAQ](#-frequently-asked-questions)

<br/>

---

</div>

<br/>

## 📑 Table of Contents

<details>
<summary><strong>Click to expand full table of contents</strong></summary>

- [🎯 Executive Summary](#-executive-summary)
- [✨ Feature Highlights](#-feature-highlights)
- [🏗️ System Architecture](#%EF%B8%8F-system-architecture)
  - [High-Level Architecture](#high-level-architecture)
  - [Technology Stack](#technology-stack)
  - [Database Design](#database-design)
  - [Directory Structure](#directory-structure)
- [🚀 Quick Start](#-quick-start)
  - [Prerequisites](#prerequisites)
  - [One-Command Setup (Docker)](#one-command-setup-docker)
  - [Manual Setup](#manual-setup)
  - [Environment Configuration](#environment-configuration)
- [🖥️ Backend (Node.js + Express 5)](#%EF%B8%8F-backend-nodejs--express-5)
  - [API Architecture](#api-architecture)
  - [Authentication & Authorization](#authentication--authorization)
  - [Route Modules](#route-modules)
  - [Middleware Pipeline](#middleware-pipeline)
  - [Real-time WebSocket Hub](#real-time-websocket-hub)
- [🌐 Frontend (React 19 + Vite)](#-frontend-react-19--vite)
  - [Component Architecture](#component-architecture)
  - [Pages & Views](#pages--views)
  - [State Management](#state-management)
  - [Responsive Design](#responsive-design)
- [📱 Mobile Application (Flutter)](#-mobile-application-flutter)
  - [Cross-Platform Support](#cross-platform-support)
  - [Offline-First Architecture](#offline-first-architecture)
  - [Voice Search (Telugu/Hindi)](#voice-search-teluguhindi)
  - [Real-time GPS Tracking](#real-time-gps-tracking)
- [🗄️ Database (PostgreSQL 16)](#%EF%B8%8F-database-postgresql-16)
  - [Schema Design](#schema-design)
  - [Migrations](#migrations)
  - [Indexes & Performance](#indexes--performance)
- [🔌 API Reference & Endpoints](#-api-reference--endpoints)
  - [Authentication API](#authentication-api)
  - [Professional API](#professional-api)
  - [Booking & Payment API](#booking--payment-api)
  - [Search & Discovery API](#search--discovery-api)
  - [Messaging & Notifications API](#messaging--notifications-api)
  - [Admin & Analytics API](#admin--analytics-api)
- [💳 Payments & Transactions](#-payments--transactions)
- [🔐 Security & Compliance](#-security--compliance)
- [🌍 Internationalization & Localization (i18n)](#-internationalization--localization-i18n)
- [📡 Real-time Features](#-real-time-features)
- [🤖 AI-Powered Features](#-ai-powered-features)
- [🧪 Testing & Quality Assurance](#-testing--quality-assurance)
- [📦 Deployment & DevOps](#-deployment--devops)
- [📊 Monitoring & Observability](#-monitoring--observability)
- [🚀 Performance Optimization](#-performance-optimization)
- [🤝 Contributing](#-contributing)
- [📋 Roadmap](#-roadmap)
- [❓ Frequently Asked Questions](#-frequently-asked-questions)
- [📜 License](#-license)
- [🙏 Acknowledgments](#-acknowledgments)

</details>

<br/>

---

<br/>

## 🎯 Executive Summary

<table>
<tr>
<td width="50%">

### The Problem

India's unorganized service sector (worth **₹12+ lakh crore**) suffers from:
- 🔍 **Discovery Gap** — Customers can't find trusted professionals nearby
- ❌ **Trust Deficit** — No KYC verification, fake reviews, scams
- 💸 **Payment Friction** — Cash-only, no escrow protection
- 📵 **Digital Divide** — Professionals lack digital presence
- 🗣️ **Language Barriers** — Most platforms are English-only

</td>
<td width="50%">

### Our Solution

**SkillConnect** bridges this gap with:
- 📍 **Hyperlocal Discovery** — GPS-based matching within configurable radius
- ✅ **KYC Verification** — Government ID + selfie + phone verification
- 💳 **Secure Payments** — Razorpay escrow with milestone-based releases
- 🏪 **Digital Storefronts** — Full-featured professional profiles
- 🗣️ **Multilingual Voice Search** — Telugu, Hindi & English support
- 🛡️ **Trust & Safety** — Dispute resolution, warranty protection, fraud prevention

</td>
</tr>
</table>

<br/>

### 📈 Key Metrics & Scale

| Metric | Value |
|--------|-------|
| 🗂️ **Service Categories** | 50+ across 10 verticals |
| 🔌 **API Endpoints** | 75+ RESTful endpoints |
| 👥 **User Roles** | Customer, Professional, Admin, Agent |
| 📱 **Platforms** | Web (React), Mobile (Flutter — iOS/Android/Web) |
| 🌐 **Languages** | English, Hindi, Telugu |
| 🔒 **Security** | JWT + Refresh tokens, Helmet, Rate limiting, CORS |
| ⚡ **Real-time** | WebSocket hub with presence, typing, GPS tracking |
| 🗄️ **Database** | 15+ tables, 10+ migrations, optimized indexes |

<br/>

---

<br/>

## ✨ Feature Highlights

<div align="center">

### 🏆 Platform Capabilities at a Glance

</div>

<br/>

<table>
<tr>
<td width="33%" valign="top">

#### 👤 For Customers
- 🔍 Smart search with filters (location, rating, price, availability)
- 📍 GPS-based professional discovery
- 🗣️ Voice search in Telugu/Hindi/English
- 📅 Real-time booking & scheduling
- 💬 In-app messaging with media sharing
- 💳 Secure Razorpay payments
- ⭐ Verified reviews & ratings
- 🛡️ Warranty protection on services
- 🆘 Emergency service requests
- ❤️ Favorites & saved professionals
- 🔔 Push notifications
- 📊 Booking history & tracking

</td>
<td width="33%" valign="top">

#### 🔧 For Professionals
- 🏪 Customizable digital storefront
- 📸 Portfolio management (images/videos/certificates)
- 📅 Schedule & availability management
- 💰 Earnings dashboard & analytics
- 📈 Performance insights & growth metrics
- 🎯 AI-powered job matching
- 💬 Real-time client messaging
- 🔔 Instant booking notifications
- 📍 Location-based lead generation
- 🏷️ Subscription tiers (Basic/Premium/Featured)
- 📱 Mobile-first experience
- 🆔 KYC verification badge

</td>
<td width="33%" valign="top">

#### 🛡️ Platform & Admin
- 👨‍💼 Admin dashboard & controls
- 🤖 Agent management system
- 📊 Platform-wide analytics
- 🚨 Fraud prevention & detection
- ⚖️ Dispute resolution workflow
- 🔐 KYC verification pipeline
- 📋 Complaint management
- 🎁 Referral & growth system
- 💳 Payment webhook handling
- 📈 Revenue & conversion tracking
- 🌐 SEO optimization
- 🔄 Real-time WebSocket hub

</td>
</tr>
</table>

<br/>

---

<br/>

## 🏗️ System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              SkillConnect Platform                                    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────────────────┐  │
│  │   React 19 SPA   │    │  Flutter Mobile   │    │     Admin Dashboard          │  │
│  │   (Vite + HMR)   │    │  (iOS/Android/Web)│    │     (React + Analytics)      │  │
│  └────────┬─────────┘    └────────┬─────────┘    └──────────────┬───────────────┘  │
│           │                        │                              │                   │
│           └────────────────────────┼──────────────────────────────┘                   │
│                                    │                                                  │
│                    ┌───────────────┴───────────────┐                                  │
│                    │     API Gateway / Nginx       │                                  │
│                    │    (Load Balancer + SSL)       │                                  │
│                    └───────────────┬───────────────┘                                  │
│                                    │                                                  │
│  ┌─────────────────────────────────┼─────────────────────────────────────────────┐   │
│  │               Express 5 Backend (Node.js 22+)                                  │   │
│  │                                                                                 │   │
│  │  ┌───────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │   │
│  │  │   Auth    │ │ Booking  │ │ Payment  │ │ Search   │ │   WebSocket Hub  │  │   │
│  │  │  (JWT +   │ │  Engine  │ │ (Razor-  │ │ (Geo +   │ │   (Presence +    │  │   │
│  │  │  Refresh) │ │          │ │   pay)   │ │  Filter) │ │    Messaging)    │  │   │
│  │  └───────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────────────┘  │   │
│  │                                                                                 │   │
│  │  ┌───────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │   │
│  │  │    KYC    │ │ Dispute  │ │ Matching │ │Analytics │ │  Notification    │  │   │
│  │  │ Pipeline  │ │Resolution│ │   (AI)   │ │  Engine  │ │    Service       │  │   │
│  │  └───────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────────────┘  │   │
│  └─────────────────────────────────┼─────────────────────────────────────────────┘   │
│                                    │                                                  │
│                    ┌───────────────┴───────────────┐                                  │
│                    │   PostgreSQL 16 + pgcrypto    │                                  │
│                    │   (UUID, GeoIndex, Triggers)   │                                  │
│                    └───────────────────────────────┘                                  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

<br/>

### Technology Stack

<table>
<tr>
<th width="15%">Layer</th>
<th width="25%">Technology</th>
<th width="15%">Version</th>
<th width="45%">Purpose</th>
</tr>
<tr><td><strong>Frontend</strong></td><td>React + Vite</td><td>19.x + 8.x</td><td>Single-page application with hot module replacement</td></tr>
<tr><td></td><td>React Router</td><td>7.x</td><td>Client-side routing with nested layouts</td></tr>
<tr><td></td><td>React Icons</td><td>5.x</td><td>Comprehensive icon library</td></tr>
<tr><td></td><td>Vitest</td><td>4.x</td><td>Unit & integration testing</td></tr>
<tr><td><strong>Backend</strong></td><td>Node.js + Express</td><td>22+ / 5.x</td><td>REST API server with async middleware</td></tr>
<tr><td></td><td>PostgreSQL (pg)</td><td>8.x</td><td>Database driver with connection pooling</td></tr>
<tr><td></td><td>JWT + bcryptjs</td><td>9.x / 3.x</td><td>Authentication & password hashing</td></tr>
<tr><td></td><td>Helmet + CORS</td><td>8.x / 2.x</td><td>Security headers & cross-origin protection</td></tr>
<tr><td></td><td>WebSocket (ws)</td><td>8.x</td><td>Real-time bi-directional communication</td></tr>
<tr><td></td><td>Pino</td><td>10.x</td><td>High-performance structured logging</td></tr>
<tr><td></td><td>Multer</td><td>2.x</td><td>File upload handling (multipart/form-data)</td></tr>
<tr><td></td><td>Express Validator</td><td>7.x</td><td>Input validation & sanitization</td></tr>
<tr><td></td><td>Express Rate Limit</td><td>8.x</td><td>API rate limiting & DDoS protection</td></tr>
<tr><td></td><td>Jest + Supertest</td><td>30.x / 7.x</td><td>Backend testing with HTTP assertions</td></tr>
<tr><td><strong>Mobile</strong></td><td>Flutter + Dart</td><td>3.8+</td><td>Cross-platform native mobile (iOS/Android/Web)</td></tr>
<tr><td></td><td>Provider</td><td>6.x</td><td>State management</td></tr>
<tr><td></td><td>Hive + Hive Flutter</td><td>2.x</td><td>Offline-first local storage</td></tr>
<tr><td></td><td>Geolocator</td><td>12.x</td><td>GPS location services</td></tr>
<tr><td></td><td>Speech to Text</td><td>7.x</td><td>Voice search (Telugu/Hindi/English)</td></tr>
<tr><td></td><td>WebSocket Channel</td><td>2.x</td><td>Real-time communication</td></tr>
<tr><td></td><td>Cached Network Image</td><td>3.x</td><td>Image caching & performance</td></tr>
<tr><td><strong>Database</strong></td><td>PostgreSQL</td><td>16</td><td>ACID-compliant relational database</td></tr>
<tr><td></td><td>pgcrypto</td><td>Built-in</td><td>UUID generation & cryptographic functions</td></tr>
<tr><td><strong>DevOps</strong></td><td>Docker + Compose</td><td>Latest</td><td>Containerization & orchestration</td></tr>
<tr><td></td><td>Nginx</td><td>Alpine</td><td>Reverse proxy & static file serving</td></tr>
<tr><td></td><td>GitHub Actions</td><td>—</td><td>CI/CD pipeline</td></tr>
</table>

<br/>

### Database Design

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DATABASE ENTITY RELATIONSHIPS                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────┐     1:1     ┌──────────────┐     M:M     ┌──────────────┐   │
│  │  USERS   │────────────▶│PROFESSIONALS │◀────────────▶│ CATEGORIES   │   │
│  └──────┬───┘             └──────┬───────┘             └──────────────┘   │
│         │                        │                                         │
│         │  1:M                   │  1:M                                    │
│         ▼                        ▼                                         │
│  ┌──────────┐             ┌──────────────┐                                │
│  │ BOOKINGS │────────────▶│  PORTFOLIO   │                                │
│  └──────┬───┘             └──────────────┘                                │
│         │                                                                  │
│         │  1:1                                                             │
│         ▼                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ PAYMENTS │  │ REVIEWS  │  │ DISPUTES │  │COMPLAINTS│  │WARRANTIES│  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │ MESSAGES │  │FAVORITES │  │REFERRALS │  │SCHEDULES │               │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key Tables:** `users` • `professionals` • `categories` • `professional_categories` • `portfolio_items` • `contacts` • `reviews` • `complaints` • `bookings` • `payments` • `messages` • `disputes` • `warranties` • `favorites` • `schedules` • `referrals` • `notifications`

<br/>

### Directory Structure

```
SKILL/
├── 📁 backend/                    # Node.js + Express 5 API Server
│   ├── 📁 src/
│   │   ├── 📁 config/            # Database, logger, app configuration
│   │   ├── 📁 controllers/       # 28 controller modules (business logic)
│   │   ├── 📁 middleware/        # Auth, cache, error handling, fraud prevention
│   │   ├── 📁 realtime/          # WebSocket hub (presence, messaging, tracking)
│   │   ├── 📁 routes/            # 30 route modules (REST endpoints)
│   │   ├── 📁 services/          # Service layer (payments, notifications, etc.)
│   │   ├── 📁 utils/             # Shared utilities
│   │   ├── 📄 app.js             # Express app configuration
│   │   └── 📄 server.js          # HTTP + WebSocket server entry point
│   ├── 📁 tests/                  # Jest test suites
│   ├── 📁 public/                 # Static assets
│   ├── 📄 Dockerfile             # Backend container image
│   ├── 📄 .env.example           # Environment variables template
│   ├── 📄 .eslintrc.json         # Linting configuration
│   └── 📄 package.json           # Dependencies & scripts
│
├── 📁 frontend/                   # React 19 + Vite SPA
│   ├── 📁 src/
│   │   ├── 📁 api/               # API client & HTTP utilities
│   │   ├── 📁 components/        # 34 reusable UI components
│   │   ├── 📁 context/           # React context providers
│   │   ├── 📁 data/              # Static data & constants
│   │   ├── 📁 pages/             # 30+ page components & views
│   │   │   └── 📁 admin/         # Admin dashboard pages
│   │   ├── 📁 tests/             # Vitest test suites
│   │   ├── 📄 App.jsx            # Root component & routing
│   │   └── 📄 main.jsx           # Application entry point
│   ├── 📄 Dockerfile             # Frontend container (Nginx)
│   ├── 📄 nginx.conf             # Nginx reverse proxy config
│   ├── 📄 vite.config.js         # Vite build configuration
│   ├── 📄 vitest.config.js       # Test configuration
│   └── 📄 package.json           # Dependencies & scripts
│
├── 📁 mobile/skillconnect/        # Flutter Cross-Platform App
│   ├── 📁 lib/
│   │   ├── 📁 data/              # Data layer & repositories
│   │   ├── 📁 l10n/              # Localization (EN/HI/TE)
│   │   ├── 📁 models/            # Data models
│   │   ├── 📁 screens/           # 23+ screen modules
│   │   │   ├── 📁 auth/          # Login, register, OTP
│   │   │   ├── 📁 bookings/      # Booking management
│   │   │   ├── 📁 home/          # Home & discovery
│   │   │   ├── 📁 messages/      # Chat & messaging
│   │   │   ├── 📁 payments/      # Payment flows
│   │   │   ├── 📁 search/        # Search & filters
│   │   │   ├── 📁 storefront/    # Professional profiles
│   │   │   └── 📁 tracking/      # Real-time GPS tracking
│   │   ├── 📁 services/          # 16 service classes
│   │   │   ├── 📁 offline/       # Hive-based offline storage
│   │   │   ├── 📄 auth_service.dart
│   │   │   ├── 📄 realtime_service.dart
│   │   │   └── 📄 smart_location_service.dart
│   │   ├── 📁 widgets/           # Reusable Flutter widgets
│   │   └── 📄 main.dart          # App entry point
│   ├── 📁 android/               # Android-specific configuration
│   ├── 📁 ios/                   # iOS-specific configuration
│   ├── 📁 web/                   # Web-specific configuration
│   ├── 📁 assets/l10n/           # Translation files
│   └── 📄 pubspec.yaml           # Flutter dependencies
│
├── 📁 database/                   # Database Management
│   ├── 📄 schema.sql             # Core schema (15+ tables, enums, indexes)
│   ├── 📄 seed.sql               # Demo data & test fixtures
│   └── 📁 migrations/            # 10+ incremental migrations
│       ├── 📄 001_kyc.sql
│       ├── 📄 002_bookings_chat.sql
│       ├── 📄 003_review_by_booking.sql
│       ├── 📄 004_seed_geo.sql
│       ├── 📄 005_reputation_trigger.sql
│       ├── 📄 006_phase1_features.sql
│       ├── 📄 006_storefront_fields.sql
│       ├── 📄 007_auth_admin_services.sql
│       ├── 📄 007_provider_type.sql
│       ├── 📄 008_analytics_and_chat_images.sql
│       ├── 📄 009_agent_system.sql
│       └── 📄 010_growth_acquisition.sql
│
├── 📄 docker-compose.yml          # Full-stack orchestration
├── 📄 build.sh                    # Automated build + test + deploy script
├── 📄 .gitignore                  # Git ignore rules
└── 📄 README.md                   # This file
```

<br/>

---

<br/>

## 🚀 Quick Start

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Node.js](https://nodejs.org/) | 22+ | Backend runtime |
| [PostgreSQL](https://postgresql.org/) | 16+ | Database |
| [Docker](https://docker.com/) | Latest | Containerization (optional) |
| [Flutter](https://flutter.dev/) | 3.8+ | Mobile development (optional) |
| [Git](https://git-scm.com/) | 2.x+ | Version control |

<br/>

### One-Command Setup (Docker)

```bash
# Clone the repository
git clone https://github.com/Govin111b8/SKILL.git
cd SKILL

# Start everything with Docker Compose
docker compose up -d

# 🎉 That's it! Services are running:
# ├── Frontend:  http://localhost:3000
# ├── Backend:   http://localhost:5000
# └── Database:  localhost:5432
```

<br/>

### Manual Setup

<details>
<summary><strong>📋 Step-by-Step Manual Installation</strong></summary>

<br/>

#### 1️⃣ Clone & Setup Database

```bash
# Clone repository
git clone https://github.com/Govin111b8/SKILL.git
cd SKILL

# Create PostgreSQL database
createdb skillconnect

# Apply schema and seed data
psql -U postgres -d skillconnect -f database/schema.sql
psql -U postgres -d skillconnect -f database/seed.sql

# Apply migrations (in order)
for f in database/migrations/*.sql; do
  psql -U postgres -d skillconnect -f "$f"
done
```

#### 2️⃣ Start Backend

```bash
cd backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your database credentials

# Start development server
npm run dev

# ✓ Backend running at http://localhost:5000
```

#### 3️⃣ Start Frontend

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev

# ✓ Frontend running at http://localhost:5173
```

#### 4️⃣ Start Mobile App (Optional)

```bash
cd mobile/skillconnect

# Get Flutter dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Or build for web
flutter build web --release
```

</details>

<br/>

### Environment Configuration

<details>
<summary><strong>🔧 Complete Environment Variables Reference</strong></summary>

<br/>

```env
# ═══════════════════════════════════════════════════
# Application
# ═══════════════════════════════════════════════════
NODE_ENV=development          # development | production | test
PORT=5000                     # Server port

# ═══════════════════════════════════════════════════
# Database (PostgreSQL)
# ═══════════════════════════════════════════════════
DB_HOST=localhost             # Database host
DB_PORT=5432                  # Database port
DB_NAME=skillconnect          # Database name
DB_USER=postgres              # Database user
DB_PASSWORD=password          # Database password
DB_MAX_CONNECTIONS=20         # Connection pool maximum
DB_IDLE_TIMEOUT=30000         # Idle connection timeout (ms)
DB_CONNECTION_TIMEOUT=5000    # Connection attempt timeout (ms)

# ═══════════════════════════════════════════════════
# Authentication (JWT)
# ═══════════════════════════════════════════════════
JWT_SECRET=your-secret-key-minimum-32-chars-long!!
JWT_EXPIRES_IN=15m            # Access token lifetime
JWT_REFRESH_EXPIRES_IN=7d    # Refresh token lifetime

# ═══════════════════════════════════════════════════
# Security
# ═══════════════════════════════════════════════════
CORS_ORIGINS=http://localhost:3000,http://localhost:5173
RATE_LIMIT_AUTH_MAX=30        # Auth endpoint rate limit
RATE_LIMIT_API_MAX=200        # General API rate limit
MAX_LOGIN_ATTEMPTS=5          # Before account lockout
LOCKOUT_DURATION_MIN=15       # Lockout period in minutes

# ═══════════════════════════════════════════════════
# Logging
# ═══════════════════════════════════════════════════
LOG_LEVEL=debug               # trace | debug | info | warn | error | fatal
```

</details>

<br/>

---

<br/>

## 🖥️ Backend (Node.js + Express 5)

### API Architecture

The backend follows a **layered architecture** pattern with clear separation of concerns:

```
Request → Middleware Pipeline → Route → Controller → Service → Database
                                                          ↓
Response ← Error Handler ← Controller ← Service ← Query Result
```

<br/>

### Authentication & Authorization

```
┌─────────────────────────────────────────────────────────────────┐
│                    Authentication Flow                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Client                    Server                    Database    │
│    │                         │                          │        │
│    │── POST /auth/register ─▶│                          │        │
│    │                         │── Hash password ────────▶│        │
│    │                         │◀── User created ─────────│        │
│    │◀── JWT + Refresh ───────│                          │        │
│    │                         │                          │        │
│    │── POST /auth/login ────▶│                          │        │
│    │                         │── Verify credentials ──▶│        │
│    │                         │◀── User data ────────────│        │
│    │◀── JWT + Refresh ───────│                          │        │
│    │                         │                          │        │
│    │── GET /api/* ──────────▶│                          │        │
│    │   (Bearer Token)        │── Verify JWT ───────────▶│        │
│    │                         │◀── Valid ────────────────│        │
│    │◀── Protected Data ──────│                          │        │
│    │                         │                          │        │
│    │── POST /auth/refresh ──▶│                          │        │
│    │   (Refresh Token)       │── Validate + Rotate ───▶│        │
│    │◀── New JWT + Refresh ───│                          │        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Security Features:**
- 🔑 **JWT Access Tokens** — Short-lived (15 min) for API access
- 🔄 **Refresh Tokens** — Long-lived (7 days) with rotation
- 🔒 **bcryptjs** — Password hashing with salt rounds
- 🚫 **Account Lockout** — After 5 failed login attempts (15 min cooldown)
- 🛡️ **Rate Limiting** — Per-endpoint configurable limits

<br/>

### Route Modules

The backend exposes **30 route modules** with **75+ endpoints**:

<table>
<tr>
<th>Module</th>
<th>Endpoints</th>
<th>Description</th>
</tr>
<tr><td><code>/api/auth</code></td><td>register, login, refresh, logout, verify</td><td>Authentication & session management</td></tr>
<tr><td><code>/api/users</code></td><td>profile, update, settings, delete</td><td>User account management</td></tr>
<tr><td><code>/api/professionals</code></td><td>CRUD, search, nearby, availability</td><td>Professional profile management</td></tr>
<tr><td><code>/api/categories</code></td><td>list, hierarchy, details</td><td>Service category tree</td></tr>
<tr><td><code>/api/search</code></td><td>query, filter, geo, suggestions</td><td>Full-text + geo search engine</td></tr>
<tr><td><code>/api/bookings</code></td><td>create, update, cancel, complete, track</td><td>Booking lifecycle management</td></tr>
<tr><td><code>/api/payments</code></td><td>create-order, verify, refund, history</td><td>Razorpay payment processing</td></tr>
<tr><td><code>/api/messages</code></td><td>threads, send, media, read-receipts</td><td>In-app messaging system</td></tr>
<tr><td><code>/api/notifications</code></td><td>list, mark-read, preferences</td><td>Push & in-app notifications</td></tr>
<tr><td><code>/api/reviews</code></td><td>create, list, respond, report</td><td>Review & rating system</td></tr>
<tr><td><code>/api/portfolio</code></td><td>upload, manage, reorder</td><td>Professional portfolio management</td></tr>
<tr><td><code>/api/kyc</code></td><td>submit, verify, status</td><td>KYC verification pipeline</td></tr>
<tr><td><code>/api/favorites</code></td><td>add, remove, list</td><td>Favorites/wishlist management</td></tr>
<tr><td><code>/api/schedule</code></td><td>set, update, availability</td><td>Professional scheduling</td></tr>
<tr><td><code>/api/disputes</code></td><td>create, respond, resolve, escalate</td><td>Dispute resolution workflow</td></tr>
<tr><td><code>/api/warranties</code></td><td>create, claim, status</td><td>Service warranty protection</td></tr>
<tr><td><code>/api/emergency</code></td><td>request, respond, track</td><td>Emergency service requests</td></tr>
<tr><td><code>/api/referrals</code></td><td>generate, track, redeem</td><td>Referral & reward system</td></tr>
<tr><td><code>/api/dashboard</code></td><td>stats, earnings, funnel</td><td>Professional analytics dashboard</td></tr>
<tr><td><code>/api/analytics</code></td><td>events, metrics, reports</td><td>Platform-wide analytics</td></tr>
<tr><td><code>/api/storefront</code></td><td>get, update, customize</td><td>Professional digital storefront</td></tr>
<tr><td><code>/api/matching</code></td><td>suggest, accept, decline</td><td>AI-powered job matching</td></tr>
<tr><td><code>/api/complaints</code></td><td>file, update, resolve</td><td>Complaint management</td></tr>
<tr><td><code>/api/contacts</code></td><td>request, accept, decline</td><td>Contact request system</td></tr>
<tr><td><code>/api/uploads</code></td><td>image, video, document</td><td>File upload (multer)</td></tr>
<tr><td><code>/api/agents</code></td><td>register, dashboard, wallet</td><td>Agent management system</td></tr>
<tr><td><code>/api/admin</code></td><td>users, reports, settings, moderate</td><td>Admin control panel</td></tr>
<tr><td><code>/api/webhooks</code></td><td>razorpay, notifications</td><td>External webhook handlers</td></tr>
<tr><td><code>/api/seo</code></td><td>sitemap, meta, structured-data</td><td>SEO optimization</td></tr>
<tr><td><code>/api/growth</code></td><td>campaigns, acquisition, metrics</td><td>Growth & acquisition tools</td></tr>
</table>

<br/>

### Middleware Pipeline

```
Request
  │
  ├── 1. requestId          → Unique request correlation ID (X-Request-ID)
  ├── 2. helmet             → Security headers (CSP, HSTS, XSS, etc.)
  ├── 3. compression        → gzip/brotli response compression
  ├── 4. cors               → Cross-origin resource sharing
  ├── 5. express.json       → JSON body parsing (10kb limit)
  ├── 6. httpLogger         → Structured request logging (Pino)
  ├── 7. rateLimit          → Per-route rate limiting
  ├── 8. auth (optional)    → JWT verification & user injection
  ├── 9. validate           → Input validation (express-validator)
  ├── 10. fraudPrevention   → Suspicious activity detection
  ├── 11. cache (optional)  → Response caching layer
  │
  ▼
Controller → Service → Database
  │
  ├── errorHandler          → Centralized error formatting & logging
  │
  ▼
Response
```

<br/>

### Real-time WebSocket Hub

The WebSocket hub (`/ws`) supports:

| Feature | Event | Description |
|---------|-------|-------------|
| 🟢 **Presence** | `user:online` / `user:offline` | Real-time online status |
| 💬 **Messaging** | `message:new` / `message:read` | Instant chat messages |
| ⌨️ **Typing** | `typing:start` / `typing:stop` | Typing indicators |
| 📍 **GPS Tracking** | `location:update` | Live professional location |
| 🔔 **Notifications** | `notification:new` | Push-style notifications |
| 📅 **Bookings** | `booking:update` / `booking:status` | Booking state changes |
| 💳 **Payments** | `payment:confirmed` | Payment confirmations |

**Connection:**
```javascript
const ws = new WebSocket('wss://your-domain.com/ws?token=<JWT_TOKEN>');
```

<br/>

---

<br/>

## 🌐 Frontend (React 19 + Vite)

### Component Architecture

The frontend follows an **atomic design pattern** with clear component hierarchy:

```
src/
├── components/     → Atoms & Molecules (reusable building blocks)
├── pages/          → Organisms & Templates (full-page views)
├── context/        → Global state providers
├── api/            → HTTP client & request utilities
└── data/           → Constants, config, static data
```

<br/>

### Pages & Views

<table>
<tr>
<th>Category</th>
<th>Pages</th>
<th>Features</th>
</tr>
<tr>
<td><strong>🏠 Discovery</strong></td>
<td>Home, Categories, CategoryDetail, SearchResults</td>
<td>Hero section, popular categories, featured pros, search bar</td>
</tr>
<tr>
<td><strong>👤 Authentication</strong></td>
<td>Login, Register</td>
<td>Email/phone login, role-based registration, form validation</td>
</tr>
<tr>
<td><strong>📅 Bookings</strong></td>
<td>Bookings, BookingDetail, CreateBooking</td>
<td>Booking list, status tracking, create flow, cancellation</td>
</tr>
<tr>
<td><strong>💬 Communication</strong></td>
<td>Messages, Chat, Notifications</td>
<td>Thread list, real-time chat, media sharing, push notifications</td>
</tr>
<tr>
<td><strong>💰 Payments</strong></td>
<td>Payment, Earnings</td>
<td>Razorpay integration, transaction history, earnings dashboard</td>
</tr>
<tr>
<td><strong>🔧 Professional</strong></td>
<td>ProfessionalProfile, Dashboard, Schedule, Storefront, StorefrontSetup</td>
<td>Full profile view, analytics, availability management</td>
</tr>
<tr>
<td><strong>🛡️ Trust & Safety</strong></td>
<td>Disputes, Warranties, Emergency</td>
<td>Dispute filing, warranty claims, emergency requests</td>
</tr>
<tr>
<td><strong>👤 User</strong></td>
<td>Settings, Favorites, Referrals</td>
<td>Profile settings, saved professionals, referral program</td>
</tr>
<tr>
<td><strong>📊 Analytics</strong></td>
<td>Analytics</td>
<td>Platform metrics, conversion funnels, revenue charts</td>
</tr>
<tr>
<td><strong>🤖 Agent</strong></td>
<td>AgentDashboard, AgentOnboard, AgentLeaderboard, AgentWallet</td>
<td>Agent management, onboarding, performance tracking</td>
</tr>
<tr>
<td><strong>👨‍💼 Admin</strong></td>
<td>admin/ (multiple)</td>
<td>User management, moderation, platform settings</td>
</tr>
</table>

<br/>

### UI Components Library

| Component | Purpose |
|-----------|---------|
| `Navbar` | Responsive navigation with auth state |
| `BottomNav` | Mobile bottom navigation bar |
| `SearchBar` | Smart search with voice & suggestions |
| `CategoryCard` | Category display with icon & count |
| `ProfessionalCard` | Professional summary card |
| `ReviewCard` | Star rating with review content |
| `StarRating` | Interactive star rating widget |
| `Toast` | Notification toast messages |
| `LoadingSpinner` | Loading state indicators |
| `Skeleton` | Content skeleton loading |
| `ErrorBoundary` | Error boundary with fallback UI |
| `ProtectedRoute` | Auth-guarded route wrapper |
| `ShareButton` | Social sharing functionality |
| `OnlineIndicator` | Real-time online status dot |
| `TrustSection` | Trust badges & verification info |
| `InviteEarn` | Referral program CTA |
| `CookieConsent` | GDPR cookie consent banner |
| `AppInstallBanner` | PWA install prompt |
| `AnnouncementBar` | Platform announcements |
| `Footer` | Site footer with links & info |

<br/>

### State Management

```
┌─────────────────────────────────────────┐
│           React Context Providers        │
├─────────────────────────────────────────┤
│                                          │
│  AuthContext                             │
│  ├── user state (profile, role, token)   │
│  ├── login / logout / register           │
│  └── token refresh                       │
│                                          │
│  ThemeContext                             │
│  ├── dark / light mode                   │
│  └── user preferences                    │
│                                          │
│  NotificationContext                     │
│  ├── unread count                        │
│  ├── notification list                   │
│  └── mark as read                        │
│                                          │
│  WebSocketContext                         │
│  ├── connection state                    │
│  ├── event listeners                     │
│  └── message dispatch                    │
│                                          │
└─────────────────────────────────────────┘
```

<br/>

---

<br/>

## 📱 Mobile Application (Flutter)

### Cross-Platform Support

<table>
<tr>
<td align="center" width="25%">

**📱 Android**
<br/>
Material Design 3
<br/>
Min SDK: 21+

</td>
<td align="center" width="25%">

**🍎 iOS**
<br/>
Cupertino widgets
<br/>
iOS 12+

</td>
<td align="center" width="25%">

**🌐 Web**
<br/>
Progressive Web App
<br/>
All modern browsers

</td>
<td align="center" width="25%">

**🖥️ Desktop**
<br/>
Windows/macOS/Linux
<br/>
Flutter Desktop

</td>
</tr>
</table>

<br/>

### Offline-First Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  Offline-First Strategy                    │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────┐  │
│  │   Flutter    │    │    Hive      │    │   Remote   │  │
│  │     UI       │◀──▶│  Local DB    │◀──▶│    API     │  │
│  │   Layer      │    │  (Encrypted) │    │  (Server)  │  │
│  └─────────────┘    └──────────────┘    └────────────┘  │
│                                                           │
│  Strategy:                                                │
│  1. Always read from Hive first (instant UI)              │
│  2. Fetch fresh data from API in background               │
│  3. Merge & update Hive with new data                     │
│  4. Queue mutations when offline                          │
│  5. Sync queue when connectivity restored                 │
│                                                           │
│  Cached Data:                                             │
│  ├── User profile & preferences                          │
│  ├── Recent bookings & history                            │
│  ├── Favorite professionals                               │
│  ├── Message threads (last 50 per thread)                 │
│  ├── Categories & service data                            │
│  └── Search results (last 10 queries)                     │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

<br/>

### Voice Search (Telugu/Hindi)

The app supports **multilingual voice search** powered by device-native speech recognition:

| Language | Code | Coverage | Accuracy |
|----------|------|----------|----------|
| 🇬🇧 English | `en-IN` | Full | 95%+ |
| 🇮🇳 Hindi | `hi-IN` | Full | 90%+ |
| 🇮🇳 Telugu | `te-IN` | Full | 88%+ |

**Implementation:** Uses `speech_to_text` package with locale-specific models for accurate recognition of service-related terms in regional languages.

<br/>

### Screen Modules

| Module | Screens | Features |
|--------|---------|----------|
| `auth/` | Login, Register, OTP Verification | Phone + email auth, biometric |
| `home/` | Home, Discovery, Featured | Category grid, nearby pros, promotions |
| `search/` | Search, Filters, Results | Voice search, location-based, filters |
| `bookings/` | List, Detail, Create, Track | Full booking lifecycle |
| `messages/` | Threads, Chat, Media | Real-time messaging, voice notes |
| `payments/` | Checkout, History, Wallet | Razorpay, UPI, transaction log |
| `profile/` | View, Edit, KYC | Profile management, verification |
| `storefront/` | View, Edit, Customize | Professional digital storefront |
| `portfolio/` | Gallery, Upload, Manage | Media portfolio management |
| `schedule/` | Calendar, Slots, Availability | Table calendar integration |
| `reviews/` | List, Write, Respond | Rating & review system |
| `tracking/` | Live Map, ETA, Status | GPS tracking with geolocator |
| `disputes/` | File, Track, Resolve | Dispute management |
| `warranty/` | View, Claim, Status | Warranty protection |
| `emergency/` | Request, Track | Emergency service requests |
| `earnings/` | Dashboard, Withdraw, History | Professional earnings |
| `favorites/` | List, Manage | Saved professionals |
| `notifications/` | List, Preferences | Push + in-app notifications |
| `settings/` | Account, Privacy, Language | App preferences |

<br/>

### Services Architecture

```dart
// 16 specialized service classes
├── ApiService          → HTTP client with interceptors & retry logic
├── AuthService         → JWT management, biometric, session handling
├── BookingService      → Booking CRUD & state machine
├── RealtimeService     → WebSocket connection & event handling
├── SmartLocationService → GPS, geocoding, geofencing
├── OfflineService      → Hive sync, queue management
├── AnalyticsService    → Event tracking, session analytics
├── UploadService       → Image/video upload with compression
├── StorefrontService   → Professional storefront management
├── ThemeService        → Dynamic theming & dark mode
├── PushNotificationService → FCM + local notifications
├── PerformanceMonitor  → App performance tracking
├── NetworkSimulator    → Dev-only network condition testing
├── MobileClient        → Platform-specific native bridges
└── WebClient           → Web-specific implementations
```

<br/>

---

<br/>

## 🗄️ Database (PostgreSQL 16)

### Schema Design

<details>
<summary><strong>📊 Complete Table Reference (Click to expand)</strong></summary>

<br/>

| # | Table | Columns | Purpose | Key Relationships |
|---|-------|---------|---------|-------------------|
| 1 | `users` | 12 | Base user accounts | Primary identity table |
| 2 | `professionals` | 25+ | Extended professional profiles | FK → users |
| 3 | `categories` | 5 | Service category hierarchy | Self-referencing (parent_id) |
| 4 | `professional_categories` | 2 | Professional ↔ Category mapping | Junction table (M:M) |
| 5 | `portfolio_items` | 6 | Professional portfolio media | FK → professionals |
| 6 | `contacts` | 6 | Customer contact requests | FK → users, professionals |
| 7 | `reviews` | 6 | Service reviews & ratings | FK → professionals, users, contacts |
| 8 | `complaints` | 7 | User complaints & reports | FK → users (reporter + reported) |
| 9 | `bookings` | 15+ | Service bookings | FK → users, professionals |
| 10 | `payments` | 10+ | Payment transactions | FK → bookings |
| 11 | `messages` | 8+ | Chat messages | FK → users (sender + receiver) |
| 12 | `disputes` | 10+ | Dispute cases | FK → bookings |
| 13 | `warranties` | 8+ | Service warranties | FK → bookings |
| 14 | `favorites` | 3 | Saved professionals | FK → users, professionals |
| 15 | `schedules` | 6+ | Professional availability | FK → professionals |
| 16 | `notifications` | 7+ | User notifications | FK → users |
| 17 | `referrals` | 6+ | Referral tracking | FK → users |

</details>

<br/>

### Custom Types (PostgreSQL Enums)

```sql
user_role           → 'customer' | 'professional'
availability_status → 'available' | 'busy' | 'offline'
subscription_plan   → 'basic' | 'premium' | 'featured'
media_type          → 'image' | 'video' | 'certificate'
contact_type        → 'call' | 'message' | 'quote_request'
contact_status      → 'pending' | 'accepted' | 'declined'
complaint_type      → 'fraud' | 'harassment' | 'poor_service' | 'fake_profile'
complaint_status    → 'pending' | 'warning_issued' | 'suspended' | 'banned' | 'resolved'
provider_type       → 'individual' | 'organization'
```

<br/>

### Migrations

Migrations are applied incrementally and maintain backward compatibility:

| # | Migration | Description |
|---|-----------|-------------|
| 001 | `kyc.sql` | KYC verification tables & workflow |
| 002 | `bookings_chat.sql` | Booking system + chat messaging |
| 003 | `review_by_booking.sql` | Reviews linked to completed bookings |
| 004 | `seed_geo.sql` | Geographic data & location seeding |
| 005 | `reputation_trigger.sql` | Automatic reputation score calculation |
| 006 | `phase1_features.sql` | Storefront, schedule, warranties |
| 006 | `storefront_fields.sql` | Extended storefront customization |
| 007 | `auth_admin_services.sql` | Admin roles & service management |
| 007 | `provider_type.sql` | Individual vs. organization professionals |
| 008 | `analytics_and_chat_images.sql` | Analytics events + image messages |
| 009 | `agent_system.sql` | Field agent management system |
| 010 | `growth_acquisition.sql` | Growth campaigns & user acquisition |

<br/>

### Indexes & Performance

```sql
-- Optimized for common query patterns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_professionals_user_id ON professionals(user_id);
CREATE INDEX idx_professionals_provider_type ON professionals(provider_type);
CREATE INDEX idx_professionals_reputation_score ON professionals(reputation_score DESC);
CREATE INDEX idx_professionals_location ON professionals(latitude, longitude);
CREATE INDEX idx_reviews_professional_id ON reviews(professional_id);
CREATE INDEX idx_contacts_customer_id ON contacts(customer_id);
CREATE INDEX idx_contacts_professional_id ON contacts(professional_id);
CREATE INDEX idx_complaints_reported_user_id ON complaints(reported_user_id);
CREATE INDEX idx_categories_parent_id ON categories(parent_id);
CREATE INDEX idx_portfolio_items_professional_id ON portfolio_items(professional_id);
```

<br/>

---

<br/>

## 🔌 API Reference & Endpoints

### Base URL

```
Production:  https://api.skillconnect.in/api
Development: http://localhost:5000/api
WebSocket:   wss://api.skillconnect.in/ws?token=<JWT>
```

<br/>

### Authentication API

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/auth/register` | ❌ | Create new user account |
| `POST` | `/auth/login` | ❌ | Login with email/password |
| `POST` | `/auth/refresh` | 🔄 | Refresh access token |
| `POST` | `/auth/logout` | ✅ | Invalidate refresh token |
| `POST` | `/auth/verify-phone` | ✅ | Verify phone via OTP |
| `POST` | `/auth/forgot-password` | ❌ | Request password reset |
| `POST` | `/auth/reset-password` | ❌ | Reset password with token |

<br/>

### Professional API

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/professionals` | ❌ | List all professionals |
| `GET` | `/professionals/:id` | ❌ | Get professional profile |
| `PUT` | `/professionals/:id` | ✅ | Update professional profile |
| `GET` | `/professionals/nearby` | ❌ | Find nearby professionals (geo) |
| `PATCH` | `/professionals/:id/availability` | ✅ | Update availability status |

<br/>

### Booking & Payment API

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/bookings` | ✅ | Create new booking |
| `GET` | `/bookings` | ✅ | List user bookings |
| `GET` | `/bookings/:id` | ✅ | Get booking details |
| `PATCH` | `/bookings/:id/status` | ✅ | Update booking status |
| `POST` | `/bookings/:id/cancel` | ✅ | Cancel booking |
| `POST` | `/payments/create-order` | ✅ | Create Razorpay order |
| `POST` | `/payments/verify` | ✅ | Verify payment signature |
| `POST` | `/payments/refund` | ✅ | Initiate refund |
| `GET` | `/payments/history` | ✅ | Payment transaction history |

<br/>

### Search & Discovery API

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/search` | ❌ | Full-text search with filters |
| `GET` | `/search?latitude=x&longitude=y&radius_km=z` | ❌ | Geo-spatial search |
| `GET` | `/search?availability=available` | ❌ | Filter by real-time availability |
| `GET` | `/categories` | ❌ | List all categories (tree) |
| `GET` | `/categories/:id` | ❌ | Category details with pros |
| `GET` | `/matching/suggestions` | ✅ | AI-powered job suggestions |

<br/>

### Messaging & Notifications API

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/messages/threads` | ✅ | List message threads |
| `GET` | `/messages/threads/:id` | ✅ | Get thread messages |
| `POST` | `/messages` | ✅ | Send message |
| `POST` | `/messages/media` | ✅ | Send media message |
| `GET` | `/notifications` | ✅ | List notifications |
| `PATCH` | `/notifications/:id/read` | ✅ | Mark notification as read |
| `PUT` | `/notifications/preferences` | ✅ | Update notification settings |

<br/>

### Admin & Analytics API

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/admin/users` | 🔐 Admin | List all users |
| `PATCH` | `/admin/users/:id/status` | 🔐 Admin | Suspend/activate user |
| `GET` | `/admin/reports` | 🔐 Admin | Platform reports |
| `GET` | `/analytics/overview` | ✅ | Analytics dashboard |
| `POST` | `/analytics/events` | ✅ | Track analytics event |
| `GET` | `/dashboard` | ✅ Pro | Professional dashboard stats |
| `GET` | `/growth/metrics` | 🔐 Admin | Growth & acquisition metrics |

<br/>

---

<br/>

## 💳 Payments & Transactions

### Payment Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       Razorpay Payment Flow                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Customer          SkillConnect API          Razorpay          Professional│
│     │                    │                      │                    │    │
│     │─ Book Service ────▶│                      │                    │    │
│     │                    │─ Create Order ──────▶│                    │    │
│     │                    │◀─ Order ID ──────────│                    │    │
│     │◀─ Payment Form ───│                      │                    │    │
│     │                    │                      │                    │    │
│     │─ Pay (UPI/Card) ──│──────────────────────▶│                    │    │
│     │                    │                      │                    │    │
│     │                    │◀─ Webhook: Paid ─────│                    │    │
│     │                    │─ Verify Signature ──▶│                    │    │
│     │                    │◀─ Valid ─────────────│                    │    │
│     │                    │                      │                    │    │
│     │◀─ Booking Confirmed│                      │  ─ Notify ───────▶│    │
│     │                    │                      │                    │    │
│     │  [Service Complete]│                      │                    │    │
│     │─ Confirm Done ────▶│                      │                    │    │
│     │                    │─ Release Payment ───▶│──── Transfer ────▶│    │
│     │                    │                      │                    │    │
│     │◀─ Receipt ─────────│                      │◀── Confirmed ─────│    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**Supported Payment Methods:**
- 💳 Credit/Debit Cards (Visa, Mastercard, RuPay)
- 📱 UPI (Google Pay, PhonePe, Paytm)
- 🏦 Net Banking (50+ banks)
- 💰 Wallets (Paytm, Amazon Pay)
- 🔄 EMI (select amounts)

<br/>

---

<br/>

## 🔐 Security & Compliance

### Security Architecture

<table>
<tr>
<th width="20%">Layer</th>
<th width="30%">Mechanism</th>
<th width="50%">Implementation</th>
</tr>
<tr>
<td><strong>🔒 Transport</strong></td>
<td>TLS 1.3 / HTTPS</td>
<td>All communications encrypted in transit</td>
</tr>
<tr>
<td><strong>🛡️ Headers</strong></td>
<td>Helmet.js</td>
<td>CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy</td>
</tr>
<tr>
<td><strong>🔑 Authentication</strong></td>
<td>JWT + Refresh Tokens</td>
<td>Short-lived access (15m), long-lived refresh (7d) with rotation</td>
</tr>
<tr>
<td><strong>🔐 Passwords</strong></td>
<td>bcryptjs</td>
<td>Salted hash with configurable rounds</td>
</tr>
<tr>
<td><strong>🚦 Rate Limiting</strong></td>
<td>express-rate-limit</td>
<td>Auth: 30 req/window, API: 200 req/window, configurable per-route</td>
</tr>
<tr>
<td><strong>🌐 CORS</strong></td>
<td>cors middleware</td>
<td>Whitelist-based origin validation</td>
</tr>
<tr>
<td><strong>✅ Validation</strong></td>
<td>express-validator</td>
<td>Input sanitization & type checking on all endpoints</td>
</tr>
<tr>
<td><strong>🆔 KYC</strong></td>
<td>3-factor verification</td>
<td>Government ID + selfie match + phone OTP</td>
</tr>
<tr>
<td><strong>🚨 Fraud</strong></td>
<td>Fraud prevention middleware</td>
<td>Behavioral analysis, velocity checks, device fingerprinting</td>
</tr>
<tr>
<td><strong>🔏 Data</strong></td>
<td>pgcrypto</td>
<td>UUID generation, encrypted sensitive fields</td>
</tr>
<tr>
<td><strong>📊 Audit</strong></td>
<td>Structured logging (Pino)</td>
<td>Request correlation IDs, action audit trail</td>
</tr>
<tr>
<td><strong>🚫 Account Lock</strong></td>
<td>Brute force protection</td>
<td>5 failed attempts → 15 min lockout</td>
</tr>
</table>

<br/>

### Security Best Practices

- ✅ **No secrets in code** — All sensitive values via environment variables
- ✅ **Parameterized queries** — Protection against SQL injection
- ✅ **Input validation** — All user input sanitized before processing
- ✅ **CORS whitelist** — Only approved origins can make requests
- ✅ **Dependency auditing** — Regular `npm audit` checks
- ✅ **Minimal permissions** — Role-based access control (RBAC)
- ✅ **Error masking** — Internal errors never exposed to clients
- ✅ **Request IDs** — Every request traceable through logs

<br/>

---

<br/>

## 🌍 Internationalization & Localization (i18n)

### Supported Languages

| Language | Code | Platform | Status |
|----------|------|----------|--------|
| 🇬🇧 English | `en` | Web + Mobile | ✅ Complete |
| 🇮🇳 Hindi | `hi` | Mobile | ✅ Complete |
| 🇮🇳 Telugu | `te` | Mobile | ✅ Complete |

<br/>

### Implementation

**Mobile (Flutter):**
- Uses Flutter's built-in `flutter_localizations` package
- ARB (Application Resource Bundle) files in `assets/l10n/`
- Runtime language switching
- Voice search supports all three languages

**Web (React):**
- i18n context provider
- Language detection from browser
- RTL support ready

<br/>

### Adding a New Language

```bash
# 1. Create ARB file
touch mobile/skillconnect/assets/l10n/app_<LANG_CODE>.arb

# 2. Add translations (JSON format)
{
  "@@locale": "<LANG_CODE>",
  "appTitle": "SkillConnect",
  "searchPlaceholder": "<Translated text>"
}

# 3. Register in l10n.yaml
# 4. Run code generation
flutter gen-l10n
```

<br/>

---

<br/>

## 📡 Real-time Features

### WebSocket Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    WebSocket Hub Architecture                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Client A ──────┐                                                │
│  Client B ──────┤        ┌────────────────────┐                  │
│  Client C ──────┼───────▶│   WebSocket Hub    │                  │
│  Client D ──────┤        │   (realtime/hub.js)│                  │
│  Client E ──────┘        └────────┬───────────┘                  │
│                                   │                              │
│                    ┌──────────────┼──────────────┐               │
│                    ▼              ▼              ▼               │
│             ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│             │ Presence │  │  Chat    │  │ Tracking │           │
│             │  Manager │  │  Router  │  │  Engine  │           │
│             └──────────┘  └──────────┘  └──────────┘           │
│                                                                  │
│  Features:                                                       │
│  • JWT-authenticated connections                                 │
│  • Room-based messaging (1:1, group)                            │
│  • Presence tracking (online/offline/busy)                      │
│  • Typing indicators with debounce                              │
│  • GPS location streaming                                       │
│  • Booking status broadcasts                                    │
│  • Payment confirmation events                                  │
│  • Auto-reconnect with exponential backoff                      │
│  • Message delivery acknowledgments                             │
│  • Connection heartbeat (30s interval)                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

<br/>

### Event Types

| Category | Events | Direction |
|----------|--------|-----------|
| **Connection** | `connect`, `disconnect`, `heartbeat` | Bidirectional |
| **Presence** | `user:online`, `user:offline`, `user:busy` | Server → Client |
| **Messaging** | `message:new`, `message:read`, `message:delivered` | Bidirectional |
| **Typing** | `typing:start`, `typing:stop` | Bidirectional |
| **Booking** | `booking:created`, `booking:accepted`, `booking:completed` | Server → Client |
| **Location** | `location:update`, `location:request` | Bidirectional |
| **Payment** | `payment:received`, `payment:confirmed` | Server → Client |
| **Notification** | `notification:new`, `notification:count` | Server → Client |

<br/>

---

<br/>

## 🤖 AI-Powered Features

### Smart Matching Engine

The platform uses intelligent algorithms to match customers with the best-suited professionals:

| Factor | Weight | Description |
|--------|--------|-------------|
| 📍 **Proximity** | 30% | Distance from customer location |
| ⭐ **Reputation** | 25% | Rating, reviews, completion rate |
| 🕐 **Availability** | 20% | Real-time availability status |
| 💰 **Pricing** | 15% | Budget alignment |
| 📈 **Response Time** | 10% | Historical response speed |

### Agent System

Field agents help with professional onboarding and verification:

- 🤖 Agent registration & onboarding
- 📊 Agent dashboard with KPIs
- 💰 Agent wallet & commission tracking
- 🏆 Leaderboard & gamification
- 📍 Territory assignment & tracking

<br/>

---

<br/>

## 🧪 Testing & Quality Assurance

### Testing Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                       Testing Pyramid                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                        ╱ ╲                                       │
│                       ╱ E2E ╲          ← Cypress / Playwright    │
│                      ╱───────╲                                   │
│                     ╱Integration╲      ← Supertest + Jest        │
│                    ╱─────────────╲                                │
│                   ╱   Unit Tests   ╲   ← Jest + Vitest           │
│                  ╱───────────────────╲                            │
│                 ╱    Static Analysis   ╲ ← ESLint + TypeCheck    │
│                ╱───────────────────────────╲                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

<br/>

### Running Tests

```bash
# ═══════════════════════════════════════
# Backend Tests (Jest)
# ═══════════════════════════════════════
cd backend

# Run all tests
npm test

# Run with coverage report
npm run test:coverage

# Run specific test file
npx jest tests/auth.test.js

# ═══════════════════════════════════════
# Frontend Tests (Vitest)
# ═══════════════════════════════════════
cd frontend

# Run all tests
npm test

# Run in watch mode
npx vitest

# ═══════════════════════════════════════
# Mobile Tests (Flutter)
# ═══════════════════════════════════════
cd mobile/skillconnect

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# ═══════════════════════════════════════
# Linting
# ═══════════════════════════════════════
cd backend && npm run lint        # ESLint
cd mobile/skillconnect && flutter analyze  # Dart analyzer
```

<br/>

### Code Quality Standards

| Metric | Target | Tool |
|--------|--------|------|
| Branch Coverage | 50%+ | Jest / Vitest |
| Function Coverage | 50%+ | Jest / Vitest |
| Line Coverage | 50%+ | Jest / Vitest |
| Code Style | Consistent | ESLint |
| Type Safety | Strict | Dart Analyzer |
| Security Audit | 0 critical | npm audit |

<br/>

---

<br/>

## 📦 Deployment & DevOps

### Docker Deployment

```bash
# One-command deployment
docker compose up -d --build

# Services:
# ├── db:       PostgreSQL 16 (Alpine) on port 5432
# ├── backend:  Node.js Express 5 on port 5000
# └── frontend: Nginx + React SPA on port 3000
```

<br/>

### Docker Architecture

```yaml
┌─────────────────────────────────────────────────────────┐
│                  Docker Compose Stack                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Frontend   │  │   Backend    │  │   Database   │ │
│  │   (Nginx)    │  │ (Node.js)    │  │ (PostgreSQL) │ │
│  │   Port 3000  │  │  Port 5000   │  │  Port 5432   │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
│         │                  │                  │         │
│         │  depends_on      │  depends_on      │         │
│         └─────────────────▶└─────────────────▶│         │
│                                               │         │
│                          ┌────────────────────┘         │
│                          │  Volumes:                    │
│                          │  └── pgdata (persistent)     │
│                          │                              │
│                          │  Init Scripts:                │
│                          │  ├── 01-schema.sql           │
│                          │  └── 02-seed.sql             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

<br/>

### Production Deployment Checklist

- [ ] Set `NODE_ENV=production`
- [ ] Generate secure `JWT_SECRET` (32+ characters)
- [ ] Configure production `DB_PASSWORD`
- [ ] Set `CORS_ORIGINS` to production domains only
- [ ] Enable TLS/SSL certificates
- [ ] Configure proper rate limits
- [ ] Set up database backups
- [ ] Enable error monitoring (Sentry, etc.)
- [ ] Configure CDN for static assets
- [ ] Set up health check endpoints
- [ ] Configure log aggregation
- [ ] Enable database connection pooling
- [ ] Set up CI/CD pipeline

<br/>

### CI/CD Pipeline

```
┌─────────┐     ┌─────────┐     ┌──────────┐     ┌──────────┐
│  Push   │────▶│  Lint   │────▶│   Test   │────▶│  Build   │
│ to main │     │ ESLint  │     │Jest/Vitest│     │  Docker  │
└─────────┘     └─────────┘     └──────────┘     └────┬─────┘
                                                       │
                ┌─────────┐     ┌──────────┐          │
                │ Monitor │◀────│  Deploy  │◀─────────┘
                │  Logs   │     │Production│
                └─────────┘     └──────────┘
```

<br/>

---

<br/>

## 📊 Monitoring & Observability

### Logging Architecture

| Layer | Tool | Format | Purpose |
|-------|------|--------|---------|
| **Application** | Pino | JSON structured | High-performance app logging |
| **HTTP** | Morgan + Pino | JSON | Request/response logging |
| **Database** | pg events | JSON | Query performance & errors |
| **Real-time** | WebSocket hub | JSON | Connection & event logging |

<br/>

### Health Check Endpoints

```http
GET /api/health          → Application health status
GET /api/health/db       → Database connectivity check
GET /api/health/ws       → WebSocket hub status
```

<br/>

### Key Metrics Tracked

| Category | Metrics |
|----------|---------|
| **Performance** | Response time (p50, p95, p99), throughput (req/sec) |
| **Availability** | Uptime %, error rate, health check status |
| **Business** | Active users, bookings/day, conversion rate |
| **Database** | Query time, connection pool usage, deadlocks |
| **WebSocket** | Active connections, messages/sec, reconnect rate |

<br/>

---

<br/>

## 🚀 Performance Optimization

### Backend Optimizations

| Optimization | Implementation | Impact |
|-------------|----------------|--------|
| **Response Compression** | `compression` middleware (gzip/brotli) | ~70% bandwidth reduction |
| **Connection Pooling** | `pg` pool with 20 max connections | Reduced connection overhead |
| **Query Optimization** | Targeted indexes on frequently queried columns | Sub-100ms query times |
| **Rate Limiting** | Per-route limits prevent resource exhaustion | DDoS protection |
| **Static Caching** | Nginx caching for static assets | Reduced server load |
| **JSON Streaming** | Pino logger (30x faster than Winston) | Minimal logging overhead |

<br/>

### Frontend Optimizations

| Optimization | Implementation | Impact |
|-------------|----------------|--------|
| **Code Splitting** | Vite dynamic imports | Smaller initial bundle |
| **Tree Shaking** | Vite production build | Dead code elimination |
| **Image Optimization** | Lazy loading, srcset | Faster page loads |
| **HMR** | Vite Hot Module Replacement | Instant dev updates |
| **Skeleton Loading** | Custom skeleton components | Perceived performance |
| **Error Boundaries** | React error boundaries | Graceful degradation |

<br/>

### Mobile Optimizations

| Optimization | Implementation | Impact |
|-------------|----------------|--------|
| **Offline-First** | Hive local storage | Instant data display |
| **Image Caching** | cached_network_image | Reduced data usage |
| **Lazy Loading** | ListView.builder | Memory-efficient scrolling |
| **Background Sync** | Connectivity detection + queue | Seamless offline → online |
| **Native Compilation** | AOT compilation (release) | Fast startup & execution |

<br/>

---

<br/>

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### Development Workflow

```bash
# 1. Fork & clone
git clone https://github.com/<your-username>/SKILL.git
cd SKILL

# 2. Create feature branch
git checkout -b feat/your-feature-name

# 3. Install dependencies
cd backend && npm install
cd ../frontend && npm install

# 4. Make changes & test
npm test              # Run tests
npm run lint          # Check code style
npm run lint:fix      # Auto-fix lint issues

# 5. Commit with conventional commits
git commit -m "feat: add voice search for Kannada language"
# Types: feat | fix | docs | style | refactor | perf | test | chore

# 6. Push & create PR
git push origin feat/your-feature-name
```

<br/>

### Commit Convention

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feat:` | New feature | `feat: add UPI payment support` |
| `fix:` | Bug fix | `fix: resolve WebSocket reconnection loop` |
| `docs:` | Documentation | `docs: update API reference` |
| `style:` | Code style | `style: format with prettier` |
| `refactor:` | Code refactoring | `refactor: extract payment service` |
| `perf:` | Performance | `perf: add database query caching` |
| `test:` | Testing | `test: add booking flow integration tests` |
| `chore:` | Maintenance | `chore: update dependencies` |

<br/>

### Code Review Checklist

- [ ] Follows existing code patterns and conventions
- [ ] Includes tests for new functionality
- [ ] No security vulnerabilities introduced
- [ ] API endpoints documented
- [ ] Database migrations are backward-compatible
- [ ] Error handling is comprehensive
- [ ] Logging is appropriate (not excessive)
- [ ] No hardcoded credentials or secrets

<br/>

---

<br/>

## 📋 Roadmap

### 🏗️ Current Version (v1.0)

- [x] Core marketplace (professionals, categories, search)
- [x] Authentication (JWT + refresh tokens)
- [x] Real-time messaging & notifications
- [x] Booking management system
- [x] Razorpay payment integration
- [x] KYC verification pipeline
- [x] Professional storefronts
- [x] Dispute resolution
- [x] Warranty protection
- [x] Agent management system
- [x] Multilingual support (EN/HI/TE)
- [x] Offline-first mobile app
- [x] GPS tracking & geo-search

<br/>

### 🚀 Upcoming (v2.0)

- [ ] Kannada & Tamil language support
- [ ] AI chatbot for customer support
- [ ] Video calling integration
- [ ] Subscription marketplace (recurring services)
- [ ] Professional certification program
- [ ] Machine learning recommendation engine
- [ ] Push notifications (FCM + APNs)
- [ ] Social login (Google, Facebook)
- [ ] PWA desktop app support
- [ ] Advanced analytics dashboard
- [ ] Multi-city expansion framework
- [ ] Franchise management system

<br/>

### 🔮 Future Vision (v3.0+)

- [ ] AR-based service visualization
- [ ] Blockchain-based reputation system
- [ ] IoT integration for home services
- [ ] White-label platform-as-a-service
- [ ] Multi-language voice AI assistant
- [ ] Predictive maintenance scheduling
- [ ] Community marketplace features
- [ ] Enterprise B2B service management

<br/>

---

<br/>

## ❓ Frequently Asked Questions

<details>
<summary><strong>🔧 How do I reset the database?</strong></summary>

```bash
dropdb skillconnect
createdb skillconnect
psql -U postgres -d skillconnect -f database/schema.sql
psql -U postgres -d skillconnect -f database/seed.sql
for f in database/migrations/*.sql; do psql -U postgres -d skillconnect -f "$f"; done
```
</details>

<details>
<summary><strong>🐳 How do I rebuild Docker containers?</strong></summary>

```bash
docker compose down -v
docker compose up -d --build
```
</details>

<details>
<summary><strong>📱 How do I build the mobile APK?</strong></summary>

```bash
cd mobile/skillconnect
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```
</details>

<details>
<summary><strong>🔑 How do I get demo credentials?</strong></summary>

After seeding the database, use these demo accounts:
- **Customer:** `customer@demo.com` / `demo123`
- **Professional:** `pro1@demo.com` / `demo123`
</details>

<details>
<summary><strong>🌐 How do I change the API port?</strong></summary>

Edit `.env` in the backend directory:
```env
PORT=8000
```
Then restart the server.
</details>

<details>
<summary><strong>📡 How do I connect to WebSocket?</strong></summary>

```javascript
const token = 'your-jwt-token';
const ws = new WebSocket(`ws://localhost:5000/ws?token=${token}`);

ws.onopen = () => console.log('Connected');
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
};
```
</details>

<details>
<summary><strong>🧪 How do I add a new test?</strong></summary>

**Backend (Jest):**
```javascript
// backend/tests/your-feature.test.js
const request = require('supertest');
const app = require('../src/app');

describe('Your Feature', () => {
  it('should do something', async () => {
    const res = await request(app).get('/api/your-endpoint');
    expect(res.status).toBe(200);
  });
});
```

**Frontend (Vitest):**
```javascript
// frontend/src/tests/YourComponent.test.jsx
import { render, screen } from '@testing-library/react';
import YourComponent from '../components/YourComponent';

test('renders correctly', () => {
  render(<YourComponent />);
  expect(screen.getByText('Expected Text')).toBeInTheDocument();
});
```
</details>

<details>
<summary><strong>🔒 How do I add a new API endpoint?</strong></summary>

1. Create controller in `backend/src/controllers/`
2. Create route in `backend/src/routes/`
3. Register route in `backend/src/app.js`
4. Add validation middleware
5. Write tests
6. Update this README
</details>

<details>
<summary><strong>📱 How do I add a new mobile screen?</strong></summary>

1. Create screen file in `mobile/skillconnect/lib/screens/`
2. Add route in navigation
3. Create corresponding service if needed
4. Add localization keys in ARB files
5. Write widget tests
</details>

<details>
<summary><strong>💳 How do I test Razorpay payments?</strong></summary>

Use Razorpay's test mode with test keys:
```env
RAZORPAY_KEY_ID=rzp_test_xxxxx
RAZORPAY_KEY_SECRET=xxxxx
```
Test card: `4111 1111 1111 1111` (any future expiry, any CVV)
</details>

<br/>

---

<br/>

## 📜 License

<div align="center">

This project is licensed under the **ISC License**.

```
ISC License

Copyright (c) 2024 SkillConnect

Permission to use, copy, modify, and/or distribute this software
for any purpose with or without fee is hereby granted, provided
that the above copyright notice and this permission notice appear
in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

</div>

<br/>

---

<br/>

## 🙏 Acknowledgments

<div align="center">

### Built With Love Using

<br/>

[![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com/)
[![React](https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com/)
[![Vite](https://img.shields.io/badge/Vite-646CFF?style=for-the-badge&logo=vite&logoColor=white)](https://vitejs.dev/)
[![Razorpay](https://img.shields.io/badge/Razorpay-528FF0?style=for-the-badge&logo=razorpay&logoColor=white)](https://razorpay.com/)

<br/>

### Inspired By

[**React**](https://github.com/facebook/react) •
[**Next.js**](https://github.com/vercel/next.js) •
[**Flutter**](https://github.com/flutter/flutter) •
[**Supabase**](https://github.com/supabase/supabase) •
[**Stripe**](https://github.com/stripe/stripe-node) •
[**Vercel**](https://github.com/vercel/vercel) •
[**Prisma**](https://github.com/prisma/prisma)

<br/>

---

<br/>

<img src="https://img.shields.io/badge/Made_with-❤️_in_India-FF9933?style=for-the-badge" alt="Made with love in India" />

<br/><br/>

**⭐ Star this repository if you find it useful!**

<br/>

[⬆ Back to Top](#%EF%B8%8F-skillconnect)

</div>
