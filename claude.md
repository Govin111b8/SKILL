# SkillConnect — Master Implementation Plan (claude.md)

> **Purpose:** Comprehensive guide for Copilot/Claude sessions to evolve SkillConnect from a functional marketplace into a **Professional Identity + Business Operating System**  
> **Last Updated:** 2026-05-16 (Deep Audit v2)  
> **Context:** Core features COMPLETE. Auth & Payments handled separately. Focus now shifts to UX, identity, social, and AI layers.  
> **Vision:** "Build your professional business online" — NOT just a service booking app.

---

## 🎯 APP IDENTITY & CORE CONCEPT

**What is SkillConnect?** A connecting platform for skilled service providers (individuals + companies) across different categories, services, and sub-services. Providers create profiles; customers discover nearby professionals, browse by service/sub-service, and book appointments.

**Two Distinct User Experiences:**

| Aspect | Service Provider App | Customer/User App |
|--------|---------------------|-------------------|
| **Login** | Professional login → choose Individual or Company | Customer login → see all professionals |
| **Profile Setup** | Fill detailed service profile + storefront | Simple profile with preferences |
| **Main Screen** | Business dashboard: bookings, earnings, analytics | Discovery: nearby professionals, categories, search |
| **Key Actions** | Manage schedule, respond to bookings, grow business | Find professionals, compare, book appointments |
| **Content** | Upload portfolio, create reels, post tips | Browse services, save favorites, write reviews |

---

## 🔴 CRITICAL PRODUCTION-READINESS GAP ANALYSIS (2026-05-16)

> **Core Finding:** The platform is technically comprehensive (42 controllers, 60+ pages, 120+ endpoints) but has **critical UX and data flow gaps** that prevent it from being production-ready as a user-friendly app.

### GAP 1: Service & Sub-Service Hierarchy (🔴 CRITICAL)

**Current State:**
- ✅ Categories table has `parent_id` supporting hierarchy (categories → subcategories)
- ✅ `professional_categories` junction table links professionals to categories
- ✅ Frontend `Categories.jsx` shows parent categories with expandable subcategories
- ✅ `CategoryDetail.jsx` shows professionals within a category with sub-category filtering
- ⚠️ `services_offered TEXT[]` on professionals table — just a freetext array, not linked to a services table

**What's Missing:**
- ❌ **No formal `services` or `sub_services` table** — professionals have a freetext `services_offered TEXT[]` field instead of a normalized service catalog
- ❌ **No service pricing per sub-service** — pricing is a single `pricing_estimate` string on the professional, not per-service
- ❌ **No service-level search** — search finds professionals by name/category, but users can't search "AC Repair" and find all professionals who offer that specific sub-service
- ❌ **No service catalog management UI** — professionals can't add/manage specific services with individual pricing, duration, descriptions
- ❌ **Category seed data is static** — `frontend/src/data/categories.js` has hardcoded categories; backend categories need proper seeding

**Action Plan:**
1. ~~Create `professional_services` table~~ ✅ Migration 017 created
2. ~~Add service management UI in `StorefrontSetup.jsx`~~ ✅ "Services" tab with add/remove
3. ~~Update `CreateBooking.jsx` wizard to let users select a specific service~~ ✅ Service selection chips
4. ~~Service display on Storefront.jsx~~ ✅ Service catalog cards with pricing + book button
5. ~~Update search to include service-level matching~~ ✅ `searchController.js` now JOINs `professional_services` + `service` query param
6. ~~Update `ProfessionalCard` to show specific services~~ ✅ Shows up to 3 service chips with pricing

### GAP 2: Individual vs Company Experience (🟠 HIGH)

**Current State:**
- ✅ DB has `provider_type ENUM ('individual', 'organization')` on professionals
- ✅ `ProfessionalRegister.jsx` has Individual/Organization toggle with company fields
- ✅ `ProfessionalCard.jsx` shows "🏢 Company" badge for organizations
- ✅ Backend `professionalController.js` stores `provider_type`, `company_name`, `team_size`
- ✅ `SearchResults.jsx` has `provider_type` filter

**What's Missing:**
- ❌ **No differentiated onboarding flow** — Individual and Company share the exact same registration form; Company just shows 2 extra fields (company_name, team_size). Should have distinct step-by-step wizards:
  - **Individual:** Skills → Experience → Portfolio → Pricing → KYC
  - **Company:** Company Info → Team Size → Services Offered → Documents → Pricing
- ❌ **No company-specific profile view** — Storefront looks identical for individuals and companies. Companies should show: team members, service departments, company certifications, larger project gallery
- ❌ **No team member management** — Companies can't add/manage team members
- ❌ **No company document verification** — KYC only handles individual ID verification, not company registration documents (GST, incorporation certificate)
- ❌ **No organization dashboard widgets** — Dashboard shows same view for both; companies need: team performance, department bookings, revenue by service

**Action Plan:**
1. Create multi-step onboarding wizard: `ProfessionalOnboarding.jsx` with role-aware steps
2. Add company-specific sections to `Storefront.jsx` (team members, departments, certifications)
3. Extend KYC flow for company documents
4. Add team management for company profiles

### GAP 3: Customer Discovery UX (🟠 HIGH)

**Current State:**
- ✅ Home page has search bar, category grid, trending searches, stats
- ✅ Discovery endpoints: `/discover/trending`, `/discover/new`, `/discover/responsive`
- ✅ Category browsing with sub-category filtering
- ✅ Search with filters (category, rating, price, availability, provider_type)
- ✅ Reels feed for visual discovery

**What's Missing:**
- ❌ **No location-based "near me" on home page** — Home.jsx has hardcoded cities but doesn't request user location or show nearby professionals automatically
- ❌ **No "recently viewed" persistence** — `recentlyViewed` state in Home.jsx doesn't persist across sessions
- ❌ **No service-based browsing** — Users browse by category (e.g., "Plumbing") but can't drill into specific services (e.g., "Tap Repair", "Pipeline", "Bathroom Fitting")
- ❌ **No availability-first search** — Can't search "available today" or "available this weekend" as primary filter
- ❌ **No map view** — No visual map showing nearby professionals
- ❌ **No comparison feature** — Can't compare 2-3 professionals side by side
- ❌ **Hardcoded category list** in multiple places — Should be backend-driven everywhere

**Action Plan:**
1. Add geolocation prompt on Home.jsx → show nearby professionals automatically
2. Add service-level browsing inside CategoryDetail.jsx
3. Add "Available Today" / "This Week" quick filters on search
4. Add map view option to SearchResults.jsx
5. Add professional comparison modal

### GAP 4: Booking & Appointment Flow (🟡 MEDIUM)

**Current State:**
- ✅ Multi-step booking wizard: What → When → Where → Confirm
- ✅ Available time slots fetched from professional schedule
- ✅ Booking status tracking with humanized labels
- ✅ Payment integration

**What's Missing:**
- ~~❌ **No service selection in booking**~~ ✅ Fixed — Service selection chips with pricing in booking wizard
- ~~❌ **No instant price estimate**~~ ✅ Partially fixed — Shows price range from selected service
- ❌ **No recurring bookings** — Can't schedule weekly/monthly recurring services
- ❌ **No booking rescheduling UI** — Can only cancel, not reschedule
- ❌ **No booking modification** — Can't change service address or notes after creation
- ❌ **No "similar professionals" suggestion** if selected one is unavailable

### GAP 5: Professional Dashboard Completeness (🟡 MEDIUM)

**Current State:**
- ✅ Dashboard shows stats, recent bookings, reviews, contacts
- ✅ Different view for professional vs customer
- ✅ Storefront setup with themes, packages, colors

**What's Missing:**
- ❌ **No service management page** — Professionals can't manage their service catalog (add services, set prices per service, enable/disable services)
- ❌ **No booking calendar view** — Only list view of bookings, no calendar/schedule visualization
- ❌ **No customer management** — No way to see repeat customers, customer notes, customer history
- ❌ **No quick actions** — No "mark as available today", "set vacation mode", "quick price update"
- ❌ **No revenue analytics** — No charts showing revenue trends, best services, peak hours
- ❌ **No notification preferences** — Can't choose which notifications to receive

### GAP 6: Mobile App Completeness (🟡 MEDIUM)

**Current State:**
- ✅ Flutter app with 49 screens, 4 roles, offline-first, i18n
- ✅ Auth, booking, storefront, search screens

**What's Missing (per claude.md Sprint 3 items 19-21):**
- ❌ 7 screens: Collections, Community, Followers, Stories, Loyalty/Points, Referral detail, Admin dashboard
- ❌ 6+ services: WarrantyService, DisputeService, CollectionService, PointsService, CommunityService, ReferralService
- ❌ 9+ models: Warranty, Dispute, Collection, UserPoints, CommunityPost, Badge, Follow, Story, FeaturedSlot
- ❌ Monolithic models.dart needs splitting

---

## 📊 PRODUCTION READINESS SCORECARD (Updated)

| Area | Score | What's Done | What's Missing |
|------|-------|-------------|----------------|
| **Auth & Roles** | 9/10 | ✅ 4 roles, RBAC, token refresh, role-specific login pages | Minor: company doc verification |
| **Backend API** | 9/10 | ✅ 37 controllers, 100+ endpoints, retry logic, rate limiting | Tests for 29 controllers |
| **Service Catalog** | 9/10 | ✅ professional_services table, CRUD API, management UI, storefront display, booking integration, search matching, card display | Minor: category seed data |
| **Provider Onboarding** | 8/10 | ✅ Individual/Company toggle, multi-step wizard, company storefront sections | Company KYC extension |
| **Customer Discovery** | 8/10 | ✅ Search, categories, trending, reels, geolocation, service browsing, quick filters, recently viewed | Map view |
| **Booking Flow** | 7/10 | ✅ Multi-step wizard, slot selection, payments, calendar view | No recurring, no reschedule |
| **Professional Dashboard** | 8/10 | ✅ Stats, bookings, storefront setup, quick actions, customer insights, calendar | Minor: revenue analytics charts |
| **Storefront** | 8/10 | ✅ Themes, packages, media, trust badges | Minor: company-specific sections |
| **Social Features** | 8/10 | ✅ Follow, collections, stories, community, reels | Minor: collection sharing |
| **Trust System** | 9/10 | ✅ Badges, timeline, explainability, auto-calculation | Minor: top_rated calculation |
| **Mobile App** | 7/10 | ✅ 49 screens, offline, i18n | ❌ 7 screens + 6 services missing |
| **Infrastructure** | 9/10 | ✅ K8s, monitoring, CI/CD, security | Minor: HA database, staging overlay |

**Overall Production Readiness: 8.5/10** — Strong across all areas, remaining items are enhancements (map view, mobile screens, company KYC)

---

## 🔬 DEEP AUDIT v2 — NEW ISSUES DISCOVERED (2026-05-16)

