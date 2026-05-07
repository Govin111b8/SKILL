# PRD §9 — API Design
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §9; SkillConnect_Technical_Supplement_v1.0.docx §A.2  
> **Current Score:** 8 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 2

---

## PRD §9 Endpoints Status

### §9.1 Authentication Endpoints
| Method | Endpoint | Status |
|---|---|---|
| POST | /auth/register | ✅ |
| POST | /auth/verify-otp | ✅ |
| POST | /auth/login | ✅ |
| POST | /auth/refresh | ✅ |
| POST | /auth/logout | ✅ |
| POST | /auth/forgot-password | ✅ |
| POST | /auth/reset-password | ✅ |

### §9.2 Professional Endpoints
| Method | Endpoint | Status |
|---|---|---|
| POST | /professionals/onboard | ✅ |
| GET | /professionals/:id | ✅ |
| PUT | /professionals/profile | ✅ |
| GET | /professionals/dashboard | ✅ |
| POST | /professionals/portfolio | ✅ |
| DELETE | /professionals/portfolio/:itemId | ✅ |
| POST | /professionals/certifications | ✅ |
| PUT | /professionals/availability | ✅ |
| GET | /professionals/reviews | ✅ |
| POST | /professionals/reply-review/:id | ✅ |

### §9.3 Search & Discovery Endpoints
| Method | Endpoint | Status |
|---|---|---|
| GET | /search | ✅ |
| GET | /categories | ✅ |
| GET | /categories/:id/professionals | ✅ |
| GET | /professionals/featured | ✅ |
| GET | /search/suggestions | ❌ Missing |

### §9.4 Interaction & Review Endpoints
| Method | Endpoint | Status |
|---|---|---|
| POST | /interactions (contacts) | ✅ |
| PUT | /interactions/:id/complete | ⚠️ Check if present |
| POST | /reviews | ✅ |
| PUT | /reviews/:id/rate-customer | ⚠️ Partially |

### §9.5 Admin Endpoints
| Method | Endpoint | Status |
|---|---|---|
| GET | /admin/verifications/pending | ✅ |
| PUT | /admin/verifications/:id | ✅ |
| GET | /admin/complaints | ✅ |
| PUT | /admin/complaints/:id/action | ✅ |
| GET | /admin/users/:id | ✅ |
| GET | /admin/stats | ✅ |

---

## Tech Supplement §A.2 — Missing Endpoints

| Method | Endpoint | Status | Priority |
|---|---|---|---|
| GET | /professionals/:id/availability | ✅ (schedule routes) | - |
| PUT | /professionals/hours | ✅ | - |
| POST | /professionals/block-customer/:userId | ❌ Missing | HIGH |
| GET | /search/history | ✅ | - |
| DELETE | /search/history | ⚠️ May be missing | MEDIUM |
| POST | /referrals/apply | ✅ | - |
| GET | /referrals/my-code | ✅ | - |
| GET | /categories/trending | ❌ Missing | HIGH |
| POST | /waitlist | ❌ Missing | MEDIUM |
| GET | /professionals/:id/similar | ❌ Missing | HIGH |
| POST | /interactions/:id/quote-accept | ❌ Missing | HIGH |
| GET | /invoices/:id | ⚠️ May be missing | MEDIUM |
| PUT | /users/language | ❌ Missing | MEDIUM |
| POST | /reviews/:id/helpful | ❌ Missing | MEDIUM |
| GET | /admin/ab-experiments | ❌ Missing | LOW |
| PUT | /admin/featured-slots | ❌ Missing | HIGH |
| GET | /professionals/export-data | ❌ Missing | HIGH (DPDPA) |
| DELETE | /users/account | ❌ Missing | HIGH (DPDPA) |

---

## Gap Analysis

### Gap 1 — DPDPA Required Endpoints
**`GET /professionals/export-data`** and **`DELETE /users/account`** are legal requirements under DPDPA 2023.  
**Fix:**
- Export: collect all user data (profile, contacts, reviews, bookings, messages) → return as JSON
- Delete: set `deleted_at = NOW()`, anonymise PII, schedule permanent purge in 30 days (cron)

### Gap 2 — Block Customer Not Implemented
**Fix:** `POST /professionals/block-customer/:userId`:
1. Insert into `blocked_users` table
2. Future contact attempts from blocked user to this professional → 403
3. Blocked user cannot view this professional's profile (return 404)

### Gap 3 — Featured Slots Admin Management Missing
**Fix:** `PUT /admin/featured-slots`:
1. Assign professional to a featured slot (home/category/search, city, date range)
2. Search query reads from `featured_slots` to boost featured professionals
3. This enables monetisation: Featured tier professionals pay for guaranteed slots

### Gap 4 — Invoice Download Missing
**Fix:** `GET /invoices/:id`:
1. Fetch GST invoice record
2. Return PDF URL (pre-signed S3 URL, 15-min expiry)
3. Guard: only the professional who owns the subscription can download

---

## Implementation Tasks (Sprint 2)

### Backend
- [ ] **T1** `POST /professionals/block-customer/:userId` (insert to blocked_users; check on contact)
- [ ] **T2** `GET /search/suggestions` (autocomplete with Redis cache)
- [ ] **T3** `GET /categories/trending` (search_history aggregation with Redis cache)
- [ ] **T4** `POST /waitlist` (insert email/phone/city/service_interest)
- [ ] **T5** `GET /professionals/:id/similar` (same category + proximity, limit 5)
- [ ] **T6** `POST /interactions/:id/quote-accept` (status update + customer notification)
- [ ] **T7** `GET /invoices/:id` (pre-signed PDF URL)
- [ ] **T8** `PUT /users/language` (update preferred_language)
- [ ] **T9** `POST /reviews/:id/helpful` (+1 helpful_count)
- [ ] **T10** `GET /admin/ab-experiments` (list from ab_experiments table)
- [ ] **T11** `PUT /admin/featured-slots` (assign professional to featured slot)
- [ ] **T12** `GET /professionals/export-data` (DPDPA data export)
- [ ] **T13** `DELETE /users/account` (30-day soft delete)
- [ ] **T14** `DELETE /search/history` (if missing)
- [ ] **T15** `PUT /interactions/:id/complete` (if missing)
- [ ] **T16** `PUT /reviews/:id/rate-customer` (complete two-way rating)

### API Tests
- [ ] **T17** Add Jest tests for each new endpoint (following existing test patterns)

---

## Acceptance Criteria
- [ ] All 18 missing endpoints from Tech Supplement §A.2 implemented
- [ ] Data export returns complete JSON of all user data
- [ ] Account deletion initiates 30-day soft delete; permanent purge cron scheduled
- [ ] Blocked user gets 403/404 when accessing blocking professional's profile
- [ ] Featured slots admin endpoint allows assigning/removing Featured-tier placements
- [ ] Invoice download returns valid pre-signed S3 PDF URL
