# Tech Supplement §E — UI/UX Design System
## Implementation Plan (Pin-to-Pin)

> **Reference:** SkillConnect_Technical_Supplement_v1.0.docx §E  
> **Current Score:** 5 / 10  
> **Target Score:** 8 / 10  
> **Sprint:** Sprint 1 (UX polish) + Sprint 4 (design system formalisation)

---

## What Tech Supplement §E Specifies

### Design Tokens
| Token Category | Specified | Status |
|---|---|---|
| Primary colour | #6366F1 (Indigo) | ⚠️ Used in some places; not as CSS variable |
| Success colour | #10B981 (Emerald) | ⚠️ Not formalised |
| Warning colour | #F59E0B (Amber) | ⚠️ Not formalised |
| Error colour | #EF4444 (Red) | ⚠️ Not formalised |
| Neutral scale (9 shades) | Gray 50–900 | ⚠️ Not formalised |
| Typography: Inter font | Inter font system | ⚠️ Not confirmed |
| Spacing: 4px base unit (4/8/12/16/24/32/48/64) | 4px system | ⚠️ Not formalised |
| Border radius: 8px cards, 12px modals, 50% pills | Rounded system | ⚠️ Inconsistent |
| Shadow: 3 levels | xs/sm/md shadows | ⚠️ Not formalised |

### Component Library (Tech Supplement §E.2)
| Component | Status |
|---|---|
| Button (primary/secondary/ghost/danger, 3 sizes) | ⚠️ Not componentised; per-page styles |
| Card (professional, booking, review, category) | ⚠️ Inline styles |
| Input / TextArea / Select | ⚠️ Native HTML elements |
| Badge (verified, Premium, Featured, Trust Index tier) | ⚠️ Not standardised |
| Modal / Drawer | ⚠️ May exist; not documented |
| Toast / Alert | ✅ Toast component exists |
| Skeleton Loader | ✅ Skeleton component exists |
| Avatar (with fallback initials) | ⚠️ Not documented |
| Rating Stars | ⚠️ May exist inline |
| Tag / Pill (category, skill) | ⚠️ Inline styles |
| Progress Bar (profile completeness) | ❌ Not built |

---

## Gap Analysis

### Gap 1 — No CSS Custom Properties (Design Tokens)
**File:** `frontend/src/index.css` or new `frontend/src/styles/tokens.css`  
**Fix:** Create design token CSS file:
```css
:root {
  /* Colors */
  --color-primary: #6366F1;
  --color-primary-dark: #4F46E5;
  --color-success: #10B981;
  --color-warning: #F59E0B;
  --color-error: #EF4444;
  --color-neutral-50: #F9FAFB;
  /* ... through neutral-900 */

  /* Typography */
  --font-family: 'Inter', sans-serif;
  --font-size-xs: 0.75rem;   /* 12px */
  --font-size-sm: 0.875rem;  /* 14px */
  --font-size-base: 1rem;    /* 16px */
  --font-size-lg: 1.125rem;  /* 18px */
  --font-size-xl: 1.25rem;   /* 20px */
  --font-size-2xl: 1.5rem;   /* 24px */

  /* Spacing */
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-6: 24px;
  --space-8: 32px;
  --space-12: 48px;
  --space-16: 64px;

  /* Radius */
  --radius-sm: 4px;
  --radius-md: 8px;    /* cards */
  --radius-lg: 12px;   /* modals */
  --radius-full: 9999px; /* pills */

  /* Shadows */
  --shadow-xs: 0 1px 2px rgba(0,0,0,0.05);
  --shadow-sm: 0 1px 3px rgba(0,0,0,0.1);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.07);
}
```

### Gap 2 — Reusable Component Library Not Built
**Fix (Sprint 4):** Create `frontend/src/components/ui/` with standardised components:
- `Button.jsx` (variants: primary/secondary/ghost/danger; sizes: sm/md/lg)
- `Badge.jsx` (variants: verified/premium/featured/trust-tier)
- `Input.jsx` (with label, error state, helper text)
- `Card.jsx` (wrapper with shadow and radius)
- `ProgressBar.jsx` (with percentage and label)
- `StarRating.jsx` (display + interactive modes)
- `Avatar.jsx` (image with fallback initials)
- `Tag.jsx` (category/skill pill)

### Gap 3 — Inconsistent Spacing
**Fix:** Audit all CSS files; replace hardcoded pixel values with CSS variable references.

### Gap 4 — No Storybook Documentation
**Fix (Phase 2):**
```bash
cd frontend && npx storybook@latest init
```
Document all UI components with stories for each variant.

---

## Implementation Tasks

### Sprint 1 (Immediate)
- [ ] **T1** Create `frontend/src/styles/tokens.css` with all design tokens
- [ ] **T2** Import tokens.css in `main.jsx`
- [ ] **T3** Apply `--color-primary` to all currently hardcoded `#6366F1` usages
- [ ] **T4** Create `ProgressBar.jsx` component (used in profile completeness)
- [ ] **T5** Create `StarRating.jsx` component (used on profile + review forms)
- [ ] **T6** Create `Badge.jsx` component (verified/premium/featured tiers)

### Sprint 4 (Design System Formalisation)
- [ ] **T7** Create `Button.jsx` with all variants and sizes
- [ ] **T8** Create `Input.jsx`, `Card.jsx`, `Avatar.jsx`, `Tag.jsx`
- [ ] **T9** Migrate all pages to use new component library (replace inline styles)
- [ ] **T10** Add Storybook: `npx storybook@latest init`
- [ ] **T11** Write stories for all 8 new components

---

## Acceptance Criteria
- [ ] All UI colours reference CSS variables (not hardcoded hex)
- [ ] `ProgressBar` renders at correct percentage in Dashboard
- [ ] `Badge` renders with correct colour and icon for each subscription tier
- [ ] `StarRating` works in both display (read-only) and interactive (review submission) modes
- [ ] Storybook runs with stories for all base UI components
- [ ] Inter font loaded from Google Fonts in production
