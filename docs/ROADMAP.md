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
- [x] **Task 3D: Improve receipt discovery**
  - Enhanced search to cover product name, store name, and category with case-insensitivity.
  - Expanded category filter chips row to include full app categories (`All`, `Electronics`, `Food`, `Clothing`, `Home`, `Others`).
  - Added 5 sorting strategies via `ReceiptSortOption`: Newest purchase (default), Oldest purchase, Product name (A–Z), Amount (high to low), Amount (low to high).
  - Built `ReceiptSortFilterBar` widget with dynamic results count ("X receipts" or "X of Y receipts"), inline "Clear" action button, and Material 3 sort popup menu.
  - Implemented `ReceiptDiscoveryService` domain service for pure in-memory filtering and deterministic multi-attribute sorting with ID tie-breaking.
  - Enhanced `ReceiptsEmptyState` to provide detailed contextual feedback on empty query/category results, explaining what criteria matched zero items and offering a "Reset filters" action.
  - Preserved full database reactivity to real-time inserts, edits, and deletions without redundant SQL queries.
  - Added 18 unit and widget tests in `test/features/receipts/receipt_discovery_test.dart` (131 total tests passing in suite).

---

## 🔲 Phase 3 — Receipt Creation & Add Flow

**Reference:** `design/mockups/add_receipt/screen.png` and `code.html`

- [x] **Task 2B: Add Receipt form UI (`AddReceiptScreen`)**
  - Reused existing `/add` route connected to the center Add destination in `AppShell`.
  - Implemented `AddReceiptScreen` matching `design/mockups/add_receipt/code.html` and M3 theme tokens.
  - Built required product name field, store name, category choice chips (with icons), price numeric input with `$` prefix, date picker, warranty dropdown presets (No warranty, 6m, 1y, 2y, 3y, Custom duration) with custom days field, and multi-line notes.
  - Built dashed outline photo placeholder with `Icons.add_a_photo_outlined` and user affordance SnackBar.
  - Form validation: missing required fields, non-positive amounts, invalid custom warranty days.
  - Unsaved changes guard: `PopScope` and BackButton interception with "Discard changes?" confirmation dialog.
  - Save Receipt action: validates form, executes optional `onSubmit` callback, and displays informational SnackBar.
  - Added 10 tests (9 widget tests in `test/features/home/add_receipt_screen_test.dart` and 1 navigation test in `test/widget_test.dart`, total 44 tests passing).

- [x] **Task 2C: Connect Add Receipt form to SQLite persistence**
  - Connected `AddReceiptScreen` to `ReceiptsRepository.insertReceipt` via `receiptsRepositoryProvider`.
  - Mapped form values (required product name, validated non-negative amount, purchase date, optional category, store name, notes, and non-negative warranty duration days) to Drift `ReceiptsCompanion`.
  - Implemented duplicate submission prevention via `_isSaving` state, button disabling, progress spinner, and back navigation lock.
  - Implemented error handling with error SnackBar and input preservation if database write fails.
  - On successful save, returns to `ReceiptsScreen`, which reactively displays the new receipt card through the Drift `watchReceiptCards()` stream.
  - Added targeted tests for persistence, error resilience, and end-to-end add flow (14/14 targeted tests passed, 46 total in suite).

- [x] **Task 2D: Add receipt photo selection and local file storage**
  - Integrated `image_picker: ^1.2.4` for device gallery selection and camera capture.
  - Configured iOS `Info.plist` with `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`.
  - Created `ReceiptImageService` abstraction and Riverpod provider `receiptImageServiceProvider` in `lib/core/storage/receipt_image_service.dart`.
  - Implemented persistent file copying into `getApplicationDocumentsDirectory() / receipt_images / receipt_<microseconds>.<ext>`, eliminating dependence on volatile system cache directories.
  - Built interactive photo preview in `AddReceiptScreen` with "Replace" and "Remove" controls.
  - Connected local persistent image path to `Receipts.imagePath` in SQLite on save.
  - Safe error fallback for missing or corrupted images (`_buildMissingImageFallback`) and leading thumbnail support in `ReceiptCard`.
  - Safe unreferenced file cleanup ensuring no files referenced by existing saved receipts are ever deleted.
  - Robust exception handling for user cancellation, permission denials, unsupported platforms/missing hardware, and file copy errors while preserving all other form fields.
  - Added 13 comprehensive widget tests covering camera, gallery, replace, remove, SQLite persistence, errors, and discard cleanup (26/26 targeted tests passing, 59 total in suite).

