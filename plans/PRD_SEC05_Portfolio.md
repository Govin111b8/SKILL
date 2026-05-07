# PRD §6.5 — Portfolio Showcase System
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §6.5  
> **Current Score:** 7 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 1

---

## What PRD Specifies

| Content Type | Specification | Status |
|---|---|---|
| Photos | Max 20 images; JPEG/PNG/WEBP; max 5MB each; auto-compressed to 1080px | ⚠️ Limit not enforced; compression not confirmed |
| Videos | Max 5 videos; MP4/MOV; max 100MB each; auto-compressed; thumbnail generated | ⚠️ Limit not enforced; thumbnails not generated |
| Project Cards | Title + description + date + category tag; up to 30 project cards | ⚠️ No limit enforced |
| Certifications | PDF/JPEG; max 5 documents; displayed as badge | ✅ Upload works; limit not enforced |
| Customer Quotes | Auto from 5-star reviews (with consent); shown as testimonials | ❌ Not implemented |

---

## Gap Analysis

### Gap 1 — Portfolio Upload Limits Not Enforced at API Level
**File:** `backend/src/controllers/portfolioController.js` (or `uploadController.js`)  
**Issue:** PRD specifies: 20 images max, 5 videos max, 30 project cards max, 5 certifications max. Currently no count check.  
**Fix:**
1. Before inserting a portfolio item, count existing items by type for the professional
2. Return 422 with message if limit exceeded
3. Add limits as constants: `MAX_IMAGES=20`, `MAX_VIDEOS=5`, `MAX_PROJECTS=30`, `MAX_CERTS=5`

### Gap 2 — Image Auto-Compression to 1080px Missing
**Files:** `backend/src/services/storage.js`, `backend/src/controllers/uploadController.js`  
**Issue:** PRD says photos auto-compressed to 1080px. Tech Supplement §H.4 specifies Sharp library with WebP conversion and srcset generation.  
**Fix:**
1. Install `sharp` in backend: `npm install sharp`
2. In upload pipeline (before S3 upload): resize image to max 1080px width, convert to WebP, reduce quality to 80%
3. Store original + compressed versions; serve compressed via CDN
4. Env gate: `ENABLE_IMAGE_COMPRESSION=true`

### Gap 3 — Video Thumbnail Not Generated
**Files:** `backend/src/controllers/uploadController.js`  
**Issue:** Video uploads have no thumbnail. PRD requires thumbnail generation for videos.  
**Fix:**
1. Install `fluent-ffmpeg` for thumbnail generation: `npm install fluent-ffmpeg`
2. On video upload: extract frame at 1 second → upload as thumbnail → store `thumbnail_url` in `portfolio_items`
3. Frontend: show thumbnail on gallery; open full video on tap

### Gap 4 — Project Card Category Tag Missing
**Files:** `database/schema.sql` → `portfolio_items` table  
**Issue:** PRD says project cards have a "category tag". Current schema has `title`, `description`, `media_url` but no `category_id` on portfolio items.  
**Fix:** Add `project_category_id` (nullable FK to categories) and `project_date` (DATE) to `portfolio_items`.

### Gap 5 — Portfolio Reorder Not Implemented
**Issue:** PRD dashboard says "drag-to-reorder" for portfolio. No `sort_order` column.  
**Fix:** Add `sort_order` INTEGER to `portfolio_items`. Add `PUT /professionals/portfolio/reorder` endpoint accepting ordered array of IDs.

---

## Implementation Tasks (Sprint 1)

### Backend
- [ ] **T1** Add portfolio limit checks in upload controller (20 images, 5 videos, 30 projects, 5 certs)
- [ ] **T2** Install `sharp`; add image resize + WebP conversion pipeline before upload
- [ ] **T3** Install `fluent-ffmpeg`; add video thumbnail extraction (1s frame) on upload
- [ ] **T4** Store `thumbnail_url` in `portfolio_items` table (migration)
- [ ] **T5** Add `project_category_id` and `project_date` to `portfolio_items` (migration)
- [ ] **T6** Add `sort_order` to `portfolio_items`
- [ ] **T7** `PUT /professionals/portfolio/reorder` endpoint

### Frontend
- [ ] **T8** Show video thumbnails in portfolio gallery; play on tap
- [ ] **T9** Show project category tag on project cards
- [ ] **T10** Implement drag-to-reorder in portfolio management (StorefrontSetup or Dashboard)
- [ ] **T11** Show "20/20 images used" counter in portfolio management

---

## Acceptance Criteria
- [ ] API rejects 21st image upload with clear error message
- [ ] Images served as WebP; max 1080px width in portfolio view
- [ ] Video uploads generate and display a thumbnail
- [ ] Project cards display category tag and date
- [ ] Professional can reorder portfolio items via drag; order persists
- [ ] Certifications capped at 5; API rejects 6th
