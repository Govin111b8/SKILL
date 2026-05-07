# PRD §6.1 — Registration & Onboarding
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §6.1  
> **Current Score:** 7 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 1

---

## What PRD Specifies

### Customer Registration Fields
| Field | Validation | Status |
|---|---|---|
| Full Name | Min 2 chars, letters only | ✅ Implemented |
| Email | Valid format, unique | ✅ Implemented |
| Phone | 10-digit, OTP verified | ✅ Implemented |
| City / Location | Dropdown from supported cities | ⚠️ Free text only |
| Password | Min 8 chars, 1 upper, 1 number, 1 special | ✅ Implemented |
| Profile Photo | JPEG/PNG, max 2MB, optional | ✅ Implemented |

### Professional Registration Fields
| Field | Required | Status |
|---|---|---|
| Full Name (match govt ID) | Yes | ✅ |
| Phone (OTP verified) | Yes | ✅ |
| Email (unique) | Yes | ✅ |
| Government ID Type (Aadhaar/PAN/Passport/Voter) | Yes | ✅ |
| ID Number (encrypted) | Yes | ✅ |
| ID Document Upload (front + back, max 5MB) | Yes | ✅ |
| Selfie (live capture, AI face match) | Yes | ⚠️ Mock mode only |
| Service Category (up to 3) | Yes | ✅ |
| Sub-category Skills (per category) | Yes | ✅ |
| Service Locations (up to 5 zones) | Yes | ⚠️ Partial |
| Years of Experience | Yes | ✅ |
| Pricing Estimate | No | ✅ |
| Bio/About (100–500 chars) | Yes | ✅ |
| Business Name | No | ✅ |
| Language selection | No (but in Tech Supplement) | ❌ Missing |

### Verification SLA
| Requirement | Status |
|---|---|
| Government ID + Selfie completed within 24h | ⚠️ No SLA timer/tracking |
| Profiles with pending verification NOT in search | ✅ `government_id_verified = false` filter |
| Email/SMS at each verification stage | ⚠️ Service exists; triggers incomplete |

### Business Logic (PRD + Tech Supplement A.3)
| Logic | Status |
|---|---|
| OTP: 6-digit, 5-min expiry, max 3 attempts | ✅ |
| OTP: max 3 requests/hr per number | ✅ |
| OTP: max 10 failed attempts/IP/day | ✅ |
| Resend cooldown 60 seconds | ⚠️ Backend not enforced |
| Device fingerprint check on banned account device | ❌ Not implemented |
| Professional onboarding nudge (<60% complete → banner) | ❌ Not implemented |
| 7-day free Profile Boost on profile completion | ❌ Not implemented |
| Supported cities dropdown (not free text) | ❌ City is free text |

---

## Gap Analysis

### Gap 1 — Selfie face-match runs in mock mode
**File:** `backend/src/services/faceMatch.js`  
**Issue:** `FACE_MATCH_PROVIDER=mock` by default; returns configurable score.  
**Fix:** Wire HyperVerge or AWS Rekognition with real credentials in production env. Add `FACE_MATCH_PROVIDER` to production secrets. Document liveness-detection flow.

### Gap 2 — No verification SLA tracking
**File:** `backend/src/controllers/kycController.js`  
**Issue:** No timestamp tracking for "submitted at" vs "reviewed at".  
**Fix:** Add `submitted_at` and `reviewed_at` timestamps to KYC records. Add cron job to alert if pending KYC > 20 hours. Send professional reminder SMS at 22h.

### Gap 3 — City field is free text
**File:** `backend/src/controllers/authController.js`, `frontend/src/pages/Register.jsx`  
**Issue:** PRD requires city from a supported cities dropdown.  
**Fix:** Create `supported_cities` table (or seed config). Replace city text input with autocomplete dropdown in registration flow.

### Gap 4 — Professional onboarding nudge missing
**Files:** `frontend/src/pages/Dashboard.jsx`, `backend/src/controllers/dashboardController.js`  
**Issue:** After verification, if profile < 60% complete, a persistent banner should appear with a checklist. Completion unlocks 7-day free Profile Boost.  
**Fix:**
1. Add `profile_completeness` calculated field to dashboard API response (count filled fields / total × 100)
2. Frontend: render `ProfileCompleteBanner` component when completeness < 60
3. Backend: when completeness crosses 60%, create a 7-day `subscription_boost` event

### Gap 5 — Language selection not in registration
**Files:** `database/schema.sql`, `backend/src/routes/professionals.js`  
**Issue:** Tech Supplement specifies `professional_languages` table. Not in onboarding flow.  
**Fix:** Migration 012 partially added columns. Add language selection step to professional onboarding (Step 2 of registration), store in `professional_languages` table.

### Gap 6 — OTP resend cooldown not enforced in backend
**File:** `backend/src/routes/auth.js`  
**Issue:** Frontend may show countdown but backend doesn't enforce 60-second cooldown.  
**Fix:** Store last OTP send timestamp in Redis with 60-second TTL. Reject requests within cooldown window.

### Gap 7 — Device fingerprint for banned accounts
**File:** `backend/src/controllers/authController.js`  
**Issue:** PRD §11.2 requires device fingerprint check — new registrations from a device that had a banned account should trigger manual review.  
**Fix:** Accept `device_fingerprint` header from clients. On registration, check if fingerprint exists in `banned_devices` table. If match, flag account for review.

---

## Implementation Tasks (Sprint 1)

### Backend
- [ ] **T1** Add `submitted_at`, `reviewed_at` to KYC records; add 22h alert cron
- [ ] **T2** Add `supported_cities` seed data and endpoint (`GET /cities`)
- [ ] **T3** Add `profile_completeness` calculation to dashboard controller
- [ ] **T4** Add 7-day profile boost logic on completeness crossing 60%
- [ ] **T5** Add language selection to professional onboarding endpoint
- [ ] **T6** Enforce OTP resend 60s cooldown in Redis
- [ ] **T7** Add device fingerprint check on registration (optional param, flag-on-match)

### Frontend
- [ ] **T8** Replace city text input with `CitySelect` component in `Register.jsx`
- [ ] **T9** Add language selection step in professional registration flow
- [ ] **T10** Add `ProfileCompleteBanner` to `Dashboard.jsx` for < 60% profiles
- [ ] **T11** Add profile completeness progress bar with checklist items

### Environment / Config
- [ ] **T12** Document `FACE_MATCH_PROVIDER=hyperverge` setup in `.env.example`
- [ ] **T13** Add HyperVerge credentials to K8s Secret template in `SECRETS.md`

---

## Acceptance Criteria
- [ ] New customer registration with city dropdown works end-to-end
- [ ] Professional KYC flow: submit → 24h SLA timer starts → admin reviews → SMS sent
- [ ] Professional with < 60% profile sees banner with checklist
- [ ] Completing 60% unlocks 7-day boost (visible in subscription table)
- [ ] OTP resend blocked within 60 seconds (backend enforced)
- [ ] `FACE_MATCH_PROVIDER=hyperverge` passes a real selfie-ID match in staging
