# PRD §16 — UI/UX Design Requirements
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §16  
> **Current Score:** 7 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 1 (UX polish)

---

## Design Principles Status (PRD §16.1)

| Principle | Status |
|---|---|
| Trust-first: every screen reinforces verified & safe | ✅ Verified badge prominent |
| Discovery-focused: effortless browsing | ✅ Category grid + search |
| Professional dignity: workers feel respected | ✅ Profile design is dignified |
| Low-literacy friendly: icons + minimal text | ⚠️ Some dense text areas |
| Speed above all: search < 2s, profile < 1.5s | ⚠️ Not load-tested |

---

## Screen-by-Screen Requirements Status (PRD §16.2)

### Home Screen
| Requirement | Status |
|---|---|
| Category grid (6–8 categories visible) | ✅ |
| Featured professionals carousel (auto-scrolling) | ✅ |
| Search bar with placeholder text | ✅ |
| Location selector (Showing results for [City]) | ⚠️ No location selector |
| Recently viewed professionals (logged-in) | ❌ Not implemented |

### Search Results Screen
| Requirement | Status |
|---|---|
| Filter bar visible without scrolling | ✅ |
| Result card: photo, name, verified badge, rating, review count, distance, skills, price | ⚠️ Distance missing unless GPS provided |
| Verified Only toggle prominently placed (default ON) | ✅ |
| Map view toggle (Phase 2) | ❌ Phase 2 |

### Professional Profile Screen
| Requirement | Status |
|---|---|
| Hero: large photo, name, verified badge, star rating, Trust Index badge | ⚠️ Trust Index badge missing |
| Sticky "Contact" CTA throughout scrolling | ⚠️ Button may not be sticky |
| Portfolio: horizontal scrollable with full-screen tap | ✅ |
| Stats row: Completed Jobs / Years Experience / Response Rate / Repeat Customers | ⚠️ Response rate + Repeat Customers missing |
| Reviews: sorted by recency; Overall + Recent Rating; pro reply shown | ⚠️ Recent rating not shown |
| Skills and service area tags | ✅ |
| Certifications: badge-style display | ✅ |

### Professional Dashboard
| Requirement | Status |
|---|---|
| Profile completeness meter | ❌ Not implemented |
| Quick stats: Profile Views (7d/30d), Quote Requests, Rating, Reviews | ⚠️ Views may not be tracked |
| Review management with reply option | ✅ |
| Portfolio management: drag-to-reorder, delete, add | ⚠️ Reorder missing |
| Subscription status: current plan, expiry, upgrade CTA | ✅ |
| Availability toggle at top | ✅ |

---

## Accessibility Requirements (PRD §16.3)

| Requirement | Standard | Status |
|---|---|---|
| Colour contrast | WCAG AA (4.5:1 normal, 3:1 large) | ⚠️ Not audited |
| Touch target size | Min 44x44 points | ⚠️ Not audited |
| Screen reader support (TalkBack/VoiceOver) | All images alt-text; form labels | ⚠️ Not audited |
| Font scaling up to 150% | UI usable at 150% system font | ⚠️ Not tested |
| Language | English + Hindi (Phase 1) | ✅ Flutter has Hindi; Web is English-only |

---

## Performance Requirements (PRD §16.4)

| Metric | Target | Status |
|---|---|---|
| App launch (cold) | < 2.5s | ⚠️ Not measured |
| Search results | < 1.5s | ⚠️ Not load-tested |
| Profile page | < 1.0s | ⚠️ Not load-tested |
| Image first render | < 0.8s | ⚠️ No CDN optimisation confirmed |
| API response P95 | < 300ms | ⚠️ Not load-tested |
| Uptime SLA | 99.5% | ⚠️ No uptime monitoring |

---

## Gap Analysis

### Gap 1 — Recently Viewed Professionals Not Implemented
**File:** `frontend/src/pages/Home.jsx`, `backend/src/routes/professionals.js`  
**Fix:**
1. On `GET /professionals/:id`: if authenticated, store professional_id in `recently_viewed` Redis list (user_id → [pro_ids], TTL 30 days)
2. `GET /users/recently-viewed` → returns last 5 professional profiles
3. Home screen: show "Recently Viewed" horizontal scroll section below featured carousel

### Gap 2 — Location Selector Not on Home Screen
**Fix:** Add "Showing results for [City] — Change?" bar below search bar on Home.jsx.  
Store selected city in localStorage/context. All searches default to selected city.

### Gap 3 — Sticky Contact Button on Profile
**File:** `frontend/src/pages/ProfessionalProfile.jsx`  
**Fix:** Add CSS `position: sticky; bottom: 0;` to the Contact button container. Ensure it stays visible during scroll through long profiles.

### Gap 4 — Profile Completeness Meter Missing
**File:** `frontend/src/pages/Dashboard.jsx`  
**Fix:** See PRD_SEC01_Registration.md Gap 4. Backend provides `profile_completeness` %; frontend renders progress bar with checklist.

### Gap 5 — Accessibility Audit Not Done
**Fix:**
1. Run axe-core accessibility scanner on key pages
2. Add `alt` text to all portfolio images
3. Ensure all form inputs have associated `<label>` elements
4. Check colour contrast ratios with Lighthouse audit
5. Add `aria-label` to all icon-only buttons

---

## Implementation Tasks (Sprint 1 — UX Polish)

### Frontend
- [ ] **T1** Add recently-viewed professionals section to Home.jsx
- [ ] **T2** Add city location selector to Home.jsx
- [ ] **T3** Make Contact CTA sticky on ProfessionalProfile.jsx
- [ ] **T4** Add profile completeness progress bar to Dashboard.jsx
- [ ] **T5** Add Trust Index badge on ProfessionalProfile.jsx
- [ ] **T6** Add "Response Rate" and "Repeat Customer %" to profile stats row
- [ ] **T7** Show "Recent: X.X ⭐" rating badge on profile
- [ ] **T8** Run Lighthouse audit on Home, Search, Profile pages
- [ ] **T9** Fix any WCAG AA contrast failures from Lighthouse audit
- [ ] **T10** Add alt text to all dynamic images in portfolio/profile

### Backend
- [ ] **T11** Store recently-viewed list in Redis on profile GET
- [ ] **T12** `GET /users/recently-viewed` endpoint

---

## Acceptance Criteria
- [ ] Home screen shows up to 5 recently viewed professionals for logged-in users
- [ ] City selector on home screen persists to localStorage; all searches use it
- [ ] "Contact" button remains visible at bottom of screen while scrolling profile
- [ ] Profile completeness meter shows % and checklist in professional dashboard
- [ ] Lighthouse accessibility score ≥ 85 on Home, Search Results, and Profile pages
- [ ] All portfolio images have descriptive alt text
