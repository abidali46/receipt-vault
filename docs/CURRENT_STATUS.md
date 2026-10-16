# Receipt Vault – Current Status

_Last updated: 2026-10-16_

## What Has Been Built (Verified Working)

### 1. App Theme — `lib/app/theme/app_theme.dart`

A complete Material 3 theme with:

- `AppColors` — 20+ static const `Color` tokens for light and dark modes, including resolved M3 tokens: `primary` (`#004AC6` deep blue for titles/icons), `primaryContainer` (`#2563EB` action blue for chips, Add button, and focus rings), and `secondaryContainer` (`#D0E1FB` nav active indicator).
- `AppShapes` — 5 `BorderRadius` constants (sm=8, md=12, lg=16, xl=24, full=999).
- `AppTheme.light` and `AppTheme.dark` — full `ThemeData` covering: AppBar, NavigationBar, Card, ElevatedButton, OutlinedButton, TextButton, FAB, InputDecoration, Divider, Chip.
- Text theme with 13 Material text styles using the system sans-serif font (NOT Inter — see Decisions doc).

### 2. App Navigation — `lib/app/router/`

- `app_router.dart` — `GoRouter` instance with `StatefulShellRoute.indexedStack` for 5 branches, plus a top-level `/add` route.
- `app_shell.dart` — `AppShell` widget with a `NavigationBar` containing 5 destinations. The centre **Add** destination is styled as a filled blue rounded-square using `primaryContainer`, tapped it pushes `/add` as a new route rather than switching tab branches.
- Route constants in `AppRoutes` abstract class.

**Navigation structure:**

```
/ (initial: /receipts)
├── StatefulShellRoute (AppShell)
│   ├── Branch 0 → /receipts         (ReceiptsScreen — real UI & reactive database stream)
│   ├── Branch 1 → /warranties       (WarrantyScreen — placeholder)
│   ├── Branch 2 → /add-placeholder  (SizedBox.shrink — intercepted by shell)
│   ├── Branch 3 → /alerts           (AlertsScreen — placeholder)
│   └── Branch 4 → /settings        (SettingsScreen — placeholder)
└── GoRoute → /add                   (AddReceiptScreen — placeholder)
```

### 3. Entry Point & State Management — `lib/main.dart`

`ReceiptVaultApp` widget using `MaterialApp.router` wrapped with `ProviderScope`:
- `ProviderScope` root container for Riverpod providers.
- `theme: AppTheme.light`
- `darkTheme: AppTheme.dark`
- `themeMode: ThemeMode.system`
- `routerConfig: appRouter`

### 4. Local Database (Drift + SQLite) — `lib/core/storage/`

- **Database**: `AppDatabase` (`lib/core/storage/app_database.dart`), generated code in `app_database.g.dart`.
- **Table**: `Receipts` table with:
  - `id`: Auto-increment integer primary key
  - `productName`: Required text
  - `storeName`: Optional text
  - `category`: Optional text
  - `purchaseDate`: Required dateTime
  - `totalAmount`: Required real (double)
  - `warrantyDurationDays`: Optional integer (null = no warranty)
  - `notes`: Optional text
  - `imagePath`: Optional text (local image path)
  - `createdAt`: Required dateTime (default `currentDateAndTime`)
- **Storage Strategy**: Persistent local SQLite database located in `getApplicationDocumentsDirectory() / receipt_vault.sqlite`. Executes via `NativeDatabase.createInBackground` on a background isolate to keep UI frame rendering smooth.
- **Test Isolation**: Accepts an optional `QueryExecutor`, allowing fast in-memory execution via `NativeDatabase.memory()`.
- **Provider**: `databaseProvider` (`lib/core/storage/database_provider.dart`) exposes the singleton `AppDatabase` instance with lifecycle disposal.

### 5. Receipts Repository & Domain Services — `lib/features/receipts/`

- **Repository Interface**: `ReceiptsRepository` (`lib/features/receipts/domain/repositories/receipts_repository.dart`) declaring:
  - `watchReceipts()`: Reactive Drift stream of raw `Receipt` rows.
  - `watchReceiptCards()`: Reactive Drift stream mapped to `ReceiptCardData` presentation models.
  - CRUD operations: `getAllReceipts()`, `getReceiptById(id)`, `insertReceipt(companion)`, `updateReceipt(receipt)`, `deleteReceipt(id)`.
