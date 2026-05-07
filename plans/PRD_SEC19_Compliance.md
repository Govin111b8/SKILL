# PRD §19 — Compliance & Legal
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §19  
> **Current Score:** 5 / 10  
> **Target Score:** 9 / 10  
> **Sprint:** Sprint 6

---

## DPDPA 2023 Compliance (PRD §19.1)

| Requirement | Status |
|---|---|
| Data Principal rights: export, correction, deletion | ❌ Export endpoint missing; correction partial; deletion missing |
| Data minimisation | ✅ Only necessary fields collected |
| Explicit consent for marketing communications | ⚠️ No consent management UI |
| Separate consent per data category | ❌ Not implemented |
| Retained while account active; deleted accounts purged within 90 days | ❌ No soft-delete or purge cron |
| Govt ID documents retained 12 months post-verification; purged after | ❌ No document retention policy enforced |
| Data Protection Officer contact details | ❌ No DPO designated or displayed |

---

## Required Legal Documents (PRD §19.3)

| Document | Status |
|---|---|
| Terms of Service | ❌ No content page exists |
| Privacy Policy | ❌ No content page exists |
| Professional Terms (independent contractor, verification consent) | ❌ No content page |
| Cookie Policy | ❌ No content page (CookieConsent component exists but links nowhere) |
| Content Moderation Policy | ❌ No published policy |
| Refund Policy | ❌ No content page |

---

## SMS/Communication Compliance (PRD §19.4)

| Requirement | Status |
|---|---|
| All SMS via DLT-registered sender IDs | ❌ No DLT registration documentation |
| Promotional SMS only to opted-in users | ❌ No opt-in tracking |
| Transactional SMS exempt from DND | ⚠️ Flagged correctly in service but DLT template IDs missing |

---

## Platform Liability (PRD §19.2)

| Requirement | Status |
|---|---|
| ToS clarifies SkillConnect is discovery platform, not employer | ❌ No ToS |
| Not liable for quality of services performed offline | ❌ No ToS |
| PLATFORM_CHANGE_RECORD.md documents scope deviations | ✅ Exists |

---

## Gap Analysis

### Gap 1 — No Legal Content Pages
**File:** `frontend/src/pages/`  
**Fix:** Create the following pages:
1. `frontend/src/pages/legal/TermsOfService.jsx`
2. `frontend/src/pages/legal/PrivacyPolicy.jsx`
3. `frontend/src/pages/legal/ProfessionalTerms.jsx`
4. `frontend/src/pages/legal/CookiePolicy.jsx`
5. `frontend/src/pages/legal/ContentModeration.jsx`
6. `frontend/src/pages/legal/RefundPolicy.jsx`

Link from Footer, Registration, and CookieConsent component.

### Gap 2 — DPDPA Data Export Not Implemented
**Fix:** `GET /professionals/export-data` (also in API plan):
- Returns JSON blob of: user profile, professional profile, contacts, reviews, bookings, messages
- Triggers download in browser
- Logged in `audit_log` table
- Rate limited: max 1 export per 24h per user

### Gap 3 — Account Deletion (30-Day Soft Delete)
**Fix:** `DELETE /users/account`:
1. Set `users.deleted_at = NOW()`
2. Anonymise: name → "Deleted User", email → `deleted_{uuid}@deleted.local`, phone → null
3. Professional profile: `is_available = false`, `verification_status = 'deactivated'`
4. Cron job: permanently purge accounts where `deleted_at < NOW() - INTERVAL '90 days'`

### Gap 4 — Consent Management Missing
**Fix:**
1. Add `consent_records` table: (user_id, consent_type, granted_at, revoked_at, ip_address)
2. On registration: explicit checkboxes for marketing consent
3. Settings: manage consent for each category
4. Marketing email/SMS only to users with active marketing consent

### Gap 5 — Document Retention Policy for Govt ID
**Files:** `backend/src/workers/cron.js`, `backend/src/services/storage.js`  
**Fix:**
1. KYC records: store `verified_at` timestamp
2. Cron: after 12 months from verification, delete ID document from S3 (keep hash in DB for blacklist)
3. After account deletion + 90 days: delete selfie from S3
4. Log all S3 deletions to `soft_deletes_log`

### Gap 6 — Data Protection Officer
**Fix:**
1. Add DPO contact (email) to `.env`: `DPO_EMAIL=dpo@skillconnect.in`
2. Display in Privacy Policy and Contact Us page
3. Add `GET /legal/dpo-contact` endpoint returning DPO email

---

## Implementation Tasks (Sprint 6)

### Backend
- [ ] **T1** `GET /professionals/export-data` (full DPDPA data export)
- [ ] **T2** `DELETE /users/account` (30-day soft delete + anonymisation)
- [ ] **T3** Cron: purge deleted accounts after 90 days
- [ ] **T4** Cron: purge ID documents from S3 after 12 months post-verification
- [ ] **T5** Create `consent_records` table + consent endpoints
- [ ] **T6** Create `audit_log` table for data access logging

### Frontend
- [ ] **T7** Create TermsOfService.jsx, PrivacyPolicy.jsx, ProfessionalTerms.jsx
- [ ] **T8** Create CookiePolicy.jsx, ContentModeration.jsx, RefundPolicy.jsx
- [ ] **T9** Add routes for all legal pages in `App.jsx`
- [ ] **T10** Footer links to all legal documents
- [ ] **T11** Registration: explicit consent checkboxes with links to ToS + Privacy Policy
- [ ] **T12** CookieConsent component links to Cookie Policy
- [ ] **T13** Settings: consent management toggles

---

## Acceptance Criteria
- [ ] All 6 legal documents accessible from footer and registration
- [ ] Data export: user receives complete JSON of their data within 5 seconds
- [ ] Account deletion: user profile invisible within 1 minute; purged within 90 days
- [ ] Marketing emails only sent to users with explicit marketing consent
- [ ] KYC documents auto-deleted from S3 after 12 months (cron test)
- [ ] Registration requires checking ToS consent checkbox before submission