> **Methodology:** Full codebase scan of all 109 backend files, 57 frontend pages, 23 components, 18 migrations, 49 mobile screens, all K8s manifests.
> **New issues found:** 30 backend, 22 frontend, 8 database, 7 mobile, 12 DevOps = **79 new issues** beyond the original 80.

### 🔴 NEW P0 — CRITICAL (Immediate Action Required)

#### Backend Security & Logic Gaps
| # | Issue | File | Impact | Status |
|---|-------|------|--------|--------|
| 81 | **Payment escrow releases without dispute check** — `releaseEscrow()` checks booking completed but not dispute status | `paymentController.js:162-165` | Funds released during active disputes | ✅ Fixed |
| 82 | **Remaining silent catches** — 6 instances still exist in backend | `realtime/hub.js:47`, `middleware/auth.js:33`, `routes/payments.js (2)`, `services/pushNotification.js (1)` | Errors silently swallowed in production | ✅ Fixed |
| 83 | **Referral code bypass** — no deduplication check, users can apply same code multiple times | `referralController.js` | Duplicate reward credits | ❌ Fix Now |
| 84 | **No rate limiting on auth endpoints** — `/register`, `/login`, `/forgot-password` lack route-level rate limits | `routes/auth.js` | Brute force attacks possible | ✅ Already in app.js |
| 85 | **Booking date allows 100+ years in future** — no upper bound validation | `bookingController.js:52-59` | Spam bookings, data pollution | ✅ Fixed (90d cap) |
| 86 | **`quoted_amount`/`final_amount` no max cap** — parsed as float without range validation | `bookingController.js:178-181` | Billing system vulnerability | ✅ Fixed (₹10L cap) |
| 86b | **SQL injection in analytics** — string interpolation in INTERVAL queries | `analyticsEventsController.js`, `adminController.js` | SQL injection attack | ✅ Fixed (parameterized) |
| 86c | **NaN pagination** — parseInt without fallback causes NaN offsets | `searchController.js`, `categoryController.js`, `contactController.js`, `reviewController.js` | Broken pagination | ✅ Fixed |
| 86d | **Upload path traversal** — unvalidated folder query parameter | `uploadController.js` | File system traversal | ✅ Fixed (whitelist) |
| 86e | **Unsafe COUNT access** — missing null checks on `.rows[0].count` | `notificationController.js`, `fraudPrevention.js` | Runtime crashes | ✅ Fixed |
| 86f | **Missing password validation** — changePassword accepts weak passwords | `userController.js` | Weak passwords | ✅ Fixed (8+, uppercase, digit) |
| 86g | **5 storefrontController silent catches** — errors swallowed for theme/media/badges/packages/followers | `storefrontController.js` | Hidden DB errors | ✅ Fixed (logger.warn) |

#### Frontend Security & UX Gaps
| # | Issue | File | Impact | Status |
|---|-------|------|--------|--------|
| 87 | **No logout API call** — frontend clears localStorage but never calls `POST /auth/logout` | `AuthContext.jsx:83-89` | Server-side sessions remain active | ✅ Fixed |
| 88 | **Remaining silent catches** — 22+ instances across 11+ frontend files | Multiple files | Users see blank sections, no feedback | ✅ Fixed (40+ catches now log errors) |
| 89 | **WebSocket timer memory leaks** — `setTimeout` not guarded by mountedRef | `WebSocketContext.jsx:37-39` | Memory leak in long sessions | ✅ Fixed |
| 90 | **Dashboard.jsx.bak file in source** — backup file committed to repository | `frontend/src/pages/Dashboard.jsx.bak` | Code clutter, potential confusion | ✅ Removed |
| 90b | **Wrong currency symbol** — Bookings.jsx uses $ instead of ₹ | `Bookings.jsx:22-24` | Wrong currency for India-first app | ✅ Fixed (₹ with locale) |
| 90c | **Missing useEffect dependency** — CreateBooking doesn't re-fetch on professionalId change | `CreateBooking.jsx:59` | Stale service data | ✅ Fixed |
| 90d | **Chat null reference** — otherName[0] crashes when otherName is undefined | `Chat.jsx:271` | Chat page crash | ✅ Fixed |
| 90e | **ReelsFeed array bounds** — reels[current] undefined when navigating past end | `ReelsFeed.jsx:61` | Reels page crash | ✅ Fixed (fallback guard) |
| 90f | **Emergency.jsx wrong fallback** — categories state gets object instead of array | `Emergency.jsx:39` | .map() crash on categories | ✅ Fixed |

### 🟠 NEW P1 — HIGH PRIORITY

#### Backend Performance & Quality
| # | Issue | File | Impact |
|---|-------|------|--------|
| 91 | **N+1 query in search ranking** — 6 subqueries in SELECT clause execute per row | `searchController.js:81-84` | 1000 results = 6000 subqueries |
| 92 | **Missing composite indexes** — no index on `(customer_id, status)` for bookings, `(professional_id, created_at)` for reviews, `(payer_id, status)` for payments | DB schema | Slow queries at scale |
| 93 | **In-memory fraud prevention store** — `fraudPrevention.js:16` uses Map, breaks in load-balanced setup | `middleware/fraudPrevention.js` | Fraud detection fails across instances |
| 94 | **AI cache unbounded** — 10k entry cap with FIFO, should use LRU | `services/ai.js:52-56` | Memory leak potential |
| 95 | **Razorpay error handling gap** — error response parsed assuming JSON, no 5xx fallback | `services/razorpay.js:39-44` | Crashes on malformed responses |
| 96 | **No input sanitization for XSS** — all text fields (bio, headline, description) stored as-is | Multiple controllers | XSS when data rendered |
| 97 | **`top_rated` badge always false** — TODO at `trustController.js:64` never implemented | `trustController.js:64` | Badge never awarded | ✅ Fixed |
| 98 | **Inconsistent response formats** — mix of `{success,data}`, `{error}`, and plain objects | Multiple controllers/routes | Client parsing errors |
| 99 | **Missing file type/size validation on uploads** | `uploadController.js` | Security risk | ✅ Partially fixed (folder whitelist) |
| 100 | **Missing password strength validation on change** | `userController.js:45-68` | Weak passwords accepted | ✅ Fixed |

#### Frontend Quality
| # | Issue | File | Impact |
|---|-------|------|--------|
| 101 | **No loading skeletons for professional cards** — shows text "Loading..." only | `SearchResults.jsx:80-101` | Poor perceived performance |
| 102 | **No empty states** on Messages, Chat, Notifications pages | Multiple pages | Confusing blank screens |
| 103 | **No search debouncing** — every keystroke triggers search | `SearchBar.jsx` | API spam, poor UX |
| 104 | **No form double-submit prevention** — submit buttons not disabled during requests | Multiple pages | Duplicate bookings/payments |
| 105 | **No confirmation dialogs** on destructive actions (delete) | Multiple pages | Accidental data loss |
| 106 | **Hardcoded demo credentials in production code** | `Login.jsx:14-19` | Security exposure |
| 107 | **No React.memo on list components** — ProfessionalCard, ReviewCard re-render entire lists | Multiple pages | Performance degradation |
| 108 | **No code splitting / lazy loading** — all 57 pages imported statically | `App.jsx` | Large initial bundle |
| 109 | **Footer has placeholder phone number** | `Footer.jsx:60` — `+1 (555) 123-4567` | Unprofessional appearance | ✅ Fixed |

### 🟡 NEW P2 — MEDIUM PRIORITY

#### Database Quality
| # | Issue | File | Impact |
|---|-------|------|--------|
| 110 | **Migrations 003, 015 missing BEGIN/COMMIT** | `003_review_by_booking.sql`, `015_collections_points.sql` | Partial failures possible |
| 111 | **seed.sql not idempotent** — no ON CONFLICT on INSERTs | `seed.sql` | Re-import fails |
| 112 | **No rollback/DOWN support in any migration** | All 18 migrations | Can't safely rollback |
| 113 | **CI pipeline silently ignores migration errors** — `2>/dev/null || true` | `.github/workflows/ci.yml:96-102` | Broken migrations undetected |

#### Mobile Quality
| # | Issue | File | Impact |
|---|-------|------|--------|
| 114 | **Monolithic models.dart (394 lines)** — all models in single file | `models.dart` | Hard to maintain |
| 115 | **i18n only 53 keys per language** — many UI strings not translated | `l10n/` | Incomplete localization |
| 116 | **Service layer thin** — no retry, no interceptors | `api_service.dart` | No auth failure recovery |
| 117 | **Professional model missing Phase 4 fields** | `models.dart` | Missing tagline, introVideoUrl |

#### DevOps Quality
| # | Issue | File | Impact |
|---|-------|------|--------|
| 118 | **No NetworkPolicy definitions** — no network segmentation in K8s | K8s manifests | Zero network isolation |
| 119 | **Database single replica** — no HA setup | `statefulsets.yaml:15` | No failover |
| 120 | **Staging/production deployment placeholder** — not implemented | `ci.yml:312-375` | Manual deployments |
| 121 | **Frontend Dockerfile missing HEALTHCHECK** | `frontend/Dockerfile` | No container health monitoring |
| 122 | **Frontend Dockerfile runs as root** | `frontend/Dockerfile` | Security risk |
| 123 | **No E2E/integration tests in CI** | `ci.yml` | Integration bugs undetected |
| 124 | **Missing scrape targets** — only backend monitored | `monitoring/` | No postgres/redis/nginx metrics |
| 125 | **Only 4 alert rules** — missing disk, memory, pool exhaustion | `monitoring/alerts.yml` | Insufficient alerting |

### 🔵 NEW P3 — LOW PRIORITY (Tech Debt)

| # | Issue | File | Impact |
|---|-------|------|--------|
| 126 | **No Swagger/OpenAPI documentation** | Backend | API discovery difficult |
| 127 | **No Web Vitals tracking** | Frontend | No performance monitoring |
| 128 | **No dark mode CSS** on 40+ files | Frontend CSS | Incomplete theming |
| 129 | **console.error/log statements in production code** | 11+ files | Noisy console |
| 130 | **No breadcrumb navigation** on detail pages | Frontend | Poor navigation UX |
| 131 | **Admin flag queried every request** | `middleware/auth.js` | Should cache admin status |
| 132 | **Docker credentials hardcoded** | `docker-compose.yml` | Should use .env file |
| 133 | **K8s storage class hardcoded to AWS** | `statefulsets.yaml` | Not portable |
| 134 | **No request size limit beyond JSON 1mb** | Backend | Memory exhaustion risk |

---

## 📊 UPDATED PRODUCTION READINESS SCORECARD (Deep Audit v2)

