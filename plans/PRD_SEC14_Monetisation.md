# PRD §14 — Monetisation & Revenue Model
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §14  
> **Current Score:** 7 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 2

---

## Subscription Plans Status (PRD §14.1)

| Feature | Basic (Free) | Premium (₹999/mo) | Featured (₹2,499/mo) | Status |
|---|---|---|---|---|
| Profile & Verification | ✅ | ✅ | ✅ | ✅ Implemented |
| Portfolio Images | 5 | 20 | 20 | ⚠️ Limits not enforced |
| Portfolio Videos | 0 | 5 | 5 | ⚠️ Limits not enforced |
| Project Cards | 5 | 30 | 30 | ⚠️ Limits not enforced |
| Certifications | 1 | 5 | 5 | ⚠️ Limits not enforced |
| Search Visibility | Standard | +20% ranking | Top-section +50% | ⚠️ Boost implemented; tiers not enforced per plan |
| Analytics Dashboard | Basic (views) | Full | Full + competitor | ⚠️ Analytics exists; tier gating missing |
| Featured in Category Page | No | No | Yes (top 3) | ❌ Not implemented |
| Home Screen Feature | No | No | Yes (weekly rotation) | ❌ Not implemented |
| WhatsApp Business Badge | No | Yes | Yes | ❌ Not implemented |
| Priority Support | 48h | 24h | Same-day | ❌ Not implemented (process only) |

### Pricing
| Plan | Monthly | Annual (33% off) | Status |
|---|---|---|---|
| Basic | Free | — | ✅ |
| Premium | ₹999/mo | ₹7,999/yr | ⚠️ Monthly exists; annual discount not applied |
| Featured | ₹2,499/mo | ₹19,999/yr | ⚠️ Monthly exists; annual discount not applied |
| Introductory | Premium ₹499/mo, Featured ₹1,499/mo | — | ❌ Not implemented |

### Subscription Grace Period (Tech Supplement §A.3)
| Rule | Status |
|---|---|
| 3-day grace period on lapse | ❌ Not implemented |
| Send day-0, day-1, day-3 renewal reminders | ❌ Not implemented |
| After grace: downgrade to Basic silently | ❌ Not implemented |

---

## Gap Analysis

### Gap 1 — Subscription-Gated Portfolio Limits Not Enforced
**File:** `backend/src/controllers/portfolioController.js`  
**Fix:** Before allowing portfolio upload, check professional's `subscription_plan`:
- Basic: max 5 images, 0 videos, 5 projects, 1 cert
- Premium/Featured: max 20 images, 5 videos, 30 projects, 5 certs

### Gap 2 — Featured Category Page Placement Not Implemented
**Files:** `backend/src/routes/categories.js`, `frontend/src/pages/CategoryDetail.jsx`  
**Fix:**
1. `GET /categories/:id/professionals` → Featured tier professionals appear in top 3 results
2. Add visual "Featured" badge on category page cards
3. Backend: `featured_slots` table tracks which Featured-tier professionals are assigned to which category slots

### Gap 3 — Home Screen Featured Rotation Not Implemented
**File:** `backend/src/routes/professionals.js` → `GET /professionals/featured`  
**Fix:**
1. `featured_slots` table with `slot_type = 'home'`
2. Weekly rotation cron: select rotating subset of Featured-tier professionals per city for home screen
3. Frontend: home screen carousel shows only professionals in active home featured slots

### Gap 4 — Annual Plan Discount Not Applied
**File:** `backend/src/controllers/paymentController.js`  
**Fix:**
1. Add `billing_cycle` field to subscription creation: `monthly | annual`
2. If annual: apply 33% discount (Premium: ₹7,999, Featured: ₹19,999)
3. Frontend: show monthly vs annual toggle on payment page with savings highlighted

### Gap 5 — Grace Period Not Implemented
**File:** `backend/src/workers/cron.js`  
**Fix:**
1. On subscription expiry: set status to `grace`, `grace_period_end = expiry + 3 days`
2. Cron job at day 0, 1, 3: send renewal reminder push + email
3. If not renewed by grace_period_end: set subscription to `expired`, set `subscription_plan = 'basic'`

### Gap 6 — WhatsApp Business Badge Not Implemented
**Fix:** When professional has Premium or Featured subscription, display a WhatsApp Business-style verified badge next to the WhatsApp contact button. This is a UI-only badge (no actual WhatsApp Business API needed).

### Gap 7 — Introductory Pricing Not Implemented
**File:** `backend/src/controllers/paymentController.js`  
**Fix:** Add `INTRODUCTORY_PRICING_ENABLED=true` env flag. When enabled, Premium charges ₹499/mo and Featured ₹1,499/mo. Add `introductory_price_expires_at` date config.

---

## Implementation Tasks (Sprint 2)

### Backend
- [ ] **T1** Enforce subscription-gated portfolio limits (Basic vs Premium/Featured)
- [ ] **T2** Implement annual billing cycle with 33% discount
- [ ] **T3** Implement 3-day grace period in cron (day-0, day-1, day-3 reminders)
- [ ] **T4** Auto-downgrade to Basic after grace period expires
- [ ] **T5** Add `INTRODUCTORY_PRICING_ENABLED` env toggle
- [ ] **T6** Implement `featured_slots` management for home + category placement
- [ ] **T7** Featured-tier professionals appear in top 3 of category page results

### Frontend
- [ ] **T8** Add monthly/annual billing toggle on Payment.jsx with savings displayed
- [ ] **T9** Show "Featured" badge on category page for Featured-tier professionals
- [ ] **T10** Show WhatsApp Business badge for Premium/Featured subscribers
- [ ] **T11** Show "Portfolio limit reached" message for Basic professionals (5 images)
- [ ] **T12** Analytics page: show tier-gated features (Full analytics for Premium+)

---

## Acceptance Criteria
- [ ] Basic professional cannot upload 6th image (API returns 422 with upgrade prompt)
- [ ] Annual subscription charges ₹7,999 for Premium and ₹19,999 for Featured
- [ ] Expired subscription enters 3-day grace with daily reminder notifications
- [ ] After grace period: profile automatically reverts to Basic tier
- [ ] Featured professional appears in top 3 of their category page
- [ ] Home screen carousel shows only active Featured-slot professionals
- [ ] GST invoice auto-generated and emailed on every subscription payment
