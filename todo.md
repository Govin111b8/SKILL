# SkillConnect — TODO & Future Reference

> **Last Updated:** 2026-05-29  
> **Purpose:** Comprehensive tracking of all known gaps, bugs, tech-debt, and planned features for future development sessions.  
> **Overall Production Readiness:** ~8.5/10

---

## 🐛 KNOWN BUGS (Fix ASAP)

### Backend

| # | Bug | File | Status |
|---|-----|------|--------|
| B1 | **`getPaymentHistory` count query sends wrong params** — `params.slice(0, idx - 3)` excludes too many/few params from the count query when 1 or 2 filters (from/to/status) are active, causing PostgreSQL `$N not bound` errors | `backend/src/controllers/sprint11Controller.js:152` | ✅ Fixed |
| B2 | **`getLoyaltyHistory` unvalidated pagination** — `page` and `limit` from `req.query` are strings; `offset = (page - 1) * limit` relies on JS coercion; passing `"abc"` produces `NaN` which breaks Postgres | `backend/src/controllers/referralController.js:174-175` | ✅ Fixed |
| B3 | **`updateRecurring` allows any `status` value** — no validation against allowed status enum values; arbitrary strings can be written to DB | `backend/src/controllers/recurringBookingController.js:95` | ⬜ Open |
| B4 | **`deleteAddress` no 404 response** — silently succeeds even if the address doesn't exist or doesn't belong to the user | `backend/src/controllers/sprint11Controller.js:372-378` | ⬜ Open |
| B5 | **`deleteQuickReply` no 404 response** — same issue as B4 | `backend/src/controllers/sprint11Controller.js:240-245` | ⬜ Open |
| B6 | **`compareProfessionals` no UUID validation** — `ids.split(',')` are passed directly as `::uuid[]`; non-UUID strings cause Postgres cast errors | `backend/src/controllers/sprint11Controller.js:88-108` | ⬜ Open |
| B7 | **`createRecurring` `nextDate` not adjusted for frequency** — always sets `next_booking_date = start_date` regardless of `frequency` (weekly should advance to next matching day_of_week) | `backend/src/controllers/recurringBookingController.js:34` | ⬜ Open |
| B8 | **Cron empty catches swallow errors** — two `.catch(() => {})` in cron job loops hide failures from production alerts | `backend/src/workers/cron.js:622,654` | ⬜ Open |
| B9 | **`Home.jsx` promotional banners and quick-rebook fetch swallow all errors** — no logging means silent failures in production | `frontend/src/pages/Home.jsx:167,170,171` | ✅ Fixed |
| B10 | **`CategoryDetail.jsx` service enrichment fully silent** — no log on failure | `frontend/src/pages/CategoryDetail.jsx:86` | ⬜ Open |
| B11 | **`AgentDashboard.jsx` catch block discards errors** — empty `catch (_) {}` | `frontend/src/pages/AgentDashboard.jsx:34` | ⬜ Open |

---

## 🔴 P0 — CRITICAL (Production Blockers)

| # | Issue | Area | File |
|---|-------|------|------|
| C1 | **Aadhaar KYC not connected** — `aadhaar.js` HyperVerge integration exists but credentials are placeholders; eKYC OTP flow is mocked | Backend | `backend/src/services/aadhaar.js` |
| C2 | **Razorpay credentials not filled** — recurring subscriptions and webhook signature verification will fail in production | Backend | `.env.example` |
| C3 | **SendGrid / MSG91 / FCM credentials** — email, SMS, and push notifications need real keys before go-live | Backend | `.env.example` |
| C4 | **S3 bucket not configured** — file uploads fall back to local disk, incompatible with multi-pod K8s | Backend | `backend/src/services/storage.js` |
| C5 | **SSL/TLS not configured on Nginx** — currently serves HTTP only; needs Let's Encrypt cert provisioning | DevOps | `nginx/` |
| C6 | **In-memory fraud prevention breaks under load balancing** — `fraudPrevention.js` Map is per-process; migrate to Redis | Backend | `backend/src/middleware/fraudPrevention.js` |
| C7 | **AI cache unbounded LRU gap** — 10 k entry FIFO cap; should use proper LRU eviction | Backend | `backend/src/services/ai.js:52-56` |

