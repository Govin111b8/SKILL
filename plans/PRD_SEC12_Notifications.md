# PRD §12 — Notification & Communication System
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §12  
> **Current Score:** 7 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 1

---

## Notification Types Status (PRD §12.1)

| Event | Recipient | Channel | Status |
|---|---|---|---|
| OTP sent | User | SMS | ✅ |
| Verification approved | Professional | SMS + Push | ⚠️ Push trigger not confirmed |
| Verification rejected | Professional | SMS + Email | ⚠️ Email trigger not confirmed |
| Profile viewed | Professional | Push | ❌ No profile-view push trigger |
| Quote request received | Professional | Push + SMS | ❌ Not wired to contact creation |
| Review received | Professional | Push | ❌ Not wired to review creation |
| Complaint filed against you | Professional | Email | ❌ Not wired to complaint creation |
| Subscription expiring (7 days) | Professional | Push + Email | ⚠️ Cron exists; email template needed |
| Subscription expired | Professional | Email | ⚠️ Cron exists; email template needed |
| Complaint outcome | Reporter | Push | ❌ Not wired to complaint resolution |
| Account suspended | Any | Email + SMS | ❌ Not wired to admin action |

---

## Notification Preferences (PRD §12.2)

| Category | Default | Can Disable | Status |
|---|---|---|---|
| Security alerts (OTP, password change) | ON | No | ✅ |
| Verification status updates | ON | No | ⚠️ Not enforced |
| Complaint & moderation updates | ON | No | ❌ Not enforced |
| Subscription alerts | ON | Yes | ⚠️ No preference management |
| Profile activity (views, reviews) | ON | Yes | ❌ No preference management |
| Quote requests | ON | Yes | ❌ No preference management |
| Promotional / marketing | OFF | Yes | ❌ No preference management |

---

## Gap Analysis

### Gap 1 — Notification Triggers Not Wired to Events
**Files:** `backend/src/controllers/reviewController.js`, `backend/src/controllers/contactController.js`, `backend/src/controllers/complaintController.js`, `backend/src/controllers/kycController.js`

The notification service (`pushNotification.js`, `email.js`, `sms.js`) exists but is not called in most event handlers.

**Fix — Wire the following:**
1. `reviewController.js` → after inserting review → FCM push to professional
2. `contactController.js` → after contact with `quote_request` type → FCM push + SMS to professional
3. `contactController.js` → after any contact → record profile view notification
4. `complaintController.js` → after filing complaint → email to reported professional
5. `kycController.js` → after admin approves/rejects → SMS + push to professional
6. Admin action (suspend/ban) → email + SMS to affected user
7. Complaint resolution → push to reporter

### Gap 2 — Notification Preferences Not Managed
**Files:** `frontend/src/pages/Settings.jsx`, `backend/src/routes/users.js`  
**Issue:** Users cannot control which notifications they receive.  
**Fix:**
1. Add `notification_preferences` JSONB column to users table
2. `PUT /users/notification-preferences` endpoint
3. Settings page: toggle for each notification category
4. Notification dispatch function checks preferences before sending

### Gap 3 — Profile View Notification Not Implemented
**Files:** `backend/src/controllers/professionalController.js`  
**Issue:** "Someone viewed your profile today" push notification not sent.  
**Fix:**
1. On `GET /professionals/:id` when viewed by an authenticated customer: log to `profile_views` table (professional_id, viewer_id, viewed_at)
2. Daily aggregation cron: "Your profile was viewed X times today" push at 8 PM

### Gap 4 — DLT Registration for Indian SMS (TRAI Compliance)
**File:** `backend/src/services/sms.js`  
**Issue:** PRD §19.4 requires all SMS sent via DLT-registered sender ID. Promotional SMS only to opted-in users.  
**Fix:**
1. Register templates with MSG91 DLT portal (documentation needed)
2. Use template IDs in SMS API calls (not free-form text)
3. Mark transactional vs promotional in each SMS dispatch call
4. Filter promotional SMS by user opt-in preference

---

## Implementation Tasks (Sprint 1)

### Backend
- [ ] **T1** Wire review → FCM push to professional in `reviewController.js`
- [ ] **T2** Wire quote_request contact → FCM push + SMS to professional in `contactController.js`
- [ ] **T3** Wire KYC approval/rejection → SMS + push in `kycController.js`
- [ ] **T4** Wire complaint filing → email to reported professional in `complaintController.js`
- [ ] **T5** Wire complaint resolution → push to reporter
- [ ] **T6** Wire admin account suspension → email + SMS to user
- [ ] **T7** Add `notification_preferences` JSONB to users table (migration)
- [ ] **T8** `PUT /users/notification-preferences` endpoint
- [ ] **T9** Add profile view logging + daily aggregation cron

### Frontend
- [ ] **T10** Add notification preferences toggles to `Settings.jsx`
- [ ] **T11** Load and save preferences from API

### Documentation
- [ ] **T12** Add DLT template registration guide to SECRETS.md
- [ ] **T13** Add MSG91 template IDs to `.env.example`

---

## Acceptance Criteria
- [ ] Professional receives push notification within 5 seconds of a review being submitted
- [ ] Professional receives push + SMS on new quote request
- [ ] KYC approved → professional receives "Your profile is live!" SMS and push
- [ ] Complaint filed → professional receives "A complaint has been filed" email within 1 minute
- [ ] Account suspended → user receives email with reason and appeal link
- [ ] User can disable optional notification categories in Settings
- [ ] Profile view count push sent to professional daily at 8 PM if >0 views
