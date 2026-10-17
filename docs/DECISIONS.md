# Receipt Vault – Architecture Decisions

Records significant technical and design decisions, their reasons, and important constraints.

---

## D-001: Feature-First Folder Structure

**Decision:** Use feature-first (`lib/features/<feature>/`) organization rather than layer-first (`lib/data/`, `lib/presentation/`).

**Reason:** Feature-first scales better as the app grows. Related code (data, domain, UI) lives together, making it easier to work on one feature without touching files spread across multiple top-level directories.

**Constraint:** Shared code goes in `lib/shared/` (widgets, enums, utils) or `lib/core/` (services, storage). Do not put feature-specific code in `core/` or `shared/`.

---

## D-002: go_router with StatefulShellRoute

**Decision:** Use `go_router` and `StatefulShellRoute.indexedStack` for the bottom navigation shell.

**Reason:** `StatefulShellRoute` preserves each tab's navigation stack independently (e.g., navigating deep into Receipts and then switching to Warranties doesn't reset the Receipts stack). `go_router` is already a dependency and is the Flutter team's recommended routing solution.

**Constraint:** Route paths are defined as constants in `AppRoutes` abstract class (`lib/app/router/app_router.dart`). Never use raw path strings elsewhere.

---

## D-003: Add Button as Push Route, Not Tab Branch

**Decision:** Tapping the Add button pushes `/add` as a new route on top of the current shell, rather than switching to a "dummy" 3rd tab branch.

**Reason:** The Add action is transactional (user fills a form and goes back). It should not appear as a persistent tab state. The mockup also shows Add as a raised button, not a regular tab.

**Constraint:** Branch 2 (`/add-placeholder`) still exists in the `StatefulShellRoute` to keep the `NavigationBar` index alignment (5 destinations = 5 branches). The shell overrides the tap at index 2 with `context.push('/add')`.

---

## D-004: Material 3 Theme from a Single File

**Decision:** All colors, shapes, and component themes are defined in `lib/app/theme/app_theme.dart`. No colors are hardcoded elsewhere.

**Reason:** Centralizing theme tokens prevents drift between screens, makes dark mode consistent, and makes colour adjustments a one-file operation.

**Constraint:** Always access colors via `Theme.of(context).colorScheme.*` in widgets. Only access `AppColors.*` directly when you need a color that is not part of the `ColorScheme` (e.g., status-specific colors for badges).

---

## D-005: No Inter Font Yet

**Decision:** The app currently uses the system font, not Inter.

**Reason:** Adding `google_fonts` is a deliberate package addition. It was excluded from the foundation task to keep the initial implementation minimal. The type scale (sizes, weights, line heights) matches the design spec — only the typeface differs.

**Action Required:** Add `google_fonts` package, then update `AppTheme._buildTextTheme` to wrap with `GoogleFonts.interTextTheme(...)`.

---

## D-006: Riverpod Wired with ProviderScope (Resolved)

**Decision:** The app is wrapped with `ProviderScope` at the root in `lib/main.dart`.

**Details:**

- `ProviderScope` wraps `ReceiptVaultApp` in `lib/main.dart`.
- Root smoke test in `test/widget_test.dart` also wraps `ReceiptVaultApp` with `ProviderScope` so downstream consumers function without missing provider scope errors.

---

## D-007: Drift SQLite Database Created (Resolved)

**Decision:** Drift database schema and singleton provider implemented in `lib/core/storage/`.

**Details:**

- `AppDatabase` in `lib/core/storage/app_database.dart` defines the `Receipts` table.
- `databaseProvider` in `lib/core/storage/database_provider.dart` provides the singleton instance with automatic `ref.onDispose(() => database.close())`.
- Default persistent path: `getApplicationDocumentsDirectory() / receipt_vault.sqlite`.
- Background isolate execution via `NativeDatabase.createInBackground` to keep the UI thread jank-free.
- Test isolation: `AppDatabase(NativeDatabase.memory())` allows isolated in-memory testing.

---

## D-008: Primary Colour Discrepancy Between Sources (Resolved)

**Decision:** Resolved in favor of the Material 3 token hierarchy from the mockup reference (`design/mockups/my_receipts_home_updated_nav/screen.png` and `code.html`).

**Details & Resolution:**

- Visual inspection of `screen.png` and the Tailwind configuration in `code.html` confirmed the two-tier blue hierarchy:
  1. `primary` = `#004AC6` (Deep royal blue): Used for prominent brand typography, AppBar receipt icon, and "My Receipts" title in light mode. In dark mode, maps to `primary-fixed-dim` `#B4C5FF` for high-contrast legibility against dark surfaces.
  2. `primaryContainer` = `#2563EB` (Vibrant action blue): Used for filled interactive components, including active category filter chips ("All"), the prominent center Add button in the navigation bar, and focused input borders.
  3. `secondaryContainer` = `#D0E1FB`: Used for the active tab indicator pill in the bottom navigation bar.
- `lib/app/theme/app_theme.dart` was updated:
  - `AppColors.primary` set to `Color(0xFF004AC6)`.
  - `AppColors.primaryContainer` set to `Color(0xFF2563EB)`.
  - `AppTheme.light` and `AppTheme.dark` `ColorScheme` instances configured to map these tokens properly.
  - `AppShell` and Receipts components updated to reference `colorScheme.primaryContainer` and `colorScheme.secondaryContainer` appropriately.

---

## D-009: App Name Discrepancy in Design File

**Decision:** Ignore "Lumina Ledger" references in `design/DESIGN.md` YAML front-matter.

**Details:** The YAML front-matter in `design/DESIGN.md` says `name: Lumina Ledger`. This appears to be a leftover from an earlier draft. The Flutter package name is `receipt_vault`, the app title in `main.dart` is "Receipt Vault", and all other references use that name.

**Constraint:** Never rename the package or any code file to "Lumina Ledger".

---

## D-010: `build_runner` Code Generation Executed (Resolved)

**Decision:** Code generation run with `build_runner build`.

**Details:**

- Generated `lib/core/storage/app_database.g.dart` via `drift_dev`.
- Produces `$ReceiptsTable`, `Receipt` row data class, and `ReceiptsCompanion`.

---

## D-011: Decoupled UI & Presentation Data for Receipts Screen