---

## 🟠 P1 — HIGH PRIORITY

### Backend

| # | Issue | File |
|---|-------|------|
| H1 | **No recurring booking cron job** — `recurring_bookings` table is populated but no cron spawns actual bookings from them | `backend/src/workers/cron.js` |
| H2 | **Review edit 24h window not enforced** — columns `edit_deadline` exist in migration 012 but no business logic | `backend/src/controllers/reviewController.js` |
| H3 | **Review burst detection missing** — >5 reviews in 24 h for same professional should hold for moderation | `backend/src/controllers/reviewController.js` |
| H4 | **Two-way review (pro rates customer) UI incomplete** — DB schema exists, no frontend flow | `frontend/src/pages/Bookings.jsx` |
| H5 | **Profile completeness nudge missing** — <60% complete banner specified in PRD, not implemented | `frontend/src/pages/Dashboard.jsx` |
| H6 | **Subscription grace period not enforced** — 3-day grace period after expiry specified in PRD | `backend/src/controllers/subscriptionController.js` |
| H7 | **Portfolio limits not enforced at API level** — 20 image / 5 video cap defined in PRD, not in code | `backend/src/controllers/portfolioController.js` |
| H8 | **`discoverController` limit unbounded** — `req.query.limit` parsed without max cap; DoS risk | `backend/src/controllers/discoverController.js` |
| H9 | **NLP / hate-speech filter on reviews missing** — referenced in PRD, not implemented | `backend/src/controllers/reviewController.js` |
| H10 | **Company KYC extension (P2.3) incomplete** — GST/CIN/Udyam/PAN wizard exists (`CompanyKYC.jsx`) but backend document verification is not wired to approval flow | `backend/src/controllers/kycController.js`, `frontend/src/pages/CompanyKYC.jsx` |

### Frontend

| # | Issue | File |
|---|-------|------|
| H11 | **Map view (P3.4) not built** — Leaflet/OpenStreetMap toggle referenced in plan but never implemented | `frontend/src/pages/SearchResults.jsx` |
| H12 | **No booking rescheduling UI** — backend `reschedule` endpoint exists but no frontend button/modal | `frontend/src/pages/BookingDetail.jsx` |
| H13 | **No professional comparison UI** — `CompareProf.jsx` page exists but compare button on `ProfessionalCard` is absent | `frontend/src/components/ProfessionalCard.jsx` |
| H14 | **No confirmation dialog on destructive actions** — delete review, cancel booking, remove portfolio item all lack confirm steps | Multiple pages |
| H15 | **Platform fee (5%) hardcoded in frontend** — should come from server config endpoint | `frontend/src/pages/Payment.jsx:76` |

---

## 🟡 P2 — MEDIUM PRIORITY

### Backend

| # | Issue | File |
|---|-------|------|
| M1 | **No E2E test suite** — only unit tests; no Playwright/Supertest integration tests in CI | `.github/workflows/ci.yml` |
| M2 | **22/53 controllers have no backend tests** — untested: `recurringBookingController`, `sprint11Controller`, `couponController`, `countryController`, `householdController`, `providerBusinessController`, `demandController`, `societyController`, `amcController`, `quoteController`, `trackingController`, `homeProfileController` | `backend/tests/` |
| M3 | **Inconsistent response format** — mix of `{success,data}` and plain objects across controllers | Multiple controllers |
| M4 | **Admin flag queried on every request** — consider caching admin status in JWT claims | `backend/src/middleware/auth.js` |
| M5 | **No request size limit for multipart/form-data** — only JSON is capped at 1 mb | `backend/src/app.js:117` |
| M6 | **No rollback/DOWN migrations** — can't safely rollback schema changes | `database/migrations/` |
| M7 | **Staging/production deployment pipeline placeholder** — CI has placeholder steps | `.github/workflows/ci.yml:312-375` |
| M8 | **Database single replica** — no HA/read-replica setup for production | `k8s/base/statefulsets.yaml` |
| M9 | **Meilisearch fallback** — `meilisearch.js` service exists but search controller doesn't use it as fallback when Postgres FTS is slow | `backend/src/services/meilisearch.js` |