---

## ✅ Phase 4 — Receipt Details, Editing & Deletion (Complete)

**Reference:** `design/mockups/receipt_details_samsung_mobile/screen.png` and `code.html`

- [x] **Task 2E: Receipt Details & Editing**
  - Added GoRouter routes `/receipts/:id` and `/receipts/:id/edit` with `parentNavigatorKey: rootNavigatorKey` for full-screen presentation above the bottom nav shell.
  - Connected receipt-card taps in `ReceiptsScreen` to push `/receipts/:id` using receipt ID.
  - Implemented `watchReceiptById(int id)` in `ReceiptsRepository` and `DriftReceiptsRepository` using Drift's `watchSingleOrNull()`.
  - Added `receiptDetailStreamProvider` (`StreamProvider.autoDispose.family<Receipt?, int>`), automatically cleaning up query streams when popped.
  - Implemented `ReceiptDetailScreen` with:
    - Loading (`CircularProgressIndicator`), error (retry/back UI), and missing record fallback states.
    - Responsive card layout (max-width 640px) supporting light and dark themes.
    - Product header with category chip and warranty status badge (`WarrantyStatus`).
    - Full-width photo preview with missing image fallback container (`_buildMissingPhotoFallback`).
    - Details card: store, formatted amount, purchase date, warranty duration, and expiration date.
    - Color-coded warranty progress bar reusing `WarrantyCalculator.calculate`.
    - "Edit Details" action button pushing `/receipts/:id/edit`.
  - Implemented Edit Mode reusing `AddReceiptScreen`:
    - Prefills all form fields, category chips, dates, warranty presets/custom days, notes, and image preview.
    - Checks form cleanliness against initial values so pristine edit forms pop immediately without discard dialogs.
    - Calls `repository.updateReceipt(updated)` on save, updating the existing record without creating duplicates.
    - Preserves existing image unless explicitly replaced or removed; cleans only uncommitted new images on discard.
    - Reactively updates both `ReceiptDetailScreen` and `ReceiptsScreen` on save.
  - Added 8 widget/unit tests in `test/features/receipts/receipt_detail_screen_test.dart` and full end-to-end integration test in `test/widget_test.dart`.

- [x] **Task 2F: Receipt Deletion & Referential Safe Image Cleanup**
  - Added Delete action to `ReceiptDetailScreen` via AppBar trash icon and prominent error-tinted action button.
  - Added Material `AlertDialog` confirmation dialog with product name and permanent deletion warning.
  - Concurrency & navigation protection: `_isDeleting` flag disables all buttons, shows spinner, and locks back navigation (`PopScope(canPop: !_isDeleting)`).
  - Database deletion: deletes record via `ReceiptsRepository.deleteReceipt(id)`.
  - Referential safe image cleanup: verifies with repository whether image file is referenced by any other receipt; if so (or if referential safety cannot be proven), leaves file intact; safely deletes file if unreferenced.
  - Error feedback: database failures display error SnackBar with details; never shows false success message or navigates away.
  - Reactive stream update: Drift stream emits null / removes row; navigating back to `ReceiptsScreen` immediately removes card from the list.
  - Added 5 widget tests in `test/features/receipts/receipt_detail_screen_test.dart` and 1 end-to-end integration test in `test/widget_test.dart` (79 total tests passing).

---

## ✅ Phase 5 — Warranties Screen (Complete)

**Reference:** `design/mockups/active_warranties/screen.png` and `code.html`

- [x] **Task 3A: Implement the Warranties screen using actual saved receipts**
  - Replaced `WarrantyScreen` placeholder with full working screen backed by `warrantiesStreamProvider`.
  - Reused centralized `WarrantyCalculator` calculation with `WarrantyInfo.progress` (0.0 to 1.0) for visual progress bar.
  - Strictly omits receipts without warranties (`warrantyDurationDays == null` or `<= 0`).
  - Sorted warranties by urgency: Active & Expiring Soon first (soonest expiry first), followed by Expired (most recently expired first).
  - Category filter chips row (`WarrantyFilterRow`) with counts: All, Active, Expiring Soon, Expired.
  - Summary count row with amber "X Expiring Soon" indicator badge.
  - Reusable `WarrantyCard` component with category icon, status badge, purchase and expiry dates, duration remaining, percentage, and 6px rounded progress bar.
  - Tapping warranty card navigates to receipt details (`AppRoutes.receiptDetailPath(item.receipt.id)`).
  - Contextual empty states (`WarrantyEmptyState`) for pristine state ("Add Receipt") and filtered states ("View All Warranties").
  - Light and dark mode support adhering to `AppTheme`, `AppColors`, and `AppShapes`.
  - Added 12 tests in `test/features/warranty/warranty_screen_test.dart` and 1 end-to-end integration test in `test/widget_test.dart` (91 total tests passing).

