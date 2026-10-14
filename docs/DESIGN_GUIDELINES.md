# Receipt Vault – Design Guidelines

> **Source of truth priority:**
> 1. `design/mockups/my_receipts_home_updated_nav/` (most recent nav mockup — 5-tab version)
> 2. Other mockups in `design/mockups/`
> 3. `design/DESIGN.md` (design tokens in YAML front-matter + prose)
> 4. `design/component-specs/` (.docx files — open separately for full spec)
>
> When mockups and DESIGN.md disagree, the mockup takes precedence for visual decisions. Note the conflict instead of silently resolving it.

---

## Colour Palette

### Tokens from `design/DESIGN.md` (prose description)

| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#2563EB` | Primary actions, active states, brand emphasis |
| Secondary | `#64748B` | Secondary info, icons, supporting text |
| Tertiary / Success | `#10B981` (emerald green) | "Active Warranty", "Verified Receipt" badges |
| Background / Neutral | `#F9FAFB` | Page background |
| Accent Red / Error | `#EF4444` | Expiring warranties, critical alerts |

### Tokens from HTML Mockups (YAML front-matter in DESIGN.md)

The mockup HTML files use a Tailwind-based Material Design 3 color system. These are the actual colors used in the screen designs:

| Token | Hex | Flutter Usage |
|-------|-----|---------------|
| `primary` | `#004AC6` | Deep blue — primary actions |
| `primary-container` | `#2563EB` | Bright blue — nav active indicator, Add button |
| `on-primary` | `#FFFFFF` | Text on primary buttons |
| `secondary` | `#505F76` | Secondary text, icons |
| `secondary-container` | `#D0E1FB` | Active nav tab background |
| `surface` | `#F8F9FA` | Page background |
| `surface-container-lowest` | `#FFFFFF` | Card backgrounds |
| `surface-container` | `#EDEEEF` | Icon container backgrounds |
| `on-surface` | `#191C1D` | Primary text |
| `on-surface-variant` | `#434655` | Secondary text, hints |
| `outline` | `#737686` | Borders, subtle text |
| `outline-variant` | `#C3C6D7` | Light borders |
| `tertiary` | `#006242` | Success / active warranty (green) |
| `tertiary-container` | `#007D55` | Active warranty badge background |
| `on-tertiary-container` | `#BDFFDB` | Text on tertiary container |
| `error` | `#BA1A1A` | Expired / expiring soon (red) |
| `error-container` | `#FFDAD6` | Error badge background |

> ⚠️ **Colour conflict:** The `AppColors` values in `lib/app/theme/app_theme.dart` were implemented using the prose values from DESIGN.md (e.g., primary `#2563EB`, error `#EF4444`), **not** the mockup Tailwind values (primary `#004AC6`, error `#BA1A1A`). When implementing real screens, reconcile these by checking the mockup `.png` images visually and aligning `AppColors` before building the screen.

---

## Typography

All designs use **Inter**. The Flutter app currently uses the **system font** (no `google_fonts` package added yet).

### Type Scale (from mockup HTML)

| Token | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| `display-lg` | 32px | 700 | 40px | -0.02em | Desktop dashboard headers |
| `display-lg-mobile` | 24px | 700 | 32px | -0.01em | Mobile screen titles |
| `headline-md` | 20px | 600 | 28px | — | Card titles, item names |
| `body-lg` | 16px | 400 | 24px | — | Detail text, form labels |
| `body-sm` | 14px | 400 | 20px | — | Secondary metadata |
| `label-caps` | 12px | 600 | 16px | 0.05em | Category tags, status badges, nav labels |

---

## Spacing System

Based on a 4px base grid:

| Token | Value |
|-------|-------|
| `xs` | 4px |
| `sm` | 8px |
| `md` | 16px |
| `lg` | 24px |
| `xl` | 32px |
| `gutter` | 16px (page margins on mobile) |

---

## Shape / Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| DEFAULT | 4px (0.25rem) | Very subtle rounding |
| `lg` | 8px (0.5rem) | **Cards, input fields** |
| `xl` | 12px (0.75rem) | Larger containers |
| `full` | 9999px | **Buttons, filter chips, badges, nav indicators** |