**Decision:** Implemented `ReceiptsScreen` with modular presentation components (`ReceiptCard`, `ReceiptSearchBar`, `CategoryFilterRow`, `ReceiptsEmptyState`), `WarrantyStatus` enum in `lib/shared/enums/`, and a pure presentation entity `ReceiptCardData` in `lib/features/receipts/domain/entities/`. No fake receipt data is hardcoded into the app runtime; by default the screen displays the pristine empty state.

**Reason:** Enables thorough visual and interaction testing (search, category filtering, expired strikethrough, active/expiring badges, tap callbacks) without hardcoding mock data or prematurely coupling the UI to a specific database ORM implementation.

---

## D-012: Drift Database Schema Design & Concurrency Model

**Decision:**

- Table name: `Receipts` (`receipts` in SQLite).
- Primary Key: `id` (integer, auto-incrementing).
- Required Fields: `productName` (text), `purchaseDate` (dateTime), `totalAmount` (real).
- Optional Fields: `storeName` (text), `category` (text), `warrantyDurationDays` (integer), `notes` (text), `imagePath` (text).
- Audit timestamp: `createdAt` (dateTime with default `currentDateAndTime`).
- Concurrency: `NativeDatabase.createInBackground` used for persistent connection so queries and writes run in a dedicated background isolate without blocking the Flutter UI frame rendering.
- Test Strategy: `AppDatabase` accepts an optional `QueryExecutor`. Unit tests pass `NativeDatabase.memory()` to ensure each test runs in complete isolation without file system side-effects.

---

## D-013: Reactive Database Stream to Receipts UI Architecture & Warranty Calculation Model

**Decision:** Connect `ReceiptsScreen` to Drift SQLite through a clean repository and Riverpod reactive stream pipeline, with centralized warranty calculations.

**Details:**

1. **Repository Layer:**
   - Abstract `ReceiptsRepository` interface in `lib/features/receipts/domain/repositories/receipts_repository.dart`.
   - Concrete `DriftReceiptsRepository` in `lib/features/receipts/data/repositories/drift_receipts_repository.dart`.
   - Queries order by `purchaseDate` descending and `id` descending so newly purchased receipts appear at the top of the list.
2. **Centralized Warranty Calculator (`WarrantyCalculator`):**
   - Service in `lib/features/receipts/domain/services/warranty_calculator.dart`.
   - Calculates `WarrantyStatus` (`none`, `expired`, `expiringSoon`, `active`) and human-friendly badge labels:
     - Null or <= 0 duration: `none`, "No warranty".
     - In past: `expired`, "Expired".
     - 0 days left: `expiringSoon`, "Expires today".
     - <= 30 days left: `expiringSoon`, "X day(s) left".
     - > = 365 days left: `active`, "X year(s) left".
     - > 30 days left: `active`, "X days left".
   - Maps category strings to Material icons (`Electronics` -> `Icons.devices_outlined`, `Food` -> `Icons.restaurant_outlined`, etc.).
   - Prevents duplicating warranty business logic across widgets and screens.
3. **Domain Mapping:**
   - `ReceiptCardData.fromReceipt(Receipt receipt, {DateTime? now})` constructor converts Drift database entities into presentation models.
   - Accepts an optional `now` parameter for predictable, hermetic unit testing.
4. **Riverpod Providers:**
   - `receiptsRepositoryProvider`: Provider backed by `databaseProvider`.
   - `receiptsStreamProvider`: StreamProvider exposing `List<ReceiptCardData>`.
5. **UI States & Integration:**
   - `ReceiptsScreen` converted to `ConsumerStatefulWidget`.
   - Handles `AsyncLoading` with `CircularProgressIndicator` without flashing empty states before the database query completes.
   - Handles `AsyncError` with a dedicated error UI (`_buildErrorState`).
   - Filters search queries and category selections reactively over streamed data.
   - Retains optional `receipts` constructor parameter to maintain backwards compatibility for static test fixtures.
6. **Hermetic In-Memory Testing:**
   - Tests override `databaseProvider` with `AppDatabase(NativeDatabase.memory())` or `receiptsStreamProvider`.
   - Closes in-memory databases and pumps timers cleanly to avoid leaking Drift stream timers.

---

## D-014: Add Receipt Form UI Architecture, Validation & Unsaved Guard

**Decision:** Implement `AddReceiptScreen` with comprehensive form inputs, responsive constraints, inline validations, beginner-friendly presets, and an unsaved changes discard guard.

**Details:**

1. **Routing Continuity:**
   - Reuses existing `/add` route mapped to `AddReceiptScreen`.
   - AppShell's prominent center button invokes `context.push('/add')` seamlessly.
   - Back navigation employs safe pop handling (`Navigator.of(context).canPop()` / `Navigator.of(context).pop()`) compatible with both GoRouter navigation and standalone widget test harnesses.
2. **Form Layout & Theming:**
   - Centered container constrained to a maximum width of 600px, ensuring optimal presentation on mobile, foldable, and tablet/desktop screens.
   - Visual design faithful to `design/mockups/add_receipt/code.html`:
     - Dashed outline photo placeholder card using a custom `_DashedBorderPainter` (1.5px stroke, 6px dash, 4px gap, 12px border radius).
     - Enclosed form details card with ambient elevation (`BoxShadow(color: Colors.black.withAlpha(...), blurRadius: 4, offset: Offset(0, 2))`), subtle borders, and theme-adaptive surfaces.
3. **Input Fields & Validation Rules:**
   - **Product Name (required):** Validates non-empty input; capitalizes words.
   - **Store Name (optional):** Free text input with word capitalization.
   - **Category Selection:** Horizontally wrapped `ChoiceChip` widgets populated with app categories (`Electronics`, `Food`, `Clothing`, `Home`, `Others`), mapped with category icons from `WarrantyCalculator.iconForCategory()`. Selected chip uses `primaryContainer` (`#2563EB`) with white text.
   - **Price (required):** Numeric keyboard with decimal point (`FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))`), prefixed with `$`, and strictly validated for positive non-zero value.
   - **Purchase Date (required):** `InputDecorator` with calendar icon opening standard Material `showDatePicker`, defaulting to today.
   - **Warranty Duration:** `DropdownButtonFormField<int?>` offering clear presets:
     - `null`: "No warranty"
     - `180`: "6 months"
     - `365`: "12 months (1 year)"
     - `730`: "24 months (2 years)"
     - `1095`: "36 months (3 years)"
     - `-1`: "Custom duration..."
     - When "Custom duration..." is selected, dynamically reveals a positive integer days text field with digits-only validation.
   - **Notes (optional):** Multiline text area (3-5 lines).
