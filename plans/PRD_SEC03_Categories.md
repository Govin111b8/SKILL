# PRD §6.3 — Category & Taxonomy System
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §6.3  
> **Current Score:** 8 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 2

---

## What PRD Specifies

### Taxonomy Structure
- **3 levels:** Category → Sub-category → Skill Tag
- Platform-managed (not user-created) to prevent fragmentation
- 8 top-level categories: Home Services, Event Services, Personal Services, Technical Services, Creative Services, Business Services, Beauty & Wellness, Pets & Animals

### Required Categories (PRD §6.3)
| Category | Sub-categories | Status |
|---|---|---|
| Home Services | Plumbing, Electrical, Carpentry, Painting, Cleaning, Pest Control, Waterproofing | ✅ Seed data |
| Event Services | Wedding Planning, Photography, Videography, Catering, DJ & Sound, Decor, MC/Host | ✅ Seed data |
| Personal Services | Tutoring, Fitness Training, Yoga, Nutritionist, Life Coach, Makeup, Hair Styling | ✅ Seed data |
| Technical Services | Computer Repair, Mobile Repair, CCTV, AC/Refrigerator, Appliance Repair | ✅ Seed data |
| Creative Services | Graphic Design, Video Editing, Content Writing, Animation, UI/UX | ✅ Seed data |
| Business Services | Accounting, Legal, Digital Marketing, HR Consulting, Business Plan Writing | ✅ Seed data |
| Beauty & Wellness | Salon, Spa, Tattoo, Piercing, Massage Therapy | ✅ Seed data |
| Pets & Animals | Dog training, Pet grooming, Veterinary visits, Pet boarding | ✅ Seed data |

### Required Features
| Feature | Status |
|---|---|
| Admin-managed categories (no user creation) | ✅ Admin-only create |
| Category requests from professionals | ❌ Not implemented |
| 3-level deep taxonomy | ✅ (parent_id self-reference) |
| Skill tags within sub-categories | ⚠️ Stored as text array, not normalised |
| Trending categories endpoint | ❌ Not implemented |
| Professionals can select up to 3 primary categories | ⚠️ No limit enforced |

---

## Gap Analysis

### Gap 1 — Category Request System Missing
**Files:** `backend/src/routes/categories.js`, `backend/src/routes/admin.js`  
**Issue:** PRD specifies professionals can request new categories via a form. An admin reviews the request. No such endpoint or table exists.  
**Fix:**
1. Create `category_requests` table: `(id, user_id, category_name, description, status, admin_note, created_at)`
2. `POST /categories/request` — authenticated professional; sends request
3. `GET /admin/category-requests` — admin lists pending requests
4. `PUT /admin/category-requests/:id` — admin approve/reject with note

### Gap 2 — Trending Categories Endpoint Missing
**Files:** `backend/src/routes/categories.js`  
**Issue:** Tech Supplement §A.2 specifies `GET /categories/trending` — most-searched categories in user's city this week. Frontend home screen and search would use this.  
**Fix:**
1. Add query to `search_history` table: group by category filter, count by city, last 7 days
2. `GET /categories/trending?city=Bangalore` → top 6 category IDs + names + search count
3. Cache result in Redis with 1-hour TTL

### Gap 3 — 3-Category Limit Not Enforced
**Files:** `backend/src/controllers/professionalController.js`  
**Issue:** PRD says professionals can select "up to 3 primary categories." No enforcement at API level.  
**Fix:** In professional onboarding/update endpoint, validate `category_ids.length <= 3`. Return 400 if exceeded.

### Gap 4 — Skill Tags Not Normalised
**Issue:** Skill tags stored as `TEXT[]` array on `professionals`. Cannot search/filter by skill tag efficiently.  
**Fix (Phase 2):** Create `skill_tags` table with normalised entries. Link via `professional_skill_tags` junction. Enables trending skill search and autocomplete.  
**Phase 1 Fix:** Ensure GIN index exists on `skill_tags` array for array-contains search.

---

## Implementation Tasks (Sprint 2)

### Database
- [ ] **T1** Create `category_requests` table (migration 013)
- [ ] **T2** Add GIN index on `professionals.skill_tags` if not present

### Backend
- [ ] **T3** `POST /categories/request` endpoint
- [ ] **T4** `GET /admin/category-requests` + `PUT /admin/category-requests/:id` endpoints
- [ ] **T5** `GET /categories/trending?city=X` endpoint with Redis cache
- [ ] **T6** Enforce max 3 categories in professional profile update endpoint

### Frontend
- [ ] **T7** Add "Request a Category" form in professional Settings page
- [ ] **T8** Admin panel: category requests queue tab
- [ ] **T9** Display trending categories on home screen (replace or augment static grid)

---

## Acceptance Criteria
- [ ] Professional can submit a category request with name + description
- [ ] Admin sees request in queue; can approve (creates category) or reject with note
- [ ] Professional is notified of outcome via notification
- [ ] Trending categories API returns top 6 for a given city based on search history
- [ ] Professional cannot select more than 3 primary categories (API enforced)
- [ ] All 8 top-level categories with correct sub-categories in seed data