> The design spec distinguishes card shapes (8px rectangular) from button shapes (pill/full). This reflects the principle: rectangular = data, rounded = action.

---

## Component Specifications

### Receipt Card (from mockup)

- Background: `surface-container-lowest` (#FFFFFF)
- Border: `1px solid #F1F5F9`
- Shadow: `0px 2px 4px rgba(0,0,0,0.05)` (ambient)
- Hover: shadow increases to `0px 4px 12px rgba(0,0,0,0.08)`, border → `#E2E8F0`, lifts 1px
- Border radius: 8px (`rounded-lg`)
- Padding: 16px (`md`)
- Layout: Row — left (icon circle + name/store) / right (price + status badge)
- Icon: 48x48 circle, `surface-container` background, `secondary` icon color
- Product name: `headline-md`, `on-surface`
- Store name: `body-sm`, `outline`
- Price: `headline-md`, `on-surface`, right-aligned
- Status badge: pill-shaped, colored dot + `label-caps` text
  - Active (>30 days): green dot, `tertiary` text
  - Expiring (<30 days): red dot, `error` text
  - Expired: grey dot, `outline` text + strikethrough on product name

### Filter Chips (from mockup)

- Inactive: `surface-container-lowest` background, `outline-variant` border, `on-surface-variant` text
- Active: `primary-container` background, `on-primary` text
- Shape: pill (`full`)
- Size: `body-sm` text, `md` horizontal padding, `xs` vertical padding

### Navigation Bar (Implemented — updated 5-tab version)

Based on `my_receipts_home_updated_nav/code.html`:
- 5 tabs: Receipts, Warranties, Add (centre), Alerts, Settings
- Background: `surface-container-lowest` with top shadow `0px -2px 4px rgba(0,0,0,0.05)`
- Active tab: `secondary-container` background, rounded pill indicator
- Add button: Larger (56x56), `primary-container` background, elevated, -8px top margin (visually raised)
- Shadow above Add button: wrapped in white `p-2 rounded-full shadow-sm` container

> Currently implemented with `NavigationBar` (Material 3) using a filled rounded-square for Add. This differs slightly from the mockup's raised circle design. Refine when building the receipts screen.

### Warranty Progress Bar (from receipt-details mockup)

- Track: `surface-variant` background, 4px height, rounded full
- Fill: `tertiary-container` (green) when active, `error` (red) when < 30 days
- Label row: `label-caps` "Warranty Progress" left, status text right

### Status Badges

- Active: light green background (`tertiary-container/20`), dark green text (`tertiary`)
- Expiring Soon: amber background, amber-800 text
- Expired / Urgent: `error-container` background, `on-error-container` text
- Shape: pill, `label-caps` text, optional icon preceding text

---

## Elevation / Shadows

| Level | Usage | Shadow |
|-------|-------|--------|
| 0 | Background | None |
| 1 | Cards | `0px 2px 4px rgba(0,0,0,0.05)` |
| 2 | Modals / Overlays | `0px 10px 25px rgba(0,0,0,0.10)` |
| 3 | FAB / Add button | `shadow-lg` |

---

## Layout

- Mobile: fluid, full-width, 16px (`gutter`) page margins
- Desktop: centered 1200px max-width container
- App targets mobile-first. Desktop is not a priority.
- Sticky top AppBar on scroll, fixed bottom NavigationBar

---

## Icons

The mockups use **Material Symbols Outlined** (variable font). Flutter uses `Icons.*` (Material icons). Approximate equivalents:

| Mockup symbol | Flutter `Icons.*` |
|--------------|-------------------|
| `receipt_long` | `Icons.receipt_long_outlined` |
| `smartphone` | `Icons.smartphone_outlined` |
| `laptop_mac` | `Icons.laptop_mac_outlined` |
| `verified_user` | `Icons.verified_outlined` |
| `notifications` | `Icons.notifications_outlined` |
| `settings` | `Icons.settings_outlined` |
| `add` / `add_circle` | `Icons.add_circle_outline` |
| `arrow_back` | `Icons.arrow_back` |
| `share` | `Icons.share_outlined` |
| `delete` | `Icons.delete_outlined` |
| `edit` | `Icons.edit_outlined` |
