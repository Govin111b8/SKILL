# PRD §15 — Go-to-Market & Growth Strategy
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §15  
> **Current Score:** 4 / 10  
> **Target Score:** 8 / 10 (GTM is partly operational, not technical)  
> **Sprint:** Sprint 6

---

## GTM Features Status

| Feature | PRD Phase | Status |
|---|---|---|
| Waitlist system for cities not yet live | Phase 1 | ❌ Not implemented |
| Referral programme (professional → 1 month free Premium) | Phase 2 | ✅ Backend implemented |
| Customer referral ("SkillPoints" for referring friends) | Phase 2 | ⚠️ Referral code exists; SkillPoints reward unclear |
| City activation by admin (notify waitlist) | Phase 2 | ❌ Not implemented |
| First 100 waitlist professionals: 1 month free Premium | Phase 2 | ❌ Not implemented |
| Introductory pricing (first 6 months) | Phase 1 | ❌ Not implemented |
| SEO: sitemap.xml | Phase 1 | ❌ Not implemented |
| SEO: structured data (JSON-LD) | Phase 1 | ❌ Not implemented |
| SEO: social meta tags (og:) | Phase 1 | ❌ Not implemented |
| Professional onboarding nudges | Phase 1 | ❌ Not implemented |
| Profile Boost reward (7 days free on 60% completion) | Phase 1 | ❌ Not implemented |

---

## Gap Analysis

### Gap 1 — Waitlist System Not Implemented
**File:** `backend/src/routes/growth.js` (likely placeholder)  
**Fix:**
1. Create `waitlist` table (email, phone, city, service_interest, source, created_at)
2. `POST /waitlist` — public endpoint; email dedup; confirmation email sent
3. Admin: `GET /admin/waitlist?city=X` — view waitlist by city; export CSV
4. When admin activates a new city: trigger `POST /admin/cities/:id/activate` → send SMS/push to all waitlist entries for that city

### Gap 2 — City Activation System Missing
**Fix:**
1. Create `supported_cities` table (id, name, state, is_active, activated_at, waitlist_offer_sent)
2. Admin endpoint: `PUT /admin/cities/:id/activate`
3. On activation: queue background job to notify all waitlist users for that city
4. First 100 professional signups from that city get 1 month free Premium (via referral_code)

### Gap 3 — SEO Infrastructure Missing
**Files:** `frontend/src/`, `backend/src/routes/seo.js`  
**Fix:**
1. Add React Helmet to frontend: `npm install react-helmet-async`
2. Dynamic meta tags on Professional Profile page: `og:title`, `og:description`, `og:image`, `og:url`
3. Backend `GET /sitemap.xml`: lists all active verified professional profile URLs with `lastmod`
4. JSON-LD on professional profile: `schema.org/LocalBusiness` + `schema.org/Person`
5. `robots.txt` with correct sitemap URL

### Gap 4 — SkillPoints Customer Referral Reward Unclear
**File:** `backend/src/controllers/referralController.js`  
**Issue:** "SkillPoints" reward for customers who refer friends. What are SkillPoints? The backend has referral_codes but the reward type for customers is not defined.  
**Fix:**
1. Define SkillPoints as account credit (non-monetary, cosmetic in Phase 1)
2. Add `skillpoints_balance` INTEGER to users table
3. On successful referral (referred user makes first contact): award 50 SkillPoints to referrer
4. SkillPoints displayed in Referrals.jsx as "Ambassador Points"
5. Phase 2: SkillPoints unlock profile-related perks (extended history, priority search)

### Gap 5 — Professional Onboarding Nudge Missing
**See:** PRD_SEC01_Registration.md Gap 4 (same issue, cross-referenced)

---

## Implementation Tasks (Sprint 6)

### Backend
- [ ] **T1** Create `waitlist` table + `POST /waitlist` public endpoint
- [ ] **T2** Create `supported_cities` table + admin activation endpoint
- [ ] **T3** Wire city activation → waitlist notification job (FCM/SMS)
- [ ] **T4** Grant first-100 waitlist professionals 1 month free Premium on city activation
- [ ] **T5** `GET /sitemap.xml` endpoint listing all public professional URLs
- [ ] **T6** Add `skillpoints_balance` to users; award on successful referral

### Frontend
- [ ] **T7** Add React Helmet to all public pages
- [ ] **T8** Professional profile: og: meta tags + JSON-LD structured data
- [ ] **T9** Home page: og: + basic SEO meta
- [ ] **T10** Category pages: og: + JSON-LD (ItemList of professionals)
- [ ] **T11** `public/robots.txt` with sitemap reference
- [ ] **T12** Referrals.jsx: display SkillPoints balance for customers

### Infrastructure
- [ ] **T13** Submit sitemap.xml to Google Search Console (post-deployment task)

---

## Acceptance Criteria
- [ ] Visiting /waitlist form → enter email/phone/city → receive confirmation email
- [ ] Admin activating a city → all waitlist users for that city receive notification within 5 min
- [ ] Professional profile page has correct og: tags (verify with Facebook Sharing Debugger)
- [ ] /sitemap.xml returns valid XML with all active professional profile URLs
- [ ] Customer who refers a friend sees SkillPoints credited after referral completes
- [ ] Introductory pricing active when env flag `INTRODUCTORY_PRICING_ENABLED=true`