### Frontend

| # | Issue | File |
|---|-------|------|
| M10 | **No dark mode** — 40+ pages have no dark theme CSS | Frontend CSS files |
| M11 | **No breadcrumb navigation** on detail pages | Multiple pages |
| M12 | **No Web Vitals tracking** | `frontend/src/main.jsx` |
| M13 | **`console.log` statements in production code** — 84 occurrences across pages | Multiple pages |
| M14 | **`Login.jsx` has hardcoded demo credentials** — security exposure | `frontend/src/pages/Login.jsx:14-19` |
| M15 | **No recurring booking management UI** — backend routes exist at `/api/recurring-bookings` | Missing page |
| M16 | **No saved searches UI** — backend at `/api/saved-searches`, `SavedSearches.jsx` page exists but no link from SearchResults | `frontend/src/pages/SearchResults.jsx` |
| M17 | **No coupon entry in payment flow** — backend coupon validation endpoint exists, not wired to UI | `frontend/src/pages/Payment.jsx` |
| M18 | **No address book UI** — backend at `/api/addresses`, no frontend page | Missing page |
| M19 | **No professional goals UI** — backend at `/api/goals`, no frontend page | Missing page |
| M20 | **No quick-reply templates UI in Chat** — backend at `/api/quick-replies`, not wired to Chat.jsx | `frontend/src/pages/Chat.jsx` |

### Mobile (Flutter)

| # | Issue | File |
|---|-------|------|
| M21 | **Recurring booking screen missing** | `mobile/skillconnect/lib/screens/` |
| M22 | **Booking reschedule screen missing** | `mobile/skillconnect/lib/screens/` |
| M23 | **Coupon entry missing in mobile payment flow** | `mobile/skillconnect/lib/screens/` |
| M24 | **Address book screen missing** | `mobile/skillconnect/lib/screens/` |
| M25 | **i18n incomplete** — many UI strings not translated in 9 supported languages | `mobile/skillconnect/assets/l10n/` |
| M26 | **No retry interceptor in `api_service.dart`** — single failure drops requests | `mobile/skillconnect/lib/services/api_service.dart` |

---

## 🔵 P3 — LOW PRIORITY (Tech Debt)

| # | Issue | File |
|---|-------|------|
| T1 | **No Swagger/OpenAPI docs for sprint11 routes** — 15 controllers have JSDoc; sprint11, recurring, coupon routes are missing | `backend/src/routes/sprint11.js` |
| T2 | **`1800-XXX-XXXX` placeholder phone in WhatsApp message** | `backend/src/services/whatsapp.js:161` |
| T3 | **Docker Compose uses hardcoded credentials** — should fully use `.env` file | `docker-compose.yml` |
| T4 | **K8s storage class hardcoded to AWS** — not portable to GKE/AKS | `k8s/base/statefulsets.yaml` |
| T5 | **No request body size limit for multipart uploads beyond multer** | `backend/src/controllers/uploadController.js` |
| T6 | **Reputation score uses 0-5 scale** — PRD specifies 0-100 Trust Index; formula needs to be rescaled | `database/migrations/005_*.sql` |
| T7 | **`schema.sql` out of sync** — only 8 tables; 74+ production tables only in migrations; no single source of truth | `database/schema.sql` |
| T8 | **AI cache not persisted across restarts** — in-memory only; warm-up latency on cold start | `backend/src/services/ai.js` |
| T9 | **`external-secrets.yaml` K8s manifest needs real secret store backend** — currently a placeholder | `k8s/base/external-secret.yaml` |
| T10 | **No automated DB backup strategy** | DevOps |

---

## 🚀 FUTURE FEATURES (Planned but Not Started)

### High Impact