- **Repository Implementation**: `DriftReceiptsRepository` (`lib/features/receipts/data/repositories/drift_receipts_repository.dart`) backed by `AppDatabase`. Queries order by `purchaseDate` descending and `id` descending.
- **Warranty Calculator Service**: `WarrantyCalculator` (`lib/features/receipts/domain/services/warranty_calculator.dart`) providing centralized, reproducible calculation of:
  - `WarrantyStatus` (`none`, `expired`, `expiringSoon`, `active`)
  - Human-friendly status badge labels ('No warranty', 'Expired', 'Expires today', 'X days left', 'X year(s) left')
  - Material Category icon mappings (`Electronics` -> `Icons.devices_outlined`, `Food` -> `Icons.restaurant_outlined`, etc.).
- **Presentation Mapping**: `ReceiptCardData.fromReceipt(Receipt receipt, {DateTime? now})` constructor maps SQLite database rows directly to presentation models.
- **Riverpod Providers**: `lib/features/receipts/presentation/providers/receipts_providers.dart` exposing:
  - `receiptsRepositoryProvider`: Provider for `ReceiptsRepository` backed by `databaseProvider`.
  - `receiptsStreamProvider`: StreamProvider for `List<ReceiptCardData>` providing reactive updates to the UI.

### 6. Receipts Screen UI & Components — `lib/features/receipts/presentation/`

A fully functional, responsive Receipts screen matching the 5-tab updated mockup and `DESIGN.md` guidelines, wired reactively to the database stream:
- **Reactive Integration**: Connects via `ConsumerStatefulWidget` to `receiptsStreamProvider`.
- **Screen States**:
  - **Loading State**: Displays `CircularProgressIndicator` during initial database load; does not prematurely flash empty state.
  - **Error State**: Displays friendly error icon, title, and details if the database stream fails.
  - **Pristine Empty State**: Displays empty state illustration text ("No receipts yet. Tap + to add your first receipt") when the database has zero records.
  - **Filtered Empty State**: Displays "No matching receipts" with a "Reset filters" button when search queries or category filters yield zero results.
  - **Populated List**: Displays reactive `ListView.separated` of `ReceiptCard` items, updating automatically whenever database mutations occur.
- **Screen Header**: `AppBar` with `receipt_long` brand icon in primary color, bold "My Receipts" title, and overflow action button.
- **Search Bar** (`ReceiptSearchBar`): 8px radius, white/dark fill, search icon, clear button on text entry, focus state in primaryContainer blue.
- **Category Filter Chips** (`CategoryFilterRow`): Horizontally scrollable row with pill-shaped chips ("All", "Electronics", "Food", "Others"). Active chip filled in primaryContainer blue with white text; inactive chips styled with surface fill, subtle border, and secondary text.
- **Receipt Card** (`ReceiptCard`): 8px radius, 1px subtle border, ambient shadow (`0px 2px 4px rgba(0,0,0,0.05)`), 48x48 icon circle, product title, store name, right-aligned formatted price, and pill warranty status badge with status indicator dot. Expired items render with strikethrough text, muted colors, and 0.75 opacity.

| Screen | File | Status |
|--------|------|--------|
| Receipts | `lib/features/receipts/presentation/receipts_screen.dart` | ✅ Real UI connected to reactive database stream via Riverpod |
| Warranties | `lib/features/warranty/presentation/warranty_screen.dart` | Placeholder stub |
| Alerts | `lib/features/alerts/presentation/alerts_screen.dart` | Placeholder stub |
| Settings | `lib/features/settings/presentation/settings_screen.dart` | Placeholder stub |
| Add Receipt | `lib/features/home/presentation/add_receipt_screen.dart` | Placeholder stub |

### 7. Shared Widgets & Enums

