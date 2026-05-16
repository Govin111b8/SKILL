# SkillConnect — Master Implementation Plan (claude.md)

> **Purpose:** Comprehensive guide for Copilot/Claude sessions to evolve SkillConnect from a functional marketplace into a **Professional Identity + Business Operating System**  
> **Last Updated:** 2026-05-16  
> **Context:** Core features COMPLETE. Auth & Payments handled separately. Focus now shifts to UX, identity, social, and AI layers.  
> **Vision:** "Build your professional business online" — NOT just a service booking app.

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

---

## Platform Scorecard

| Area | Score | Status | Target |
|------|-------|--------|--------|
| Backend Engineering | 9.2/10 | ✅ Very strong | Maintain |
| Security | 9.0/10 | ✅ Production-grade | Maintain |
| Marketplace Logic | 9.0/10 | ✅ Mature | Maintain |
| Ecosystem Potential | 9.5/10 | ✅ Huge potential | Unlock |
| Mobile Architecture | 8.8/10 | ✅ Good foundations | Enhance |
| Trust/Safety | 8.7/10 | ✅ Strong | Evolve to visible UX |
| Scalability Planning | 8.5/10 | ✅ Good early decisions | Maintain |
| UX Philosophy | 6.8/10 | ⚠️ Biggest weakness | → 9.0 |
| Emotional Product Design | 5.5/10 | ⚠️ Missing | → 8.5 |
| Retention Systems | 5.5/10 | ⚠️ Weak | → 8.0 |
| Consumer Delight | 5.0/10 | ⚠️ Functional not addictive | → 8.5 |
| Storefront Experience | 5.0/10 | 🔴 Underdeveloped | → 9.0 |
| Professional Branding | 4.5/10 | 🔴 Weak | → 8.5 |
| Social/Engagement Layer | 4.0/10 | 🔴 Missing | → 8.0 |
| AI Layer | 3.5/10 | 🔴 Very early | → 8.0 |
| Virality | 3.0/10 | 🔴 Weak | → 7.5 |

### Core Problem Statement

The platform is **feature-complete** but NOT **emotionally premium**. It feels like an "enterprise listing system" instead of a "personal business app." The storefront behaves like a marketplace profile page — it should feel like a **mini personal business app** that professionals feel ownership over.

### Future Moat (NOT replicable)

The long-term competitive advantage is the **Professional Graph + Trust Graph**: identity, customer history, repeat interactions, reviews, content, business reputation, AI insights, storefront reputation, engagement history. This becomes impossible for competitors to copy.

---

## Current State (What's Built)

- **Frontend:** 50+ pages, React 19, Vite, responsive, WebSocket chat, 40+ components — `frontend/src/pages/`
- **Backend:** 100+ endpoints, Express 5, 37 controllers, 38 route files, 16 test suites (150 tests), fraud middleware — `backend/src/`
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
│   ├── pages/              # 35+ page components
│   │   ├── Storefront.jsx  # ⭐ KEY: Needs Phase 4 upgrade
│   │   ├── StorefrontSetup.jsx
│   │   ├── Home.jsx        # ⭐ KEY: Needs discovery sections
│   │   └── ...
│   ├── components/         # 35 shared UI components
│   ├── context/            # AuthContext, WebSocketContext
│   └── api/client.js       # API client
├── backend/src/
│   ├── routes/             # 31 route files
│   ├── controllers/        # 30 controllers
│   │   ├── storefrontController.js  # ⭐ KEY: Needs expansion
│   │   ├── matchingController.js    # ⭐ KEY: Needs AI upgrade
│   │   └── ...
│   ├── middleware/          # 7 middleware files
│   ├── services/            # 9 external integrations
│   │   ├── ai.js            # ⭐ KEY: Needs expansion
│   │   └── ...
│   ├── realtime/hub.js      # WebSocket server
│   ├── config/              # DB, logger, metrics, sentry
│   └── workers/             # Cron jobs
├── mobile/skillconnect/lib/
│   ├── screens/             # 22+ screen directories
│   │   └── storefront/      # ⭐ KEY: Needs Phase 4 upgrade
│   ├── services/            # API, auth, booking
│   └── l10n/                # i18n (EN/HI/TE)
├── database/
│   ├── schema.sql           # Current schema
│   ├── seed.sql             # Demo data
│   └── migrations/          # DB migrations
├── k8s/                     # Kubernetes manifests
├── monitoring/              # Prometheus + Grafana
└── docker-compose.yml       # One-command setup
```

---

## Session Notes for Next Agent

1. **Auth & Payments are separate tracks** — don't touch unless specifically asked
2. **11 backend test files exist** — always run `npm test` after changes
3. **Frontend uses Vite** — fast HMR, build with `npm run build`
4. **Mobile is Flutter** — analyze with `flutter analyze`, test with `flutter test`
5. **Docker Compose works** — use it for integration testing
6. **Express 5** — uses promise-based error handling
7. **PostgreSQL 16** — uses `gen_random_uuid()`, no separate uuid extension needed
8. **WebSocket via `ws` library** — not Socket.IO; simpler but no auto-reconnect
9. **Storefront is the #1 priority** — Phase 4 is the single biggest improvement area
10. **Consumer-grade UX** — must feel like Airbnb/Instagram, NOT enterprise admin software
11. **India-first** — WhatsApp integration, Hindi/Telugu i18n already in place
12. **Start with 3–5 verticals** — Beauty, Home Services, Fitness, Tutors, Photographers

---

*Priority order: Phase 4 (Storefront) → Phase 5 (Social) → Phase 6 (Discovery) → Phase 7 (Trust) → Phase 8–12 (iterate)*
