# PRD §6.2 — Professional Profile System
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §6.2  
> **Current Score:** 8 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 1

---

## What PRD Specifies

### Profile Components
| Component | Visibility | Status |
|---|---|---|
| Verified Badge (blue checkmark) | Public | ✅ Implemented |
| Profile Photo (AI-checked appropriateness) | Public | ⚠️ No NSFW check |
| Name & Business Name | Public | ✅ |
| Category Tags (primary + secondary) | Public | ✅ |
| Skill Tags | Public | ✅ |
| Location Zones (no exact address) | Public | ✅ |
| Rating Display (avg + last 10 + total count) | Public | ⚠️ last-10 not displayed |
| Reputation Score (Trust Index 0–100) | Public | ⚠️ Stored as 0–5 scale, not 0–100 |
| Years of Experience | Public | ✅ |
| Completed Jobs Count (auto-increment) | Public | ✅ |
| Pricing Estimate | Public | ✅ |
| Bio | Public | ✅ |
| Portfolio Gallery (up to 20 images, 5 videos) | Public | ⚠️ No limit enforcement |
| Certifications as badges | Public | ✅ |
| Testimonials (from 5-star reviews) | Public | ❌ Not implemented |
| Response Rate (% replied in 24h) | Public | ⚠️ Field in DB, not calculated |
| Member Since date | Public | ✅ |
| Contact Button (reveals phone/WhatsApp after login) | Logged-in | ✅ |
| ID Details | Admin only | ✅ |

---

## Gap Analysis

### Gap 1 — Reputation Score is 0–5 scale, PRD requires 0–100 Trust Index
**Files:** `database/migrations/005_reputation_trigger.sql`, `backend/src/controllers/professionalController.js`  
**Issue:** The `reputation_score` column stores a 0–5 scale average. PRD specifies a 0–100 Trust Index with 7 components (avg rating 30%, recent rating 20%, completed jobs 15%, repeat customers 15%, response rate 10%, profile completeness 5%, complaint penalty -15%, verification bonus +5%).  
**Fix:**
1. Add `trust_index` column (0–100) to `professionals` table
2. Rewrite reputation trigger to compute 0–100 Trust Index per PRD §13.4
3. Display Trust Index badge on profile (colour-coded: <40 bronze, 40–70 silver, 70–90 gold, 90+ platinum)
4. Keep `reputation_score` (0–5) as average rating; rename for clarity

### Gap 2 — "Last 10 Jobs" rating not displayed
**Files:** `backend/src/controllers/professionalController.js`, `frontend/src/pages/ProfessionalProfile.jsx`  
**Issue:** `recent_rating` column exists in DB but is not included in profile API response / frontend display.  
**Fix:** Include `recent_rating` in GET `/professionals/:id` response. Show as "Recent: 4.8" badge next to overall rating.

### Gap 3 — Response Rate not calculated
**Files:** `backend/src/workers/cron.js`  
**Issue:** `response_rate` column exists but is never updated. PRD: % of inquiries responded to within 24h across last 30 days.  
**Fix:** Add nightly cron: for each professional, count contacts in last 30 days where professional sent a message within 24h of contact / total contacts. Update `response_rate`.

### Gap 4 — Testimonials from 5-star reviews not implemented
**Files:** `backend/src/controllers/reviewController.js`, `frontend/src/pages/ProfessionalProfile.jsx`  
**Issue:** PRD says auto-generate customer quotes from 5-star reviews (with customer consent) shown as testimonials on profile.  
**Fix:**
1. Add `show_as_testimonial` boolean to `reviews` table (default false)
2. Add customer consent prompt after 5-star review: "May we show your review as a testimonial?"
3. Display consented testimonials in a styled "What clients say" section on profile
4. Max 5 testimonials; most recent preferred

### Gap 5 — Profile photo NSFW check not implemented
**Files:** `backend/src/services/storage.js`, `backend/src/controllers/uploadController.js`  
**Issue:** PRD says profile photos are AI-checked for appropriateness.  
**Fix:** Integrate AWS Rekognition `DetectModerationLabels` (or similar) on profile photo upload. Reject images with confidence > 80% for adult/suggestive content.

### Gap 6 — Repeat Customer % not calculated or displayed
**Issue:** PRD says "Chosen again by 34%" trust signal. Not in current response.  
**Fix:** Add `repeat_customer_rate` column. Nightly cron: (customers who contacted same pro ≥ 2 times / total unique customers) × 100. Display on profile.

---

## Implementation Tasks (Sprint 1)

### Backend
- [ ] **T1** Add `trust_index` DECIMAL(5,2) column to professionals table
- [ ] **T2** Rewrite reputation trigger (`005_reputation_trigger.sql`) with 7-factor Trust Index formula per PRD §13.4
- [ ] **T3** Include `recent_rating`, `trust_index`, `repeat_customer_rate` in GET `/professionals/:id` response
- [ ] **T4** Add `response_rate` nightly cron calculation in `workers/cron.js`
- [ ] **T5** Add `repeat_customer_rate` nightly cron calculation
- [ ] **T6** Add `show_as_testimonial` to reviews table + consent endpoint
- [ ] **T7** Add Rekognition NSFW check in upload controller (env-gated)

### Frontend
- [ ] **T8** Display Trust Index badge on `ProfessionalProfile.jsx` (colour-coded tier)
- [ ] **T9** Show "Recent: X.X ⭐" badge for `recent_rating` next to overall rating
- [ ] **T10** Show "Chosen again by X%" repeat customer signal on profile
- [ ] **T11** Display "Response Rate: X%" on profile stats row
- [ ] **T12** Render testimonials section from consented 5-star reviews

---

## Acceptance Criteria
- [ ] Trust Index (0–100) displayed on every verified professional profile
- [ ] Recent-10-jobs rating shown separately from overall rating
- [ ] Repeat customer % calculated and shown on profiles with ≥ 5 customers
- [ ] Response rate updated nightly and shown on profile
- [ ] Testimonials section shows up to 5 consented 5-star reviews
- [ ] Profile photo upload rejects NSFW images in staging (with Rekognition)
