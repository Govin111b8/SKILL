# SkillConnect — Threat Model

> **Framework:** STRIDE | **Updated:** May 2026 | **Classification:** Internal

## Assets Under Protection

| Asset | Sensitivity | Threat Level |
|---|---|---|
| User PII (name, phone, email) | High | DPDPA §11 regulated |
| Government ID documents (Aadhaar, PAN) | Critical | KYC — 12-month retention |
| Payment data (booking amounts, escrow) | High | PCI-DSS adjacent |
| Professional verification status | High | Trust & Safety |
| JWT tokens / refresh tokens | High | Authentication bypass risk |
| Admin credentials | Critical | Full platform access |
| Database credentials | Critical | Complete data access |
| API keys (Razorpay, SendGrid, FCM) | High | Service abuse / fraud |

---

## STRIDE Threat Analysis

### Spoofing (Identity)
| Threat | Mitigation |
|---|---|
| JWT token theft from localStorage | Short expiry (15min) + refresh token rotation |
| Account takeover via credential stuffing | Account lockout (5 attempts), Redis-backed |
| Fake professional impersonation | KYC verification with face match |
| Admin impersonation | `is_admin` flag + separate admin auth flow |

### Tampering (Data Integrity)
| Threat | Mitigation |
|---|---|
| Review manipulation (fake reviews) | Velocity detection, timing window (1h-60d), profanity filter |
| Trust Index manipulation | Server-side calculation only, nightly recalc |
| Payment amount tampering | Server-side amount calculation, webhook signature verification |
| Portfolio media replacement | Signed S3 URLs, server-side file type validation |

### Repudiation (Non-repudiation)
| Threat | Mitigation |
|---|---|
| Denying booking completion | Booking FSM with timestamps, audit_log table |
| Denying KYC submission | verification_audit trail |
| Denying data export request | soft_deletes_log + audit_log |

### Information Disclosure (Confidentiality)
| Threat | Mitigation |
|---|---|
| PII in server logs | Pino redact (phone, email, govt_id at all nesting levels) |
| Government ID exposure | AES-256-GCM encryption at rest, masked in API responses |
| Database credentials in codebase | .env files + GitHub secret scanning (Gitleaks) |
| API key exposure | SEMGREP_APP_TOKEN, RAZORPAY secrets stored in K8s Secrets |
| Cross-tenant data leakage | Row-level WHERE user_id = $1 on all queries |

### Denial of Service
| Threat | Mitigation |
|---|---|
| API flooding | express-rate-limit (100 req/15min per IP) |
| Search scraping | Rate limiting + optional CAPTCHA trigger |
| WebSocket flood | Per-user connection limit, heartbeat kill |
| Upload bomb | Multer file size limits (5MB images, 50MB video) |

### Elevation of Privilege
| Threat | Mitigation |
|---|---|
| Customer accessing admin routes | `requireAdmin` middleware checks `is_admin` flag |
| Customer accessing professional APIs | `authorize('professional')` middleware |
| SQL injection | Parameterized queries throughout (no raw string interpolation) |
| Path traversal in uploads | Multer + UUID-based S3 keys (no user-controlled paths) |

---

## Attack Surface

### External
- HTTPS only (HSTS + TLS 1.2+ enforced by nginx)
- No direct database access from internet
- API gateway enforces rate limiting and auth

### Internal
- PgBouncer mediates all DB connections
- Redis not exposed outside cluster
- Admin endpoints require `is_admin=true` + JWT

### CI/CD
- Gitleaks: prevents secrets in commits
- Semgrep SAST: NodeJS + OWASP-top-ten rulesets
- Trivy: container image CVE scanning + SARIF upload
- npm audit: fails pipeline on critical vulnerabilities

---

## Known Residual Risks

| Risk | Status | Owner |
|---|---|---|
| ClamAV antivirus on uploads | Planned (Sprint 7) | Backend Team |
| Rate limiting granularity per user (currently per IP) | Planned | Backend Team |
| Cosign Docker image signing | Planned | DevOps Team |
| PagerDuty alerting integration | Planned | DevOps Team |
| Multi-region failover | Planned (RDS Multi-AZ) | Infrastructure |
| OTP brute force on phone login | Partial (5-attempt limit) | Backend Team |

---

## Security Contacts

- **DPO:** dpo@skillconnect.in
- **Security disclosures:** security@skillconnect.in
- **Bug bounty:** We responsibly disclose, no public program yet