4. **Scope Boundary Enforcement:**
   - "Save Receipt" button triggers form validation. If valid, passes structured data map to optional `onSubmit` callback and displays an informative `SnackBar` explaining that SQLite database persistence will be connected in Task 2C.
   - Dashed photo button triggers an informational `SnackBar` clarifying camera/gallery support is scheduled for Task 3A.
5. **Unsaved Changes Guard:**
   - Tracks `_isDirty` state across all text controllers, category choices, warranty presets, and date modifications.
   - Intercepts system back gestures via `PopScope` and AppBar BackButton.
   - If pristine, pops immediately without interruption.
   - If dirty, presents a confirmation `AlertDialog` ("Discard changes?") offering "Keep Editing" or "Discard".

---

## D-015: Add Receipt SQLite Database Persistence & Concurrency Strategy

**Decision:** Connect `AddReceiptScreen` directly to the existing Drift SQLite database using `ReceiptsRepository` and Riverpod, ensuring thread safety, duplicate prevention, and reactive UI updates.

**Details:**

1. **Riverpod Consumer Integration:**
   - `AddReceiptScreen` extends `ConsumerStatefulWidget` to read `receiptsRepositoryProvider`.
   - Accepts an optional `ReceiptsRepository? repository` constructor parameter to support fast, hermetic mock or in-memory repository testing without requiring provider overrides.
2. **Data Mapping & Drift Companion:**
   - On valid submission, constructs a `ReceiptsCompanion.insert`:
     - `productName`: Required non-empty string.
     - `totalAmount`: Required non-negative double (`>= 0`).
     - `purchaseDate`: Required `DateTime` from date picker.
     - `storeName`: Optional trimmed string; saved as `const Value.absent()` (null) if empty.
     - `category`: `Value(selectedCategory)` from standard app categories.
     - `warrantyDurationDays`: Optional non-negative integer from presets or custom days field; saved as `const Value.absent()` (null) if "No warranty" is selected.
     - `notes`: Optional multiline string; saved as `const Value.absent()` (null) if empty.
     - `imagePath`: `const Value.absent()` (null) pending Phase 3 image picker integration.
3. **Concurrency & Double-Submit Guard:**
   - `_isSaving` boolean flag guards against rapid or concurrent taps.
   - The Save button is disabled (`onPressed: null`) and displays a centered `CircularProgressIndicator` while the asynchronous write executes.
   - `PopScope` and `_handleBack` disallow popping or dismissing while `_isSaving` is true.
4. **Resilience & Feedback:**
   - Database writes are wrapped in `try/catch`.
   - If writing throws, `_isSaving` resets to `false`, an error `SnackBar` is displayed with error details, the screen does NOT pop, and all user inputs in controllers remain completely intact for retry.
   - If writing succeeds, `_isSaved = true` prevents the unsaved-changes confirmation dialog, a success `SnackBar` is displayed, and the screen pops back to `ReceiptsScreen`.
5. **Reactive Propagation:**
   - No manual cache invalidation or refresh callbacks needed. Drift's SQLite table query listeners trigger automatically on insert, immediately pushing the new `ReceiptCardData` to `receiptsStreamProvider`, which seamlessly re-renders `ReceiptsScreen` with the new receipt at the top.

---

## D-016: Receipt Photo Selection, App-Owned Local Storage & Resilience Strategy

**Decision:** Abstract camera capture, photo library selection, and local disk persistence behind a clean `ReceiptImageService` interface, saving copies directly into an app-owned persistent directory rather than relying on temporary system cache paths.

**Details:**

