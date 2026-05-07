# Tech Supplement §H — Performance Engineering
## Implementation Plan (Pin-to-Pin)

> **Reference:** SkillConnect_Technical_Supplement_v1.0.docx §H  
> **Current Score:** 5 / 10  
> **Target Score:** 9 / 10  
> **Sprint:** Sprint 4

---

## Performance Budget Status (§H.1)

| Metric | Target | Status |
|---|---|---|
| Search API response (P95) | < 300ms | ⚠️ Not measured; no load test |
| Profile page load (mobile web, FCP) | < 1.5s | ⚠️ Not measured |
| App cold start (Android mid-range) | < 2.5s | ⚠️ Not measured |
| App cold start (iOS) | < 2.0s | ⚠️ Not measured |
| Time to Interactive (web, 4G) | < 3.0s | ⚠️ Not measured |
| Largest Contentful Paint | < 2.0s | ⚠️ Not measured |
| Cumulative Layout Shift | < 0.05 | ⚠️ Not measured |
| API error rate | < 0.1% | ⚠️ Not measured in production |
| Database query P99 | < 100ms | ⚠️ No slow query logging |
| CDN cache hit rate | > 90% | ⚠️ No CDN configured (Cloudflare pending) |

---

## Caching Architecture Status (§H.2)

| Cache Layer | What | TTL | Status |
|---|---|---|---|
| CDN (Cloudflare) | Profile photos, portfolio, icons, JS/CSS | 1yr / 5min | ❌ No CDN |
| Redis — Hot Profiles | Top 1000 viewed per city (15 min) | 15 min | ⚠️ Redis exists; hot profile cache not implemented |
| Redis — Search Cache | Top 100 queries per city | 5 min | ✅ Search caching implemented |
| Redis — Category Tree | Full category JSON | 6 hours | ✅ Implemented |
| Redis — OTP | Active OTP hashes | 5 min TTL | ✅ |
| Redis — Rate Limits | Per IP/user counters | 60s sliding | ✅ |
| Redis — Sessions | Refresh token families | 30 days | ⚠️ Partial |
| Application Cache (in-memory LRU) | City list, feature flags, GST rates | 30 min | ⚠️ Some implemented |
| DB Materialized Views | search_index, reputation_score_snapshot | nightly | ⚠️ search_index trigger exists |

---

## Database Performance Status (§H.3)

### Critical Indexes (§H.3.1)
| Index | Status |
|---|---|
| PostGIS GiST on service_areas (geography) | ❌ PostGIS not installed; Haversine used |
| GIN on search_index.tsv_content | ⚠️ Verify |
| Composite on professionals (verification_status, is_available) INCLUDE (reputation_score...) | ❌ Missing |
| reviews (professional_id, is_visible, created_at DESC) | ⚠️ Basic index exists |
| contacts (customer_id, professional_id, status) | ⚠️ Basic indexes exist |
| complaints partial WHERE status='open' | ❌ Missing |
| UNIQUE partial users.phone WHERE deleted_at IS NULL | ❌ Missing |

### Query Optimisation Rules (§H.3.2)
| Rule | Status |
|---|---|
| All search queries use search_index view | ✅ searchController uses it |
| No N+1 queries on profile page load | ⚠️ Not verified |
| Cursor-based pagination (WHERE id > last) | ⚠️ Offset pagination used in some routes |
| PgBouncer connection pooling | ✅ In docker-compose + K8s |
| Read replicas: GETs to read replica | ❌ Single primary only |
| Slow query budget: >50ms logged | ❌ Not configured |

---

## Mobile App Performance (§H.4)
| Optimisation | Status |
|---|---|
| Images converted to WebP on upload (Sharp) | ❌ Not implemented |
| Responsive srcset (200w/400w/800w/1200w) | ❌ Not implemented |
| React Native Hermes JS engine | ✅ Flutter uses Dart AOT (equivalent) |
| FlatList with getItemLayout | ⚠️ Flutter ListView equivalent |
| Image lazy loading | ⚠️ Flutter uses cached_network_image |
| App size budget (Android < 20MB) | ⚠️ Not measured |

---

## Gap Analysis

### Gap 1 — No Load Testing
**Fix:**
1. Install k6: `brew install k6` or use Docker image
2. Create `tests/load/search.js` — simulate 100 users searching simultaneously
3. Create `tests/load/profile.js` — simulate 200 users loading profiles
4. Run k6 tests against staging; measure P95 response times
5. Optimise until P95 < 300ms for search, < 500ms for profile

### Gap 2 — No Hot Profile Cache
**File:** `backend/src/controllers/professionalController.js`  
**Fix:**
1. On `GET /professionals/:id`: check Redis key `hot_profile:{id}`
2. If miss: fetch from DB → store in Redis with 15-min TTL
3. On profile update: invalidate `hot_profile:{id}` key immediately
4. Pre-warm cache for Featured-tier professionals nightly (top 100 most-viewed)

### Gap 3 — Cursor-Based Pagination Missing
**Issue:** Several routes use `OFFSET` pagination which breaks at scale.  
**Fix:** Identify all routes using `LIMIT $n OFFSET $m` → convert to cursor-based:
```sql
-- Instead of: WHERE 1=1 LIMIT 20 OFFSET 100
-- Use: WHERE id > $last_seen_id ORDER BY id LIMIT 20
```
Routes to convert: search results, reviews list, notifications, contacts list.

### Gap 4 — Slow Query Logging Not Configured
**File:** `docker-compose.yml` → PostgreSQL command  
**Fix:** Add `log_min_duration_statement = 50` (ms) to PostgreSQL config. Slow queries logged to PostgreSQL log → scraped by Prometheus pg_exporter.

### Gap 5 — Image Processing Pipeline Missing
**Fix:** Install `sharp`: `cd backend && npm install sharp`
- On image upload: resize to max 1080px, convert to WebP, save to S3
- Generate thumbnail (400px) for search result card display
- Store both full + thumbnail URLs in portfolio_items

---

## Implementation Tasks (Sprint 4)

### Backend Performance
- [ ] **T1** Implement hot profile Redis cache in professionalController.js
- [ ] **T2** Convert OFFSET pagination to cursor-based in search + reviews + notifications
- [ ] **T3** Add composite covering index on professionals table
- [ ] **T4** Add partial index on complaints WHERE status='open'
- [ ] **T5** Configure PostgreSQL slow query log at 50ms threshold
- [ ] **T6** Add `sharp` image processing pipeline (WebP + resize + thumbnail)
- [ ] **T7** Read replica routing in database.js

### Load Testing
- [ ] **T8** Write `tests/load/search.js` k6 script (100 VUs, 60s)
- [ ] **T9** Write `tests/load/profile.js` k6 script (200 VUs, 60s)
- [ ] **T10** Write `tests/load/contact.js` k6 script (50 VUs, 60s)
- [ ] **T11** Add k6 smoke test (10 VUs, 30s) to CI/CD pipeline

### Frontend Performance
- [ ] **T12** Add `loading="lazy"` to all portfolio/profile images
- [ ] **T13** Run Lighthouse CI on search and profile pages; fix issues

---

## Acceptance Criteria
- [ ] k6 search test: P95 < 300ms at 100 concurrent users
- [ ] k6 profile test: P95 < 500ms at 200 concurrent users
- [ ] Hot profile cache hit rate > 80% for top 1000 professionals
- [ ] All list endpoints use cursor pagination; no OFFSET queries on large tables
- [ ] Slow queries > 50ms logged to PostgreSQL log
- [ ] Images stored as WebP; thumbnail generated for search cards
- [ ] Lighthouse performance score ≥ 80 on profile page (desktop)