| # | Feature | Notes |
|---|---------|-------|
| F1 | **Booking reschedule flow (full)** — UI + notifications + history display | Backend done (`recurringBookingController.js:reschedule`) |
| F2 | **Recurring bookings full lifecycle** — cron to auto-generate bookings + management UI | Backend model done |
| F3 | **Coupon/promo code entry in checkout** | Backend done (`couponController.js`) |
| F4 | **Professional comparison side-by-side modal** | Backend done (`sprint11Controller.js:compareProfessionals`) |
| F5 | **Address book (saved addresses)** | Backend done (`sprint11Controller.js:getAddresses`) |
| F6 | **Professional goals tracker** | Backend done (`sprint11Controller.js:getGoals`) |
| F7 | **Quick reply templates in Chat** | Backend done (`sprint11Controller.js:getQuickReplies`) |
| F8 | **Map view in SearchResults** | Leaflet + OpenStreetMap; toggle with list/grid |
| F9 | **Saved searches with email alerts** | Backend done (`sprint11Controller.js:listSavedSearches`) |
| F10 | **Promotional banner system** | Backend done; needs frontend banner component on Home |
| F11 | **Payment history page** | Backend done; `PaymentHistory.jsx` page exists |

### Medium Impact

| # | Feature | Notes |
|---|---------|-------|
| F12 | **Company team member management** — add/remove team members to company profile | DB + backend + UI |
| F13 | **Real-time demand heatmap** — aggregate demand signals cron runs; frontend heatmap needed | Backend done |
| F14 | **AI-powered professional matching** — matching controller exists but uses rule-based scoring | Needs ML model |
| F15 | **Multi-city expansion** — country/city/currency config via `countryController` | Backend done |
| F16 | **Agent commission wallet top-up** — agent wallet logic partial | `agentController.js` |
| F17 | **Review response from professional** — professional can reply to reviews | Schema may need column |
| F18 | **Provider availability calendar (customer view)** — customer sees pro's calendar before booking | |
| F19 | **Professional leaderboard (web)** — `ProviderLeaderboard.jsx` exists; needs real data endpoint | |
| F20 | **City+Service SEO landing pages** — `CityServiceLanding.jsx` exists; needs sitemap automation | |

### Low Impact / Polish

| # | Feature | Notes |
|---|---------|-------|
| F21 | **Dark mode** | CSS custom properties already partially set up |
| F22 | **Web Vitals tracking** | Add `web-vitals` library call in `main.jsx` |
| F23 | **Breadcrumb navigation** | Add to detail pages (Storefront, BookingDetail, CategoryDetail) |
| F24 | **Notification preferences page** | Channels: email/SMS/push per event type |
| F25 | **Admin audit log page** | Route `/admin/audit-log` exists in plan; page missing |
| F26 | **Admin categories management page** | Route `/admin/categories` referenced in plan |
| F27 | **Admin complaints management page** | Route `/admin/complaints` referenced |
| F28 | **Revenue analytics charts** | Add Recharts/Chart.js to Dashboard for pros |

---

## 🏗️ INFRASTRUCTURE TODO

| # | Task | Priority |
|---|------|----------|
| I1 | Provision Kubernetes cluster (EKS/GKE) | 🔴 Before launch |
| I2 | Provision SSL cert via cert-manager + Let's Encrypt | 🔴 Before launch |
| I3 | Fill production secrets in K8s ExternalSecrets / Vault | 🔴 Before launch |
| I4 | Configure S3 bucket + CloudFront CDN for uploads | 🔴 Before launch |
| I5 | Set up PostgreSQL HA (primary + standby replica) | 🟠 Before launch |
| I6 | Configure Redis cluster mode for fraud prevention | 🟠 Before launch |
| I7 | Set up automated DB backups (pg_dump → S3 daily) | 🟠 Before launch |
| I8 | Configure Alertmanager Slack + PagerDuty webhooks | 🟡 Pre-launch |
| I9 | Add k6 load test run to CI pipeline | 🟡 Pre-launch |
| I10 | Add E2E tests (Playwright) to CI pipeline | 🟡 Pre-launch |
| I11 | Set up staging K8s overlay (separate namespace) | 🟡 Pre-launch |
| I12 | Configure CloudWatch/Datadog for cost and error alerting | 🔵 Post-launch |
| I13 | Set up CDN cache-busting for frontend assets | 🔵 Post-launch |

---

## ✅ COMPLETED (For Reference)

