# PRD §10 — Technical Architecture
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §10  
> **Current Score:** 6 / 10  
> **Target Score:** 8 / 10 (some decisions are permanent tech choices)  
> **Sprint:** Sprint 5 (Architecture Evolution)

---

## Tech Stack Deviations from PRD

| PRD Specified | Actually Built | Deviation Impact | Fix Needed? |
|---|---|---|---|
| React Native (Expo) | Flutter 3.8 | ✅ Equivalent capability; better offline | No |
| Next.js 14 (SSR/SSG) | React 19 + Vite (SPA) | ⚠️ SEO gap for public pages | Partial |
| TypeScript | JavaScript | ⚠️ No compile-time type safety | Gradual |
| Kafka message bus | In-memory job queue | ⚠️ Single-instance scalability limit | Phase 2 |
| AWS API Gateway + Kong | Express middleware | ✅ Acceptable Phase 1 | No |
| Elasticsearch (Phase 2) | PostgreSQL FTS (Phase 1) | ✅ Correct phasing | Phase 2 |
| AWS ECS Fargate | Kubernetes | ✅ Better choice | No |
| Prisma ORM | Raw pg queries | ⚠️ Migration-heavy, less type safety | Consider |
| PostGIS | Haversine calculation | ⚠️ Less accurate at scale | Phase 2 |
| AWS Rekognition/HyperVerge | Mock (configurable) | ⚠️ Production needs real provider | Yes |

---

## Architecture Gaps

### Gap 1 — SEO: No Server-Side Rendering for Public Pages
**Issue:** PRD references SEO as important. Next.js was specified for SSR. React SPA cannot be crawled well by Google for:
- Professional profile pages (need `og:` meta tags per profile)
- Category pages
- Home screen

**Fix (Phase 2):**
1. Add React Helmet (or `@vitejs/plugin-react` + meta plugin) for dynamic meta tags on public pages
2. Add a pre-rendering sitemap: `GET /sitemap.xml` endpoint listing all public professional profile URLs
3. Add structured data (JSON-LD) for professional profiles per PRD §4.2 (schema.org/LocalBusiness)
4. Consider static pre-rendering of category pages via `vite-plugin-ssr` or Astro (Phase 3)

### Gap 2 — TypeScript Not Used
**Issue:** PRD specifies TypeScript for type safety.  
**Fix (Gradual, Sprint 5):** Do not rewrite. Instead:
1. Add JSDoc type annotations to all new files
2. Enable TypeScript `allowJs` checking: add `jsconfig.json` with strict mode
3. New service files written in `.ts` (compile alongside .js)
4. Set as team convention for all new code going forward

### Gap 3 — In-Memory Job Queue (Not Production-Scale)
**Issue:** Current `jobQueue.js` uses an in-memory queue. In a multi-instance deployment, jobs are not shared across instances. Queue is lost on restart.  
**Fix (Sprint 5):**
1. Replace with BullMQ + Redis: `npm install bullmq`
2. Migrate all job types: email, SMS, push, analytics, search-index, image-processing
3. Add Bull Board admin UI for queue monitoring
4. Keep in-memory fallback for development (`QUEUE_BACKEND=memory|redis`)

### Gap 4 — No OTP Audit Log in Database
**Issue:** PRD §8.1 specifies `otp_log` table. Currently OTP is Redis-only (no DB audit trail).  
**Fix:** Add `otp_log` table (phone, hashed OTP, expires_at, is_used, created_at, ip_address) for audit/forensics. Write-only; TTL-based Redis continues to enforce expiry.

### Gap 5 — HyperVerge/Rekognition Not Wired for Production
**Issue:** `faceMatch.js` defaults to mock mode.  
**Fix:** Add production onboarding guide in `SECRETS.md`:
- Set `FACE_MATCH_PROVIDER=hyperverge`
- Add `HYPERVERGE_APP_ID`, `HYPERVERGE_APP_KEY` to K8s Secret
- Test with a live selfie + Aadhaar scan in staging

### Gap 6 — Scalability Plan Not Implemented Beyond Phase 1
**PRD §10.4 Scalability:** Documented plan for 3 phases. Phase 2 requires:
- Load balancer + 2 API instances
- RDS read replica routing
- Redis cluster

**Fix (Phase 2, tracked here as reminder):**
- Implement read/write split in `database.js`: route GET queries to read replica connection pool
- HPA already configured in K8s for API (2–10 replicas)
- Redis already in cluster mode in Docker Compose

---

## Implementation Tasks (Sprint 5)

### Immediate (Phase 1 Completion)
- [ ] **T1** Add `otp_log` table (migration 013)
- [ ] **T2** Write OTP events to DB audit log (alongside Redis TTL)
- [ ] **T3** Document `FACE_MATCH_PROVIDER=hyperverge` setup in SECRETS.md
- [ ] **T4** Add React Helmet to frontend for dynamic meta tags on profile/category pages
- [ ] **T5** Add JSON-LD structured data (schema.org/Person) to professional profile page
- [ ] **T6** Add `GET /sitemap.xml` endpoint listing all public profile URLs
- [ ] **T7** Add `jsconfig.json` with TypeScript checking enabled for new JS files

### Phase 2 (BullMQ Migration)
- [ ] **T8** Replace in-memory jobQueue with BullMQ + Redis backend
- [ ] **T9** Add Bull Board admin route (`/admin/queues`) for queue monitoring
- [ ] **T10** Configure `QUEUE_BACKEND` env var for dev/prod switching

### Phase 2 (Database Read Replica)
- [ ] **T11** Add `DB_READ_HOST` env var; route SELECT queries to read replica in `database.js`

---

## Acceptance Criteria
- [ ] Professional profile pages have correct og:title, og:description, og:image meta tags
- [ ] /sitemap.xml lists all active verified professional profile URLs
- [ ] JSON-LD structured data passes Google Rich Results Test
- [ ] OTP events logged to `otp_log` table with IP and phone
- [ ] BullMQ processes all job types with retry logic and dead-letter queue
- [ ] Queue admin dashboard accessible at `/admin/queues` (admin-only)