| Area | Previous | Updated | Delta | Key Issue |
|------|----------|---------|-------|-----------|
| **Auth & Roles** | 9/10 | 9/10 | 0 | ✅ Logout API added, rate limiting in place |
| **Backend API** | 9/10 | 8.5/10 | -0.5 | SQL injection fixed, silent catches fixed, N+1 queries remain |
| **Service Catalog** | 9/10 | 9/10 | 0 | Solid |
| **Provider Onboarding** | 8/10 | 8/10 | 0 | Company KYC still pending |
| **Customer Discovery** | 8/10 | 8/10 | 0 | Silent catches fixed |
| **Booking Flow** | 7/10 | 7.5/10 | +0.5 | Date validation + amount cap added |
| **Professional Dashboard** | 8/10 | 8/10 | 0 | .bak removed, silent catches fixed |
| **Storefront** | 8/10 | 8.5/10 | +0.5 | Silent catches now logged properly |
| **Social Features** | 8/10 | 8/10 | 0 | Good |
| **Trust System** | 9/10 | 9/10 | 0 | ✅ top_rated badge implemented |
| **Mobile App** | 7/10 | 6.5/10 | -0.5 | Monolithic models, thin service layer |
| **Infrastructure** | 9/10 | 7/10 | -2.0 | No NetworkPolicy, single DB replica, placeholder deploy |
| **Security** | 9/10 | 8.5/10 | -0.5 | ✅ SQL injection, path traversal, password validation fixed |
| **Performance** | 8/10 | 7/10 | -1.0 | N+1 queries, no code splitting, no memo |
| **Test Coverage** | 6/10 | 6/10 | 0 | 22/38 controllers still untested |

**Updated Overall: 8.1/10** (up from 7.7 — critical security & stability bugs fixed)

---

## 🚀 UPDATED IMPLEMENTATION PLAN — PRODUCTION SPRINT

> **Priority:** Make the app production-ready with user-friendly dual-experience (provider + customer)

### Sprint P1: Service Catalog Foundation (🔴 CRITICAL — ✅ MOSTLY COMPLETE)

- [x] **P1.1 Database: professional_services table** — Migration 017 created with indexes
- [x] **P1.2 Backend: Service CRUD** — `serviceController.js` with 5 endpoints at `/api/services`
- [x] **P1.3 Frontend: Service Management** — New "🛠️ Services" tab in StorefrontSetup.jsx
- [x] **P1.4 Frontend: Service Display** — Service catalog cards on Storefront.jsx with pricing + book button
- [x] **P1.5 Frontend: Service-Based Booking** — Service selection chips in CreateBooking.jsx with price display

### Sprint P2: Provider Onboarding Excellence (🟠 HIGH — ✅ MOSTLY COMPLETE)

- [x] **P2.1 Multi-Step Onboarding Wizard** — New `ProfessionalOnboarding.jsx` at `/onboarding/professional`:
  - Step 1: "Are you an Individual or Company?" (large selection cards)
  - Step 2 (Individual): Personal details + skills + experience
  - Step 2 (Company): Company details + registration + team size
  - Step 3: Select categories + add specific services with pricing
  - Step 4: Upload portfolio (photos/videos)
  - Step 5: Set availability schedule
  - Step 6: Review & publish storefront
  - Progress bar + save draft capability
- [x] **P2.2 Company-Specific Profile Sections** — Extended `Storefront.jsx`:
  - Company info card (name, team size, registration number) for organizations
  - Departments / service areas display
- [ ] **P2.3 Company KYC Extension** — Extend KYC flow:
  - Company registration document upload
  - GST certificate upload
  - Company address verification

### Sprint P3: Customer Discovery Excellence (🟠 HIGH — ✅ MOSTLY COMPLETE)

- [x] **P3.1 Geolocation Integration** — Updated `Home.jsx`:
  - Request location permission with button
  - Show "Near You" section with nearby professionals in horizontal scroll
  - Coords cached in localStorage for instant reload
- [x] **P3.2 Service-Level Browsing** — Updated `CategoryDetail.jsx`:
  - Fetches services from `/services/search?category=` API
  - Shows service chips with pricing between subcategories and results
  - Click to filter by specific service
- [x] **P3.3 Quick Filters** — Updated `SearchResults.jsx`:
  - "Available Now" prominent toggle chip
  - "Individuals" / "Companies" provider type chips
  - Rating filter chip with dismiss
- [ ] **P3.4 Map View** — Future enhancement:
  - Toggle between grid/list/map views
  - Map markers for professionals with lat/lng
- [x] **P3.5 Recently Viewed Persistence** — Updated `Home.jsx`:
  - Loads from localStorage instantly (no flash)
  - Refreshes from API and saves up to 20 items

### Sprint P4: Professional Dashboard Enhancement (🟡 MEDIUM — ✅ MOSTLY COMPLETE)

- [x] **P4.1 Service Management Page** — Already implemented in StorefrontSetup.jsx "Services" tab
- [x] **P4.2 Booking Calendar View** — Added to `Bookings.jsx`:
  - List/Calendar toggle with icons
  - BookingCalendar component with month navigation
  - Color-coded booking status dots per day
- [x] **P4.3 Quick Actions Widget** — Added to `Dashboard.jsx`:
  - "Available Today" toggle (ON/OFF with live status)
  - View Storefront, Edit Storefront, Onboarding Wizard links
- [x] **P4.4 Customer Insights** — Added to `Dashboard.jsx`:
  - Total Customers, Repeat Customers, Jobs Completed, Avg Rating cards

### Sprint P5: Mobile Completion (🟡 MEDIUM)

- [ ] **P5.1 Missing Screens** — Create 7 screens:
  - Collections screen (save boards)
  - Community feed screen (tips/posts)
  - Followers list screen
  - Stories viewer screen
  - Points/loyalty screen
  - Referral detail screen
  - Admin dashboard screen
- [ ] **P5.2 Missing Services** — Create 6+ services:
  - WarrantyService, DisputeService, CollectionService
  - PointsService, CommunityService, ReferralService
- [ ] **P5.3 Missing Models** — Create 9+ models + split models.dart
- [ ] **P5.4 Service Catalog in Mobile** — Mirror web service management

---

## 📋 WHAT'S ALREADY DONE CORRECTLY ✅

> **Important:** A huge amount of work is already correctly implemented. This section documents what NOT to change.

### ✅ Correctly Implemented — Do Not Modify

1. **Auth System** — 4 roles (customer, professional, agent, admin), RBAC ProtectedRoute, token refresh, role helpers, role-specific login/register pages. **Perfect.**
2. **Individual/Company Toggle** — DB has `provider_type ENUM`, registration form supports it, cards show company badge, search filters by it. **Correct foundation — just needs deeper UX.**
3. **Category Hierarchy** — `categories` table with `parent_id`, backend returns nested tree, frontend shows parent → subcategory navigation. **Correct.**
4. **Booking Flow** — Multi-step wizard (What → When → Where → Confirm), slot fetching, status tracking with humanized labels. **Good — needs service selection upgrade.**
5. **Storefront System** — Themes, packages, media (reels/before-after/highlights), branding, trust badges. **Excellent.**
6. **Social Layer** — Follow system, collections/save boards, professional stories, community posts, reels feed. **Excellent.**
7. **Trust System** — Badge tiers (Rising Pro → Elite), auto-calculation cron, trust timeline, trust explainability. **Excellent.**
8. **Discovery** — Trending/new/responsive discovery endpoints, horizontal carousels on home page. **Good foundation.**
9. **Dashboard** — Dual view (professional vs customer), stats, recent bookings/reviews/contacts. **Good foundation.**
10. **Error Handling** — Silent catches replaced, error boundaries wrapping routes, retry logic on services. **Fixed.**
11. **Security** — Rate limiting, input validation, bcrypt consistency, token blacklist cleanup, fraud middleware. **Production-grade.**
12. **Infrastructure** — Docker Compose, K8s manifests, Prometheus/Grafana, CI/CD pipeline, PgBouncer. **Production-grade.**

---

## 🔍 GAP ANALYSIS & ISSUES (2026-05-16 Deep Audit)

> **Summary:** Comprehensive codebase audit identified **150+ issues** across backend, frontend, database, mobile, and DevOps. Issues categorized by severity with actionable fixes.

### 🔴 P0 — CRITICAL ISSUES (Fix Immediately)

#### Backend Error Handling
| # | Issue | File | Impact | Status |
|---|-------|------|--------|--------|
| 1 | **Silent `.catch(() => {})` in 23+ backend places** — swallows errors | `paymentController.js:116`, `contactController.js:89,97,108`, `growthController.js:40,245,286,293,396`, `kycController.js:267,280,283`, `complaintController.js:56,58`, `searchController.js:42`, `reviewController.js:117` | Failed emails/SMS/payments silently lost | ✅ Fixed in Sprint 1 (cron.js), remaining 23 instances in Sprint 2 |
| 2 | **Email service method mismatch** — cron calls `.send()` but service exports `.sendEmail()` | `workers/cron.js:172,211` | Runtime errors in subscription expiry cron | ✅ Fixed |
| 3 | **Inconsistent bcrypt rounds** — auth uses 12 rounds, userController uses 10 | `authController.js` vs `userController.js:60` | Weaker passwords for profile updates | ✅ Fixed |
| 4 | **Token blacklist table grows forever** — no cleanup cron | `authController.js:388-392` | Unbounded DB table growth | ✅ Fixed |
| 5 | **No API request timeout** — frontend fetch calls hang | `frontend/src/api/client.js` | Frozen UI on network issues | ✅ Fixed (30s timeout) |
| 6 | **No retry logic in API client** — single failure | `frontend/src/api/client.js` | Poor resilience | ✅ Fixed (2 retries + backoff) |

#### Frontend Critical
| # | Issue | File | Impact | Status |
|---|-------|------|--------|--------|
| 7 | **No role-based access control** — ProtectedRoute only checks `isAuthenticated` | `ProtectedRoute.jsx:5-19` | Admin routes accessible to any authenticated user | 🔧 Sprint 2 |
| 8 | **Admin dashboard broken links** — 3 buttons to non-existent routes | `AdminDashboard.jsx:58-60` (`/admin/complaints`, `/admin/categories`, `/admin/audit-log`) | 404 errors for admin users | 🔧 Sprint 2 |
| 9 | **No token refresh on 401** — expired tokens force re-login | `AuthContext.jsx`, `client.js` | Users forced to re-login frequently | 🔧 Sprint 2 |
| 10 | **30+ silent catches in frontend pages** — no user feedback | `Home.jsx:92,103,108-111`, `Storefront.jsx:50,51,71,84,92`, `Collections.jsx:43,53,77`, `Dashboard.jsx:249,259,264,274,278`, `Favorites.jsx:32`, `CommunityFeed.jsx:47`, `ProfessionalProfile.jsx:35,44`, `Notifications.jsx:102,118`, `Disputes.jsx:54`, `StorefrontSetup.jsx:96`, `AgentDashboard.jsx:34` | Users see blank sections, failed actions with no feedback | 🔧 Sprint 2 |
| 11 | **Error states defined but not rendered** — `error` state unused in UI | `Messages.jsx:37-41`, `Chat.jsx:42,68`, `Bookings.jsx:54`, `Notifications.jsx:59` | Error messages never shown to users | 🔧 Sprint 2 |

