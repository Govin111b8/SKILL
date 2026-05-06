# SkillConnect — Platform Change Record

> **Document Type:** Formal Deviation Record  
> **Document Date:** 2026-05-06  
> **Status:** Approved (Founding Team)  
> **Reviewed Against:** SkillConnect_PRD_v1.0.docx §5.2, SkillConnect_Technical_Supplement_v1.0.docx

---

## PRD Statement (§5.2 — What SkillConnect Is NOT)

The Product Requirements Document explicitly states:

> *"NOT a payment gateway or escrow service"*  
> *"NOT a job assignment or workforce management platform"*  
> *"NOT an agency or employer — professionals remain fully independent"*  
> *"NOT responsible for the quality of work performed offline"*

---

## Deviation Summary

The following features were built **beyond Phase 1 scope** as defined in the PRD:

| Feature | PRD Phase | Built In | Deviation Severity |
|---|---|---|---|
| Booking system (create/list/detail/state machine) | Phase 3 | v1.0 | 🟡 Medium |
| Warranties module (claim workflow) | Not in PRD | v1.0 | 🔴 High |
| Emergency SOS dispatch | Not in PRD | v1.0 | 🟡 Medium |
| Agent commission system | Not in PRD | v1.0 | 🔴 High |
| In-app messaging/chat | Phase 3 | v1.0 | 🟡 Medium |
| Dispute resolution system | Phase 3 | v1.0 | 🟡 Medium |

---

## Decision: Retain as "Extended Platform" Features

After review with the founding team, the decision is to **retain** all extended features with the following conditions:

1. **Phase 1 launch (discovery-only mode):** Core Phase 1 is presented as the discovery layer — search, verified profiles, contact reveal, portfolio, subscriptions. Extended features are available but not promoted in onboarding.

2. **Feature flags:** All extended features gated behind `FEATURE_*` environment variables (see below). This allows A/B testing and gradual rollout.

3. **Legal clarity:** Terms of Service updated to clarify SkillConnect's role as an optional facilitator — not a guarantor — for bookings. Professionals remain independent contractors.

4. **Liability shield maintained:** Payment escrow uses Razorpay (regulated entity). SkillConnect does not hold funds directly.

---

## Feature Flag Configuration

Set the following environment variables in production to control feature availability:

```bash
# Phase 1 Core (always enabled)
FEATURE_SEARCH=true
FEATURE_PROFILES=true
FEATURE_CONTACT_REVEAL=true
FEATURE_PORTFOLIO=true
FEATURE_SUBSCRIPTIONS=true
FEATURE_REVIEWS=true
FEATURE_KYC=true

# Extended Features (enable gradually)
FEATURE_BOOKINGS=true          # Full booking flow with escrow
FEATURE_CHAT=true              # In-app WebSocket messaging
FEATURE_DISPUTES=true          # Formal dispute resolution
FEATURE_EMERGENCIES=false      # Emergency SOS dispatch (enable after testing)
FEATURE_WARRANTIES=false       # Post-booking warranties (enable after legal review)
FEATURE_AGENTS=false           # Agent commission network (enable after compliance review)
```

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| User confusion about platform scope | Medium | Medium | Clear onboarding, FAQ, TOS |
| Warranty claims creating liability | Low | High | TOS disclaimer, agent-managed only |
| Agent commission tax compliance | Medium | High | GST invoicing system (Sprint 6) |
| Emergency SOS false positives | Medium | Medium | Admin verification before dispatch |

---

## Phase 1 — Core Discovery Feature Checklist

These are the features that define SkillConnect Phase 1 per the PRD:

- [x] Verified professional profiles (govt ID + selfie match)
- [x] 3-level category taxonomy (8 categories, 50+ sub-categories)
- [x] Search with 8 filters + 6-factor ranking algorithm
- [x] Portfolio gallery (photos, videos, project cards)
- [x] Two-way reputation system (customer rates pro + pro rates customer)
- [x] Contact reveal (phone + WhatsApp) for logged-in customers
- [x] Subscription tiers (Basic / Premium / Featured)
- [x] GST-compliant invoices for subscriptions
- [x] Admin KYC verification queue
- [x] Complaint/moderation system

---

## Sign-off

| Role | Name | Date |
|---|---|---|
| Product Owner | ___________________ | 2026-05-06 |
| Tech Lead | ___________________ | 2026-05-06 |
| Legal Review | ___________________ | ___________ |

---

*This document is maintained in the repository root as `PLATFORM_CHANGE_RECORD.md` and must be updated whenever a feature deviates from the PRD baseline.*
