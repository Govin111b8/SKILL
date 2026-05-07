# PRD §11 — Security & Verification System
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §11; Tech Supplement §G  
> **Current Score:** 7 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 3

---

## Verification Pipeline Status (PRD §11.1)

| Stage | Method | Technology | Status |
|---|---|---|---|
| Stage 1: Phone OTP | SMS OTP | MSG91/Twilio | ✅ Implemented |
| Stage 2: Government ID | Upload front+back | S3 + admin review | ✅ Implemented |
| Stage 3: Selfie Match | Live selfie vs ID | HyperVerge/Rekognition | ⚠️ Mock mode default |

### Anti-Spoofing
| Requirement | Status |
|---|---|
| Liveness detection (blink/smile prompt) | ❌ Not implemented |
| Static image rejection | ❌ (mock doesn't test this) |

---

## Security Gaps

### Gap 1 — Liveness Detection Not Implemented
**File:** `backend/src/services/faceMatch.js`, mobile onboarding screen  
**Fix:**
- HyperVerge SDK supports liveness detection natively
- Flutter mobile: use HyperVerge Flutter SDK or camera challenge (ask user to blink)
- Backend: pass `liveness_check=true` parameter to HyperVerge API

### Gap 2 — Device Fingerprint Check Not Implemented
**File:** `backend/src/controllers/authController.js`  
**Fix:**
1. Accept `X-Device-Fingerprint` header (hash of device identifiers, computed on client)
2. On registration: check `banned_devices` table
3. On suspicious login: log to `device_fingerprints` table
4. Flutter: use `device_info_plus` package; Web: use FingerprintJS (open source)

### Gap 3 — Review Fraud Prevention Gaps
| Rule | Status |
|---|---|
| Interaction gate | ✅ |
| 1 review per customer | ✅ |
| 1h–60d timing window | ❌ |
| Velocity detection (>5 in 24h) | ❌ |
| Sentiment/hate speech filter | ❌ |
**Fix:** See PRD_SEC06_Reputation.md

### Gap 4 — ClamAV Antivirus on File Uploads
**File:** `backend/src/controllers/uploadController.js`  
**Issue:** PRD §11.4: "antivirus scan via ClamAV before storage."  
**Fix:**
1. Install `clamscan` Node package: `npm install clamscan`
2. Add virus scan step in upload pipeline before S3 storage
3. If infected: reject upload with 422; log to audit
4. ClamAV runs as sidecar in Docker Compose / K8s (image: `clamav/clamav:latest`)

### Gap 5 — CSRF Protection Not Confirmed
**File:** `backend/src/app.js`  
**Issue:** PRD §11.5 requires SameSite=Strict cookies and CSRF token for state-changing web requests.  
**Fix:** Verify `SameSite=Strict` is set on all cookies. Add `csurf` middleware (or equivalent CSRF token) for all non-GET endpoints on the web frontend.

### Gap 6 — SQL Injection: Parameterized Queries Only
**Status:** ✅ All queries use parameterized `$1, $2` syntax  
**Action:** Add `sqlfluff` or `semgrep` rule to CI to detect string concatenation in SQL queries.

### Gap 7 — OWASP A04: Insecure Design — No Threat Model
**Fix:** Create `THREAT_MODEL.md` documenting:
- Data flow diagram
- Trust boundaries
- Top 10 threat vectors with mitigations
- "Abuse cases" for review manipulation, fake profiles, data exfiltration

### Gap 8 — Account Lockout After 5 Failed Login Attempts
**File:** `backend/src/controllers/authController.js`  
**Issue:** Progressive delay after failed logins not confirmed.  
**Fix:** 
1. Track failed login count in Redis per user per hour
2. After 3 failures: 30-second delay
3. After 5 failures: account temporarily locked (15 min); alert user by email

### Gap 9 — Signed Docker Images Not Implemented
**Issue:** Tech Supplement §G.4 (A08) requires signed Docker images with Cosign.  
**Fix:** Add `cosign sign` step to CI/CD after Docker build. Store public key in repository. Verify signature in K8s admission webhook (Phase 2).

---

## Implementation Tasks (Sprint 3)

### Backend
- [ ] **T1** Wire liveness detection in faceMatch service (HyperVerge liveness API)
- [ ] **T2** Add device fingerprint check on registration (X-Device-Fingerprint header)
- [ ] **T3** Add ClamAV virus scan in upload pipeline (Docker Compose sidecar)
- [ ] **T4** Add account lockout after 5 failed logins (Redis counter + 15-min lock)
- [ ] **T5** Add OTP audit log to DB (otp_log table)
- [ ] **T6** Verify/add SameSite=Strict on all cookies
- [ ] **T7** Add review timing window enforcement (1h–60d)
- [ ] **T8** Add review velocity detection (>5 in 24h → held)

### CI/CD
- [ ] **T9** Add Semgrep SAST to GitHub Actions (already has Trivy; add Semgrep for code)
- [ ] **T10** Add Cosign Docker image signing step to CI

### Documentation
- [ ] **T11** Create `THREAT_MODEL.md` with data flow diagram and threat register
- [ ] **T12** Update `SECRETS.md` with HyperVerge liveness setup

### Mobile (Flutter)
- [ ] **T13** Add `device_info_plus` package; send device fingerprint on registration/login
- [ ] **T14** Implement camera challenge (blink/smile) for liveness in KYC screen

---

## Acceptance Criteria
- [ ] Liveness detection rejects static photo (mock test: `liveness_score < 50` → rejected)
- [ ] ClamAV scans files before upload; infected file returns 422
- [ ] After 5 failed logins: account locked 15 min; email alert sent
- [ ] Device fingerprint header processed; banned device flagged for review
- [ ] SAST (Semgrep) runs in CI on every PR; blocks critical findings
- [ ] Docker images signed with Cosign in CI pipeline