#### Database Critical
| # | Issue | File | Impact | Status |
|---|-------|------|--------|--------|
| 12 | **Duplicate migration numbers** — two `006_*.sql` and two `007_*.sql` files | `database/migrations/` | Undefined execution order | ✅ Fixed (renamed to 006b, 007b) |
| 13 | **Base schema only 8 tables** — 74+ production tables defined only in migrations | `schema.sql` vs migrations | No single source of truth | ⚠️ P2 |
| 14 | **8/17 migrations lack BEGIN/COMMIT** — partial failures corrupt DB | `004_seed_geo.sql`, `006_phase1_features.sql`, `006b`, `007b`, `008`, `009`, `010` | Partial migration = broken schema | 🔧 Sprint 2 |

### 🟠 P1 — HIGH PRIORITY (Fix This Sprint)

#### Backend Validation Gaps
| # | Issue | File |
|---|-------|------|
| 15 | Missing validation for `service_lat`, `service_lng`, `preferred_date` | `bookingController.js:36-50` |
| 16 | No UUID validation for `booking_id`, no enum check for payment `method` | `paymentController.js:7-35` |
| 17 | Missing password strength validation on `changePassword()` | `userController.js:45-68` |
| 18 | No file type/size validation on uploads | `uploadController.js` |
| 19 | `discoverController.js` — `req.query.limit` parsed without bounds checking (DoS risk) | `discoverController.js` |

#### Backend Missing Pagination (6 controllers)
| # | Issue | File |
|---|-------|------|
| 20 | `getRecentContacts/Reviews/Bookings` hardcoded LIMIT, no offset | `dashboardController.js` |
| 21 | No pagination support | `matchingController.js` |
| 22 | No pagination on list endpoint | `disputeController.js` |
| 23 | No pagination | `scheduleController.js` |
| 24 | No pagination on list endpoints | `analyticsController.js` |
| 25 | No pagination | `portfolioController.js` |

#### Backend Missing Test Coverage (78% of controllers untested)
| # | Issue | Details |
|---|-------|---------|
| 26 | **29 out of 37 controllers have NO tests** | Critical untested: `paymentController`, `matchingController`, `notificationController`, `bookingController`, `userController`, `professionalController`, `aiController` |
| 27 | Only 16 test files (2,477 lines) for 37 controllers + 38 routes | Missing edge cases, integration tests |

#### Frontend Error Handling
| # | Issue | File |
|---|-------|------|
| 28 | Failed search silently returns empty results | `SearchResults.jsx:85` |
| 29 | No debounce on search/filter rapid clicks | `SearchResults.jsx:63`, `Messages.jsx:31` |
| 30 | Platform fee (5%) hardcoded in frontend | `Payment.jsx:76` — should come from server config |

#### Missing Rate Limiting
| # | Issue | Endpoint |
|---|-------|----------|
| 31 | Payment endpoints need stricter limits | `/api/payments/*` |
| 32 | KYC operations lack rate limiting | `/api/kyc/*` |
| 33 | Admin operations need dedicated limits | `/api/admin/*` |
| 34 | Booking state transition spam | `/api/bookings/:id/transition` |
| 35 | Upload resource exhaustion | `/api/upload` |

#### Webhook Error Handling
| # | Issue | File |
|---|-------|------|
| 36 | Silent `.catch(() => {})` in 3 webhook handlers — subscription/invoice ops fail silently | `routes/webhooks.js:79,96,104` |

### 🟡 P2 — MEDIUM PRIORITY (Next Sprint)

#### Frontend Quality
| # | Issue | Details |
|---|-------|---------|
| 37 | **No PropTypes** in any of 40+ components | Zero type safety |
| 38 | **Accessibility gaps** — missing aria-labels, keyboard navigation | `SearchResults.jsx`, `Dashboard.jsx`, `ProfessionalCard.jsx` |
| 39 | **External dependency for avatars** — `ui-avatars.com` as fallback | `Favorites.jsx:60` |
| 40 | **Hardcoded cities array** in Home.jsx | `Home.jsx:71-74` — should be backend-driven |
| 41 | **Inconsistent API response parsing** | `Bookings.jsx`, `SearchResults.jsx`, `Dashboard.jsx` |
| 42 | **No ErrorBoundary wrapping pages** — one page crash takes out entire app | `App.jsx` — ErrorBoundary exists but isn't wrapping routes |
| 43 | **Missing role helper functions** in AuthContext | No `isAdmin()`, `isProfessional()`, `isAgent()`, `hasRole()` |

#### Backend Quality
| # | Issue | Details |
|---|-------|---------|
| 44 | Missing retry logic in 5 services | `email.js`, `sms.js`, `razorpay.js`, `pushNotification.js`, `storage.js` |
| 45 | Incomplete service implementations | `gstInvoice.js:105` (PDF unavailable), `storage.js:41` (S3 not available), `faceMatch.js:32` (no credentials) |
| 46 | Account lockout uses in-memory Map | Won't work in load-balanced setup |
| 47 | `top_rated` badge TODO unimplemented | `trustController.js:64` — percentile not calculated |
| 48 | `storefrontController.js` — 5 silent catches for "table may not exist" | Lines 82, 95, 108, 118, 128 — should handle gracefully with proper logging |
| 49 | Missing cron jobs | Booking cleanup >90d, complaint escalation >30d, dispute auto-escalation >14d, analytics aggregation |

#### Database Quality
| # | Issue | Details |
|---|-------|---------|
| 50 | Missing UNIQUE constraint on `users.phone` | Duplicate registrations possible |
| 51 | Missing CHECK constraints | `users.role` no enum, coordinates no range |
| 52 | Zero rollback/DOWN support in all 17 migrations | Can't safely rollback failed deployments |
| 53 | `004_seed_geo.sql` — no IF NOT EXISTS on INSERTs | Re-run causes duplicate data |
| 54 | `seed.sql` not idempotent | Re-import will fail without cleanup |
| 55 | Missing indexes | No index on `users.phone`, `booking_status_log.created_at` |

#### Mobile Gaps
| # | Issue | Details |
|---|-------|---------|
| 56 | 7 major screens missing | Collections, Community, Followers, Stories, Loyalty/Points, Referral detail, Admin dashboard |
| 57 | 6+ missing mobile services | WarrantyService, DisputeService, CollectionService, PointsService, CommunityService, ReferralService |
| 58 | 9+ missing models | Warranty, Dispute, Collection, UserPoints, CommunityPost, Badge, Follow, Story, FeaturedSlot |
| 59 | Monolithic `models.dart` (394 lines) | Should be split into 8+ files |
| 60 | Service layer too thin — no retry, no interceptors | `api_service.dart` — no auth failure handling |
| 61 | Professional model missing Phase 4 fields | Missing: `tagline`, `introVideoUrl`, `totalCustomers`, `repeatCustomerRate` |

#### DevOps Gaps
| # | Issue | Details |
|---|-------|---------|
| 62 | K8s: No NetworkPolicy definitions | No network segmentation |
| 63 | K8s: Database not HA — single replica | `statefulsets.yaml:15` — no replication |
| 64 | K8s: Redis single instance — no HA | No sentinel/cluster configured |
| 65 | K8s: PgBouncer missing readiness probe | Backend deployment sidecar |
| 66 | K8s: Ingress missing rate limiting & WAF | `ingress.yaml` — no annotations |
| 67 | K8s: Secrets in stringData — not production-safe | `secret-template.yaml` |
| 68 | Monitoring: Only 1 scrape target (backend) | Missing: postgres, redis, node-exporter, nginx |
| 69 | Monitoring: Only 4 alert rules — insufficient | Missing: disk, memory, pool exhaustion, cache degradation |
| 70 | Monitoring: No Alertmanager routing | No Slack/PagerDuty integration |
| 71 | Monitoring: Grafana provisioning incomplete | No datasource config or dashboard JSON |

### 🔵 P3 — LOW PRIORITY (Technical Debt)

| # | Issue | Details |
|---|-------|---------|
| 72 | No Swagger/OpenAPI documentation | API discovery difficult |
| 73 | Frontend test coverage <5% (2 test files for 50+ pages) | Regressions undetectable |
| 74 | Backend test coverage: 29/37 controllers untested | Missing edge cases |
| 75 | No environment variables guide | Onboarding friction |
| 76 | Admin flag queried every request | Should cache admin status |
| 77 | No request size limit middleware beyond JSON 1mb | Memory exhaustion risk |
| 78 | Docker credentials hardcoded in docker-compose.yml | Should use .env file |
| 79 | K8s storage class hardcoded to `gp3` (AWS-specific) | Not portable |
| 80 | API versioning not planned | Will break on schema changes |

---

## ✅ IMPLEMENTATION PLAN (Sprint Tracker)

### Sprint 1: P0 Critical Fixes ✅ COMPLETE

- [x] **1. API Client Enhancement** — 30s timeout, 2 retries with exponential backoff
- [x] **2. Backend Silent Error Fixes** — Replace `.catch(() => {})` in cron.js
- [x] **3. Bcrypt Consistency** — Standardize to 12 rounds in `userController.js`
- [x] **4. Docker Health Checks** — Health checks for backend, frontend, pgbouncer
- [x] **5. Token Blacklist Cleanup** — Cron job to clean expired blacklist entries
- [x] **6. Database Migration Numbering** — Rename duplicate 006/007 → 006b/007b

### Sprint 2: P0/P1 High Priority Fixes ✅ COMPLETE

- [x] **7. ProtectedRoute RBAC** — Role-based route guards (`allowedRoles` prop)
- [x] **8. Token Refresh on 401** — AuthContext + API client auto-refresh
- [x] **9. Missing Admin Pages** — AdminComplaints.jsx + AdminAuditLog.jsx + routes
- [x] **10. Backend Silent Error Fixes** — Replace 23 remaining `.catch(() => {})` with proper logging
- [x] **11. Frontend Error Logging** — Replace 30+ silent catches with `console.error` + user-visible toast/state
- [x] **12. Error State Display** — Wire up unused error states in Messages, Chat, Bookings, Notifications
- [x] **13. Input Validation** — Booking lat/lng/date validation, payment UUID/method validation, discover limit bounds (1-50)
- [x] **14. Pagination** — Portfolio controller with page/limit/total_count/total_pages response
- [x] **15. Rate Limiting** — Payment (10/min), KYC (10/hr), admin (30/min), upload (50/hr) rate limiters

