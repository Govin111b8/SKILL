# PRD §13 — Moderation & Trust System
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §13  
> **Current Score:** 7 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 3

---

## Complaint Categories Status (PRD §13.1)

| Category | Priority | Status |
|---|---|---|
| Fraud | Critical — 24h | ✅ In schema |
| Harassment | Critical — 24h | ✅ In schema |
| Fake Profile | High — 48h | ✅ In schema |
| False Review | High — 48h | ❌ Missing from complaint_type enum |
| Poor Service | Standard — 72h | ✅ In schema |
| Inappropriate Content | High — 48h | ❌ Missing from complaint_type enum |
| Other | Standard — 72h | ❌ Missing from complaint_type enum |

---

## Three-Strike Framework (PRD §13.2)

| Strike | Action | Duration | Appeal | Status |
|---|---|---|---|---|
| 1st | Warning email; logged | N/A | No | ⚠️ Log exists; email not wired |
| 2nd | Profile hidden; cannot contact | 7–30 days | Yes (5 days) | ⚠️ Schema has `is_active`; appeal flow missing |
| 3rd | Account disabled; phone blacklisted; ID blocked | Permanent | Yes (14 days via email) | ⚠️ `is_active=false`; phone/ID blacklist missing |
| Fair Process | Written reason + appeal path | — | — | ⚠️ Reason stored; appeal UI missing |
| Two-person review for permanent bans | — | — | — | ❌ Not implemented |

---

## Review Moderation (PRD §13.3)

| Scenario | Action | Status |
|---|---|---|
| Hate speech / slurs | Auto-flagged by NLP; held for approval | ❌ NLP not implemented |
| Below 3 stars, no text | Prompt for detail; publish after 48h if no action | ⚠️ Frontend prompt needed |
| Burst of positive reviews (>5 in 24h) | Held for manual verification | ❌ Not implemented |
| Professional disputes a review | Flag for review; remove only if policy violation | ⚠️ Flag endpoint may exist; flow incomplete |
| Review from unverified interaction | Rejected at API level | ✅ |

---

## Reputation Score (PRD §13.4 — Trust Index)

| Factor | Weight | Status |
|---|---|---|
| Average Rating | 30% | ⚠️ Used but not in 0–100 Trust Index |
| Recent Rating (last 10) | 20% | ⚠️ Field exists, not in formula |
| Completed Jobs Count (logarithmic scale) | 15% | ⚠️ Linear, not logarithmic |
| Repeat Customer Rate | 15% | ❌ Not calculated |
| Response Rate | 10% | ⚠️ Field exists, not calculated |
| Profile Completeness | 5% | ❌ Not in formula |
| Complaint Penalty (-15 per verified complaint) | -15% | ❌ Not implemented |
| Verification Bonus (+5 flat) | +5 | ❌ Not implemented |

**Recalculation:** Nightly background job (PRD requirement). Currently has trigger (migration 005) but not full formula.

---

## Gap Analysis

### Gap 1 — Missing Complaint Types
**File:** `database/schema.sql` → `complaint_type` enum  
**Fix:** Add `false_review`, `inappropriate_content`, `other` to the `complaint_type` enum (migration 013).

### Gap 2 — Appeal System Not Implemented
**Files:** `backend/src/routes/admin.js`, `frontend/src/pages/admin/`  
**Fix:**
1. Create `appeals` table: `(id, complaint_id, user_id, reason, status, reviewed_by, created_at)`
2. `POST /appeals` — user submits appeal within window (5 days for temp ban, 14 days for perm ban)
3. `GET /admin/appeals` — admin sees pending appeals
4. `PUT /admin/appeals/:id` — different admin (not original moderator) reviews and decides
5. Frontend: "Appeal this decision" button in user's notification/email

### Gap 3 — Phone/ID Blacklist Not Implemented
**Fix:** On permanent ban:
1. Add phone to `banned_phones` table
2. Hash govt ID and add to `banned_govt_ids` table
3. On registration: check against both tables; reject with 403

### Gap 4 — Two-Person Review for Permanent Bans
**File:** `backend/src/controllers/adminController.js`  
**Fix:**
1. `PUT /admin/complaints/:id/action` with action=`permanent_ban`: sets status to `pending_second_review`
2. A second admin (different user) must confirm via `PUT /admin/complaints/:id/confirm-ban`
3. Log both admin IDs in `admin_actions`

### Gap 5 — Trust Index 0–100 Formula
**File:** `database/migrations/005_reputation_trigger.sql`, `backend/src/workers/cron.js`  
**Fix (complete formula):**
```sql
trust_index = LEAST(100, GREATEST(0,
  (avg_rating / 5.0 * 30)           -- Average Rating: 30%
  + (recent_rating / 5.0 * 20)       -- Recent Rating: 20%
  + (LOG(GREATEST(1, completed_jobs + 1)) / LOG(101) * 15)  -- Completed Jobs: 15% (log scale, 100 jobs = max)
  + (repeat_customer_rate / 100 * 15) -- Repeat Customers: 15%
  + (response_rate / 100 * 10)        -- Response Rate: 10%
  + (profile_completeness / 100 * 5)  -- Profile Completeness: 5%
  + (CASE WHEN verification_status = 'verified' THEN 5 ELSE 0 END)  -- Verification bonus: +5
  - (verified_complaints_in_12mo * 15)  -- Complaint penalty: -15 each
))
```

### Gap 6 — NLP Hate Speech Filter
**Fix (lightweight):**
1. Install `bad-words` npm package: `npm install bad-words`
2. Check review text against profanity filter before insert
3. If flagged: `is_visible = false`, added to moderation queue with reason `auto_flagged_profanity`
4. For Phase 2: integrate AWS Comprehend for sentiment + toxicity detection

---

## Implementation Tasks (Sprint 3)

### Backend
- [ ] **T1** Add missing complaint types to enum (migration 013)
- [ ] **T2** Create appeals table and endpoints (POST + admin GET/PUT)
- [ ] **T3** Create banned_phones + banned_govt_ids tables
- [ ] **T4** Check banned phone/ID on registration
- [ ] **T5** Implement two-person permanent ban workflow
- [ ] **T6** Implement full Trust Index formula in cron nightly job
- [ ] **T7** Add profanity filter on review submission (`bad-words` package)
- [ ] **T8** Add review velocity detection (>5 in 24h → hold)
- [ ] **T9** Wire complaint actions to account status changes (warning → email, suspension → profile hidden)

### Frontend
- [ ] **T10** Add "Appeal this decision" flow in Settings/Notifications
- [ ] **T11** Admin panel: appeals review queue
- [ ] **T12** Admin panel: second-admin confirmation UI for permanent bans

---

## Acceptance Criteria
- [ ] All 7 complaint types available in report form
- [ ] Appealing a suspension works end-to-end: user submits → different admin reviews → decision sent by email
- [ ] Permanent ban requires two different admins to confirm
- [ ] Banned phone number cannot register a new account
- [ ] Trust Index (0–100) calculated nightly; displays on profile
- [ ] Review with profanity auto-held for moderation; not published
- [ ] >5 reviews to same professional in 24h → all held for verification
