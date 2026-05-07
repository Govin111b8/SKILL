# Tech Supplement §A — PRD Gap Analysis & Missing Fields
## Implementation Plan (Pin-to-Pin)

> **Reference:** SkillConnect_Technical_Supplement_v1.0.docx §A  
> **Current Score:** 6 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 2

---

## §A.1.1 — Missing Tables (14 Tables)

| Table | Status | Sprint |
|---|---|---|
| search_index (tsvector FTS) | ⚠️ May be in migration 006; verify trigger works | Sprint 2 |
| professional_hours | ✅ Migration 012 | Done |
| blocked_users | ❌ Missing | Sprint 2 |
| search_history | ✅ Migration 006 | Done |
| featured_slots | ❌ Missing | Sprint 2 |
| payout_log | ✅ Migration 012 | Done |
| gst_invoices | ✅ Migration 012 | Done |
| device_tokens | ✅ Migration 012 | Done |
| category_requests | ❌ Missing | Sprint 2 |
| professional_languages | ❌ Missing | Sprint 2 |
| soft_deletes_log | ❌ Missing | Sprint 2 |
| ab_experiments | ❌ Missing | Sprint 2 |
| referral_codes | ✅ Migration 010 | Done |
| waitlist | ❌ Missing | Sprint 6 |

**5 of 14 tables missing → must be added in migration 013**

---

## §A.1.2 — Missing Columns

See `PRD_SEC08_Database.md` for full column checklist.

Key items requiring migration 013:
- `blocked_users` table creation
- `featured_slots` table creation
- `category_requests` table creation
- `professional_languages` table creation
- `soft_deletes_log` table creation
- `ab_experiments` table creation
- `users.preferred_language` (if not in 012)
- `users.deleted_at` (if not in 012)
- `professionals.gender` (if not in 012)
- `reviews.helpful_count` (if not in 012)
- `contacts.source_screen` (if not in 012)
- `contacts.quote_text` (if not in 012)

---

## §A.2 — Missing API Endpoints (18 Endpoints)

See `PRD_SEC09_API.md` for full implementation plan.

Summary of missing endpoints:
| Endpoint | Priority | Status |
|---|---|---|
| GET /search/suggestions | HIGH | ❌ |
| GET /professionals/:id/similar | HIGH | ❌ |
| POST /professionals/block-customer/:userId | HIGH | ❌ |
| GET /categories/trending | HIGH | ❌ |
| PUT /admin/featured-slots | HIGH | ❌ |
| GET /professionals/export-data | HIGH (DPDPA) | ❌ |
| DELETE /users/account | HIGH (DPDPA) | ❌ |
| POST /interactions/:id/quote-accept | HIGH | ❌ |
| DELETE /search/history | MEDIUM | ⚠️ |
| POST /waitlist | MEDIUM | ❌ |
| GET /invoices/:id | MEDIUM | ⚠️ |
| PUT /users/language | MEDIUM | ❌ |
| POST /reviews/:id/helpful | MEDIUM | ❌ |
| GET /admin/ab-experiments | LOW | ❌ |

---

## §A.3 — Missing Business Logic

| Business Logic | Status | Plan |
|---|---|---|
| Profile deactivation after 90 days inactivity | ❌ | Add to cron.js (60d warn, 80d warn, 90d deactivate) |
| Review edit window (24h, text-only) | ⚠️ Columns added, no endpoint | Sprint 1 |
| Subscription grace period (3 days) | ❌ | Sprint 2 |
| Professional onboarding nudge (<60% complete) | ❌ | Sprint 1 |
| Customer duplicate contact limit (3 in 30d) | ❌ | Sprint 1 |
| Geo-expansion queue (waitlist notify on city activation) | ❌ | Sprint 6 |
| GST auto-calculation and invoice on payment | ⚠️ Service exists, trigger needed | Sprint 2 |

---

## Implementation Tasks (Sprint 2)

### Database
- [ ] **T1** Create migration 013 with all 5 missing tables
- [ ] **T2** Add missing columns to existing tables (check migration 012 first to avoid duplicates)
- [ ] **T3** Verify `search_index` trigger is active and updating on profile change
- [ ] **T4** Verify GIN index on `search_index.tsv_content` exists

### Backend — Business Logic
- [ ] **T5** Profile auto-deactivation cron (60d warn, 80d warn, 90d mark unavailable)
- [ ] **T6** `PUT /reviews/:id` edit endpoint (24h window)
- [ ] **T7** Customer contact rate limit (3 per 30 days per professional)
- [ ] **T8** GST invoice auto-generation trigger on subscription payment

### Backend — API
- [ ] **T9** All 18 missing endpoints (see PRD_SEC09_API.md for full list)

---

## Acceptance Criteria
- [ ] Migration 013 runs cleanly on fresh database
- [ ] All 14 Tech Supplement missing tables exist after migration
- [ ] search_index updated within 5 seconds of any professional profile change
- [ ] Customer gets 429 on 4th contact to same professional in 30 days
- [ ] Professional inactive 90 days: profile marked unavailable; received 2 warning notifications
- [ ] Review edit endpoint works within 24h; rejects after 24h