### Sprint 3: P2 Medium Priority ✅ MOSTLY COMPLETE

- [x] **16. Service Retry Logic** — Add exponential backoff to email, SMS, payment, push services
- [x] **17. PropTypes** — Add prop validation to 10 most-used components (ProfessionalCard, StarRating, CategoryCard, ReviewCard, LoadingSpinner, SearchBar, ShareButton, OnlineIndicator, ProtectedRoute, SEOMeta)
- [x] **18. Accessibility** — Add aria-labels to SearchResults (filter, sort, view toggles), ProfessionalCard (role=article), category filters
- [ ] **19. Mobile Screens** — Create Collections, Community, Followers, Points screens
- [ ] **20. Mobile Services** — Add WarrantyService, DisputeService, CollectionService, etc.
- [ ] **21. Mobile Models** — Add missing 9+ models, split models.dart into separate files
- [x] **22. Database Constraints** — Migration 016: CHECK on role/rating/points, indexes on phone/booking_status_log/bookings
- [x] **23. Migration Transactions** — Add BEGIN/COMMIT to 7 migrations missing them
- [x] **24. K8s Health Probes** — Liveness/readiness/startup probes on Prometheus + Grafana deployments
- [x] **25. ErrorBoundary Wrapping** — Wrap page routes with ErrorBoundary in App.jsx
- [x] **26. AuthContext Helpers** — `isAdmin()`, `isProfessional()`, `isAgent()`, `hasRole()` already implemented
- [x] **27. Webhook Error Handling** — All 3 catches in webhooks.js already log with `logger.error`
- [x] **28. Additional Cron Jobs** — Booking cleanup (>90d), complaint escalation (>30d), dispute escalation (>14d)

### Sprint 4: P3 Technical Debt (Ongoing)

- [ ] **29. API Documentation** — Generate OpenAPI/Swagger spec from routes
- [ ] **30. Frontend Tests** — Add tests for auth flow, booking wizard, storefront
- [ ] **31. Backend Tests** — Coverage for 29 untested controllers (priority: payments, matching, bookings)
- [ ] **32. Environment Guide** — Document all env vars with defaults and descriptions
- [ ] **33. Event Bus** — Decouple controllers from side effects
- [ ] **34. Monitoring Expansion** — Add postgres/redis/node exporters, more alert rules
- [ ] **35. K8s Production Hardening** — NetworkPolicy, HA database, secrets management

### Sprint 5: Deep Audit v2 — Critical Security Fixes (🔴 NEW — ✅ MOSTLY COMPLETE)

- [x] **36. Escrow Dispute Check** — Added active dispute count subquery; blocks release when dispute active
- [x] **37. Remaining Backend Silent Catches** — Fixed 6 instances in `hub.js`, `auth.js`, `payments.js`, `pushNotification.js` with proper logger.warn/error
- [x] **38. Auth Rate Limiting** — Already applied at app.js level (`authLimiter` on `/api/auth`)
- [ ] **39. Referral Code Dedup** — Add unique constraint check preventing duplicate referral applications per user
- [x] **40. Booking Date Upper Bound** — Limited preferred_date to max 90 days in future
- [x] **41. Amount Range Validation** — Added max cap (₹10,00,000) on `quoted_amount`
- [x] **42. Frontend Logout API Call** — Added `POST /auth/logout` call in AuthContext `logout()` (best-effort)
- [x] **43. Frontend Silent Catches** — Fixed 22 instances across 11 files with `console.error` logging
- [ ] **44. WebSocket Timer Cleanup** — Add proper cleanup for `setInterval`/`setTimeout` in WebSocketContext
- [x] **45. Remove Dashboard.jsx.bak** — Deleted backup file from source tree

### Sprint 6: Deep Audit v2 — Performance & Quality (🟠 NEW — PARTIAL)

- [ ] **46. Search N+1 Fix** — Refactor search ranking subqueries to use JOINs or window functions
- [ ] **47. Missing Composite Indexes** — Add indexes on `(customer_id, status)`, `(professional_id, created_at)`, `(payer_id, status)`
- [ ] **48. XSS Input Sanitization** — Add sanitization middleware for all text input fields
- [x] **49. Top Rated Badge Implementation** — Implemented category-level percentile calculation in `trustController.js`
- [ ] **50. Search Debouncing** — Add debounce (300ms) to SearchBar component
- [ ] **51. Form Double-Submit Prevention** — Disable submit buttons during API requests across all forms
- [ ] **52. Loading Skeletons** — Add CardSkeleton to SearchResults, dashboard sections
- [ ] **53. Empty States** — Add "No messages yet", "No notifications" empty states to Messages, Chat, Notifications
- [ ] **54. Code Splitting** — Add React.lazy() + Suspense for page-level code splitting in App.jsx
- [ ] **55. React.memo** — Wrap ProfessionalCard, ReviewCard, CategoryCard with React.memo
- [ ] **56. Upload Validation** — Add file type whitelist and size limit (10MB) to uploadController
- [ ] **57. Password Strength** — Add minimum 8 chars, 1 uppercase, 1 number validation on changePassword
- [x] **64. Placeholder Footer** — Replaced demo phone `+1 (555) 123-4567` with `+91 1800-XXX-XXXX`

### Sprint 7: Deep Audit v2 — Infrastructure & Database (🟡 NEW)

- [ ] **58. Migration Transactions** — Add BEGIN/COMMIT to migrations 003, 015
- [ ] **59. Seed Data Idempotency** — Add ON CONFLICT DO NOTHING to all seed.sql INSERTs
- [ ] **60. CI Migration Error Handling** — Remove `2>/dev/null || true` from CI pipeline migration execution
- [ ] **61. Frontend Dockerfile** — Add HEALTHCHECK, create non-root nginx user
- [ ] **62. NetworkPolicy** — Create K8s NetworkPolicy manifest for namespace isolation
- [ ] **63. Monitoring Alerts** — Add alerts for disk space, memory, connection pool, restart rate, cache hit ratio
- [ ] **64. Placeholder Footer** — Replace demo phone number `+1 (555) 123-4567` with real or branded placeholder
- [ ] **65. Consistent Response Format** — Standardize all API responses to `{success, data?, message?, error?}`
- [ ] **66. Fraud Prevention Redis** — Migrate in-memory Map to Redis store for load-balanced environments
- [ ] **67. Mobile Models Split** — Split monolithic models.dart into domain-specific files

---

## Platform Scorecard (Updated Deep Audit v2)

| Area | Score | Status | Target | Key Blocker |
|------|-------|--------|--------|-------------|
| Backend Engineering | 8.0/10 | ⚠️ Good, gaps found | 9.5 | N+1 queries, silent catches, escrow bug |
| Security | 7.5/10 | ⚠️ Needs hardening | 9.5 | No XSS sanitization, no auth rate limit, escrow |
| Marketplace Logic | 9.0/10 | ✅ Mature | Maintain | — |
| Ecosystem Potential | 9.5/10 | ✅ Huge potential | Unlock | — |
| Mobile Architecture | 6.5/10 | ⚠️ Needs work | 8.5 | Monolithic models, thin services, missing screens |
| Trust/Safety | 8.5/10 | ✅ Strong | 9.5 | top_rated badge unimplemented |
| Scalability Planning | 7.0/10 | ⚠️ Gaps | 9.0 | No HA DB, in-memory fraud store, no code splitting |
| Performance | 7.0/10 | ⚠️ Needs optimization | 9.0 | N+1 queries, no memo, no lazy loading |
| Test Coverage | 6.0/10 | 🔴 Weak | 8.5 | 22/38 controllers untested, <5% frontend coverage |
| Infrastructure | 7.0/10 | ⚠️ Gaps | 9.0 | No NetworkPolicy, placeholder deploys, single DB |
| UX Philosophy | 6.8/10 | ⚠️ Biggest weakness | → 9.0 | No debounce, no empty states, no code splitting |
| Emotional Product Design | 5.5/10 | ⚠️ Missing | → 8.5 | — |
| Retention Systems | 5.5/10 | ⚠️ Weak | → 8.0 | — |
| Consumer Delight | 5.0/10 | ⚠️ Functional not addictive | → 8.5 | — |
| Storefront Experience | 8.0/10 | ✅ Much improved | → 9.0 | Client testimonials, day-in-work |
| Professional Branding | 7.5/10 | ⚠️ Good foundation | → 8.5 | — |
| Social/Engagement Layer | 8.0/10 | ✅ Solid | → 8.5 | Collection sharing |
| AI Layer | 3.5/10 | 🔴 Very early | → 8.0 | — |
| Virality | 3.0/10 | 🔴 Weak | → 7.5 | — |

### Core Problem Statement

The platform is **feature-complete** but NOT **emotionally premium**. It feels like an "enterprise listing system" instead of a "personal business app." The storefront behaves like a marketplace profile page — it should feel like a **mini personal business app** that professionals feel ownership over.

### Future Moat (NOT replicable)

The long-term competitive advantage is the **Professional Graph + Trust Graph**: identity, customer history, repeat interactions, reviews, content, business reputation, AI insights, storefront reputation, engagement history. This becomes impossible for competitors to copy.

---

## Current State (What's Built)

- **Frontend:** 60+ pages, React 19, Vite, responsive, WebSocket chat, 40+ components — `frontend/src/pages/`
- **Backend:** 120+ endpoints, Express 5, 42 controllers, 43 route files, 16 test suites (150 tests), fraud middleware — `backend/src/`
- **Mobile:** Flutter 3.8, 49 screens, offline-first, i18n (EN/HI/TE), 16 services — `mobile/skillconnect/lib/`
- **Database:** PostgreSQL 16, schema + seed data + migrations — `database/`
- **DevOps:** Docker Compose, K8s manifests, CI/CD, Prometheus/Grafana, Sentry — `k8s/`, `monitoring/`
- **Services:** S3 storage, Redis cache, SendGrid email, SMS, FCM push, job queue — `backend/src/services/`
- **Existing Storefront:** Basic `Storefront.jsx` + `StorefrontSetup.jsx` + `storefrontController.js` — needs major upgrade

### Completed Phases (Reference Only)

<details>
<summary>✅ Phase 1: Core Features (DONE)</summary>

- [x] Warranties module — full CRUD + claim workflow + status transitions
- [x] Referrals module — code generation, tracking, reward crediting
- [x] Emergency module — dispatch, WebSocket broadcast, resolve endpoint
- [x] Analytics module — event pipeline, ingestion, aggregation dashboard
- [x] Agent system — commissions, wallet, leaderboard, frontend pages
</details>

<details>
<summary>✅ Phase 2: Infrastructure (DONE)</summary>

