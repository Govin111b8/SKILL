# PRD §20 — Roadmap & Milestones
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §20  
> **Current Score:** 7 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Ongoing reference document

---

## Development Milestone Status (PRD §20.1)

| Milestone | Target | Deliverables | Status |
|---|---|---|---|
| M1: Foundation | Month 1–2 | Tech stack setup, DB schema, auth, basic user registration with OTP | ✅ Complete |
| M2: Professional Core | Month 2–3 | Professional onboarding, ID + selfie upload, admin verification dashboard | ✅ Complete |
| M3: Discovery Engine | Month 3–4 | Category system, search with filters, profile display, portfolio upload | ✅ Complete |
| M4: Reputation Layer | Month 4–5 | Interaction logging, review submission, rating calculation, reputation score | ⚠️ Partial — Trust Index incomplete |
| M5: Monetisation | Month 5 | Subscription plans, Razorpay integration, plan management | ⚠️ Partial — annual plans, grace period, tier limits missing |
| M6: Beta Launch | Month 6 | Closed beta with 500 professionals + 2,000 customers | 🔲 Infrastructure ready; not launched |
| M7: Public Launch | Month 7 | Full city launch; 5,000 verified professionals | 🔲 Not launched |
| M8: Analytics & Trust | Month 8–9 | Complaint system v2, two-way reputation, advanced moderation | ⚠️ Complaint system v1 done; v2 gaps |
| M9: Expansion Ready | Month 10–12 | Multi-city support, referral programme, analytics dashboard | ⚠️ Referrals done; city expansion missing |
| M10: Scale | Month 13–18 | AI recommendations, in-app messaging (Phase 3 preview) | ⚠️ Messaging built; AI is stub |

---

## Feature Prioritisation Matrix Status (PRD §20.2)

| Feature | Priority | Phase | Status |
|---|---|---|---|
| User registration + OTP | Must Have | 1 | ✅ |
| Professional ID + selfie verification | Must Have | 1 | ✅ (mock face-match) |
| Category + search + filter | Must Have | 1 | ✅ |
| Professional profile + portfolio | Must Have | 1 | ✅ |
| Contact reveal (phone/WhatsApp) | Must Have | 1 | ✅ |
| Review + rating system | Must Have | 1 | ✅ |
| Reputation score (Trust Index) | Must Have | 1 | ⚠️ 0–5 scale; needs 0–100 |
| Subscription + Razorpay | Must Have | 1 | ⚠️ Monthly only; missing features |
| Admin verification + moderation | Must Have | 1 | ✅ |
| Push notifications (FCM) | Must Have | 1 | ⚠️ Service ready; triggers not wired |
| Two-way customer reputation | Should Have | 2 | ⚠️ Partial |
| Professional analytics dashboard | Should Have | 2 | ⚠️ Basic |
| Complaint system v2 + appeals | Should Have | 2 | ❌ |
| Referral programme | Should Have | 2 | ✅ |
| Map view | Should Have | 2 | ❌ |
| In-app messaging | Nice to Have | 3 | ✅ (built ahead) |
| AI recommendations | Nice to Have | 3 | ⚠️ Stub |
| Video consultation | Nice to Have | 3 | ❌ |
| Enterprise / B2B portal | Future | 3+ | ❌ |

---

## Sprint Mapping to Milestones

| Sprint | Work | Milestone Impact |
|---|---|---|
| Sprint 1 | Core Feature Completion (Reputation, Notifications, UX) | Completes M4, M5 partial |
| Sprint 2 | Database & API Gaps, Monetisation | Completes M5, M8 partial |
| Sprint 3 | Security Hardening, Moderation v2 | Completes M8 |
| Sprint 4 | Performance & Observability | Production readiness |
| Sprint 5 | Architecture Evolution (BullMQ, TypeScript, SEO) | M10 partial |
| Sprint 6 | Compliance & Growth (Legal, GTM, City expansion) | Completes M9 |
| Sprint 7 | Disaster Recovery, DR drills, multi-region | Production SLA |

---

## Immediate Next Steps to Reach 10/10

### Priority 1 — Must Have (Phase 1 Completers)
1. **Trust Index 0–100** recalculation (PRD_SEC06, PRD_SEC13)
2. **Notification triggers** wired to all events (PRD_SEC12)
3. **Subscription tier limits** enforced in portfolio (PRD_SEC14, PRD_SEC05)
4. **Missing API endpoints** (18 from Tech Supplement §A.2) (PRD_SEC09)
5. **Real face-match** (HyperVerge) in production (PRD_SEC01, PRD_SEC11)

### Priority 2 — Should Have (Phase 2 Completers)
6. **Appeal system** for suspensions/bans (PRD_SEC13)
7. **Annual subscription billing** with 33% discount (PRD_SEC14)
8. **SEO**: sitemap + JSON-LD + og: tags (PRD_SEC15)
9. **Waitlist + city activation** system (PRD_SEC15)
10. **Legal content pages** (PRD_SEC19)

### Priority 3 — Production Readiness
11. **BullMQ** job queue replacing in-memory (PRD_SEC10)
12. **ClamAV** antivirus on uploads (PRD_SEC11)
13. **Load testing** with k6 (TECH_H)
14. **Disaster recovery** drills (TECH_J)
15. **RDS automated backups** (TECH_J)
