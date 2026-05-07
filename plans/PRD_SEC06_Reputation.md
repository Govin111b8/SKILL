# PRD §6.6 — Reputation & Rating System
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §6.6  
> **Current Score:** 6 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 1 (highest priority)

---

## What PRD Specifies

### Customer Rating of Professionals
| Rule | Status |
|---|---|
| Customer can rate only after contacting via platform | ✅ Gated by interaction |
| One review per professional per customer | ✅ Unique constraint |
| Review timing: 1 hour to 60 days after contact | ⚠️ Not enforced |
| Velocity detection: >5 reviews in 24h → held for manual review | ❌ Not implemented |
| Sentiment analysis: hate speech auto-held | ❌ Not implemented |
| Review edit window: 24h (text only, not star rating) | ⚠️ Columns added (migration 012), no logic |
| Review below 3 stars with no text → prompt for detail | ❌ Not implemented |

### Professional Rating of Customers (Two-Way Reputation)
| Requirement | Status |
|---|---|
| Professional rates customer 1–5 stars after interaction | ⚠️ Endpoint may exist; UI incomplete |
| Average shown on customer profile | ❌ Not displayed |
| False complaint flag adds negative signal | ❌ Not implemented |
| No-show flag | ❌ Not implemented |
| Repeat Positive → "Trusted Customer" badge | ❌ Not implemented |
| Professional can view customer score BEFORE accepting | ❌ Not implemented |

### Reputation Score (Trust Index) — PRD §13.4
| Factor | Weight | Status |
|---|---|---|
| Average Rating | 30% | ⚠️ Used but at 0–5 scale, not 0–100 Trust Index |
| Recent Rating (last 10) | 20% | ⚠️ Field exists, not in Trust Index formula |
| Completed Jobs Count (logarithmic) | 15% | ⚠️ Not logarithmic |
| Repeat Customer Rate | 15% | ❌ Not calculated |
| Response Rate | 10% | ⚠️ Field exists, not calculated |
| Profile Completeness | 5% | ❌ Not in formula |
| Complaint Penalty (-15 per verified complaint) | -15% | ❌ Not implemented |
| Verification Bonus | +5 flat | ❌ Not implemented |

**Recalculation:** Nightly background job required per PRD.

---

## Gap Analysis

### Gap 1 — Trust Index (0–100) Not Computed
**Files:** `database/migrations/005_reputation_trigger.sql`, `backend/src/workers/cron.js`  
**Fix:** See PRD_SEC02_Profile.md Gap 1. This is the top priority item.

### Gap 2 — Two-Way Reputation (Professional Rates Customer) UI Missing
**Files:** `frontend/src/pages/BookingDetail.jsx` or interaction-complete flow  
**Issue:** Backend may have `PUT /reviews/:id/rate-customer` but UI prompt after completing a job is missing.  
**Fix:**
1. After professional marks booking complete, show 1-click rating prompt for the customer
2. Store rating in `contacts.customer_rating` (or separate table)
3. Calculate `users.customer_score` (average of professional ratings received)
4. Display customer score on customer profile visible to professionals

### Gap 3 — Review Timing Window (1h–60d) Not Enforced
**File:** `backend/src/controllers/reviewController.js`  
**Fix:** In `POST /reviews`, check: `NOW() - interaction.created_at` must be between 1 hour and 60 days. Return 422 if outside window.

### Gap 4 — Velocity Detection (>5 Reviews in 24h)
**File:** `backend/src/controllers/reviewController.js`  
**Fix:**
1. Before inserting review, count reviews received by professional in last 24h
2. If count ≥ 5: insert review with `is_visible = false`, add to moderation queue
3. Professional notified: "We're verifying recent reviews before publishing"

### Gap 5 — Review Edit Window (24h)
**Files:** `backend/src/controllers/reviewController.js`  
**Issue:** `is_edited` and `edited_at` columns exist (migration 012) but no edit endpoint.  
**Fix:**
1. `PUT /reviews/:id` — customer can edit review text (not star rating) within 24h
2. Validate: `NOW() - review.created_at < 24 hours`
3. Set `is_edited = true`, `edited_at = NOW()`

### Gap 6 — Low-Rating Prompt (< 3 stars, no text)
**File:** `frontend/src/pages/` (review submission UI)  
**Fix:** Client-side: if star rating ≤ 2 and text is empty, show inline prompt "Tell the professional what went wrong (helps them improve)". Prevent submit until text entered for ratings < 3.

### Gap 7 — Customer Trust Score Not Visible to Professionals
**Fix:** In `GET /contacts` (professional's contact list), include requester's `customer_score`. Show warning icon if score < 3.0.

---

## Implementation Tasks (Sprint 1)

### Backend
- [ ] **T1** Implement 7-factor Trust Index nightly recalculation in `cron.js`
- [ ] **T2** Add review timing window enforcement (1h–60d) in review controller
- [ ] **T3** Add velocity detection: >5 reviews in 24h → hold for moderation
- [ ] **T4** Add `PUT /reviews/:id` edit endpoint (24h window, text-only)
- [ ] **T5** Add `POST /reviews/:id/helpful` endpoint (+1 helpful_count)
- [ ] **T6** Wire professional-rates-customer: store in contacts/reviews; update customer_score
- [ ] **T7** Include `customer_score` in contacts list API response

### Frontend
- [ ] **T8** Show 1-click rating prompt for professional after booking complete
- [ ] **T9** Require text comment when star rating ≤ 2
- [ ] **T10** Show customer trust score to professionals in contact list
- [ ] **T11** Show "Trusted Customer" badge on customers with consistent 4+ ratings
- [ ] **T12** Show Trust Index (0–100) badge on professional profile

---

## Acceptance Criteria
- [ ] Trust Index (0–100) recalculates nightly; visible on all professional profiles
- [ ] Review submitted before 1h or after 60d of contact → rejected with clear message
- [ ] 6th review to same professional in 24h is held for moderation (not visible)
- [ ] Review text editable within 24h of submission; star rating locked
- [ ] Professional sees customer score (0–5) in contact request list
- [ ] Customers with avg ≥ 4.5 show "Trusted Customer" badge