- [x] Cloud storage (S3/R2 + signed URLs)
- [x] Redis (cache, rate-limiting, pub/sub ready)
- [x] Email (SendGrid) + SMS (MSG91/Twilio) with templates
- [x] Push notifications (FCM + device tokens + stale cleanup)
- [x] Job queue (in-memory with retry + 6 cron jobs)
- [ ] BullMQ upgrade (tracked for scale-up)
</details>

<details>
<summary>✅ Phase 3: Production Infra (MOSTLY DONE)</summary>

- [x] SSL/TLS + nginx + HSTS
- [x] Kubernetes base manifests + HPA + PDB + Ingress
- [x] CI/CD 7-stage pipeline
- [x] Prometheus + Grafana + Sentry
- [x] PgBouncer connection pooler
- [x] Security hardening (audit, Trivy, Gitleaks, headers)
- [ ] K8s overlays (staging/production)
- [ ] Automated DB backups
- [ ] OpenTelemetry tracing
</details>

---

## NEW PHASE 4: Storefront Revolution (Priority: CRITICAL)

> **Goal:** Transform the professional storefront from a "listing inside platform" into a "mini personal business app"  
> **Inspiration:** Shopify ownership + Instagram visual identity + Airbnb trust  
> **Impact:** Storefront 5/10 → 9/10, Professional Branding 4.5/10 → 8.5/10

### 4.1 Hero Experience — Premium First Impression

- [x] **Cinematic banner** — full-width hero image/video with gradient overlay on `Storefront.jsx`
- [x] **Short intro reel** — 15–30s video intro with auto-play (muted) in hero section
- [x] **Premium typography** — large name, tagline, service category with elegant font stack
- [x] **Animated verified badge** — subtle glow/pulse animation on verified professionals
- [x] **Trust indicators above the fold** — rating, jobs completed, response time, repeat customers
- [x] **Sticky CTA** — "Book Now" button that follows scroll on mobile and desktop
- [x] **Availability indicator** — "Available Today" / "Next Available: Tomorrow" live status
- [x] Backend: `GET /storefront/:id` returns hero data (banner, reel URL, tagline, trust stats, badges, media, packages, follower count)

### 4.2 Visual Storytelling — Portfolio 2.0

- [x] **Before/after slider** — before/after card grid with labeled images on storefront
- [x] **Work transformation reels** — short video gallery (Instagram Reels-style grid)
- [x] **Story highlights** — pinned circular thumbnails (like Instagram highlights) on storefront
- [ ] **Client video testimonials** — embedded video reviews from customers
- [ ] **"Day in my work" content** — photo/video journal feature for professionals
- [x] Backend: `POST /storefront/:id/media` — upload reels, before/after, highlights
- [x] Backend: `GET /storefront/:id/media` — paginated media gallery with type filter
- [x] DB migration: `storefront_media` table (id, storefront_id, type [reel/before_after/highlight/testimonial/gallery], media_url, thumbnail_url, caption, before_url, sort_order, created_at)

### 4.3 Professional Branding & Customization

- [x] **Theme selection** — 8 pre-built storefront themes (modern, classic, bold, minimal, elegant, vibrant, dark, professional)
- [x] **Brand colors** — primary + accent color picker saved per storefront
- [x] **Custom cover layouts** — choose from layout templates (centered, left-aligned, split, hero)
- [x] **Custom sections** — reorderable content blocks (About, Services, Portfolio, Reviews, FAQ)
- [x] **Intro card** — "About My Business" rich text section
- [x] **Service packages** — tiered pricing cards (Basic / Standard / Premium) with features list
- [x] Backend: `PUT /storefront/:id/theme` — save theme, colors, layout, section order
- [x] Backend: `POST/DELETE /storefront/:id/packages` — service package CRUD
- [x] DB migration: `storefront_themes` table (storefront_id, theme_name, primary_color, accent_color, layout, section_order JSONB, custom_intro TEXT)
- [x] DB migration: `service_packages` table (professional_id, name, tier, price, description, features JSONB, is_popular, sort_order)
- [x] Frontend: `StorefrontSetup.jsx` — sectioned editor with theme grid, layout picker, package management

### 4.4 Humanized Booking UX

- [x] **Booking status language overhaul** — replace technical FSM states with human language:
  - `requested` → "Request Sent ✉️"
  - `quoted` → "Quote Received 💰"
  - `accepted` → "Professional Confirmed ✅"
  - `in_progress` → "Work Started 🔨"
  - `completed` → "Job Completed 🎉"
  - `cancelled` → "Cancelled ❌"
- [x] **Visual booking timeline** — step-by-step progress tracker with emoji icons
- [x] **Conversational booking flow** — guided multi-step wizard instead of a single form
- [x] Frontend: Update `CreateBooking.jsx` with step-by-step wizard (What → When → Where → Confirm)
- [x] Frontend: Update `BookingDetail.jsx` with humanized labels + status descriptions

---

## NEW PHASE 5: Social & Engagement Layer (Priority: HIGH)

> **Goal:** Add social mechanics that drive trust, engagement, and retention  
> **Inspiration:** Instagram follow/stories + Pinterest save boards  
> **Impact:** Social 4/10 → 8/10, Retention 5.5/10 → 8/10, Virality 3/10 → 7.5/10

### 5.1 Follow System

- [x] **Follow professional** — one-tap follow button on storefront and cards
- [x] **Following feed** — activity feed from followed professionals (new portfolio, availability, offers)
- [x] **Follower count** — displayed on storefront as social proof
- [x] Backend: `POST /social/follow/:professionalId` + `DELETE /social/unfollow/:professionalId`
- [x] Backend: `GET /social/feed` — aggregated feed from followed professionals
- [x] DB migration: `follows` table (id, follower_id, following_id, created_at) with unique constraint
- [x] Frontend: Follow/unfollow button integrated in `Storefront.jsx`

### 5.2 Save Collections (Pinterest-style)

- [x] **Save to collection** — bookmark professionals and services into named collections
- [x] **Default collections** — "Favorites", "For Later", plus custom user-created collections
- [ ] **Collection sharing** — share a collection via link
- [x] Backend: `POST /collections` (create), `POST /collections/:id/items` (add item), `GET /collections` (list)
- [x] DB migration: `collections` table (id, user_id, name, is_public, created_at) + `collection_items` table (collection_id, item_type, item_id)
- [x] Frontend: `Collections.jsx` page + `SaveToCollectionModal.jsx`

### 5.3 Professional Stories (Temporary Updates)

- [x] **24-hour stories** — professionals post ephemeral updates (available today, current project, offers)
- [x] **Story viewer** — horizontal scrollable story bubbles on home page and category pages
- [x] **Story creation** — photo/video + text overlay + CTA link
- [x] Backend: `POST /stories` (create), `GET /stories/feed` (nearby active stories), auto-expire via query
- [x] DB migration: `stories` table (id, professional_id, media_url, text_overlay, cta_url, cta_label, view_count, expires_at, created_at)
- [x] Frontend: Story highlights display on `Storefront.jsx`

### 5.4 Community Posts & Tips

- [x] **Professional tips** — long-form content from professionals ("How to maintain your AC", "Wedding makeup tips")
- [x] **Like + save + share** on community posts
- [x] **Category-tagged** — posts appear in relevant category feeds
- [x] Backend: `POST /community/posts`, `GET /community/posts?category=`, `POST /community/posts/:id/like`
- [x] DB migration: `community_posts` table (id, author_id, title, content, category, media_urls JSONB, likes_count, created_at)
- [x] Frontend: `CommunityFeed.jsx` page + `PostCard.jsx` component
- [ ] Bonus: Great for SEO — each post becomes an indexed page

### 5.5 WhatsApp Integration (India-First)

- [ ] **Click-to-WhatsApp** — direct WhatsApp button on storefront with pre-filled message
- [ ] **Booking reminders via WhatsApp** — template messages for confirmations + reminders
- [ ] **Re-engagement campaigns** — "Your favorite pro is available today" via WhatsApp Business API
- [ ] Backend: `backend/src/services/whatsapp.js` — WhatsApp Business API integration
- [ ] Template messages: booking confirmation, reminder, review request, re-engagement

---

## NEW PHASE 6: Discovery Revolution (Priority: HIGH)

> **Goal:** Move from functional search/filter to feed-driven + visual + intent-driven discovery  
> **Inspiration:** TikTok recommendation + Pinterest visual browse + Instagram Explore  
> **Impact:** Consumer Delight 5/10 → 8.5/10, Virality 3/10 → 7.5/10

### 6.1 Reels / Short Video Feed

- [x] **Reels feed page** — vertical swipeable short video feed (transformations, tutorials, before/after, work process)
- [x] **Reels from storefront** — professionals upload reels via storefront media
- [x] **Like + save + share + book** — engagement actions on each reel
- [ ] **Category-filtered reels** — beauty reels, home service reels, etc.
- [x] Backend: `GET /reels/feed?category=&page=` — paginated reel feed with engagement counts
- [x] Frontend: `ReelsFeed.jsx` — full-screen swipeable video player with overlay actions
- [ ] Mobile: `ReelsScreen` — native vertical video feed with gesture navigation

### 6.2 Trending & Discovery Sections

- [x] **Trending nearby** — most-booked professionals in user's area this week
- [ ] **Fastest growing** — professionals with rapidly increasing ratings/bookings
- [x] **Newly verified** — recently verified professionals to boost early visibility
- [x] **Highly responsive** — professionals with fastest response times
- [ ] **Most booked** — overall top professionals by booking volume
- [x] Backend: `GET /discover/trending`, `GET /discover/new`, `GET /discover/responsive`
- [x] Frontend: Horizontal scroll carousels on `Home.jsx` and `Categories.jsx`

### 6.3 AI-Powered Discovery Feed (Future)

- [ ] **Personalized feed** based on: saved pros, watched reels, location, booking history, category affinity
- [ ] **Recommendation engine** — collaborative filtering + content-based scoring
- [ ] Backend: `GET /discover/for-you` — personalized professional recommendations
- [x] Track: `user_interactions` table (user_id, item_type, item_id, action [view/save/book/watch], created_at)

### 6.4 Search Enhancement — Meilisearch

- [ ] **Integrate Meilisearch** for typo-tolerant, fast autocomplete, relevance-ranked search
- [ ] **Visual search results** — card-based results with photos, ratings, availability
- [ ] **Search suggestions** — "Did you mean?" + trending searches + recent searches
- [ ] Replace current SQL/Haversine search with Meilisearch index
- [ ] `backend/src/services/search.js` — Meilisearch client + index sync

---

## NEW PHASE 7: Trust System Evolution (Priority: HIGH)

> **Goal:** Make trust VISIBLE and gamified, not just system-calculated  
> **Inspiration:** Gaming profiles + LinkedIn credibility + Airbnb Superhost  
> **Impact:** Trust/Safety 8.7/10 → 9.5/10, Retention 5.5/10 → 8/10

### 7.1 Trust Timeline (Professional Profile)