- `lib/shared/widgets/placeholder_screen.dart` — Reusable `PlaceholderScreen` widget (icon + title + subtitle).
- `lib/shared/enums/warranty_status.dart` — Shared `WarrantyStatus` enum (`active`, `expiringSoon`, `expired`, `none`).

### 8. Tests (34 Passed)

- `test/widget_test.dart` (1 test): Smoke test verifying `NavigationBar` and destinations with in-memory database provider.
- `test/core/storage/app_database_test.dart` (7 tests):
  - Starts with empty receipts table.
  - Inserts and reads receipt with required fields only.
  - Inserts and reads receipt with all optional fields populated.
  - Updates existing receipt.
  - Deletes receipt.
  - Queries and filters receipts by category and product name.
  - Watches receipts table stream for real-time reactivity on mutations.
- `test/core/storage/database_provider_test.dart` (1 test):
  - Verifies `databaseProvider` can be read and overridden with an in-memory database in `ProviderContainer`.
- `test/features/receipts/receipts_repository_test.dart` (16 tests):
  - Unit tests for `WarrantyCalculator`: none, expired, expiringSoon (today, 1 day, <= 30 days), active (days left, 1 year, 2 years).
  - Category icon mappings.
  - Presentation mapping with `ReceiptCardData.fromReceipt`.
  - Drift repository CRUD, sorting, and real-time stream emissions.
- `test/features/receipts/receipts_screen_test.dart` (9 tests):
  - Header, search bar, category filters, and default empty state rendering in light mode.
  - Receipt cards list rendering with product details, price, and status badges.
  - Category filter chip selection and empty state transitions.
  - Search query filtering and clearing.
  - Receipt card tap callback execution.
  - Dark mode rendering and interaction: search, category filter, and filter reset.
  - Loading state shows `CircularProgressIndicator` on initial load without prematurely showing empty state.
  - Error state displays user-friendly error UI when provider encounters an error.
  - Database stream integration: in-memory Drift insertions immediately appear and update reactively in the UI.

**Last verified check results:**
- `dart format` → All source & test files formatted cleanly.
- `flutter analyze` → **No issues found.**
- `flutter test` → **34/34 tests passed.**

---

## What Does NOT Exist Yet

- **No warranty tracker screen** — Dedicated active warranties screen (`/warranties`) remains a placeholder stub.
- **Remaining Screens are Stubs** — Alerts, Settings, and Add Receipt screens remain `PlaceholderScreen` stubs.
- **No receipt creation form** — No camera, gallery image picker, or manual entry forms.
- **No OCR** — Not yet added as a dependency.
- **No notifications** — No local push notifications or scheduled warranty reminders.
- **No Inter font** — System font is used.
- **No statistics/analytics** — `lib/features/statistics/` directory is empty.

---

## Installed Dependencies (from `pubspec.yaml`)

### Runtime
| Package | Version | Used? |
|---------|---------|-------|
| `flutter` | SDK | ✅ Yes |
| `cupertino_icons` | ^1.0.8 | ✅ (Material icons used instead) |
| `flutter_riverpod` | ^3.4.3 | ✅ Yes (ProviderScope + databaseProvider + receiptsStreamProvider) |
| `go_router` | ^18.0.2 | ✅ Yes |
| `drift` | ^2.35.2 | ✅ Yes (AppDatabase + Receipts table + DriftReceiptsRepository) |
| `sqlite3_flutter_libs` | ^0.6.0+eol | ✅ Yes (SQLite native library) |
| `path_provider` | ^2.1.6 | ✅ Yes (getApplicationDocumentsDirectory) |
| `path` | ^1.9.1 | ✅ Yes (Database file path joining) |
| `riverpod_annotation` | ^4.0.7 | ❌ Available for future providers |

### Dev
| Package | Version | Used? |
|---------|---------|-------|
| `flutter_test` | SDK | ✅ Yes |
| `flutter_lints` | ^6.0.0 | ✅ Yes |
| `build_runner` | ^2.15.1 | ✅ Yes (Generated code up to date) |
| `riverpod_generator` | ^4.0.9 | ❌ Available for future providers |
| `drift_dev` | ^2.35.1 | ✅ Yes (Generated app_database.g.dart) |
