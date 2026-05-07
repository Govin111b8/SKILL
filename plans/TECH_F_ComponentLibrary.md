# Tech Supplement §F — Component Library & Screen Inventory
## Implementation Plan (Pin-to-Pin)

> **Reference:** SkillConnect_Technical_Supplement_v1.0.docx §F  
> **Current Score:** 6 / 10  
> **Target Score:** 9 / 10  
> **Sprint:** Sprint 1 + Sprint 4

---

## Screen Inventory Status

### Customer Screens
| Screen | Tech Supplement Spec | Status |
|---|---|---|
| Splash / Onboarding | Animated logo + 3 value prop slides | ⚠️ May not exist |
| Login | Email + password; forgot password link | ✅ Login.jsx |
| Register (Customer) | Name, email, phone, city, password + OTP | ✅ Register.jsx |
| Home | Category grid, featured carousel, search bar, location, recent viewed | ⚠️ Missing: location picker, recent viewed |
| Search Results | Filter bar, result cards, map toggle | ✅ SearchResults.jsx (missing map) |
| Category Browse | Category list with icons and professional count | ✅ Categories.jsx |
| Sub-Category Browse | Sub-categories within category | ✅ CategoryDetail.jsx |
| Professional Profile | Full profile with portfolio, reviews, contact CTA | ✅ ProfessionalProfile.jsx |
| Booking Create | Select service, date, time, notes | ✅ CreateBooking.jsx |
| Booking List | Customer's active/past bookings | ✅ Bookings.jsx |
| Booking Detail | Full booking info with status actions | ✅ BookingDetail.jsx |
| Chat / Messages | Thread list + conversation view | ✅ Messages.jsx + Chat.jsx |
| Favorites | Saved professionals list | ✅ Favorites.jsx |
| Notifications | Notification list + mark read | ✅ Notifications.jsx |
| Settings | Profile edit, password, notification prefs, language | ✅ Settings.jsx (prefs missing) |
| Referrals (Customer) | Referral code, SkillPoints balance | ✅ Referrals.jsx |
| Waitlist | Join waitlist for city | ❌ Missing |
| Legal Pages | ToS, Privacy Policy, etc. | ❌ Missing (6 pages) |

### Professional Screens
| Screen | Status |
|---|---|
| Professional Register | ✅ |
| KYC / Verification | ✅ |
| Professional Dashboard | ✅ Dashboard.jsx |
| Schedule Management | ✅ Schedule.jsx |
| Storefront Setup | ✅ StorefrontSetup.jsx |
| Storefront View | ✅ Storefront.jsx |
| Earnings | ✅ Earnings.jsx |
| Analytics | ✅ Analytics.jsx |
| Warranties | ✅ Warranties.jsx |
| Emergency | ✅ Emergency.jsx |

### Admin Screens
| Screen | Status |
|---|---|
| Admin Dashboard | ✅ admin/Dashboard.jsx |
| User Management | ✅ admin/Users.jsx |
| KYC Queue | ✅ admin/KYC.jsx |
| Disputes | ✅ admin/Disputes.jsx |
| Category Requests | ❌ Missing |
| Featured Slots | ❌ Missing |
| A/B Experiments | ❌ Missing |
| Appeals Queue | ❌ Missing |
| Waitlist Management | ❌ Missing |

### Agent Screens
| Screen | Status |
|---|---|
| Agent Dashboard | ✅ AgentDashboard.jsx |
| Agent Onboard | ✅ AgentOnboard.jsx |
| Agent Wallet | ✅ AgentWallet.jsx |
| Agent Leaderboard | ✅ AgentLeaderboard.jsx |

---

## Gap Analysis

### Gap 1 — Missing Admin Screens (5 screens)
**Fix:** Create:
- `frontend/src/pages/admin/CategoryRequests.jsx` — review + approve/reject professional category requests
- `frontend/src/pages/admin/FeaturedSlots.jsx` — assign professionals to featured placements
- `frontend/src/pages/admin/ABExperiments.jsx` — manage A/B experiments
- `frontend/src/pages/admin/Appeals.jsx` — review suspension/ban appeals
- `frontend/src/pages/admin/WaitlistView.jsx` — view/export waitlist by city

### Gap 2 — Missing Customer Screens (2 screens)
**Fix:**
- `frontend/src/pages/Waitlist.jsx` — city waitlist signup form
- `frontend/src/pages/legal/*.jsx` — 6 legal pages (see PRD_SEC19_Compliance.md)

### Gap 3 — Splash / Onboarding Screen Missing (Web)
**Fix:** Create `frontend/src/pages/Onboarding.jsx` — shown to first-time visitors:
- 3 slides: "Find Verified Professionals", "Compare and Choose", "Safe and Trusted"
- "Get Started" button → Register
- "I'm a Professional" button → Professional Register

### Gap 4 — Settings Page Missing Notification Preferences
**Fix:** See PRD_SEC12_Notifications.md Gap 2 (same issue cross-referenced).

---

## Implementation Tasks

### Sprint 1
- [ ] **T1** Create `frontend/src/pages/Onboarding.jsx` (3-slide intro for new visitors)
- [ ] **T2** Add notification preference toggles to Settings.jsx
- [ ] **T3** Add recently-viewed section to Home.jsx
- [ ] **T4** Add city location selector to Home.jsx

### Sprint 2
- [ ] **T5** Create `admin/CategoryRequests.jsx`
- [ ] **T6** Create `admin/Appeals.jsx`
- [ ] **T7** Create `admin/FeaturedSlots.jsx`

### Sprint 6
- [ ] **T8** Create `Waitlist.jsx` customer signup page
- [ ] **T9** Create `admin/WaitlistView.jsx`
- [ ] **T10** Create all 6 legal content pages
- [ ] **T11** Create `admin/ABExperiments.jsx`

---

## Acceptance Criteria
- [ ] New visitor sees onboarding slides on first visit (stored in localStorage)
- [ ] All 5 missing admin pages accessible from admin navigation
- [ ] Waitlist signup works end-to-end (form → API → confirmation email)
- [ ] All 6 legal pages accessible from footer
- [ ] Settings page shows notification preference toggles that persist