- [x] **Visual trust timeline** showing: join date, milestones, jobs completed, repeat customers, response streaks
- [x] **Milestone badges** — auto-awarded at thresholds (10 jobs, 50 jobs, 100 jobs, first repeat customer, etc.)
- [x] Frontend: `TrustTimeline.jsx` component on storefront
- [x] Backend: `GET /trust/:professionalId/timeline` — ordered milestone events

### 7.2 Trust Badge System (Tiered)

- [x] **Badge tiers** with dynamic animations:
  - 🌱 Rising Pro — verified + 5 jobs
  - ⚡ Fast Responder — avg response < 30min
  - ⭐ Customer Favorite — 4.8+ avg rating (20+ reviews)
  - 🏆 Top Rated — top 10% in category
  - 💎 Elite Professional — 100+ jobs, 4.9+ rating, 50%+ repeat rate
- [x] **Auto-calculation** — badges recalculated weekly via cron job
- [x] Backend: `GET /trust/:professionalId/badges` — current badges with progress
- [x] DB migration: `professional_badges` table (professional_id, badge_type, earned_at, metadata JSONB)
- [x] Frontend: Badge display on `Storefront.jsx` with earned badge indicators

### 7.3 Trust Explainability

- [x] **"Why this pro is trusted"** — modal/section explaining trust score breakdown
- [x] Show: verification status, response speed, completion rate, repeat customer %, review sentiment
- [x] Backend: `GET /trust/:professionalId/explain` — trust signal breakdown
- [x] Frontend: Trust explainer modal integrated in `Storefront.jsx`

---

## NEW PHASE 8: Gamification & Retention (Priority: MEDIUM)

> **Goal:** Create dopamine loops that keep professionals and customers engaged  
> **Impact:** Retention 5.5/10 → 8/10, Engagement loops established

### 8.1 Professional Gamification

- [ ] **Response streaks** — consecutive days responding within target time
- [ ] **Monthly leaderboards** — top professionals per city per category
- [ ] **Milestone unlocks** — unlock features/perks at thresholds
- [ ] **Profile analytics dopamine** — "Your storefront got 47 views this week (+12%)"
- [ ] **AI growth score** — actionable tips ("Upload 3 more portfolio items to rank higher")
- [ ] Backend: `GET /gamification/professional/stats` — streaks, rank, progress
- [ ] Frontend: Professional dashboard widget showing streaks + rank + tips

### 8.2 Customer Gamification

- [ ] **Referral XP** — points for successful referrals
- [ ] **Loyalty points** — earn points per booking, redeem for discounts
- [ ] **Trusted reviewer badges** — earned by writing helpful reviews
- [ ] **Personalized recommendations** — "Based on your history, you might need..."
- [ ] Backend: `GET /gamification/customer/stats` — points, badges, level
- [ ] DB migration: `user_points` table (user_id, points_balance, lifetime_points, level)

### 8.3 CRM & Re-engagement

- [ ] **Repeat customer campaigns** — auto-nudge customers who booked before
- [ ] **Rebooking nudges** — "It's been 3 months since your last AC service"
- [ ] **Birthday greetings** — automated personalized messages
- [ ] **Customer segmentation** — new, active, at-risk, churned
- [ ] **Abandoned booking recovery** — reminder for incomplete bookings
- [ ] Backend: `backend/src/workers/crm.js` — CRM cron jobs for automated campaigns
- [ ] Backend: `GET /crm/customers/segments` — segmented customer lists

---

## NEW PHASE 9: AI Layer (Priority: MEDIUM)

> **Goal:** AI as a business assistant for professionals and an intelligent matchmaker for consumers  
> **Impact:** AI Layer 3.5/10 → 8/10

### 9.1 AI for Professionals

- [ ] **AI storefront builder** — auto-generate bio, service descriptions, packages from minimal input
- [ ] **AI pricing suggestions** — "Professionals in your area charge ₹500–₹800 for this service"
- [ ] **AI business coach** — weekly insights ("Respond faster to get 2x bookings", "Best posting time: 7PM")
- [ ] **AI-generated theme suggestions** — recommend storefront theme based on category
- [ ] Backend: `POST /ai/storefront/generate` — AI-powered storefront content generation
- [ ] Backend: `GET /ai/professional/insights` — personalized growth recommendations
- [ ] Integrate with existing `backend/src/services/ai.js`

### 9.2 AI for Consumers

- [ ] **AI matching** — "Best professional for your exact need" using multi-signal scoring
  - Signals: skills match, location proximity, ratings, availability, price range, response speed
- [ ] **AI requirement wizard** — conversational booking ("What do you need done?")
- [ ] **AI review summaries** — "Customers say: fast, reliable, great quality" auto-summary
- [ ] Backend: Enhance `matchingController.js` with AI-powered scoring
- [ ] Backend: `GET /ai/reviews/summary/:professionalId` — AI-generated review summary

### 9.3 AI Fraud Detection Enhancement

- [ ] Enhance existing fraud middleware with AI anomaly detection
- [ ] Fake review detection using NLP patterns
- [ ] Suspicious booking pattern detection

---

## NEW PHASE 10: Category-Specific UX (Priority: MEDIUM)

> **Goal:** Tailor the experience to 3–5 initial verticals instead of generic one-size-fits-all  
> **Recommendation:** Start with Beauty, Home Services, Fitness, Tutors, Photographers

### 10.1 Category UX Templates

- [ ] **Beauty** — before/after sliders, Instagram-style reels, makeup transformation gallery
- [ ] **Home Services** — project gallery, pricing calculator, certification badges
- [ ] **Fitness** — transformation photos, progress tracking, schedule/availability grid
- [ ] **Tutors** — demo videos, credentials display, subject expertise, class schedule
- [ ] **Photographers** — full-width portfolio grid, event type filtering, package pricing

### 10.2 Category-Specific Trust Signals

- [ ] Beauty: "Certified Makeup Artist", "500+ transformations"
- [ ] Home Services: "Licensed Electrician", "100+ homes serviced"
- [ ] Fitness: "Certified Trainer", "200+ transformations"
- [ ] Tutors: "M.Sc. Mathematics", "95% student pass rate"
- [ ] Backend: `category_trust_signals` config — per-category trust badge definitions

---

## NEW PHASE 11: Architecture Evolution (Priority: LOW — Plan Now, Execute Later)

> **Goal:** Technical improvements to support the product evolution above

### 11.1 Event-Driven Architecture

- [ ] **Domain events** — decouple controllers from side effects (notifications, analytics, CRM)
- [ ] **Event bus** — in-process event emitter → later upgrade to Redis Streams / Kafka
- [ ] `backend/src/events/eventBus.js` — publish/subscribe for domain events
- [ ] Events: `booking.created`, `review.posted`, `storefront.updated`, `badge.earned`, etc.

### 11.2 Media Pipeline

- [ ] **Adaptive image sizing** — auto-generate thumbnails (150px, 400px, 800px) on upload
- [ ] **Video optimization** — transcode uploaded videos to web-friendly formats (HLS/MP4)
- [ ] **CDN pipeline** — CloudFront/Cloudflare CDN for all media assets
- [ ] **Lazy loading** — progressive image loading across all pages
- [ ] `backend/src/services/media.js` — media processing pipeline

### 11.3 BullMQ Upgrade

- [ ] Replace in-memory job queue with BullMQ + Redis
- [ ] Queue types: email, SMS, push, media-processing, AI, CRM, analytics
- [ ] Dashboard: Bull Board for job monitoring

### 11.4 Future Considerations (Not Actionable Yet)

- [ ] Express → NestJS migration (when codebase complexity demands it)
- [ ] Vector search for AI recommendations
- [ ] OpenTelemetry distributed tracing
- [ ] Read replicas (RDS Multi-AZ)
- [ ] K8s overlays (staging/production Kustomize)

---

## NEW PHASE 12: Creator Economy & Professional OS (Priority: LOW — Future Vision)

> **Goal:** Evolve from marketplace to Professional Super App  
> **This phase defines the long-term product direction**

### 12.1 Creator Economy Layer

- [ ] **Subscriptions** — customers subscribe to premium professional content
- [ ] **Live sessions** — video consultations / live Q&A
- [ ] **Digital products** — professionals sell guides, templates, courses
- [ ] **Courses** — structured learning content from professionals

### 12.2 Professional Operating System

- [ ] **Invoicing** — generate and send professional invoices
- [ ] **Team management** — professionals with employees/assistants
- [ ] **Business banking** — integrated financial services
- [ ] **Payroll** — for professional teams
- [ ] **SaaS tools** — CRM, scheduling, analytics as standalone tools

---

## Mobile UX Guidelines (For All Phases)

> **Critical:** Avoid "enterprise feel" — must feel like a consumer-grade premium app (Airbnb/Instagram level)

### UX Principles

1. **Bottom-sheet-first UX** — avoid full-page navigations; use bottom sheets for actions
2. **Conversational over forms** — guided flows instead of raw input forms
3. **Visual-first** — images/videos before text in all discovery flows
4. **Human language** — no technical jargon in user-facing strings
5. **Premium spacing** — generous whitespace, no cramped layouts
6. **Micro-animations** — subtle transitions, loading states, success celebrations

### Screen Consolidation Strategy

- Current 22+ screens — audit for consolidation opportunities
- Merge related screens into tabbed/segmented views
- Prioritize: Home → Discovery → Storefront → Bookings → Profile (5 core flows)

---

## Design Inspiration Reference

| Platform | Adopt | Avoid |
|----------|-------|-------|
| **Airbnb** | Emotional photography, trust layout, review UX, premium spacing | Heavy travel-specific flows |
| **Instagram** | Reels, stories, highlights, swipe UX, creator engagement | Algorithmic addiction patterns |
| **LinkedIn** | Credibility structure, achievements, recommendations | Corporate/enterprise feel |
| **Shopify** | Ownership psychology, storefront customization, branded pages | B2B complexity |
| **Urban Company** | Booking trust, operational flows, standardization | Operationally heavy UX |
| **Pinterest** | Inspiration discovery, save boards, visual browsing | Passive browsing (need action) |
| **Calendly** | Ultra-simple scheduling UX | Over-simplification |

---

## Database Schema Additions (Planned)

