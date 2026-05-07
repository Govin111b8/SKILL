# PRD §6.4 — Search & Discovery System
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §6.4  
> **Current Score:** 9 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 2

---

## What PRD Specifies

### Search Filters (8 Filters)
| Filter | Type | Status |
|---|---|---|
| Keyword | Free text | ✅ |
| Category | Single select | ✅ |
| Sub-category | Multi-select | ✅ |
| City / Area | Location picker (GPS or manual) | ✅ |
| Minimum Rating | Slider 1–5 | ✅ |
| Experience (yrs) | Range slider | ✅ |
| Price Range | Range slider | ✅ |
| Availability | Toggle | ✅ |
| Verified Only | Toggle (default ON) | ✅ |

### Search Ranking Algorithm — 6 Factors
| Factor | PRD Weight | Implemented Weight | Status |
|---|---|---|---|
| Reputation Score | 30% | 30% | ✅ Exact match |
| Profile Completeness | 20% | 20% | ✅ Exact match |
| Proximity | 20% | 20% | ✅ Haversine distance |
| Activity Level | 15% | 15% | ✅ Last login recency |
| Subscription Tier | 10% | 10% | ✅ Exact match |
| Review Recency | 5% | 5% | ✅ Exact match |

### Additional Features
| Feature | Status |
|---|---|
| Search history saved (authenticated users) | ✅ |
| Autocomplete suggestions | ❌ Missing |
| Default: show only verified profiles | ✅ |
| Pagination (default 20/page) | ✅ |
| Featured professionals on home screen | ✅ |
| "Similar professionals" (GET /professionals/:id/similar) | ❌ Missing |
| Map view toggle (Phase 2) | ❌ Phase 2 scope |
| GET /search/history | ✅ |
| DELETE /search/history | ⚠️ May be missing |

---

## Gap Analysis

### Gap 1 — Autocomplete Suggestions Missing
**Files:** `backend/src/routes/search.js`  
**Issue:** Tech Supplement §A.2 and PRD §9.3 specify `GET /search/suggestions` for autocomplete. Frontend search bar may lack real-time suggestions.  
**Fix:**
1. `GET /search/suggestions?q=plumb&city=Bangalore` → search `search_history` for popular queries matching prefix + professionals where name/bio matches → return top 5
2. Cache in Redis (5-minute TTL per query prefix)
3. Frontend: wire to search bar with 300ms debounce

### Gap 2 — Similar Professionals Endpoint Missing
**Files:** `backend/src/routes/professionals.js`  
**Issue:** Tech Supplement §A.2 specifies `GET /professionals/:id/similar` — 5 similar profiles by category + location for discovery.  
**Fix:**
1. Query: same primary category + closest distance to target professional's location
2. Exclude the current professional and unverified profiles
3. Rank by reputation score; limit 5
4. Cache in Redis (15-min TTL, key = professional_id)

### Gap 3 — DELETE /search/history May Be Missing
**Files:** `backend/src/routes/search.js`  
**Fix:** Add `DELETE /search/history` endpoint — deletes all rows in `search_history` for authenticated user.

### Gap 4 — Map View (Phase 2)
**Status:** Intentionally deferred. Plan file created as reminder.  
**When to implement:** Phase 2 (after 10K MAU). Requires PostGIS + Google Maps embed or MapLibre.

---

## Implementation Tasks (Sprint 2)

### Backend
- [ ] **T1** `GET /search/suggestions?q=&city=` with Redis cache
- [ ] **T2** `GET /professionals/:id/similar` (category + proximity, limit 5, cached)
- [ ] **T3** `DELETE /search/history` for authenticated users
- [ ] **T4** Verify `GET /search/history` returns paginated results (add if missing)

### Frontend
- [ ] **T5** Wire `SearchBar` component to `/search/suggestions` with 300ms debounce
- [ ] **T6** Show autocomplete dropdown (max 5 items) below search bar
- [ ] **T7** Add "You might also like" section on `ProfessionalProfile.jsx` using similar API
- [ ] **T8** Add "Clear history" button in search history UI

---

## Acceptance Criteria
- [ ] Typing "plumb" in search shows autocomplete with 3–5 relevant suggestions
- [ ] Viewing a professional profile shows 3–5 similar professionals
- [ ] Search history can be cleared by user
- [ ] All 8 filters work end-to-end in search results
- [ ] Verified-only filter is ON by default; unverified profiles never appear without explicit toggle
- [ ] Search ranking produces Featured > Premium > Basic ordering within same trust tier