---

## ✅ Phase 6 — Alerts Screen (Complete)

**Reference:** `design/mockups/alerts/screen.png` and `code.html`

- [x] **Task 3B: Implement the Alerts screen with calculated warranty reminders**
  - Replaced `AlertsScreen` placeholder with real screen backed by reactive SQLite stream (`alertsStreamProvider`).
  - Implemented `WarrantyAlert` domain entity encapsulating `Receipt` and centralized `WarrantyCalculator`.
  - Added relative urgency labels (`urgencyLabel`: "Expires today", "Expires in 1 day", "Expires in 7 days", "Expired 1 day ago", "Expired 2 days ago").
  - Strictly excluded non-warranty receipts and safe active warranties (> 30 days remaining); bounded expired reminders to the past 90 days.
  - Deterministic urgency sorting: Expiring Soon alerts first (soonest expiry first), followed by Expired alerts (most recently expired first); descending `receipt.id` tie-breaker.
  - Implemented `AlertCard` matching mockup specs with 48×48 icon avatar, product title (strikethrough when expired), store/category subtitle, urgency badge, and mini progress bar.
  - Tapping alert card pushes receipt details (`AppRoutes.receiptDetailPath(alert.receipt.id)`).
  - Implemented `AlertFilterRow` choice chips with dynamic category counts: `All`, `Expiring Soon`, `Expired`.
  - Implemented `AlertsEmptyState` supporting pristine "All Clear" with "View Warranties" navigation, and filtered empty states with reset actions.
  - Supported light and dark modes with 100% theme token fidelity.
  - Added 12 tests in `test/features/alerts/alerts_screen_test.dart` and 1 end-to-end integration test in `test/widget_test.dart` (104 total tests passing in suite).


---

## 🔲 Phase 7 — Local Push Notifications

- Add `flutter_local_notifications` package.
- Schedule notifications N days before warranty expiry.
- Request permissions (Android 13+, iOS).
- Settings screen toggle for notification preferences.

---

## ✅ Phase 8 — Settings Screen (Complete)

**Reference:** `design/mockups/settings/screen.png` and `code.html`

- [x] **Task 3C: Implement the Settings screen**
  - Replaced `SettingsScreen` placeholder with polished, responsive screen matching the design system and mockup.
  - Zero new dependencies: utilized `path_provider: ^2.1.6` for lightweight `app_settings.json` file persistence.
  - Implemented `AppSettingsService` abstraction with `LocalFileAppSettingsService` and `InMemoryAppSettingsService`.
  - Implemented working Theme selection (System Default, Light, Dark) persisted across app restarts.
  - Eliminated theme flickering on startup by preloading `initialThemeModeProvider` in `main()` before `runApp()`.
  - Used `RadioGroup<ThemeMode>` adhering strictly to Flutter 3.32+ deprecation standards for 0 analyzer warnings.
  - Added Privacy Note card highlighting that receipts and photos are stored 100% locally on device.
  - Added About section displaying app name (`Receipt Vault`), version (`v1.0.0`), description, and build metadata.
  - Preserved scope: excluded dummy controls for non-existent features (no cloud sync, accounts, payments).
  - Added 8 tests in `test/features/settings/settings_screen_test.dart` and 1 end-to-end integration test in `test/widget_test.dart` (113 total tests passing).

