# PRD §8 + Tech Supplement §A — Database Schema
## Implementation Plan (Pin-to-Pin)

> **PRD Reference:** SkillConnect_PRD_v1.0.docx §8; SkillConnect_Technical_Supplement_v1.0.docx §A  
> **Current Score:** 7 / 10  
> **Target Score:** 10 / 10  
> **Sprint:** Sprint 2

---

## Core Tables Status (PRD §8.1)

### PRD Required Tables
| Table | Status | Notes |
|---|---|---|
| users | ✅ | Implemented with most required columns |
| professionals | ✅ | Implemented |
| categories | ✅ | 3-level hierarchy via parent_id |
| professional_categories | ✅ | Many-to-many junction |
| service_areas | ✅ | Migration 012 |
| portfolio_items | ✅ | Implemented |
| certifications | ✅ | Migration 012 |
| reviews | ✅ | Implemented |
| interactions / contacts | ✅ | Implemented as `contacts` table |
| complaints | ✅ | Implemented |
| subscriptions | ✅ | Migration 012 |
| notifications | ✅ | Migration 007 |
| otp_log | ⚠️ | Redis-based OTP; no DB log (acceptable) |
| admin_actions | ⚠️ | May be in migration 007; verify |

---

## Tech Supplement §A.1.1 — Missing Tables Status

| Table | Required Columns | Status |
|---|---|---|
| search_index | professional_id, tsv_content, updated_at | ⚠️ May be in migration 006; verify trigger |
| professional_hours | id, professional_id, day_of_week, open_time, close_time, is_closed | ✅ Migration 012 |
| blocked_users | id, blocker_id, blocked_id, reason, created_at | ❌ Missing |
| search_history | id, user_id, query_text, filters_json, result_count, created_at | ✅ Migration 006 |
| featured_slots | id, professional_id, slot_type, city, start_date, end_date, status | ❌ Missing |
| payout_log | id, professional_id, subscription_id, amount, currency, gateway_ref, status | ✅ Migration 012 |
| gst_invoices | id, subscription_id, invoice_number, gstin, amount, cgst, sgst, igst, pdf_url | ✅ Migration 012 |
| device_tokens | id, user_id, token, platform, is_active, last_used_at | ✅ Migration 012 |
| category_requests | id, user_id, category_name, description, status, admin_note | ❌ Missing |
| professional_languages | professional_id, language_code, proficiency | ❌ Missing |
| soft_deletes_log | id, entity_type, entity_id, deleted_by, reason, deleted_at | ❌ Missing |
| ab_experiments | id, name, variant_a, variant_b, start_date, end_date, metric, winner | ❌ Missing |
| referral_codes | id, user_id, code, type, uses_count, reward_given, expires_at | ✅ Migration 010 |
| waitlist | id, email, phone, city, service_interest, source, created_at | ❌ Missing |

---

## Tech Supplement §A.1.2 — Missing Columns Status

### users table
| Column | Type | Status |
|---|---|---|
| preferred_language | VARCHAR(10) | ⚠️ Check migration 012 |
| timezone | VARCHAR(50) | ⚠️ Check migration 012 |
| referral_code_used | VARCHAR(20) | ⚠️ Check migration 010 |
| acquisition_source | VARCHAR(50) | ⚠️ Check migration 010 |
| deleted_at | TIMESTAMP NULL | ⚠️ Check migration 012 |

### professionals table
| Column | Type | Status |
|---|---|---|
| instagram_url | VARCHAR(255) | ✅ Already in schema |
| website_url | VARCHAR(255) | ✅ Already in schema |
| gender | ENUM | ⚠️ Check if present |
| languages | TEXT[] | ⚠️ Check if present |
| service_radius_km | SMALLINT | ✅ As service_location_radius_km |
| base_lat / base_lng | DECIMAL | ✅ As latitude/longitude |
| last_active_at | TIMESTAMP | ⚠️ Check if present |

### reviews table
| Column | Type | Status |
|---|---|---|
| is_edited | BOOLEAN | ✅ Migration 012 |
| edited_at | TIMESTAMP | ✅ Migration 012 |
| helpful_count | INTEGER | ⚠️ Check migration 012 |

### interactions / contacts table
| Column | Type | Status |
|---|---|---|
| source_screen | VARCHAR(50) | ⚠️ Check if present |
| quote_text | TEXT | ⚠️ Check if present |

### complaints table
| Column | Type | Status |
|---|---|---|
| resolution_note | TEXT | ⚠️ Check if present |
| resolved_by | UUID FK users | ✅ Likely in schema |
| resolved_at | TIMESTAMP | ✅ In schema |

---

## Critical Indexes (Tech Supplement §H.3.1)

| Index | Status |
|---|---|
| PostGIS GiST on service_areas (lat/lng) | ❌ PostGIS not installed |
| GIN on search_index.tsv_content | ⚠️ Need to verify |
| Composite on professionals (verification_status, is_available) INCLUDE (reputation_score, avg_rating, subscription_tier) | ❌ Missing |
| reviews (professional_id, is_visible, created_at DESC) | ⚠️ Basic index exists |
| contacts (customer_id, professional_id, status) for review eligibility | ⚠️ Basic indexes exist |
| Complaints partial index WHERE status='open' | ❌ Missing |
| Unique partial index users.phone WHERE deleted_at IS NULL | ❌ Missing (plain unique index exists) |

---

## Implementation Tasks (Sprint 2)

### Migration 013 — Missing Tables
- [ ] **T1** Create `blocked_users` table
- [ ] **T2** Create `featured_slots` table (slot_type: home/category/search, city, date range)
- [ ] **T3** Create `category_requests` table
- [ ] **T4** Create `professional_languages` table
- [ ] **T5** Create `soft_deletes_log` table
- [ ] **T6** Create `ab_experiments` table
- [ ] **T7** Create `waitlist` table

### Migration 013 — Missing Columns
- [ ] **T8** Add `preferred_language`, `timezone`, `deleted_at` to users (if not in 012)
- [ ] **T9** Add `helpful_count` to reviews (if not in 012)
- [ ] **T10** Add `source_screen`, `quote_text` to contacts (if not in 012)
- [ ] **T11** Add `gender`, `languages`, `last_active_at` to professionals (if not in 012)
- [ ] **T12** Add `resolution_note` to complaints (if not in 012)

### Missing Indexes
- [ ] **T13** Add composite covering index on professionals for search query
- [ ] **T14** Add partial unique index on users.phone WHERE deleted_at IS NULL
- [ ] **T15** Add partial index on complaints WHERE status='open'
- [ ] **T16** Add GIN index on search_index.tsv_content (verify/create)
- [ ] **T17** Document PostGIS as Phase 2 upgrade (add TODO in schema.sql)

---

## Acceptance Criteria
- [ ] All 14 Tech Supplement missing tables created and indexed
- [ ] All missing columns added to existing tables
- [ ] search_history table populated on each authenticated search
- [ ] Critical performance indexes created (verified via `\d+ table_name`)
- [ ] `deleted_at` soft-delete pattern works for users
- [ ] Schema validated against PRD §8.1 table definitions line-by-line