1. **Dependency Choice:**
   - Evaluated compatibility with Flutter SDK ^3.12.0 and existing packages; utilized `image_picker: ^1.2.4` without adding redundant camera or file picker packages.
   - Configured iOS `Info.plist` usage descriptions (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`). Android uses the modern system Photo Picker and standard camera capture intent without requiring unnecessary runtime storage permissions on API 33+.
2. **Persistent App-Owned Storage:**
   - Mobile operating systems periodically clear temporary cache directories (e.g. `cache/` or OS temp folders where `image_picker` originally places captured files).
   - `ReceiptImageService` copies selected images into a dedicated `receipt_images/` subdirectory inside `getApplicationDocumentsDirectory()`.
   - Generates collision-free filenames based on microseconds timestamp: `receipt_${DateTime.now().microsecondsSinceEpoch}${extension}`.
3. **Interactive Preview, Replace & Remove:**
   - When no image is selected, `AddReceiptScreen` renders the dashed outline placeholder. Tapping opens a Material bottom sheet modal with "Take Photo" and "Choose from Gallery" options.
   - Once selected, renders a 200px preview card with a dark frosted bottom control bar featuring:
     - A green checkmark with "Photo attached" confirmation text.
     - A "Replace" action button (opens source sheet).
     - A "Remove" action button (clears attachment and cleans uncommitted file).
4. **Safe File Cleanup (Requirement 10):**
   - When replacing or removing a selected photo in `AddReceiptScreen`, or discarding an unsaved receipt draft, `ReceiptImageService.deleteImageIfUnreferenced` verifies whether the file path is referenced by any existing receipt row in the database.
   - If referenced by an existing receipt, the file is never deleted.
   - If unreferenced (an uncommitted session draft), it is safely deleted to avoid orphan file accumulation.
5. **Missing File Safety & Fallback (Requirement 9):**
   - If an image file on disk is deleted, moved, or corrupted, `_buildMissingImageFallback` renders a user-friendly error container with a broken image icon and message, while keeping the Replace and Remove controls fully functional.
   - In `ReceiptCard`, leading thumbnail rendering verifies `File.existsSync()` and provides an `errorBuilder` fallback to the standard category icon.
6. **Graceful Error Handling & Input Preservation (Requirements 7, 8):**
   - **Cancellation:** User dismissing the picker returns silently with no error snackbars.
   - **Permission Denial:** Intercepts `PlatformException` (e.g., `camera_access_denied`, `photo_access_denied`) and presents an instructional `SnackBar` prompting the user to grant permission in device Settings.
   - **Unsupported Platform / Missing Hardware:** Intercepts hardware-related errors and informs the user gracefully.
   - **File Copy / Disk Failure:** Catches `FileSystemException` or `IOException` and reports the error.
   - **Form State Preservation:** In all error and cancellation cases, every single form field (`_productNameController`, `_priceController`, category, warranty preset, notes, date) remains 100% intact.
7. **Hermetic Testability:**
   - `AddReceiptScreen` accepts an optional `ReceiptImageService? imageService` constructor parameter and falls back to `ref.read(receiptImageServiceProvider)`.
   - Widget tests inject a test double `_TestReceiptImageService` without needing native method channel mocks or platform plugins.

---

## D-017: Receipt Details Presentation, GoRouter Full-Screen Push Strategy & Form Reuse for Editing

**Decision:** Implement the receipt details view and edit flow by pushing full-screen routes over the shell via `rootNavigatorKey`, loading records reactively from SQLite by ID with `autoDispose` stream providers, and reusing `AddReceiptScreen` in edit mode with strict image preservation and dirty tracking.

**Details:**

1. **GoRouter Full-Screen Push Strategy:**
   - Configured `/receipts/:id` and `/receipts/:id/edit` as top-level `GoRoute`s using `parentNavigatorKey: rootNavigatorKey`.
   - Rationale: Detail and edit flows are deep transactional destinations where the persistent bottom navigation bar should be hidden to maximize screen real estate for product details and photo previews. Placing them at root level prevents route nesting conflicts when invoking `context.push()` from within shell destinations.
2. **Reactive Single-Source-of-Truth by ID:**
   - `ReceiptDetailScreen` accepts `receiptId: int?` (and optional `receipt: Receipt?` for isolated widget testing).
   - In production, it watches `receiptDetailStreamProvider(id)`, backed by `DriftReceiptsRepository.watchReceiptById(id)` with `watchSingleOrNull()`.
   - Any database mutation (such as an edit) immediately pushes fresh data through the stream, updating the detail view in real time without manual re-fetch logic or route parameter refreshes.
3. **Stream Lifecycle & Memory Management:**
   - Configured `receiptDetailStreamProvider` using `StreamProvider.autoDispose.family<Receipt?, int>`.
   - When the user pops back to the receipts list, Riverpod automatically cancels the stream subscription and tears down the Drift stream query, freeing memory and preventing open query streams from blocking database closure in tests.
4. **Form Reuse for Editing:**
   - Rather than creating a redundant `EditReceiptScreen` with duplicated validation, choice chips, and layout widgets, `AddReceiptScreen` was extended to support edit mode via `receiptToEdit` and `receiptId` parameters.
   - Automatically prefills product name, store name, formatted amount, category chip, purchase date, warranty duration preset (or custom days), notes, and photo preview.
   - Tracks cleanliness relative to initial prefilled values: if the user opens the edit screen and immediately presses Back without making modifications, the screen pops immediately without a discard confirmation dialog.
   - On submission, calls `repository.updateReceipt(updatedReceipt)` on the existing primary key instead of inserting a duplicate record.
5. **Existing Photo Preservation:**
   - When entering edit mode, `_selectedImagePath` is initialized to the receipt's existing `imagePath`.
   - If the user saves without changing the photo, the existing image path is retained without re-copying.
   - If the user picks a new photo, the new file path is staged in `_newlyPickedImagePath`. If the user subsequently discards changes, only the uncommitted newly picked file is cleaned up; the original saved photo file is strictly preserved.
6. **Graceful Fallbacks & State Resilience:**
   - **Loading State:** Displays a centered `CircularProgressIndicator` inside a standard `Scaffold` with an active back button.
   - **Error State:** Renders friendly error typography and an explicit "Back to Receipts" recovery action if database reads fail.
   - **Missing Record State:** If a receipt ID does not exist in SQLite (or is null), displays an empty illustration, "Receipt Not Found" message, and navigation button to return to the receipts list.
   - **Missing Photo Fallback:** If a referenced photo file is deleted or inaccessible, renders a safe fallback container (`_buildMissingPhotoFallback`) preserving the rest of the layout and typography.

---

## D-018: Receipt Deletion, Confirmation Dialog & Referential Safe Image Cleanup Strategy

**Decision:** Implement receipt deletion in `ReceiptDetailScreen` guarded by an explicit confirmation dialog, strict concurrency controls (`_isDeleting` flag and gesture lock), comprehensive error handling without false success messages, and referential safe image-file cleanup through `ReceiptImageService`.

**Details:**

1. **Dual Delete Affordances:**
   - Provided two clearly labeled delete triggers:
     - An AppBar trash icon button (`Key('receipt_detail_app_bar_delete_button')`) with a tooltip "Delete receipt".
     - A prominent action button (`Key('receipt_detail_delete_button')`) in the card action section, styled with an outlined error border and `colorScheme.errorContainer` fill, keeping visual hierarchy balanced alongside the primary "Edit Details" button.
2. **Explicit Confirmation Dialog:**
   - Tapping delete displays a Material `AlertDialog` (`Key('receipt_detail_delete_dialog')`).
   - Identifies the action with a clear title ("Delete Receipt?"), identifies the receipt by product name in the message, and explicitly warns that the action cannot be undone.
   - Provides two distinct choices: "Cancel" (default/safe option) and "Delete" (styled in `AppColors.error`).
   - Cancelling leaves the receipt completely untouched in the SQLite database and dismisses the dialog.
3. **Concurrency Guarding & Navigation Lock:**
   - Maintained an `_isDeleting` boolean state flag on `_ReceiptDetailScreenState`.
   - When confirmed, `_isDeleting` is set to `true`:
     - Disables both Delete buttons and the "Edit Details" button to prevent duplicate or race condition actions.
     - Replaces the Delete button icon with an inline `SizedBox(16, 16)` progress spinner.
     - Wraps the screen in `PopScope(canPop: !_isDeleting)` to lock back gestures and system pop attempts while the database deletion and file operations execute.
4. **Failure Feedback & Error Resilience:**
   - Deletion is wrapped in `try/catch` and checks the number of affected rows from `repository.deleteReceipt(id)`.
   - If SQLite deletion throws an exception or returns 0 affected rows:
     - `_isDeleting` resets to `false`.
     - Displays an error `SnackBar` explaining that the receipt could not be deleted.
     - Does NOT show a success message or navigate away, keeping the user on the screen so they can retry.
5. **Referential Safe Image Cleanup:**
   - Image files must never be deleted if another receipt references the same path (e.g. duplicate receipts or shared imported images).
   - `DefaultReceiptImageService.deleteImageIfUnreferenced(imagePath, repository: repository)` queries all database records via `repository.getAllReceipts()`.
   - If any other receipt references the file path, the file is preserved on disk.
   - If `repository` is null or cannot verify referential safety, the file is intentionally left on disk rather than risking accidental data loss.
   - Only when verified as unreferenced is the file unlinked from app-owned storage.
6. **Reactive Stream & Pop Transition State:**
   - When a receipt record is deleted from SQLite, Drift's `watchReceiptById` stream automatically emits `null`.
   - Normally, emitting `null` would trigger `_buildNotFoundState` ("Receipt Not Found"). To prevent a brief 1-frame flash of the not-found state while the screen pops, `build()` checks `if (_isDeleting)` and continues displaying the loading scaffold until navigation finishes.
   - Displays a green success `SnackBar` ("Receipt deleted successfully.") and navigates back to `ReceiptsScreen`, which reactively updates via `receiptsStreamProvider` to remove the deleted card from the list.

---

## D-019: Warranties Screen Architecture, Centralized Progress Calculation & State-Aware Filtering Strategy

**Decision:** Implement the Warranties screen (`/warranties`) backed directly by the existing Drift SQLite reactive stream (`repository.watchReceipts()`) mapped through pure domain calculation (`WarrantyCalculator`), eliminating duplicated expiry logic across widgets, strictly excluding non-warranty receipts, and providing state-aware filter chips and contextual empty states.

**Details:**

1. **Reuse Centralized Domain Calculation:**
   - Rather than creating duplicate date arithmetic or expiry logic inside UI widgets, extended `WarrantyInfo` in `WarrantyCalculator` (`lib/features/receipts/domain/services/warranty_calculator.dart`) with a `progress` getter returning a clamped 0.0 to 1.0 ratio (`(daysRemaining / durationDays).clamp(0.0, 1.0)` for active/expiring items, `0.0` for expired items or items without warranty).
   - `WarrantyItem` encapsulates `Receipt` and delegates all status, remaining days, expiry date, category icons, and progress directly to `WarrantyCalculator`.
2. **Strict Omission of Non-Warranty Receipts:**
   - In `filterAndSortWarrantyItems`, receipts where `warrantyDurationDays == null`, `warrantyDurationDays <= 0`, or status is `WarrantyStatus.none` are strictly filtered out before rendering or counting.
   - Prevents everyday non-warranty receipts (e.g. groceries, coffee) from polluting the warranty tracker.
3. **Sorting by Urgency:**
   - Items are sorted with high priority:
     - Active & Expiring Soon items appear first, ordered by soonest expiry date (ascending `remainingDays`).
     - Expired items appear last, ordered by most recently expired (descending `expiryDate`).
4. **Interactive Filter Row with Dynamic Counts:**
   - `WarrantyFilterRow` renders horizontal pill choice chips for `All`, `Active`, `Expiring Soon`, and `Expired`.
   - Each chip dynamically computes and displays the count of items in that category from the current stream (e.g., "All (3)", "Active (2)", "Expiring Soon (1)", "Expired (0)").
5. **Contextual Empty States:**
   - `WarrantyEmptyState` provides distinct layouts based on active filter:
     - When `filter == WarrantyFilter.all` (0 total warranties): displays a shield icon, "No Warranties Tracked", explanatory text, and an "Add Receipt" button pushing `AppRoutes.add`.
     - When a specific filter has 0 items (e.g. `WarrantyFilter.expired` has 0 expired warranties): displays category-specific messaging ("No Expired Warranties", "None of your tracked warranties have expired.") and a "View All Warranties" button that resets the filter to `All`.
6. **Detailed Warranty Card Component:**
   - `WarrantyCard` renders a card matching `design/mockups/active_warranties/`:
     - 48x48 circular container with category icon.
     - Product title and store/category subtitle.
     - Color-coded status badge with dot (green for active, amber for expiring soon, red for expired).
     - Purchase and expiry dates.
     - Elapsed duration indicator, percentage label, and 6px rounded progress bar tinted by warranty health.
     - Card tap invokes `context.push(AppRoutes.receiptDetailPath(item.receipt.id))` to open the receipt's details.
7. **No New Tables or Redundant Dependencies:**
   - Zero new database tables created. The screen queries the existing `Receipts` table.
   - Zero new third-party dependencies added.

---

## D-020: Alerts Screen Architecture, Deterministic Urgency Sorting & Relative Reminder Strategy

**Decision:** Implement the Alerts screen (`/alerts`) backed directly by the reactive SQLite database stream (`repository.watchReceipts()`) mapped through pure domain reminder logic (`WarrantyAlert` and `generateWarrantyAlerts`), with deterministic urgency sorting, relative date formatting, strikethrough styling for expired items, filter chips, and contextual empty states.

**Details:**

1. **Pure Domain Reminder Calculation:**
   - Rather than creating artificial or fake alert records in the database, alert events are purely calculated from the live `Receipt` entities using `WarrantyAlert` (`lib/features/alerts/domain/entities/warranty_alert.dart`) and `WarrantyCalculator`.
   - Exposes `urgencyLabel` matching mockup specifications:
     - 0 days remaining: "Expires today"
     - 1 day remaining: "Expires in 1 day"
     - X days remaining: "Expires in X days"
     - -1 day remaining: "Expired 1 day ago"
     - -X days remaining: "Expired X days ago"
2. **Strict Filtering of Non-Actionable Receipts:**
   - Receipts without a warranty (`warrantyDurationDays == null` or `<= 0`) or with `WarrantyStatus.none` are strictly omitted.
   - Safe active warranties with > 30 days remaining are excluded because they do not require immediate attention (these are tracked on the Warranties screen).
   - Expired receipts are bounded to recent history (`maxExpiredDays = 90`) so stale, ancient expired receipts do not clutter actionable reminders.
3. **Deterministic Urgency Sorting Rules:**
   - `compareAlerts` sorts alerts deterministically without clock jitter:
     1. Group priority: Expiring Soon alerts precede Expired alerts.
     2. Within Expiring Soon: soonest to expire first (ascending `remainingDays`: 0, 1, 2, ...).
     3. Within Expired: most recently expired first (descending `remainingDays`: -1, -2, -3, ...).
     4. Tie-breaker: newest receipt first (descending `receipt.id`).
4. **Mockup Fidelity & Component Architecture:**
   - `AlertCard` (`lib/features/alerts/presentation/widgets/alert_card.dart`):
     - 48×48 rounded circular avatar: warning amber background with warning/schedule icon for expiring soon; error red container with error icon for expired items.
     - Product title with bold typography; strikethrough text decoration (`TextDecoration.lineThrough`) when expired.
     - Store name and category subtitle.
     - Urgency badge pill ("Expires in 7 days", "Expired 2 days ago").
     - 96×4px rounded mini progress bar: amber progress fraction for expiring soon; full-width solid red for expired items.
     - Tapping any card opens receipt details via `context.push(AppRoutes.receiptDetailPath(alert.receipt.id))`.
5. **Interactive Filter Row & Contextual Empty States:**
   - `AlertFilterRow` provides horizontal choice chips for `All`, `Expiring Soon`, and `Expired` with live counts.
   - `AlertsEmptyState`:
     - `All`: displays "All Clear", notification bell illustration, reassurance, and a "View Warranties" button that navigates to the Warranties tab via `context.go(AppRoutes.warranties)`.
     - Filtered views: displays category-specific messaging ("No Warranties Expiring Soon", "No Expired Warranties") with a "View All Alerts" button that resets the filter to `All`.
6. **Reactive Stream Lifecycle:**
   - `alertsStreamProvider` is a standard `StreamProvider` (not `autoDispose`) that stays alive for the duration of the shell, preventing stream teardown/reconnect thrashing when switching tabs.
7. **Scope Boundary Enforcement:**
   - Operating system push notifications are strictly deferred to Phase 7 (`flutter_local_notifications`).
   - Zero fake or mocked records in the production database.

---

## D-021: Settings Screen Architecture, Zero-Dependency JSON Theme Persistence & Local Privacy Guarantee

**Decision:** Implement the Settings screen (`/settings`) with working theme selection (System Default, Light, Dark) persisted across restarts via a lightweight, zero-external-dependency JSON service (`LocalFileAppSettingsService`), startup theme preloading to eliminate flash of unstyled theme, local privacy assurance, and strict omission of controls for non-existent features.

**Details:**

1. **Zero New Dependencies for Settings Persistence:**
   - Evaluated `shared_preferences` vs. a local JSON file via `path_provider`.
   - `path_provider: ^2.1.6` was already present in `pubspec.yaml` for SQLite database and receipt image storage.
   - Adding `shared_preferences` would introduce platform-specific channel overhead and require channel mocking in unit/widget tests.
   - Built `AppSettingsService` with:
     - `LocalFileAppSettingsService`: writes and reads a JSON map (`app_settings.json`) located in `getApplicationDocumentsDirectory()`.
     - `InMemoryAppSettingsService`: fast, hermetic test double without file I/O dependencies.
   - Resilient parsing: if the JSON file is missing, empty, or corrupt, safely catches exceptions and cleanly defaults to `ThemeMode.system`.
2. **Elimination of Theme Flash on App Startup:**
   - Rather than initializing theme mode asynchronously _inside_ the widget tree (which causes a jarring 1-frame light/dark flash while reading preferences), `main()` preloads the stored `ThemeMode` before calling `runApp()`.
   - The preloaded value is injected into the root `ProviderScope` via `initialThemeModeProvider.overrideWithValue(initialMode)`.
   - `ThemeModeNotifier` initializes its state synchronously with `ref.read(initialThemeModeProvider)`.
   - When the user toggles a theme mode in `ThemeSelectionCard`, `ThemeModeNotifier.setThemeMode()` updates Riverpod state immediately (re-rendering the app instantly) and persists the choice asynchronously to disk in the background.
3. **Flutter 3.32+ Deprecation Compliance:**
   - In Flutter 3.32+, passing `groupValue` and `onChanged` directly to `Radio` is deprecated in favor of `RadioGroup`.
   - `ThemeSelectionCard` wraps the three radio tiles in `RadioGroup<ThemeMode>(groupValue: currentThemeMode, onChanged: (mode) => ...)` and omits `groupValue`/`onChanged` on child `Radio` widgets.
   - Avoids all deprecation warnings, ensuring 0 analyzer issues.
4. **Local Data & Privacy Note:**
   - Verified that all receipts are stored exclusively in local SQLite (`receipt_vault.sqlite`) and all photos are stored exclusively in the app's local documents directory (`receipt_images/`).
   - Implemented `PrivacyNoteCard` with a clear explanation: receipts, warranty details, and photos are stored 100% locally on the device with zero cloud uploads or third-party tracking.
5. **About Section & App Metadata:**
   - Created centralized `AppInfo` in `lib/app/constants/app_constants.dart` with version (`1.0.0`), display version (`v1.0.0`), and short description.
   - Implemented `AboutAppCard` displaying brand icon, app title, version badge, description, and build metadata (version, build, open-source license).
6. **Strict Scope Boundary Enforcement:**
   - Mockups show placeholders for notifications, data export, cloud sync, and accounts.
   - In accordance with project instructions, controls for non-existent features (no cloud sync, accounts, payments, export buttons, notifications toggles) were strictly omitted rather than adding non-functional or misleading dummy UI controls.

---

## D-022: Receipt Discovery Architecture, Multi-Field Search, Sorting Strategies & Contextual Empty States

**Decision:** Implement comprehensive receipt discovery on the Receipts screen (`/receipts`) through client-side stream filtering and sorting (`ReceiptDiscoveryService`), supporting multi-field case-insensitive search across product name, store name, and category, 5 deterministic sorting strategies (`ReceiptSortOption`), a dedicated discovery and sort bar (`ReceiptSortFilterBar`), and contextual empty states (`ReceiptsEmptyState`) without adding external dependencies or redundant SQL roundtrips.

**Details:**

1. **Client-Side Reactive Filtering & Sorting:**
   - Rather than issuing SQL `LIKE` queries to SQLite on every keystroke (which incurs channel communication overhead and query debounce latency), the app streams all receipts reactively via `receiptsStreamProvider`.
   - `ReceiptDiscoveryService` performs filtering and sorting in-memory synchronously. Keystrokes filter instantly in $O(N)$ time with zero lag.
   - Any database insert, edit, or delete automatically emits an updated list via Drift's reactive `watch()` stream, and the active search, category, and sort filters are re-applied immediately.
2. **Multi-Field Case-Insensitive Search:**
   - Search query strings are trimmed and lowercased.
   - Matches if the query is a substring of `productName` (case-insensitive), `storeName` (null-safe case-insensitive), or `category` (case-insensitive).
   - Category filtering (`CategoryFilterRow`) and search query combine with logical AND: receipts must match both criteria when both are specified.
3. **Deterministic Sorting Strategies:**
   - Added `purchaseDate` to `ReceiptCardData` mapped from `Receipt.purchaseDate`.
   - `ReceiptSortOption` supports:
     - `newestPurchase`: Latest purchase date first.
     - `oldestPurchase`: Earliest purchase date first.
     - `productName`: Alphabetical product name A to Z (case-insensitive).
     - `amountHighToLow`: Highest total amount first.
     - `amountLowToHigh`: Lowest total amount first.
   - Tie-breaking: when primary attributes compare equally (or when dates are identical/null), the receipt's integer primary key ID is used as a stable tie-breaker to prevent erratic item jumping.
4. **Receipt Discovery & Sort Bar (`ReceiptSortFilterBar`):**
   - Renders between category chips and the list.
   - Displays live item counts: "X receipts" or "X of Y receipts" when filtered.
   - Displays an inline pill "Clear" action button whenever filtering is active.
   - Features a Material 3 `PopupMenuButton<ReceiptSortOption>` styled with primary blue accents, current sort label, and checkmark indicators on the active sort option.
5. **Contextual Empty States:**
   - Clearly distinguishes between a completely empty database and zero filter matches.
   - When the vault is empty, shows pristine state: "No receipts yet. Tap + to add your first receipt."
   - When filtering yields zero matches, dynamically provides a helpful and specific explanation:
     - If both search and category active: "No receipts found matching \"[query]\" in category \"[category]\". Try another search or reset filters."
     - If only search active: "No receipts found matching \"[query]\". Try another search term or reset filters."
     - If only category active: "No receipts found in category \"[category]\". Try another category or reset filters."
   - Displays prominent "Reset filters" button to restore all items immediately.
6. **No External Dependencies:**
   - Zero third-party search packages or FTS extensions added; utilizes pure Dart collection methods and standard Material 3 widgets.

---

## D-023: User-Controlled RFC 4180 CSV Receipt Export, Destination Selection, Privacy Protection & Photo Disclaimer

**Decision:** Implement a user-controlled, 100% offline CSV backup and export feature (`ReceiptExportService`, `DataExportCard`, `ExportReceiptsDialog`) on the Settings screen (`/settings`), supporting RFC 4180 compliant CSV formatting with robust escaping, destination selection (Downloads folder vs Documents folder), clipboard sharing, progress and error feedback, empty vault handling, privacy protection (zero leakage of local device image paths), and explicit user disclosure that photo attachments are stored locally and excluded from CSV files.

**Details:**

1. **RFC 4180 Standard CSV Formatting & Robust Escaping:**
   - `ReceiptExportService.generateCsv(List<Receipt> receipts)` creates a standards-compliant CSV file using UTF-8 encoding and CRLF (`\r\n`) line separators.
   - Standard header row: `ID,Product Name,Store,Category,Purchase Date,Total Amount,Warranty Duration (Days),Warranty Status,Notes,Has Photo,Created At`.
   - Fields:
     - ID: integer primary key string.
     - Product Name: product title.
     - Store: store name or empty string if null.
     - Category: category name or empty string if null.
     - Purchase Date: ISO-8601 formatted date (`YYYY-MM-DD`).
     - Total Amount: formatted to two decimal places (`0.00`).
     - Warranty Duration (Days): positive integer day count or empty string if null/0.
     - Warranty Status: human-readable label computed deterministically via `WarrantyCalculator.calculate()` (`Active`, `X days left`, `Expired`, `No warranty`).
     - Notes: full user notes.
     - Has Photo: privacy-safe boolean indicator (`Yes` or `No`).
     - Created At: formatted timestamp (`YYYY-MM-DD HH:mm:ss`).
   - `escapeCsvField(String? value)` implements strict RFC 4180 rules: fields containing commas, double quotes, line feeds (`\n`), or carriage returns (`\r`) are wrapped in double quotes (`"..."`), and internal double quotes are escaped by doubling them (`""`).
2. **Privacy Protection & Zero Private Path Exposure:**
   - In accordance with privacy requirements, internal private device file system paths (e.g. `C:\Users\...\AppData\...` or `/data/user/0/.../receipt_images/receipt_123.jpg`) are never included in exported data.
   - Instead, a clean boolean `Has Photo` column informs the user whether an image attachment exists.
3. **Explicit Photo Attachment Exclusion Disclaimer:**
   - Both the Settings card (`DataExportCard`) and modal export dialog (`ExportReceiptsDialog`) prominently state:
     _"CSV exports contain receipt text metadata and warranty details. Attached photos remain securely stored on your local device and are not included in CSV files."_
4. **Destination Choice & Sharing Workflow:**
   - Allows the user to select between:
     - **Downloads Folder** (using `path_provider.getDownloadsDirectory()` with safe fallback).
     - **Documents Folder** (using `path_provider.getApplicationDocumentsDirectory()`).
   - Pre-populates a standardized, customizable timestamped filename: `receipt_vault_export_YYYYMMDD_HHMMSS.csv`.
   - One-click **Copy to Clipboard** action allows instant copying of full CSV data without requiring file manager navigation.
   - Upon completion, displays a success dialog with full file path, "Copy File Path" button, "Copy CSV" button, and "Done" button.
5. **Empty State & Error Feedback:**
   - If the user attempts export when the vault has 0 receipts, an informational dialog clearly explains: _"There are no receipts in your database to export. Add some receipts first."_ with a Close button.
   - Progress indicator is shown during file export, and I/O or permission errors are surfaced in an inline error container.
6. **Zero Cloud Sync, Accounts, or New Dependencies:**
   - Uses existing `path_provider: ^2.1.6`, `path: ^1.9.1`, and Flutter SDK (`dart:io`, `Clipboard`). No external CSV, cloud, or sync packages added.

---

## D-024: Quality Audit Findings, Cross-Screen Warranty Progress Harmonization & Repository Hardening

**Decision:** Conduct a full quality audit across 10 core dimensions, resolve discovered cross-screen calculation inconsistencies, align platform manifest metadata with app branding, and harden version control rules against local state leakage.

**Details:**

1. **Cross-Screen Warranty Progress Harmonization:**
   - **Discovered Inconsistency**: In `ReceiptDetailScreen`, `_buildWarrantyProgressBar` computed progress as `(elapsedDays / totalDays)`, displaying 0.0 for a brand new receipt and 1.0 for an expired receipt. Conversely, `WarrantyCalculator.calculate` and `WarrantyCard` define progress as remaining warranty duration `(daysRemaining / durationDays)`, displaying 1.0 for brand new receipts and 0.0 for expired receipts.
   - **Resolution**: Updated `ReceiptDetailScreen` to consume `warrantyInfo.progress` directly from `WarrantyCalculator`. Added targeted widget tests in `test/features/receipts/receipt_detail_screen_test.dart` to assert that progress indicator values match `WarrantyCalculator` expectations and evaluate to 0.0 on expired receipts.
2. **Platform Branding Alignment:**
   - Updated Android's `application android:label` in `android/app/src/main/AndroidManifest.xml` from `receipt_vault` to `Receipt Vault`, ensuring parity with iOS `CFBundleDisplayName` (`Receipt Vault`) and `AppInfo.appName`.
3. **Local State & User Data Protection:**
   - Extended `.gitignore` to explicitly ignore local SQLite database files (`*.sqlite`, `*.sqlite-journal`, `*.sqlite-shm`, `*.sqlite-wal`, `*.db`), user preference files (`app_settings.json`), cached image directories (`receipt_images/`), and user CSV exports (`*.csv`).
4. **Placeholder Component Audit:**
   - Verified `lib/shared/widgets/placeholder_screen.dart` is currently unmounted since all 5 navigation branches (`/receipts`, `/warranties`, `/alerts`, `/settings`, `/add`) and detail/edit routes are now production screens backed by live SQLite data. Retained as an unmounted utility widget for future phase placeholders.

---

## D-025: Scheduled Local Warranty Notifications via flutter_local_notifications & Inexact Battery-Friendly Alarms

**Decision:** Implement scheduled local warranty notifications (`WarrantyNotificationService`, `LocalWarrantyNotificationService`) using `flutter_local_notifications: ^22.3.2` and `timezone: ^0.11.2`, providing automatic 30-day and 7-day expiration reminders at 9:00 AM local time, deterministic notification ID mapping (`(receiptId * 10) + offset`), battery-optimized inexact alarms, reactive Settings UI toggle with permission handling, and complete synchronization across receipt additions, edits, deletions, and app startups.

**Details:**

1. **Package Selection & Architecture:**
   - Evaluated `flutter_local_notifications: ^22.3.2` alongside `timezone: ^0.11.2` for offline-first, time-zone-aware notification scheduling.
   - Designed clean architectural separation:
     - `WarrantyNotificationService`: abstract interface defining initialize, requestPermissions, areNotificationsEnabled, scheduleWarrantyReminders, cancelWarrantyReminders, cancelAllReminders, and syncAllReceiptReminders.
     - `LocalWarrantyNotificationService`: production implementation wrapping `FlutterLocalNotificationsPlugin` and `timezone`.
     - `FakeWarrantyNotificationService`: test double for hermetic, deterministic unit and widget testing without native platform channels.
     - Riverpod provider: `warrantyNotificationServiceProvider` exposed globally for testability and loose coupling.
2. **Deterministic Notification Identifier Strategy:**
   - Defined deterministic 32-bit integer notification IDs:
     - 30-day reminder: `(receiptId * 10) + 1` (e.g., Receipt 42 -> ID 421).
     - 7-day reminder: `(receiptId * 10) + 2` (e.g., Receipt 42 -> ID 422).
   - Guarantees zero ID collision across receipts and reminder horizons, while enabling targeted cancellation and rescheduling on edit/delete without requiring new database columns or ID tracking tables.
3. **Delivery Horizons & Centralized Calculation:**
   - Reuses centralized `WarrantyCalculator.calculate()` to evaluate valid coverage periods.
   - Expiration dates are combined with 9:00 AM local time, subtracting 30 days and 7 days.
   - Non-warranty receipts (`warrantyDurationDays == null` or `<= 0`) and already-expired receipts schedule 0 reminders.
   - Reminders for dates that have already elapsed in the past are strictly omitted (e.g. if a receipt has 15 days left, only the 7-day reminder is scheduled).
4. **Android Inexact Alarm Strategy & Battery Optimization:**
   - Utilizes `AndroidScheduleMode.inexactAllowWhileIdle` rather than exact alarms (`SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`).
   - Android 12+ (API 31+) restricts exact alarms to specialized apps (alarms, timers, calendar apps), requiring special Google Play policy compliance and user settings approval. Warranty expiration is a daily milestone where exact-to-the-minute delivery is unnecessary. Inexact alarms wake the device near 9:00 AM during normal system maintenance windows, conserving battery life while strictly respecting Google Play store policies.
   - Configured high-importance Android notification channel (`warranty_alerts_channel`, "Warranty Expiration Reminders") with default sound and vibration.
   - Registered `ScheduledNotificationBootReceiver` and `ScheduledNotificationReceiver` in `AndroidManifest.xml` for post-reboot notification restoration.
5. **iOS Notification Configuration:**
   - Configured `AppDelegate.swift` with `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate` to ensure notification presentation while in foreground.
   - Added Darwin initialization settings and granular permission request for alert, badge, and sound.
6. **Settings Integration & Permission Guarding:**
   - Extended `AppSettingsService` with `getWarrantyNotificationsEnabled()` and `setWarrantyNotificationsEnabled(bool)` (persisted in `app_settings.json`, default `true`).
   - Integrated "Notifications" section with `NotificationsSettingCard` into `SettingsScreen`.
   - On enabling: calls `notificationService.requestPermissions()`. If denied by user or OS policy, the switch immediately stays disabled and displays an explanatory `SnackBar`, preventing misleading "enabled" states.
   - On disabling: cancels all pending reminders in `LocalWarrantyNotificationService`.
   - On re-enabling: re-synchronizes all saved receipts from SQLite database.
7. **Lifecycle Synchronization Across Operations:**
   - **New receipt**: schedules future reminders if notifications are enabled.
   - **Edited receipt**: cancels existing reminders for the receipt ID and schedules updated reminders for the new purchase date and duration.
   - **Deleted receipt**: cancels pending reminders for the receipt ID.
   - **App restart**: preloads settings and initializes `LocalWarrantyNotificationService` with non-blocking startup background synchronization.
8. **Clear Distinction from In-App Alerts:**
   - Clarified distinction between the in-app `AlertsScreen` (`/alerts`)—a visual, reactive tab within the app—and local scheduled notifications delivered by the operating system when Receipt Vault is closed.
