# Receipt Vault – Current Status

_Last updated: 2026-10-14_

## What Has Been Built (Verified Working)

### 1. App Theme — `lib/app/theme/app_theme.dart`

A complete Material 3 theme with:

- `AppColors` — 20+ static const `Color` tokens for light and dark modes.
- `AppShapes` — 5 `BorderRadius` constants (sm=8, md=12, lg=16, xl=24, full=999).
- `AppTheme.light` and `AppTheme.dark` — full `ThemeData` covering: AppBar, NavigationBar, Card, ElevatedButton, OutlinedButton, TextButton, FAB, InputDecoration, Divider, Chip.
- Text theme with 13 Material text styles using the system sans-serif font (NOT Inter — see Decisions doc).

### 2. App Navigation — `lib/app/router/`

- `app_router.dart` — `GoRouter` instance with `StatefulShellRoute.indexedStack` for 5 branches, plus a top-level `/add` route.
- `app_shell.dart` — `AppShell` widget with a `NavigationBar` containing 5 destinations. The centre **Add** destination is styled as a filled blue rounded-square, tapped it pushes `/add` as a new route rather than switching tab branches.
- Route constants in `AppRoutes` abstract class.

**Navigation structure:**

```
/ (initial: /receipts)
├── StatefulShellRoute (AppShell)
│   ├── Branch 0 → /receipts         (ReceiptsScreen — real UI & components)
│   ├── Branch 1 → /warranties       (WarrantyScreen — placeholder)
│   ├── Branch 2 → /add-placeholder  (SizedBox.shrink — intercepted by shell)
│   ├── Branch 3 → /alerts           (AlertsScreen — placeholder)
│   └── Branch 4 → /settings        (SettingsScreen — placeholder)
└── GoRoute → /add                   (AddReceiptScreen — placeholder)
```

### 3. Entry Point — `lib/main.dart`

`ReceiptVaultApp` widget using `MaterialApp.router` with:
- `theme: AppTheme.light`
- `darkTheme: AppTheme.dark`
- `themeMode: ThemeMode.system`
- `routerConfig: appRouter`

### 4. Receipts Screen UI & Components — `lib/features/receipts/`

A fully functional, responsive Receipts screen matching the 5-tab updated mockup and `DESIGN.md` guidelines:
- **Screen Header**: `AppBar` with `receipt_long` brand icon in primary color, bold "My Receipts" title, and overflow action button.
- **Search Bar** (`ReceiptSearchBar`): 8px radius, white/dark fill, search icon, clear button on text entry, focus state in primary blue.
- **Category Filter Chips** (`CategoryFilterRow`): Horizontally scrollable row with pill-shaped chips ("All", "Electronics", "Food", "Others"). Active chip filled in primary blue with white text; inactive chips styled with surface fill, subtle border, and secondary text.
- **Receipt Card** (`ReceiptCard`): 8px radius, 1px subtle border, ambient shadow (`0px 2px 4px rgba(0,0,0,0.05)`), 48x48 icon circle, product title, store name, right-aligned formatted price, and pill warranty status badge with status indicator dot. Expired items render with strikethrough text, muted colors, and 0.75 opacity.
- **Empty State** (`ReceiptsEmptyState`): Displays pristine state ("No receipts yet. Tap + to add your first receipt") when no receipts exist, and filtered state ("No matching receipts") with a "Reset filters" action button when searches/filters yield zero results.
- **Shared Enums & Presentation Entity**: `WarrantyStatus` enum (`lib/shared/enums/warranty_status.dart`) and `ReceiptCardData` entity (`lib/features/receipts/domain/entities/receipt_card_data.dart`).

| Screen | File | Status |
|--------|------|--------|
| Receipts | `lib/features/receipts/presentation/receipts_screen.dart` | ✅ Real UI & Reusable Components |
| Warranties | `lib/features/warranty/presentation/warranty_screen.dart` | Placeholder |
| Alerts | `lib/features/alerts/presentation/alerts_screen.dart` | Placeholder |
| Settings | `lib/features/settings/presentation/settings_screen.dart` | Placeholder |
| Add Receipt | `lib/features/home/presentation/add_receipt_screen.dart` | Placeholder |

### 5. Shared Widgets & Enums

- `lib/shared/widgets/placeholder_screen.dart` — Reusable `PlaceholderScreen` widget (icon + title + subtitle).
- `lib/shared/enums/warranty_status.dart` — Shared `WarrantyStatus` enum (`active`, `expiringSoon`, `expired`, `none`).

### 6. Tests

- `test/widget_test.dart` — Smoke test: verifies `NavigationBar` renders and all 5 tab labels are visible.
- `test/features/receipts/receipts_screen_test.dart` — 5 unit/widget tests covering:
  - Header, search bar, category chips, and default empty state rendering.
  - Receipt cards list rendering with product details, price, and status badges.
  - Category filter chip selection and empty state transitions.
  - Search query filtering and clearing.
  - Receipt card tap callback execution.

**Last verified check results:**
- `dart format` → All source & test files formatted cleanly.
- `flutter analyze` → **No issues found.**
- `flutter test` → **6/6 tests passed.**

---

## What Does NOT Exist Yet

- **No data model** — No Drift tables, no `Receipt` or `Warranty` classes.
- **No local database** — `drift` and `sqlite3_flutter_libs` packages are in `pubspec.yaml` but zero database code exists.
- **No Riverpod providers** — `flutter_riverpod` is in `pubspec.yaml` and installed, but `ProviderScope` is NOT yet wrapping the app. Riverpod is unused.
- **Remaining Screens are Stubs** — Warranties, Alerts, Settings, and Add Receipt screens remain `PlaceholderScreen` stubs.
- **No receipt creation logic** — No camera, gallery, or manual entry.
- **No OCR** — Not yet a package dependency.
- **No notifications** — No `flutter_local_notifications` or similar package added.
- **No Inter font** — `google_fonts` is NOT a dependency. System font is used.
- **No statistics/analytics** — `lib/features/statistics/` directory is empty.
- **No core utilities** — `lib/core/services/`, `lib/core/storage/`, `lib/core/utils/`, `lib/core/widgets/` are all empty.
- **No app constants** — `lib/app/constants/` is empty.

---

## Installed Dependencies (from `pubspec.yaml`)

### Runtime
| Package | Version | Used? |
|---------|---------|-------|
| `flutter` | SDK | ✅ Yes |
| `cupertino_icons` | ^1.0.8 | ✅ (Material icons used instead) |
| `flutter_riverpod` | ^3.4.3 | ❌ Installed, not wired up |
| `go_router` | ^18.0.2 | ✅ Yes |
| `drift` | ^2.35.2 | ❌ Installed, no DB code |
| `sqlite3_flutter_libs` | ^0.6.0+eol | ❌ Installed with drift |
| `path_provider` | ^2.1.6 | ❌ Installed, not used |
| `path` | ^1.9.1 | ❌ Installed, not used |
| `riverpod_annotation` | ^4.0.7 | ❌ Installed, not used |

### Dev
| Package | Version | Used? |
|---------|---------|-------|
| `flutter_test` | SDK | ✅ Yes |
| `flutter_lints` | ^6.0.0 | ✅ Yes |
| `build_runner` | ^2.15.1 | ❌ Not yet run |
| `riverpod_generator` | ^4.0.9 | ❌ Not yet used |
| `drift_dev` | ^2.35.1 | ❌ Not yet used |
