# Receipt Vault – Project Overview

## What Is This App?

**Receipt Vault** is a Flutter mobile application for Android and iOS that lets users:

1. **Capture and store purchase receipts** — by photographing a paper receipt, importing an image from the gallery, or entering details manually.
2. **Track product warranties** — by linking warranty durations to receipts and computing expiry dates automatically.
3. **Review warranty alerts** — calculated in-app reminders and urgency-sorted alerts for expiring warranties.
4. **Browse and search receipts** — with category filtering, search, and status badges.

The design philosophy is described in `design/DESIGN.md` as **"Digital Peace of Mind"** — a minimalist-modern aesthetic targeting busy professionals who need a reliable, clutter-free way to manage high-value purchases.

## Project Name Discrepancy

> ⚠️ **Note:** `design/DESIGN.md` calls the app "Lumina Ledger" in its YAML front-matter but describes "Receipt Vault" throughout the prose. The Flutter package name is `receipt_vault`. All code uses "Receipt Vault". Treat "Lumina Ledger" as a legacy draft artefact — do NOT rename files or the package to match it.

## Goals

- Simple, intuitive UX for non-technical users.
- Fully offline-first — all data stored locally with Drift (SQLite).
- Light and dark mode support from launch.
- No authentication, cloud sync, or account system in the initial version.

## Target Platforms

- **Primary:** Android, iOS
- **Secondary (low priority):** The Flutter project includes Windows, macOS, Linux, and Web platform scaffolding — these exist by default and are not targeted for development.

## Key Features Planned

| # | Feature | Status |
|---|---------|--------|
| 1 | Bottom navigation shell (5 tabs) | ✅ Implemented |
| 2 | App theme (Material 3, light/dark) | ✅ Implemented |
| 3 | go_router navigation with StatefulShellRoute | ✅ Implemented |
| 4 | Receipts screen (real UI, reactive stream, multi-field search & 5-way sorting) | ✅ Implemented |
| 5 | Receipt data model (Drift + SQLite) | ✅ Implemented |
| 6 | Receipt creation / capture flow & local image storage | ✅ Implemented |
| 7 | Receipt detail screen & editing/deletion | ✅ Implemented |
| 8 | Warranty tracker screen (state-aware & reactive) | ✅ Implemented |
| 9 | In-app warranty alerts screen | ✅ Implemented |
| 10 | Settings screen (theme persistence, privacy guarantee & CSV export) | ✅ Implemented |
| 11 | Local push notifications | ⬜ Not started |
| 12 | OCR receipt scanning | ⬜ Not started |


## Implemented Receipts Screen Architecture

The **Receipts screen** (`lib/features/receipts/presentation/receipts_screen.dart`) is built to strictly match `design/mockups/my_receipts_home_updated_nav/` and `design/DESIGN.md`. It is composed of decoupled, reusable presentation components:

1. **Screen Header (`ReceiptsScreen`)**:
   - `AppBar` with `receipt_long_outlined` icon in `AppColors.primary` (`#004AC6` in light mode, `#B4C5FF` in dark mode) and bold title "My Receipts".
   - Overflow options menu (`Icons.more_vert`) supporting quick reset filters and navigation.
2. **Search Input (`ReceiptSearchBar`)**:
   - `lib/features/receipts/presentation/widgets/receipt_search_bar.dart`
   - 8px corner radius (`AppShapes.radiusSm`), search icon, clear button suffix on text input, and `primaryContainer` blue focused border. Case-insensitive multi-field search across product name, store name, and category.
3. **Category Filters (`CategoryFilterRow`)**:
   - `lib/features/receipts/presentation/widgets/category_filter_row.dart`
   - Horizontally scrollable pill-shaped chips: `"All"`, `"Electronics"`, `"Food"`, `"Clothing"`, `"Home"`, `"Others"`.
   - Selected chip: `colorScheme.primaryContainer` (`#2563EB`) fill with white text.
   - Inactive chips: Surface fill with subtle border (`borderLight`/`borderDark`) and secondary text.
4. **Receipt Discovery & Sorting Bar (`ReceiptSortFilterBar`)**:
   - `lib/features/receipts/presentation/widgets/receipt_sort_filter_bar.dart`
   - Dynamic item counts ("X receipts" or "X of Y receipts" when filtered).
   - Inline pill "Clear" action button when filters are active.
   - Material 3 `PopupMenuButton<ReceiptSortOption>` offering 5 sorting strategies: Newest purchase, Oldest purchase, Product name (A–Z), Amount (high to low), Amount (low to high).
5. **Receipt Item Card (`ReceiptCard`)**:
   - `lib/features/receipts/presentation/widgets/receipt_card.dart`
   - 8px corner radius, 1px subtle border, soft ambient shadow (`0px 2px 4px rgba(0,0,0,0.05)`).
   - Left: 48×48 circular icon container + product name + store name.
   - Right: Right-aligned price (`$899`) + pill status badge with colored indicator dot (active green, expiring red, or expired gray).
   - Expired items display strikethrough text, muted colors, and `0.75` opacity.
6. **Empty State (`ReceiptsEmptyState`)**:
   - `lib/features/receipts/presentation/widgets/receipts_empty_state.dart`
   - Pristine state: Shows `receipt_long_outlined` icon with "No receipts yet. Tap + to add your first receipt."
   - Filtered state: Shows `search_off_outlined` icon with "No matching receipts", contextual explanation naming the search query and/or category, and a "Reset filters" button.
7. **Data & Services**:
   - `lib/features/receipts/domain/entities/receipt_card_data.dart` — Pure presentation entity with `purchaseDate`.
   - `lib/features/receipts/domain/entities/receipt_sort_option.dart` — Sorting strategy enum.
   - `lib/features/receipts/domain/services/receipt_discovery_service.dart` — In-memory filtering and sorting domain service.
   - `lib/shared/enums/warranty_status.dart` — Shared `WarrantyStatus` enum (`active`, `expiringSoon`, `expired`, `none`).

## Design References

All design assets live in the `design/` directory at the project root. **Do not move or duplicate them.**

```
design/
├── DESIGN.md                          ← Design tokens, colour palette, typography, components
├── component-specs/
│   ├── all components of the app.docx ← Component-level specifications
│   └── Receipt keeper full details.docx ← Full product requirements / detailed spec
└── mockups/
    ├── my_receipts_home/              ← Receipts list screen (original nav: 3 tabs)
    ├── my_receipts_home_updated_nav/  ← Receipts list screen (UPDATED nav: 5 tabs) ← USE THIS
    ├── receipt_details_samsung_mobile/← Receipt detail / warranty progress screen
    ├── active_warranties/             ← Warranties tab screen
    ├── add_receipt/                   ← Add receipt form screen
    ├── alerts/                        ← In-app warranty alerts screen
    └── settings/                      ← Settings screen
```

Each mockup directory contains:
- `screen.png` — Visual reference image
- `code.html` — Reference HTML/Tailwind implementation (for visual and colour reference only — do NOT copy HTML/Tailwind to Flutter)