- [x] **Task 3E: Implement a basic user-controlled export/backup feature**
  - Standards-compliant RFC 4180 CSV export service (`ReceiptExportService`) generating human-readable receipt backups with UTF-8 encoding and CRLF (`\r\n`) lines.
  - Supported receipt fields: ID, Product Name, Store, Category, Purchase Date, Total Amount, Warranty Duration in Days, Warranty Status (`WarrantyCalculator.calculate()`), Notes, Has Photo (`Yes`/`No`), and Creation Date.
  - Proper RFC 4180 escaping: fields with commas, quotes, line feeds (`\n`), or carriage returns (`\r`) are wrapped in quotes, with internal quotes doubled (`""`).
  - Strict privacy protection: private filesystem image paths (`imagePath`) are never leaked; a clean `Has Photo` boolean is exported instead.
  - Explicit photo disclaimer in both Settings card and modal dialog: *"CSV exports contain receipt text metadata and warranty details. Attached photos remain securely stored on your local device and are not included in CSV files."*
  - User destination selection (`ExportReceiptsDialog`): choice between system Downloads and app Documents folders with editable timestamped filename (`receipt_vault_export_YYYYMMDD_HHMMSS.csv`).
  - Multiple export & sharing affordances: save file to disk, copy CSV directly to clipboard, copy file path to clipboard.
  - Progress feedback during export, inline error recovery, and empty vault detection ("Receipt Vault is Empty").
  - Seamless Settings integration with `DataExportCard` in the "Data Management" section.
  - Zero new dependencies added, 100% offline-first, no cloud sync or accounts.
  - Added 13 new unit and widget tests (144 total tests passing in suite).

---

## ✅ Quality Audit & Hardening (Complete)

- [x] **Repository Quality Audit**
  - Audited all 10 core areas: Riverpod architecture & Drift lifecycle, data integrity & photo persistence, navigation & shell routing, UI & dark mode contrast, centralized warranty calculation boundaries, search & sorting reactivity, settings & RFC 4180 CSV export, dependencies & platform configuration, documentation accuracy & unused code, and security/privacy.
  - Identified and fixed warranty progress bar calculation in `ReceiptDetailScreen` to match `WarrantyCalculator` and `WarrantyCard` remaining duration ratio.
  - Added targeted test verifying progress bar ratio accuracy and 0.0 value on expired receipts (145 total passing tests in suite).
  - Hardened Android app label in `AndroidManifest.xml` to `Receipt Vault`.
  - Hardened `.gitignore` to prevent committing local SQLite databases, settings JSON, cached images, and CSV files.
  - Verified `dart format`, `flutter analyze` (0 issues), and `flutter test` (145/145 passing).

---

## ✅ Post-Implementation QA & Targeted Fixes (Complete)

- [x] **Task 1: Improve README.md**
  - Replaced the default Flutter starter README with accurate, comprehensive project documentation matching actual repository contents.
  - Documented app purpose, implemented features across all 5 shell tabs and detail/edit screens, tech stack and architecture, prerequisites, setup instructions, test commands, current limitations, and planned roadmap.

- [x] **Task 2: Fix Missing-Receipt Edit Flow**
  - Inspected `AddReceiptScreen` and its route integration (`/receipts/:id/edit`).
  - Added clear loading state (`_buildLoadingState`) with `CircularProgressIndicator` while retrieving record by ID.
  - Added "Receipt Not Found" state (`_buildNotFoundState`) with receipt icon, informative message, and "Back to Receipts" button when ID does not exist in the database.
  - Added error state (`_buildErrorState`) with error icon, exception details, "Retry" button, and "Back to Receipts" button when repository retrieval throws.
  - Guaranteed blank editable form and save button are never displayed for missing or failing records.
  - Enforced guard in `_handleSubmit` preventing update attempts before record is loaded.
  - Updated `_isDirty` so pristine/error/not-found states do not trigger unsaved changes confirmation on exit.
  - Added 4 regression tests in `test/features/home/add_receipt_screen_test.dart` (now 149 passing tests in suite).

- [x] **Task 3: Review Currency Handling**
  - Evaluated amount entry, storage, export, and display across the entire codebase.
  - Identified all 3 hardcoded currency symbol locations (`AddReceiptScreen` price input prefix, `ReceiptCardData.formattedPrice`, and `ReceiptDetailScreen` details card).
  - Confirmed SQLite schema stores amounts as pure numeric `REAL` values (`totalAmount`) and CSV export formats pure decimals (`toStringAsFixed(2)`), keeping persistence currency-agnostic.
  - Formulated recommendation: document USD (`$`) as default for initial release, with user-selected currency setting recommended for v1.1+ requiring zero database schema migrations.

- [x] **Task 4: Verify Feature Claims**
  - Updated project documentation (`README.md`, `docs/PROJECT_OVERVIEW.md`, `docs/CURRENT_STATUS.md`, `docs/ROADMAP.md`) to explicitly distinguish:
    1. In-app calculated Alerts screen (`/alerts`) vs scheduled OS push notifications (Phase 7).
    2. CSV metadata export (`ReceiptExportService`) vs complete photo archive backup (.zip).

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
