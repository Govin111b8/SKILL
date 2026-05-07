# Tech Supplement §G — Enterprise Security Architecture
## Implementation Plan (Pin-to-Pin)

> **Reference:** SkillConnect_Technical_Supplement_v1.0.docx §G  
> **Current Score:** 6 / 10  
> **Target Score:** 9 / 10  
> **Sprint:** Sprint 3

---

## §G.1 Security Controls Audit

| Control | Specification | Status |
|---|---|---|
| JWT access token (15-min expiry) | ✅ | ✅ Implemented |
| JWT refresh token (30-day, httpOnly cookie) | ✅ | ✅ Implemented |
| Refresh token rotation | ✅ | ✅ Implemented |
| Token reuse detection | ✅ | ⚠️ May not be implemented |
| Account lockout after 5 failed logins | ✅ | ❌ Missing |
| Rate limiting (100 req/min per IP, 1000 per auth user) | ✅ | ✅ Implemented |
| SQL injection prevention (parameterised) | ✅ | ✅ Implemented |
| XSS prevention (DOMPurify + CSP) | ✅ | ⚠️ CSP in nginx; DOMPurify not confirmed on frontend |
| CSRF (SameSite=Strict + CSRF token) | ✅ | ⚠️ SameSite may be set; no CSRF token |
| File upload: MIME validation | ✅ | ✅ Implemented |
| File upload: ClamAV antivirus | ✅ | ❌ Missing |
| AES-256 for govt ID numbers | ✅ | ✅ Implemented |
| bcrypt for passwords | ✅ | ✅ Implemented |
| TLS 1.3 + HSTS | ✅ | ✅ nginx config |
| Certificate pinning in mobile app | ✅ | ❌ Not implemented |
| PII masking in logs | ✅ | ⚠️ Pino logger; PII masking not confirmed |
| Signed Docker images (Cosign) | ✅ | ❌ Missing |
| SAST in CI (Semgrep) | ✅ | ❌ Missing (Trivy exists, not Semgrep) |

---

## §G.2 JWT Architecture Status

### Access Token
| Requirement | Status |
|---|---|
| sub: user_uuid | ✅ |
| role: customer/professional/admin | ✅ |
| professional_id | ✅ |
| session_id (links to refresh family) | ⚠️ May not track family |
| iss: skillconnect-auth-v1 | ⚠️ Not confirmed |
| 15-minute expiry | ✅ |

### Refresh Token Reuse Detection
**Issue:** Tech Supplement specifies: if refresh token is reused after rotation, trigger account security alert and revoke entire session family.  
**Fix:**
1. Store `refresh_token_family` in Redis: `{family_id: [token_hash_1, token_hash_2, ...]}`
2. On refresh: check if current token is in family; if already used → revoke family + send security alert email

---

## §G.3 Data Classification Status

| Class | Examples | Protection | Status |
|---|---|---|---|
| Top Secret | Govt ID numbers, selfie, ID docs | AES-256 + KMS + private S3 + signed URL | ⚠️ AES-256 ✅; KMS ❌; signed URLs ✅; private S3 not confirmed |
| Confidential | Phone, email, passwords, payments | Encrypted at rest (RDS), TLS, masked in logs | ⚠️ Logs not confirmed masked |
| Internal | Bio, portfolio, reviews | TLS + soft-delete | ✅ |
| Public | Name, category, rating, city | No special encryption | ✅ |

---

## §G.4 OWASP Top 10 Mitigation Status

| OWASP Risk | Mitigation | Status |
|---|---|---|
| A01 Broken Access Control | Resource ownership middleware; RBAC | ✅ |
| A02 Cryptographic Failures | TLS 1.3; AES-256; bcrypt; no secrets in git | ⚠️ Gitleaks in CI ✅; KMS ❌ |
| A03 Injection | Parameterised queries | ✅ |
| A04 Insecure Design | Threat modelling | ❌ No THREAT_MODEL.md |
| A05 Security Misconfiguration | S3 public access blocked | ⚠️ Not verified in setup |
| A06 Vulnerable Components | npm audit in CI; Dependabot | ✅ |
| A07 Auth & Session Failures | JWT rotation; lockout after 5 failures | ⚠️ Lockout missing |
| A08 Software & Data Integrity | Signed Docker images | ❌ Missing |
| A09 Logging & Monitoring | Structured JSON logs; Prometheus | ⚠️ PII masking not confirmed |
| A10 SSRF | No user-controllable URLs server-side | ✅ |

---

## §G.5 Penetration Testing Schedule

| Activity | Frequency | Status |
|---|---|---|
| SAST (Semgrep) | Every PR | ❌ Missing |
| Dependency scan (npm audit) | Every PR | ✅ |
| Container scan (Trivy) | Every deploy | ✅ |
| DAST (OWASP ZAP) | Monthly | ❌ Not configured |
| Manual pen test | Every 6 months | ❌ Not done |
| Bug bounty | Phase 2 | ❌ Not launched |

---

## Implementation Tasks (Sprint 3)

### Backend
- [ ] **T1** Add account lockout: Redis counter; lock after 5 failures; 15-min cooldown
- [ ] **T2** Add refresh token family tracking in Redis (reuse detection)
- [ ] **T3** Send security alert email on token reuse detection
- [ ] **T4** Add PII masking to Pino logger (redact phone, email, name from logs)
- [ ] **T5** Implement ClamAV upload scanning (see TECH_D)

### CI/CD
- [ ] **T6** Add Semgrep SAST to GitHub Actions workflow
- [ ] **T7** Add Cosign image signing after Docker build
- [ ] **T8** Add OWASP ZAP DAST stage to CI (against staging)

### Mobile
- [ ] **T9** Add certificate pinning to Flutter app (http package pin)
- [ ] **T10** Send device fingerprint header on all API calls

### Documentation
- [ ] **T11** Create `THREAT_MODEL.md` with data flow + threat register
- [ ] **T12** Document token reuse detection in security architecture section

---

## Acceptance Criteria
- [ ] 6 failed login attempts → account locked 15 minutes; security email sent
- [ ] Reusing a rotated refresh token triggers session family revocation and alert email
- [ ] Semgrep CI stage blocks critical/high findings in PRs
- [ ] PII (phone, email) appears as `[MASKED]` in all application logs
- [ ] THREAT_MODEL.md documents top 10 threat vectors with mitigations
- [ ] ClamAV rejects infected test file upload (use EICAR test file)