### Sprints 1–13 (Major Milestones)

- ✅ **Auth system** — 4 roles, RBAC, JWT refresh, role-specific login/register
- ✅ **Service catalog** — `professional_services` table, CRUD API, management UI, storefront display, booking integration
- ✅ **Provider onboarding wizard** — 6-step `ProfessionalOnboarding.jsx`
- ✅ **Customer discovery** — geolocation, search, service-level browsing, quick filters, recently viewed
- ✅ **Booking flow** — multi-step wizard, slot selection, service selection, payment, COD, EMI
- ✅ **Professional dashboard** — stats, bookings, quick actions, customer insights, calendar view
- ✅ **Storefront** — themes, packages, media, trust badges, company sections
- ✅ **Social layer** — follow, collections, stories, community posts, reels
- ✅ **Trust system** — badge tiers (Bronze→Platinum), neighborhood trust, explainability modal
- ✅ **Quote/bid flow** — 3-bid home services quote system
- ✅ **Recurring bookings** — backend model + routes
- ✅ **Booking reschedule** — backend endpoint + history log
- ✅ **AMC plans** — annual maintenance contract subscriptions (Razorpay recurring)
- ✅ **Society/B2B module** — society dashboard, 14 endpoints
- ✅ **Gamification** — points, badges, leaderboard, award triggers
- ✅ **Demand prediction** — daily signal aggregation cron
- ✅ **Coupons** — full CRUD, per-user limit, validation
- ✅ **Referral system** — dedup check, reward on first booking completion
- ✅ **WhatsApp notifications** — Meta Cloud API / MSG91
- ✅ **9-language i18n** — EN/HI/TE + 6 Indian languages
- ✅ **Composite DB indexes** — migration 020
- ✅ **XSS sanitization middleware** — strips HTML from all body fields
- ✅ **Security fixes** — SQL injection parameterized, path traversal whitelist, password strength, NaN pagination
- ✅ **CSRF protection** — cookie-based double-submit
- ✅ **Redis WebSocket pub/sub** — hub.js multi-instance support
- ✅ **GDPR anonymization** — user data anonymization + cron
- ✅ **Prometheus + Grafana** — 14 alert rules, 4 scrape targets, Alertmanager config
- ✅ **K8s manifests** — HPA, PodDisruptionBudgets, NetworkPolicy, Ingress
- ✅ **k6 load tests** — scripts in `tests/load/`
- ✅ **Backend test coverage** — 16 suites, 150+ tests across core controllers
- ✅ **Swagger JSDoc** — on 15 route files
- ✅ **Mobile Sprint 13** — NeighbourhoodTrustScreen, QuoteBidManagementScreen, AmcVisitsScreen, SocietyScreen, AdminDashboard (revenue chart + WebSocket), ProviderAnalytics (demand heatmap + benchmarking)
- ✅ **SEO pages** — CityServiceLanding + sitemap automation + ProviderLeaderboard
- ✅ **Pro portal route** — `/pro/:slug` + `/leaderboard` + `/services/:city/:service`
- ✅ **Mobile design system** — design tokens, component library, page transitions, onboarding intro

---

## 📊 CURRENT SCORECARD

| Area | Score | Key Gap |
|------|-------|---------|
| Auth & Roles | 9/10 | Company doc verification |
| Backend API | 9/10 | Missing tests for 22 controllers |
| Service Catalog | 9/10 | Minor: category seed data |
| Provider Onboarding | 8/10 | Company KYC backend wiring |
| Customer Discovery | 8/10 | Map view |
| Booking Flow | 8/10 | No reschedule UI, no coupon UI |
| Professional Dashboard | 8/10 | Revenue analytics charts |
| Storefront | 8/10 | Team member management |
| Social Features | 8/10 | Minor: collection sharing |
| Trust System | 9/10 | Reputation 0-100 rescale |
| Mobile App | 7/10 | Missing 4 screens, no retry interceptor |
| Infrastructure | 7/10 | No HA DB, credentials not filled |
| Security | 9/10 | Fraud prevention in-memory |
| **Overall** | **8.5/10** | **~2-3 weeks to production** |
