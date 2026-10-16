# Receipt Vault – Development Roadmap

Tasks are ordered by dependency. Later tasks build on earlier ones.
Do not skip ahead — the database task unlocks all real feature work.

---

## ✅ Phase 0 — Foundation (Complete)

- [x] Flutter project structure (feature-first)
- [x] Material 3 app theme (`AppColors`, `AppShapes`, `AppTheme.light/dark`)
- [x] GoRouter navigation with `StatefulShellRoute`
- [x] 5-tab bottom navigation shell (`AppShell`)
- [x] Placeholder screens for all 5 destinations
- [x] Smoke test (`flutter test`)
- [x] `flutter analyze` clean

---

## 🔲 Phase 1 — Data Model & Database

**Priority: FIRST — everything else depends on this.**

- [x] **Task 1A: Resolve the primary colour conflict (D-008)**
  - Inspected `design/mockups/my_receipts_home_updated_nav/screen.png` and `code.html`.
  - Mapped `#004AC6` to `primary` (brand titles/icons in light mode, `#B4C5FF` in dark mode) and `#2563EB` to `primaryContainer` (active chips, Add button, focus rings).
  - Updated `AppColors`, `AppTheme.light`, and `AppTheme.dark` in `app_theme.dart`, and documented in `DECISIONS.md`.

### Task 1B: Add Inter font

1. Add `google_fonts: ^6.x.x` to `pubspec.yaml`.
2. Update `AppTheme._buildTextTheme` to use `GoogleFonts.interTextTheme(...)`.
3. Run `flutter pub get` and `flutter analyze`.

- [x] **Task 1C: Define the Receipt data model & Drift SQLite database foundation**
  - Created `lib/core/storage/app_database.dart` with Drift `@DriftDatabase` and `Receipts` table.
  - Configured persistent background isolate SQLite storage (`receipt_vault.sqlite` via `NativeDatabase.createInBackground`).
  - Created `lib/core/storage/database_provider.dart` with Riverpod `databaseProvider`.
  - Wrapped app with `ProviderScope` in `lib/main.dart` and `test/widget_test.dart`.
  - Ran `build_runner` and generated `lib/core/storage/app_database.g.dart`.
  - Added CRUD, filter, and stream unit tests using in-memory database (`test/core/storage/app_database_test.dart` and `database_provider_test.dart`).

---

## ✅ Phase 2 — Receipts Screen & Database Integration (Complete)

**Reference:** `design/mockups/my_receipts_home_updated_nav/screen.png` and `code.html`

- [x] **Task 2B: ReceiptCard widget**
  - Row layout: 48×48 icon circle | product name + store | price + status badge
  - Status badge: green dot (active), red dot (<30 days left), grey dot (expired)
  - Expired items: strikethrough on product name, reduced opacity (0.75)
  - 8px radius, subtle border, ambient shadow (`0px 2px 4px rgba(0,0,0,0.05)`)
- [x] **Task 2C: Filter chips (`CategoryFilterRow`)**
  - Pill-shaped horizontally scrollable row: All, Electronics, Food, Others
  - Active: primary blue background with white text
  - Inactive: surface background with subtle border
- [x] **Task 2D: Search bar (`ReceiptSearchBar`)**
  - Search icon, clear button suffix, 8px radius, primary blue focus ring
- [x] **Task 2E: ReceiptsScreen UI & Empty State (`ReceiptsEmptyState`)**
  - Real screen header with `receipt_long` icon and "My Receipts" title
  - Pristine empty state when no receipts are present
  - Filtered empty state with "Reset filters" action button
  - Presentation entity `ReceiptCardData` and `WarrantyStatus` enum
- [x] **Task 2A: ReceiptsRepository & Database integration**
  - Created `ReceiptsRepository` interface and `DriftReceiptsRepository` implementation using Drift `AppDatabase`.
  - Created `WarrantyCalculator` service for centralized warranty calculations and category icon mapping.
  - Implemented `ReceiptCardData.fromReceipt` mapping database rows to presentation models.
  - Added Riverpod `receiptsRepositoryProvider` and `receiptsStreamProvider`.
  - Connected `ReceiptsScreen` to `receiptsStreamProvider` via `ConsumerStatefulWidget` with loading (`CircularProgressIndicator`), error (`_buildErrorState`), and empty states.
  - Verified real-time reactivity, search/category filtering, and dark mode.
  - Added 19 new repository and widget tests (total 34 tests passing).

---

## 🔲 Phase 3 — Receipt Creation

**Reference:** `design/mockups/add_receipt/screen.png` and `code.html`

### Task 3A: Add `image_picker` package

1. Add `image_picker: ^1.x.x` to `pubspec.yaml`.
2. Configure Android permissions in `android/app/src/main/AndroidManifest.xml`.
3. Configure iOS permissions in `ios/Runner/Info.plist`.

### Task 3B: AddReceiptScreen — form UI

Replace the placeholder with a real form:
- Product name (required)
- Store name (optional)
- Category selector (chips or dropdown)
- Purchase date (date picker)
- Total amount (number input)
- Warranty duration (days or "No warranty" option)
- Notes (optional multi-line)
- Receipt image: camera or gallery picker

### Task 3C: Save logic

On submit: validate → create `ReceiptsCompanion` → call repository `.addReceipt()` → `context.pop()`.

---

## 🔲 Phase 4 — Receipt Details

**Reference:** `design/mockups/receipt_details_samsung_mobile/screen.png` and `code.html`

- Add route `/receipts/:id` (nested under the receipts branch).
- `ReceiptDetailScreen`: product name + warranty badge, receipt image preview, details card (store, price, dates), warranty progress bar, Edit / Delete actions.
- Progress bar: green when active, red when < 30 days.

---

## 🔲 Phase 5 — Warranties Screen

**Reference:** `design/mockups/active_warranties/screen.png` and `code.html`

- Replace `WarrantyScreen` placeholder.
- Shows only receipts that have a warranty duration set.
- Card per item: product name, category, days remaining badge, progress bar.
- Badge colours: green (safe), amber (expiring soon ≤ 30 days), red (urgent ≤ 7 days).
- Sort by soonest expiry first.

---

## 🔲 Phase 6 — Alerts Screen

**Reference:** `design/mockups/alerts/screen.png` and `code.html`

- Replace `AlertsScreen` placeholder.
- Lists upcoming warranty expiry notifications (sorted by date).
- Mark as read / dismiss functionality.

---

## 🔲 Phase 7 — Local Push Notifications

- Add `flutter_local_notifications` package.
- Schedule notifications N days before warranty expiry.
- Request permissions (Android 13+, iOS).
- Settings screen toggle for notification preferences.

---

## 🔲 Phase 8 — Settings Screen

**Reference:** `design/mockups/settings/screen.png` and `code.html`

- Replace `SettingsScreen` placeholder.
- Sections: Appearance (theme mode), Notifications (toggle + lead-time), Data (export, clear data), About.

---

## 🔲 Phase 9 — Statistics (Low Priority)

- `lib/features/statistics/` — Empty directory, no mockup provided.
- Basic charts: total receipts, total spend, warranties by status.
- Use `fl_chart` or similar when the time comes.

---

## 🔲 Phase 10 — OCR (Future, Lowest Priority)

- Scan a receipt photo and auto-fill form fields.
- Options: Google ML Kit (on-device), or a cloud API.
- Do not plan implementation until Phase 3 is complete.
