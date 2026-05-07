# PRD §6.7 — Contact & Communication System
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §6.7  
> **Current Score:** 8 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 1

---

## What PRD Specifies

| Contact Method | Phase | Status |
|---|---|---|
| Phone Number Reveal (logged-in customer only) | Phase 1 | ✅ Contact reveal working |
| WhatsApp Button (pre-filled message) | Phase 1 | ✅ Button exists |
| Quote Request Form (notification to professional) | Phase 1 | ⚠️ Form exists; SMS/push notification on submission incomplete |
| In-App Messaging (full chat with read receipts) | Phase 3 | ✅ Built ahead of schedule (documented in PLATFORM_CHANGE_RECORD) |
| Video Call (30-min WebRTC consultation) | Phase 3 | ❌ Not in scope for current build |

### Business Logic — Customer Duplicate Contact Limit
| Rule | Status |
|---|---|
| Same customer max 3 contacts with same professional in 30 days | ❌ Not implemented |
| After 3 contacts: show "You have recently contacted this professional — view others like them" | ❌ Not implemented |

### Quote Request Flow
| Step | Status |
|---|---|
| Customer fills quote form (message, service date, budget) | ✅ Basic form exists |
| Push notification sent to professional | ⚠️ FCM service exists; trigger not confirmed |
| SMS notification sent to professional | ⚠️ SMS service exists; trigger not confirmed |
| Professional can accept/decline quote | ⚠️ `POST /interactions/:id/quote-accept` missing |

---

## Gap Analysis

### Gap 1 — Customer Duplicate Contact Limit Not Enforced
**File:** `backend/src/controllers/contactController.js`  
**Fix:**
1. Before logging a contact, query: `SELECT COUNT(*) FROM contacts WHERE customer_id=$1 AND professional_id=$2 AND created_at > NOW() - INTERVAL '30 days'`
2. If count ≥ 3: return 429 with message and `similar_professionals` array (5 alternatives by category)
3. Frontend: display "You've recently contacted X — here are similar professionals" with suggestions

### Gap 2 — Quote Accept/Decline Endpoint Missing
**File:** `backend/src/routes/contacts.js`  
**Fix:** Add `POST /contacts/:id/accept` and `POST /contacts/:id/decline` (or `PUT /contacts/:id/status`) for professionals to signal acceptance. This enables:
- Analytics on acceptance rate
- Customer notification: "Your quote request was accepted!"
- Interaction tracking for review eligibility

### Gap 3 — Push/SMS Notification on Quote Request Not Wired
**Files:** `backend/src/controllers/contactController.js`, `backend/src/services/pushNotification.js`, `backend/src/services/sms.js`  
**Fix:** After inserting contact with `contact_type = 'quote_request'`:
1. Fetch professional's device tokens → send FCM push: "New quote request from [Customer Name]"
2. Send SMS to professional's phone via MSG91/Twilio

### Gap 4 — WhatsApp Pre-filled Message Uses SkillConnect URL
**File:** `frontend/src/pages/ProfessionalProfile.jsx`  
**Issue:** WhatsApp message should say "Hi, I found you on SkillConnect..." and include the professional's profile URL.  
**Fix:** Generate WhatsApp URL: `https://wa.me/${phone}?text=Hi%2C+I+found+you+on+SkillConnect...+${profileUrl}`

---

## Implementation Tasks (Sprint 1)

### Backend
- [ ] **T1** Add 30-day 3-contact limit check in contact creation endpoint
- [ ] **T2** Return `similar_professionals` array in 429 response
- [ ] **T3** Add `PUT /contacts/:id/status` for professional accept/decline
- [ ] **T4** Wire FCM push notification on quote request creation
- [ ] **T5** Wire SMS notification on quote request creation
- [ ] **T6** Add `POST /interactions/:id/quote-accept` (Tech Supplement §A.2)

### Frontend
- [ ] **T7** Show "similar professionals" banner when contact limit reached
- [ ] **T8** Fix WhatsApp pre-filled message text per PRD spec
- [ ] **T9** Professional dashboard: show pending quote requests with accept/decline buttons

---

## Acceptance Criteria
- [ ] 4th contact attempt by same customer to same professional within 30 days → 429 with alternatives
- [ ] Professional receives FCM push AND SMS on new quote request
- [ ] Professional can accept or decline a quote from dashboard
- [ ] Customer receives notification when quote is accepted
- [ ] WhatsApp button opens WhatsApp with pre-filled "Hi, I found you on SkillConnect..." message