```sql
-- Phase 4: Storefront
CREATE TABLE storefront_media (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), storefront_id UUID NOT NULL REFERENCES storefronts(id) ON DELETE CASCADE, type VARCHAR(20), media_url TEXT, thumbnail_url TEXT, caption TEXT, sort_order INT, created_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE storefront_themes (storefront_id UUID PRIMARY KEY REFERENCES storefronts(id) ON DELETE CASCADE, theme_name VARCHAR(50), primary_color VARCHAR(7), accent_color VARCHAR(7), layout VARCHAR(20), section_order JSONB, custom_intro TEXT);

-- Phase 5: Social
CREATE TABLE follows (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, created_at TIMESTAMPTZ DEFAULT NOW(), UNIQUE(follower_id, following_id));
CREATE TABLE collections (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, name VARCHAR(100), is_public BOOLEAN DEFAULT false, created_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE collection_items (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE, item_type VARCHAR(20), item_id UUID, added_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE stories (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, media_url TEXT, text_overlay TEXT, cta_url TEXT, expires_at TIMESTAMPTZ, created_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE community_posts (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, title VARCHAR(200), content TEXT, category VARCHAR(50), media_urls JSONB, likes_count INT DEFAULT 0, created_at TIMESTAMPTZ DEFAULT NOW());

-- Phase 7: Trust & Gamification
CREATE TABLE professional_badges (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, badge_type VARCHAR(50), earned_at TIMESTAMPTZ DEFAULT NOW(), metadata JSONB, UNIQUE(professional_id, badge_type));
CREATE TABLE user_points (user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE, points_balance INT DEFAULT 0, lifetime_points INT DEFAULT 0, level INT DEFAULT 1);

-- Phase 6: Discovery
CREATE TABLE user_interactions (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, item_type VARCHAR(20), item_id UUID, action VARCHAR(20), created_at TIMESTAMPTZ DEFAULT NOW());
CREATE INDEX idx_user_interactions_user_created ON user_interactions(user_id, created_at DESC);
CREATE INDEX idx_stories_expires ON stories(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_follows_following ON follows(following_id);
```

---

## Recommended Execution Order

| Priority | Phase | Effort | Impact |
|----------|-------|--------|--------|
| 🔴 CRITICAL | Phase 4: Storefront Revolution | Large | Transforms core product identity |
| 🟠 HIGH | Phase 5: Social & Engagement | Large | Drives retention + virality |
| 🟠 HIGH | Phase 6: Discovery Revolution | Medium | Drives acquisition + engagement |
| 🟠 HIGH | Phase 7: Trust Evolution | Medium | Differentiator + conversion |
| 🟡 MEDIUM | Phase 8: Gamification & Retention | Medium | Retention loops |
| 🟡 MEDIUM | Phase 9: AI Layer | Medium | Business value + UX |
| 🟡 MEDIUM | Phase 10: Category UX | Small | Vertical depth |
| 🔵 LOW | Phase 11: Architecture | Ongoing | Technical foundation |
| 🔵 LOW | Phase 12: Creator Economy | Future | Long-term vision |

---

## Strategic Positioning

**DO NOT market as:** ❌ "Service booking app"

**Market as:**
- ✅ "Build your professional business online"
- ✅ "Your mobile business storefront"
- ✅ "The digital identity platform for professionals"

**Winning formula:** TRUST + STOREFRONTS + SOCIAL DISCOVERY + AI BUSINESS TOOLS

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
cd backend && npm test         # jest (npx jest --forceExit --detectOpenHandles)

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
│   ├── pages/              # 57 page components
│   │   ├── Storefront.jsx  # ⭐ Storefront with hero, media, trust badges
│   │   ├── StorefrontSetup.jsx  # Theme, services, packages editor
│   │   ├── Home.jsx        # ⭐ Discovery with geo, stories, trending
│   │   ├── ProfessionalOnboarding.jsx  # 6-step onboarding wizard
│   │   └── ...
│   ├── components/         # 23 shared UI components (with PropTypes)
│   ├── context/            # AuthContext (RBAC), WebSocketContext
│   └── api/client.js       # API client (30s timeout, 2 retries)
├── backend/src/
│   ├── routes/             # 39 route files (auth, rate-limited)
│   ├── controllers/        # 38 controllers (100+ endpoints)
│   │   ├── storefrontController.js  # Media, themes, packages
│   │   ├── searchController.js      # Service-level search
│   │   ├── trustController.js       # Badges, timeline, explain
│   │   └── ...
│   ├── middleware/          # 7 middleware (auth, fraud, cache, validate)
│   ├── services/            # 9 services (email, SMS, push, AI, storage)
│   │   ├── ai.js            # OpenAI/Gemini with cache
│   │   └── ...
│   ├── utils/retry.js       # Exponential backoff utility
│   ├── realtime/hub.js      # WebSocket server
│   ├── config/              # DB, logger, metrics, sentry
│   └── workers/cron.js      # 15 cron jobs (incl. subscription scheduler, CRM sync)
├── mobile/skillconnect/lib/
│   ├── screens/             # 49 screens across 4 roles
│   │   └── storefront/      # Storefront viewer + setup
│   ├── services/            # 19 services (API, auth, booking, offline)
│   ├── models/models.dart   # ⚠️ Monolithic — needs splitting
│   └── l10n/                # i18n (EN/HI/TE — 53 keys each)
├── database/
│   ├── schema.sql           # Base 8 tables
│   ├── seed.sql             # Demo data (not idempotent)
│   └── migrations/          # 19 migrations (001-019 + 006b/007b)
├── k8s/base/                # Kubernetes manifests (StatefulSet, Deploy, Ingress)
├── monitoring/              # Prometheus + Grafana + alerts
├── .github/workflows/ci.yml # 7-stage CI/CD pipeline
└── docker-compose.yml       # One-command local setup
```

---

## Session Notes for Next Agent

1. **Auth & Payments are separate tracks** — don't touch unless specifically asked
2. **16 backend test files exist** — always run `cd backend && npx jest --forceExit --detectOpenHandles` after changes
3. **Frontend uses Vite** — fast HMR, build with `cd frontend && npm run build`
4. **Mobile is Flutter** — analyze with `flutter analyze`, test with `flutter test`
5. **Docker Compose works** — use it for integration testing
6. **Express 5** — uses promise-based error handling
7. **PostgreSQL 16** — uses `gen_random_uuid()`, no separate uuid extension needed
8. **WebSocket via `ws` library** — not Socket.IO; simpler but no auto-reconnect
9. **Consumer-grade UX** — must feel like Airbnb/Instagram, NOT enterprise admin software
10. **India-first** — WhatsApp integration; now 9 Indian languages (EN/HI/TE/TA/KN/MR/BN/GU/PA)
11. **Start with 3–5 verticals** — Beauty, Home Services, Fitness, Tutors, Photographers
12. **22/38 controllers untested** — focus on payment, admin, upload, professional, trust
13. **Deep Audit v2 found 79 new issues** — See Sprint 5-7 for prioritized fix plan
14. **Global Ecosystem implemented** — 3-engine architecture (Booking/Subscription/Marketplace), multi-tenant country system, family/household accounts, provider business OS (inventory + CRM), 9 country tenants seeded, subscription auto-scheduler cron, admin country management page
15. **Sprint 10 COMPLETE** — COD+EMI payments, demand prediction (migration 024 + demandController + cron), Society/B2B module (migration 025 + societyController + SocietyDashboard.jsx), 9-language i18n (129 keys each)
16. **Sprint 11 COMPLETE** — P3.4 Map view (Leaflet/OpenStreetMap in SearchResults), P2.3 Company KYC frontend (CompanyKYC.jsx 4-step wizard), Phase 8 Gamification (migration 028, gamificationController, /api/gamification routes, Dashboard stats widget, awardPoints wired into booking + referral), P5 Mobile (6 new model files: story/follow/user_points/badge/community_post/featured_slot; 6 new services: warranty/dispute/collection/points/community/referral; 3 new screens: Followers/Stories/Loyalty; router wired)
17. **Payment methods** — now supports: card, upi, netbanking, wallet, cod (cash-on-delivery), emi (Razorpay EMI ≥₹3000). COD confirm via POST /payments/:id/cod-confirm
18. **Cron jobs** — now 17 total (was 15). New: aggregateDemandSignals (daily 02:00 UTC)
19. **Migrations** — now 028 (latest: 028_gamification.sql)

---

## GLOBAL TRUSTED SERVICES ECOSYSTEM — Implementation Status

### ✅ Implemented (Migration 018 + 019)

| Component | Status | Key Files |
|-----------|--------|-----------|
| **3-Engine Architecture** | ✅ Complete | Home.jsx engine cards, categories.js engine metadata |
| **Subscription Engine** | ✅ Complete | subscriptionController.js (CRUD, pause/resume/cancel), Subscriptions.jsx, cron auto-scheduler |
| **Marketplace Engine** | ✅ Complete | marketplaceController.js (proposals, quotes, FSM), Marketplace.jsx |
| **Multi-Tenant Countries** | ✅ Complete | countryController.js (CRUD, config), AdminCountries.jsx, 9 countries seeded |
| **Family/Household System** | ✅ Complete | householdController.js (CRUD, members), FamilyAccount.jsx |
| **Provider Business OS** | ✅ Complete | providerBusinessController.js (inventory + CRM), Provider CRM sync cron |
| **Navigation Updates** | ✅ Complete | Navbar (6 links incl. Societies), BottomNav (Subscribe), Dashboard quick actions |
| **Home Services Expansion** | ✅ Complete | Migration 023, quoteController, homeProfileController, trackingController, amcController, whatsapp.js |
| **Vernacular Languages (9)** | ✅ Complete | EN/HI/TE/TA/KN/MR/BN/GU/PA — 129 keys, ARB + generated Dart + settings screen |
| **COD Payment** | ✅ Complete | paymentController (cod method + cod-confirm endpoint), payments route |
| **EMI via Razorpay** | ✅ Complete | razorpay.js createEMIOrder(), paymentController emi method, EMI_DURATIONS exported |
| **Provider Demand Prediction** | ✅ Complete | Migration 024, demandController (forecast/area/peak-hours/log), /api/demand routes, cron aggregateDemandSignals |
| **Society/B2B Module** | ✅ Complete | Migration 025, societyController (full CRUD + bidding + B2B enquiries), /api/societies routes, SocietyDashboard.jsx |

### 🔲 Not Yet Implemented (Future Phases)

- **Aadhaar KYC** (real HyperVerge/Digilocker integration — currently mock)
- **AI modules** (voice booking, recommendations, pricing suggestions, fraud detection)
- **WhatsApp integration** (booking reminders, re-engagement)
- **Map view** for discovery
- **Video-first trust** (provider intro videos as primary trust signal)
- **Country partner dashboard** (dedicated dashboard for franchise operators)
- **Subscription billing** (Razorpay recurring payments integration)
- **Emergency services** (controlled rollout after operational stability)
- **Meilisearch** (typo-tolerant search replacing SQL)
- **Category-specific UX** (Beauty vs Home Services vs Fitness)
- **Mobile screens** (7 missing: Collections, Community, Followers, Stories, Points, Referral, Admin)

---

*Priority order: Sprint 5 (Security Fixes) → Sprint 6 (Performance & Quality) → Sprint 7 (Infrastructure) → Global Ecosystem Phases → Phase 8-12 (iterate)*
