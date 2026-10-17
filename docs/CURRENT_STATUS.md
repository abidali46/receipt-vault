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
│   ├── Branch 1 → /warranties       (WarrantyScreen — real UI backed by reactive SQLite stream)
│   ├── Branch 2 → /add-placeholder  (SizedBox.shrink — intercepted by shell)
│   ├── Branch 3 → /alerts           (AlertsScreen — real UI backed by reactive SQLite stream & calculated reminders)
│   └── Branch 4 → /settings        (SettingsScreen — real UI with theme selection, local persistence, privacy note, and app info)
├── GoRoute → /add                   (AddReceiptScreen — full-screen push via rootNavigatorKey)
├── GoRoute → /receipts/:id          (ReceiptDetailScreen — full-screen push via rootNavigatorKey)
└── GoRoute → /receipts/:id/edit     (AddReceiptScreen in edit mode — full-screen push via rootNavigatorKey)
```

### 3. Entry Point & State Management — `lib/main.dart`

`ReceiptVaultApp` widget using `MaterialApp.router` wrapped with `ProviderScope`:
- `ProviderScope` root container for Riverpod providers, preloading `initialThemeMode` via `AppSettingsService`.
- `theme: AppTheme.light`
- `darkTheme: AppTheme.dark`
- `themeMode: ref.watch(themeModeProvider)` — reactively toggling between Light, Dark, and System Default app-wide.
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
  - `watchReceiptById(id)`: Reactive Drift stream of a single `Receipt?` entity by integer ID.
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
  - `receiptDetailStreamProvider`: `StreamProvider.autoDispose.family<Receipt?, int>` exposing a single receipt stream by ID, automatically disposing query streams when the detail view is popped.

### 6. Receipts Screen UI & Components — `lib/features/receipts/presentation/`

A fully functional, responsive Receipts screen matching the 5-tab updated mockup and `DESIGN.md` guidelines, wired reactively to the database stream and enhanced with comprehensive receipt discovery:
- **Reactive Integration**: Connects via `ConsumerStatefulWidget` to `receiptsStreamProvider`.
- **Screen States**:
  - **Loading State**: Displays `CircularProgressIndicator` during initial database load; does not prematurely flash empty state.
  - **Error State**: Displays friendly error icon, title, and details if the database stream fails.
  - **Pristine Empty State**: Displays empty state illustration text ("No receipts yet. Tap + to add your first receipt") when the database has zero records.
  - **Filtered Empty State**: Displays "No matching receipts" with detailed contextual explanation naming the search query and category that yielded zero results, accompanied by a "Reset filters" action button.
  - **Populated List**: Displays reactive `ListView.separated` of `ReceiptCard` items, updating automatically whenever database mutations occur.
- **Screen Header**: `AppBar` with `receipt_long` brand icon in primary color, bold "My Receipts" title, and overflow `more_vert` menu supporting reset filters and quick actions.
- **Search Bar** (`ReceiptSearchBar`): 8px radius, white/dark fill, search icon, clear button on text entry, focus state in primaryContainer blue. Performs case-insensitive matching across product name, store name, and category.
- **Category Filter Chips** (`CategoryFilterRow`): Horizontally scrollable row with pill-shaped chips ("All", "Electronics", "Food", "Clothing", "Home", "Others"). Active chip filled in primaryContainer blue with white text; inactive chips styled with surface fill, subtle border, and secondary text.
- **Discovery & Sorting Bar** (`ReceiptSortFilterBar`):
  - Displays dynamic results count ("X receipts" or "X of Y receipts" when filtered).
  - Displays inline pill "Clear" action button when filters are active to quickly restore all receipts.
  - Material 3 `PopupMenuButton<ReceiptSortOption>` with sort icon, active sort label, and checkmark indicators for 5 sorting strategies:
    1. **Newest purchase** (default — latest purchase date first)
    2. **Oldest purchase** (earliest purchase date first)
    3. **Product name (A–Z)** (alphabetical, case-insensitive)
    4. **Amount (high to low)** (highest purchase price first)
    5. **Amount (low to high)** (lowest purchase price first)
- **Domain Discovery Service** (`ReceiptDiscoveryService` in `lib/features/receipts/domain/services/receipt_discovery_service.dart`):
  - Encapsulates pure filtering and sorting logic with stable numeric ID tie-breaking.
  - Keeps UI performant: runs in-memory on the reactive Drift stream without roundtrip SQL overhead or duplicated widget logic.
- **Receipt Card** (`ReceiptCard`): 8px radius, 1px subtle border, ambient shadow (`0px 2px 4px rgba(0,0,0,0.05)`), 48x48 icon circle, product title, store name, right-aligned formatted price, and pill warranty status badge with status indicator dot. Expired items render with strikethrough text, muted colors, and 0.75 opacity. Tapping any card pushes `/receipts/:id` via GoRouter.

| Screen | File | Status |
|--------|------|--------|
| Receipts | `lib/features/receipts/presentation/receipts_screen.dart` | ✅ Real UI connected to reactive database stream, multi-field search, category filtering, and 5 sorting options |
| Receipt Details | `lib/features/receipts/presentation/receipt_detail_screen.dart` | ✅ Real UI connected to reactive SQLite stream by ID, warranty progress, photo preview, edit action, and deletion with confirmation & safe image cleanup |
| Warranties | `lib/features/warranty/presentation/warranty_screen.dart` | ✅ Real UI backed by reactive SQLite receipt stream, centralized warranty calculation, state-aware filtering, progress bars, card navigation, and contextual empty states |
| Alerts | `lib/features/alerts/presentation/alerts_screen.dart` | ✅ Real UI backed by reactive SQLite receipt stream, calculated warranty reminders, urgency sorting, filter chips, card navigation, and contextual empty states |
| Settings | `lib/features/settings/presentation/settings_screen.dart` | ✅ Real UI with theme selection, local persistence, RFC 4180 CSV export/backup, privacy note, and app info |
| Add / Edit Receipt | `lib/features/home/presentation/add_receipt_screen.dart` | ✅ Real Form UI, Photo Selection & Local Storage, Validation, SQLite Persistence & Edit Mode |

### 7. Add Receipt Form UI, Photo Storage & Persistence — `lib/features/home/presentation/add_receipt_screen.dart`

A complete, responsive Add Receipt form UI matching the mockup (`design/mockups/add_receipt/`) connected to Drift SQLite and local file storage:
- **Responsive Layout**: Centered card container (max-width: 600px) with 16px horizontal margins on mobile, `SingleChildScrollView` with bouncy physics.
- **Photo Selection & Local Storage** (`ReceiptImageService` in `lib/core/storage/receipt_image_service.dart`):
  - Tap "Add Photo" placeholder opens a Material bottom sheet modal with camera ("Take Photo") and gallery ("Choose from Gallery") options.
  - Copies selected images from volatile cache into an app-owned persistent directory: `getApplicationDocumentsDirectory() / receipt_images / receipt_<microseconds>.<ext>`.
  - Displays interactive preview with bottom control bar: "Photo attached" confirmation, "Replace" button, and "Remove" button.
  - Safe error fallback (`_buildMissingImageFallback`) rendered with error icon and message when an image file is missing or corrupted, keeping replace and remove controls operational.
  - Safe unreferenced file cleanup: when replacing, removing, or discarding an unsaved receipt draft, uncommitted image files are cleaned up without deleting any files referenced by existing saved receipts.
  - Graceful resilience: user cancellations return silently without errors, permission denials display clear guidance SnackBars, unsupported platform errors show device affordance messages, and file copy errors show descriptive SnackBars—all while preserving entered form values.
  - Optional attachment: receipts can be saved with or without photos.
- **Product Name**: Required text input with title capitalization and empty validation.
- **Store Name**: Optional text input (saved as null when empty).
- **Category Selector**: Horizontally wrapped choice chips with category icons (`WarrantyCalculator.iconForCategory`), active chip filled in `primaryContainer` (`#2563EB`) with white text, inactive chips using surface fill with subtle border.
- **Price / Total Amount**: Required numeric input with decimal keyboard, `$` prefix, and non-negative number validation (`>= 0`).
- **Purchase Date**: Required date field with calendar icon and Material date picker dialog, default to current date.
- **Warranty Duration**: Dropdown with presets (No warranty, 6 months, 12 months, 24 months, 36 months, Custom duration). Selecting "Custom duration..." dynamically reveals a non-negative whole number days input field.
- **Notes**: Optional multiline text field (saved as null when empty).
- **SQLite Persistence**: Connects to `ReceiptsRepository.insertReceipt` via `receiptsRepositoryProvider`. Inserts a `ReceiptsCompanion` record into SQLite (including `imagePath` when a photo is selected) and assigns the autoincrement ID.
- **Duplicate Submission Protection**: `_isSaving` state disables the Save button and shows a centered `CircularProgressIndicator` during the database write, while preventing back gesture interruptions.
- **Feedback & Error Resilience**: Displays a green success `SnackBar` and returns to `ReceiptsScreen` on success. Displays an error `SnackBar` and preserves all entered form values if the database write throws.
- **Reactive Stream Integration**: Returning to `ReceiptsScreen` immediately displays the newly created receipt card at the top of the list via Drift's reactive `watch()` stream. `ReceiptCard` renders the photo thumbnail in the 48x48 leading circle when `imagePath` exists on disk.
- **Unsaved Changes Protection**: `PopScope` integration and `BackButton` handling that checks `_isDirty` (including `_selectedImagePath != null`). Prompts a confirmation `AlertDialog` ("Discard changes?") if the user attempts to leave with unsaved input, while allowing immediate pop when pristine or successfully saved (`_isSaved`).
- **Edit Mode Support**:
  - Accepts `receiptToEdit: Receipt?` and `receiptId: int?` constructor parameters.
  - Automatically prefills product name, store name, formatted price, category choice chip, purchase date, warranty preset (or custom days), notes, and photo preview.
  - Form cleanliness: compares current form values against the initial values in edit mode, allowing pristine edit forms to pop immediately without discard prompts.
  - Save action in edit mode: calls `repository.updateReceipt(updatedReceipt)` on the existing primary key ID instead of inserting duplicate rows.
  - Preserves existing image: keeps the original `imagePath` unless the user explicitly replaces or removes it, and only cleans newly picked uncommitted images on cancel or discard.

### 8. Receipt Details Screen — `lib/features/receipts/presentation/receipt_detail_screen.dart`

A complete, responsive Receipt Details screen matching `design/mockups/receipt_details_samsung_mobile/` connected reactively to SQLite by receipt ID:
- **Reactive Stream Loading**: Watches `receiptDetailStreamProvider(id)` backed by `DriftReceiptsRepository.watchReceiptById(id)`. Any database edits or updates instantly propagate to the details view in real time.
- **Route Integration**: Tapping any `ReceiptCard` in `ReceiptsScreen` invokes `context.push(AppRoutes.receiptDetailPath(receipt.id))` with `parentNavigatorKey: rootNavigatorKey`, presenting as a full-screen view above the bottom navigation shell.
- **Screen States**:
  - **Loading State**: Displays `AppBar` with back button and centered `CircularProgressIndicator` during initial SQLite read.
  - **Error State**: Displays friendly error icon, title, error description, and "Back to Receipts" recovery button if stream errors occur.
  - **Missing Record State**: Gracefully handles missing, deleted, or null IDs with a clean icon illustration, "Receipt Not Found" header, helpful explanation, and "Back to Receipts" navigation action.
  - **Populated Details**: Responsive centered card (max-width: 640px) with smooth bouncy scrolling.
- **Header & Product Title**: Prominent title typography, category chip with Material icon (`WarrantyCalculator.iconForCategory`), and status badge with indicator dot (Active, Expiring Soon, Expired, No Warranty).
- **Photo Section**:
  - Full-width 240px photo card with subtle border and rounded corners.
  - Resilient missing photo fallback (`_buildMissingPhotoFallback`): displays an icon and "Photo not available on this device" card if the image was moved, deleted, or corrupted.
- **Details Card**:
  - 2-column or structured data grid displaying Store Name, Total Amount (formatted currency), Purchase Date (formatted MMMM d, y), Warranty Duration, and Expiration Date.
  - Additional information section displaying Notes (or "No notes added").
- **Warranty Progress Bar**:
  - Visual progress bar calculated via `WarrantyCalculator.calculate` showing elapsed warranty percentage.
  - Color-coded: green (`AppColors.success`) when safe/active, amber/red (`AppColors.warning` / `AppColors.error`) when expiring soon, grey when expired or no warranty.
- **Edit Action**:
  - Prominent "Edit Details" button navigating to `AppRoutes.editReceiptPath(receipt.id)` passing the current receipt entity.
  - Reuses `AddReceiptScreen` in edit mode, updating the database record seamlessly and refreshing both details and list screens reactively.
- **Delete Action & Confirmation Dialog**:
  - Accessible via both an AppBar trash icon button (`Key('receipt_detail_app_bar_delete_button')`) and a prominent "Delete Receipt" action button (`Key('receipt_detail_delete_button')`) styled in `colorScheme.errorContainer` with error tint.
  - Tapping displays a Material `AlertDialog` (`Key('receipt_detail_delete_dialog')`) explicitly identifying the action, naming the product to be deleted, and warning that the action is permanent.
  - Cancelling the dialog leaves the receipt completely untouched in SQLite and dismisses the dialog cleanly.
- **Safe Persistence & Concurrency Guarding**:
  - Concurrency protected: `_isDeleting` flag disables all buttons and action controls to prevent double-taps.
  - Navigation lock: `PopScope(canPop: !_isDeleting)` prevents user gesture interruptions while asynchronous deletion is in progress.
  - Stream transition protection: when SQLite deletes the row, `watchReceiptById` emits `null`. Displaying the loading indicator while `_isDeleting` is true prevents a jarring 1-frame "Receipt Not Found" flash before the screen finishes popping.
  - Database failure handling: if SQLite deletion throws or fails, `_isDeleting` resets to `false`, an error `SnackBar` is displayed with failure feedback, and the screen does NOT pop or show a false success message.
  - On success: deletes the database row via `ReceiptsRepository.deleteReceipt(id)`, triggers referential safe image-file cleanup, displays a green success `SnackBar`, and navigates back to `ReceiptsScreen`.
- **Referential Safe Image Cleanup**:
  - Reuses `ReceiptImageService.deleteImageIfUnreferenced(imagePath, repository: repository)`.
  - Queries all existing database receipts before deleting any file.
  - If any other receipt references the same image file path, the file is strictly preserved on disk.
  - If referential safety cannot be proven (e.g. `repository == null`), the file is preserved on disk to prevent accidental data loss.
  - If unreferenced, the orphaned image file is safely unlinked.
- **Known Limitations**:
  - Single-receipt deletion only (no bulk deletion or multi-select).
  - Permanent deletion (no undo/recycle bin).
  - No export or external backup prior to deletion.

### 9. Warranties Screen — `lib/features/warranty/presentation/warranty_screen.dart`

A complete, responsive Warranties tracking screen matching `design/mockups/active_warranties/` and `design/DESIGN.md`, backed by the reactive SQLite database stream:
- **Centralized Logic Reuse**:
  - Reuses `WarrantyCalculator.calculate` and `WarrantyInfo` from `lib/features/receipts/domain/services/warranty_calculator.dart`.
  - Added `progress` (0.0 to 1.0) to `WarrantyInfo` representing the elapsed/remaining warranty fraction: `(daysRemaining / durationDays).clamp(0.0, 1.0)` for active/expiring items, `0.0` for expired items or items without warranty.
  - Zero duplicated expiry or duration arithmetic in widgets.
- **Strict Omission of Non-Warranty Receipts**:
  - Receipts without warranties (where `warrantyDurationDays == null`, `<= 0`, or status evaluates to `WarrantyStatus.none`) are strictly filtered out by `filterAndSortWarrantyItems()` and never displayed as warranties.
- **Domain Entity & Provider Architecture**:
  - `WarrantyItem` in `lib/features/warranty/domain/entities/warranty_item.dart` maps raw `Receipt` rows and encapsulates `WarrantyInfo`.
  - `warrantiesStreamProvider` in `lib/features/warranty/presentation/providers/warranty_providers.dart` maps `repository.watchReceipts()` reactively into sorted `List<WarrantyItem>`.
  - Sorting: Active & Expiring Soon items appear first, ordered by soonest expiry date; Expired items follow, ordered by most recently expired.
- **Filter Row (`WarrantyFilterRow`)**:
  - Horizontal choice chips for `All`, `Active`, `Expiring Soon`, and `Expired` with dynamic count badges: e.g. "All (3)", "Active (2)", "Expiring Soon (1)", "Expired (0)".
  - Selected chip styled in `colorScheme.primary` with white text; unselected chips styled with outline and surface color.
- **Summary Row**:
  - Displays total count for the selected filter view and highlights an amber badge ("X Expiring Soon") when warranties are nearing expiration within 30 days.
- **Warranty Item Card (`WarrantyCard`)**:
  - Responsive card container with 12px bottom spacing and subtle border.
  - Left icon circle with category icon from `WarrantyCalculator.iconForCategory(receipt.category)`.
  - Product name in bold primary typography, store name & category subtitle.
  - Status pill badge with color-coded dot and text:
    - Active: green container, green text, "X days left" (or "1 day left").
    - Expiring Soon: amber container, amber text, "Expires in X days" / "Expires today".
    - Expired: red container, red text, "Expired".
  - Key dates: "Purchased: MMM d, y" and "Expires: MMM d, y" (or "Expired: MMM d, y").
  - 6px rounded progress bar showing warranty health, with percentage display and status-tinted fill.
  - Tap affordance: tapping any warranty card opens the receipt's full details via `context.push(AppRoutes.receiptDetailPath(item.receipt.id))`.
- **Contextual Empty States (`WarrantyEmptyState`)**:
  - **Pristine State ("All" with 0 warranties)**: Shield icon with "No Warranties Tracked", explanation that warranties added to receipts will be monitored automatically, and an "Add Receipt" button that opens `AppRoutes.add`.
  - **Filtered State (Category has 0 items)**: State-specific messaging ("No Active Warranties", "No Expiring Warranties", "No Expired Warranties") with a "View All Warranties" button that resets the filter.
- **Theme & Dark Mode**:
  - Strict compliance with `AppColors`, `AppShapes`, and `AppTheme`.
  - Fully tested in light and dark modes with high contrast and zero clipped layouts.

### 10. Alerts Screen UI & Calculated Reminders — `lib/features/alerts/presentation/alerts_screen.dart`

A complete, responsive Alerts tracking screen matching `design/mockups/alerts/` and `design/DESIGN.md`, backed by the reactive SQLite database stream:
- **Reactive Stream Integration**:
  - `alertsStreamProvider` (`lib/features/alerts/presentation/providers/alerts_providers.dart`) monitors `repository.watchReceipts()` reactively and generates actionable warranty reminders without polling or fake database records.
- **Pure Domain Reminders & Centralized Calculation**:
  - `WarrantyAlert` (`lib/features/alerts/domain/entities/warranty_alert.dart`) encapsulates a raw `Receipt` and calculates `WarrantyInfo` using centralized `WarrantyCalculator`.
  - Exposes `urgencyLabel` with human-friendly relative time horizons ("Expires today", "Expires in 1 day", "Expires in 7 days", "Expired 1 day ago", "Expired 2 days ago").
  - Strictly omits non-warranty receipts (`warrantyDurationDays == null` or `<= 0`) and safe active warranties with > 30 days remaining.
  - Automatically bounds expired reminders to recent history (default within past 90 days).
- **Deterministic Urgency Sorting**:
  - Group 1: Expiring Soon alerts appear first, ordered by soonest expiry (ascending `remainingDays`).
  - Group 2: Expired alerts appear second, ordered by most recently expired (descending `remainingDays`, e.g. -1 day before -10 days).
  - Tie-breaker: Newest receipt first (descending `receipt.id`).
- **Filter Row (`AlertFilterRow`)**:
  - Horizontal choice chips for `All`, `Expiring Soon`, and `Expired` with dynamic count badges: e.g. "All (2)", "Expiring Soon (1)", "Expired (1)".
  - Selected chip styled in `AppColors.primaryContainer` (`#2563EB`) with white text; unselected chips styled with subtle border and surface colors.
- **Summary Row**:
  - Displays count summary with status coloring: warning amber for expiring count and error red for expired count.
- **Alert Card (`AlertCard`)**:
  - Responsive card container matching the mockup specs:
    - 48×48 circular icon container: amber background with `Icons.warning_amber_rounded` for expiring soon; red container with `Icons.error_outline_rounded` for expired.
    - Product name title with bold typography; strikethrough text decoration (`TextDecoration.lineThrough`) when expired.
    - Store name and category subtitle.
    - Urgency status pill badge ("Expires in 7 days", "Expired 2 days ago").
    - Mini 96×4px rounded progress bar: amber progress ratio for expiring soon; solid full-width red bar for expired items.
    - Tap affordance: tapping any alert card opens full receipt details via `context.push(AppRoutes.receiptDetailPath(alert.receipt.id))`.
- **Contextual Empty States (`AlertsEmptyState`)**:
  - **Pristine State ("All Clear")**: Notification icon with "All Clear", reassurance that the user will be alerted as warranties approach expiration, and a "View Warranties" button that navigates to the Warranties tab via `context.go(AppRoutes.warranties)`.
  - **Filtered State**: Contextual messaging ("No Warranties Expiring Soon", "No Expired Warranties") with a "View All Alerts" button that resets the filter to `All`.
- **Theme & Dark Mode**:
  - Strict compliance with `AppColors`, `AppShapes`, and `AppTheme`.
  - Fully tested in light and dark modes with high contrast and zero clipped layouts.

### 11. Settings Screen UI, Theme Persistence & Privacy Guarantee — `lib/features/settings/presentation/settings_screen.dart`

A complete, responsive Settings screen matching `design/mockups/settings/` and `design/DESIGN.md`, providing working theme selection, zero-dependency persistent JSON storage, local privacy assurance, and app information:
- **Zero-Dependency Lightweight Persistence** (`AppSettingsService` in `lib/core/storage/app_settings_service.dart`):
  - Utilizes existing `path_provider: ^2.1.6` without requiring new third-party plugins (e.g. `shared_preferences`).
  - `LocalFileAppSettingsService` persists key-value settings to `getApplicationDocumentsDirectory() / app_settings.json`.
  - Resilient error recovery: handles missing files, empty files, or corrupted JSON by falling back cleanly to `ThemeMode.system` without throwing or crashing.
  - `InMemoryAppSettingsService` test double for instant, hermetic unit and widget testing.
- **Flicker-Free Theme Initialization**:
  - `main()` preloads `initialThemeMode` via `settingsService.getThemeMode()` before `runApp()`.
  - Injects `initialThemeModeProvider.overrideWithValue(initialMode)` into root `ProviderScope`.
  - Guarantees the user's persisted theme (System Default, Light, or Dark) is applied on the very first frame without white/dark flashing.
- **Theme Selection (`ThemeSelectionCard`)**:
  - Interactive radio tiles for:
    - **System Default** (`Icons.brightness_auto_outlined`): matches OS light/dark mode preference.
    - **Light Mode** (`Icons.light_mode_outlined`): enforces crisp white surfaces and dark typography.
    - **Dark Mode** (`Icons.dark_mode_outlined`): enforces deep slate surfaces and high-contrast light typography.
  - Wrapped in `RadioGroup<ThemeMode>` adhering strictly to Flutter 3.32+ deprecation standards (groupValue/onChanged on group wrapper rather than individual radios).
  - Tapping dynamically calls `themeNotifier.setThemeMode(mode)`, updating Riverpod `themeModeProvider` and persisting to disk asynchronously.
- **Local Data & Privacy Assurance (`PrivacyNoteCard`)**:
  - Reassures user with shield lock icon and clear statement: "Your receipts, warranty details, and photos are stored 100% locally on this device. Nothing is uploaded to any cloud server or external service."
  - Confirms offline-first SQLite database (`receipt_vault.sqlite`) and local app-owned photo storage (`receipt_images/`).
- **About Receipt Vault (`AboutAppCard`)**:
  - Brand header with `receipt_long` icon, app title ("Receipt Vault"), and version badge (`v1.0.0`).
  - Short description: "A minimalist, offline-first receipt keeper and warranty tracker designed for digital peace of mind."
  - Build metadata details: Version (`1.0.0`), Build (`1.0.0+1`), License (`Open Source / MIT`), and Developer note.
- **Scope Boundary Enforcement**:
  - Excludes controls for non-existent features (no dummy cloud sync switches, export buttons, notifications toggles, or account buttons).
- **Responsive Layout & Visual Consistency**:
  - Centered card container (max-width 640px) with 16px padding and smooth bouncy scroll physics.
  - Reusable `SettingsSection` wrapper with section title and caption.
  - Strict compliance with `AppColors`, `AppShapes`, and `AppTheme`.

### 12. User-Controlled CSV Export & Backup — `lib/features/settings/`

A comprehensive, offline-first CSV export and backup feature integrated into the Settings screen, adhering strictly to RFC 4180 standards and user privacy guarantees:
- **Standards-Compliant RFC 4180 CSV Engine** (`ReceiptExportService` in `lib/features/settings/domain/services/receipt_export_service.dart`):
  - Formats all supported receipt fields: ID, Product Name, Store, Category, Purchase Date (`YYYY-MM-DD`), Total Amount (`0.00`), Warranty Duration in Days, Warranty Status (`WarrantyCalculator.calculate()`), Notes, Has Photo (`Yes`/`No`), and Created At (`YYYY-MM-DD HH:mm:ss`).
  - Robust RFC 4180 escaping: fields with commas, double quotes, line breaks (`\n`), or carriage returns (`\r`) are enclosed in double quotes (`"..."`), and internal quotes are escaped by doubling (`""`).
  - Uses standard CRLF (`\r\n`) line terminators.
- **Privacy Protection & Zero Private Path Leakage**:
  - Internal private file paths (`imagePath`) are strictly omitted from exported data.
  - A privacy-safe `Has Photo` column is generated instead, protecting the user's filesystem structure from unintended disclosure.
- **Explicit Photo Attachment Exclusion Disclosure**:
  - Both `DataExportCard` and `ExportReceiptsDialog` prominently state:
    *"CSV exports contain receipt text metadata and warranty details. Attached photos remain securely stored on your local device and are not included in CSV files."*
- **Destination Selection & Sharing Affordances** (`ExportReceiptsDialog` in `lib/features/settings/presentation/widgets/export_receipts_dialog.dart`):
  - Allows selecting between system **Downloads** and app **Documents** folder.
  - Pre-populates a standardized timestamped filename (`receipt_vault_export_YYYYMMDD_HHMMSS.csv`) with custom editing support.
  - Direct **Copy to Clipboard** button enables pasting receipt tables immediately into spreadsheets or messages.
  - In-dialog progress indicator and inline error handling.
  - Success state displays full saved file path, "Copy File Path" button, "Copy CSV" button, and "Done" button.
  - Empty state guard: prevents empty file generation and displays an informative prompt if the database has 0 receipts.
- **Settings Screen Integration** (`DataExportCard` in `lib/features/settings/presentation/widgets/data_export_card.dart`):
  - "Data Management" section on the Settings screen featuring a polished action tile, export button, and photo disclaimer caption.
- **Zero New Dependencies & No Cloud Sync**:
  - 100% offline, local-only, utilizing existing `path_provider` and `path` packages.

### 13. Shared Widgets & Enums

- `lib/shared/widgets/placeholder_screen.dart` — Reusable `PlaceholderScreen` widget (icon + title + subtitle).
- `lib/shared/enums/warranty_status.dart` — Shared `WarrantyStatus` enum (`active`, `expiringSoon`, `expired`, `none`).

### 14. Tests (145 Total Tests in Suite)

- `test/widget_test.dart` (8 tests):
  - Smoke test verifying `NavigationBar` and all 5 destinations with in-memory database provider.
  - Integration test verifying center "Add" button navigates to `AddReceiptScreen` and back button returns cleanly to `ReceiptsScreen`.
  - End-to-end integration test verifying complete Add flow: navigate to Add from shell, fill in fields, save to SQLite, return to shell, and verify new card appears in `ReceiptsScreen`.
  - End-to-end integration test verifying complete Details & Edit flow: tap receipt card, navigate to `ReceiptDetailScreen`, verify details, tap "Edit Details", update product name, save changes, and verify both `ReceiptDetailScreen` and `ReceiptsScreen` list update reactively.
  - End-to-end integration test verifying complete Details & Delete flow: tap receipt card, navigate to `ReceiptDetailScreen`, tap "Delete Receipt", confirm in dialog, verify success feedback and pop back to `ReceiptsScreen`, and verify receipt card is reactively removed from the list.
  - End-to-end integration test verifying Warranties tab: switch to Warranties tab via shell navigation bar, verify active warranty cards render while non-warranty receipts are strictly excluded, tap card to open details, and navigate back cleanly.
  - End-to-end integration test verifying Alerts tab: switch to Alerts tab via shell navigation bar, verify calculated warranty alerts render with urgency badges, safe/no-warranty receipts are excluded, tap alert card to open details, and navigate back cleanly.
  - End-to-end integration test verifying Settings tab: switch to Settings tab via shell navigation bar, verify settings sections render (Appearance, Privacy, About), switch theme modes, and navigate cleanly.
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
- `test/features/receipts/receipts_repository_test.dart` (17 tests):
  - Unit tests for `WarrantyCalculator`: none, expired, expiringSoon (today, 1 day, <= 30 days), active (days left, 1 year, 2 years).
  - Category icon mappings.
  - Presentation mapping with `ReceiptCardData.fromReceipt`.
  - Drift repository CRUD, sorting, real-time stream emissions, and single receipt query (`watchReceiptById`).
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
- `test/features/receipts/receipt_discovery_test.dart` (18 tests):
  - Unit test: search is case-insensitive for product name.
  - Unit test: search is case-insensitive for store name.
  - Unit test: search is case-insensitive for category.
  - Unit test: category filter filters precisely and All includes all categories.
  - Unit test: search and category filter combine with AND logic.
  - Unit test: sorts by newest purchase date first (default).
  - Unit test: sorts by oldest purchase date first.
  - Unit test: sorts by product name alphabetically (A to Z).
  - Unit test: sorts by amount high to low.
  - Unit test: sorts by amount low to high.
  - Unit test: safely handles null purchaseDate with stable tie-breaking.
  - Widget test: renders sort filter bar with counts and sort menu.
  - Widget test: can change sort option via popup menu and updates list order.
  - Widget test: filtering by category and search updates count label and displays inline clear button.
  - Widget test: displays contextual empty state when search finds no match.
  - Widget test: displays contextual empty state when category has no receipts.
  - Widget test: displays contextual empty state when both search and category fail to match.
  - Widget test: database reactivity maintains active sorting and filtering on live insertions.
- `test/features/receipts/receipt_detail_screen_test.dart` (14 tests):
  - Missing record state when receiptId is null.
  - Loading state on initial stream load.
  - Error state when provider emits an error.
  - Missing record state when receipt does not exist in SQLite database.
  - Displays full receipt details with warranty progress and edit button.
  - Renders progress bar with 0.0 for expired receipt matching `WarrantyCalculator`.
  - Displays Delete action button and AppBar delete action button.
  - Cancelling delete confirmation dialog dismisses dialog and leaves receipt in database.
  - Confirming deletion invokes deleteReceipt, cleans unreferenced image, shows success SnackBar, and navigates back.
  - Database failure during deletion displays error SnackBar, resets deleting state, and does NOT show success message or pop.
  - Safe image cleanup skips file deletion if another receipt references the same image file path.
  - Renders safe fallback when image file is missing on disk.
  - Dark mode rendering.
  - Reactively updates in real-time when receipt is modified in SQLite database.
- `test/features/warranty/warranty_screen_test.dart` (12 tests):
  - Calculates correct progress ratio for active warranties.
  - Calculates correct progress ratio for expiring soon warranties.
  - Returns 0.0 progress for expired or 0-day warranties.
  - `filterAndSortWarrantyItems` strictly excludes receipts without warranty.
  - `filterAndSortWarrantyItems` sorts soonest expiry first and expired items last.
  - Renders empty state when no warranties exist.
  - Renders warranty cards with product, store, dates, badge, and progress bar.
  - Strictly omits receipts without warranties from list and count chips.
  - Filter chips filter between All, Active, Expiring Soon, and Expired with counts.
  - Shows contextual empty state when filtered category has 0 items and resets filter on tap.
  - Tapping warranty card invokes navigation callback to open receipt details.
  - Renders cleanly in dark mode without contrast defects or overflow errors.
- `test/features/alerts/alerts_screen_test.dart` (12 tests):
  - `WarrantyAlert` entity: formats relative urgency labels ("Expires today", "Expires in 1 day", "Expires in 7 days", "Expired 1 day ago", "Expired 2 days ago").
  - `generateWarrantyAlerts`: strictly excludes receipts without warranty and safe active receipts (> 30 days remaining).
  - `generateWarrantyAlerts`: sorts alerts with deterministic urgency and date rules (expiring soon first by soonest expiry, then expired by most recent expiry).
  - `generateWarrantyAlerts`: tie-breaks identical urgency by descending receipt ID.
  - Renders pristine empty state ("All Clear") when no alerts exist.
  - Renders alert cards with product name, subtitle, badges, and progress bar.
  - Strikethrough text decoration on expired product name titles.
  - Filter chips toggle between All, Expiring Soon, and Expired with counts.
  - Shows contextual empty state when filtered category has 0 items and resets to All on tap.
  - Tapping alert card pushes receipt details route (`AppRoutes.receiptDetailPath`).
  - Renders cleanly in dark mode without errors or contrast defects.
  - Reactively streams alerts from SQLite database.
- `test/features/settings/settings_screen_test.dart` (8 tests):
  - Unit test: `InMemoryAppSettingsService` defaults to system and persists theme mode in-memory.
  - Unit test: `LocalFileAppSettingsService` persists and reads theme mode from `app_settings.json` file.
  - Unit test: `LocalFileAppSettingsService` gracefully handles corrupt or malformed JSON files by falling back to `ThemeMode.system`.
  - Widget test: `SettingsScreen` renders all four sections (Appearance, Data Management, Privacy, About).
  - Widget test: `SettingsScreen` allows selecting theme mode (Light, Dark, System Default) and updates `themeModeProvider`.
  - Widget test: `SettingsScreen` renders privacy note card emphasizing 100% offline local storage.
  - Widget test: `SettingsScreen` renders about section with app name, version (`v1.0.0`), and description.
  - Widget test: `SettingsScreen` renders cleanly in dark mode without contrast defects or overflows.
- `test/features/settings/receipt_export_service_test.dart` (8 tests):
  - Unit test: `generateCsv` outputs standard headers on first line.
  - Unit test: `generateCsv` formats fields, dates, and amounts cleanly.
  - Unit test: `generateCsv` protects privacy by omitting private image paths and outputting `Has Photo: Yes/No`.
  - Unit test: `escapeCsvField` escapes commas, double quotes, newlines, CRLF, and nulls per RFC 4180.
  - Unit test: `generateCsv` properly escapes special characters in real receipt fields.
  - Unit test: `defaultFileName` formats timestamped filename deterministically.
  - Unit test: `resolveDirectory` respects Downloads and Documents targets with graceful fallback.
  - Unit test: `saveToFile` writes CSV content to disk and appends `.csv` if missing.
- `test/features/settings/data_export_card_test.dart` (5 tests):
  - Widget test: renders tile, title, subtitle, export button, and photo disclaimer.
  - Widget test: shows empty state dialog when repository has 0 receipts and closes cleanly.
  - Widget test: shows export dialog with receipt count, destination selector, and filename field.
  - Widget test: tapping Copy CSV copies content to clipboard and displays confirmation SnackBar.
  - Widget test: saving file writes CSV and transitions to success state with path, copy actions, and done button.
- `test/features/home/add_receipt_screen_test.dart` (27 tests):
  - Form fields rendering, validation, custom warranty days, photo selection/preview/replace/remove, persistent image storage, discard confirmation, dark mode, and persistence.
  - Edit mode: prefills all fields from `receiptToEdit` and `receiptId`, updates existing record via `updateReceipt`, preserves image, and pops pristine edit form without discard confirmation.

### 15. Repository Quality Audit Findings & Hardening

A comprehensive repository-wide quality audit was executed covering architecture, data integrity, navigation, UI, warranty logic, discovery, settings & export, dependencies & platforms, documentation, and security/privacy:
- **Warranty Progress Consistency Fix**: `ReceiptDetailScreen` previously calculated progress via `elapsedDays / totalDays` (showing 0% on new receipts and 100% on expired receipts), directly conflicting with `WarrantyCard` and `WarrantyCalculator` (which evaluate remaining progress `(daysRemaining / durationDays)`). Corrected to use centralized `warrantyInfo.progress`, harmonizing progress indicators across all screens.
- **Platform Configuration Hardening**: `AndroidManifest.xml` was updated to declare `android:label="Receipt Vault"` (matching iOS `CFBundleDisplayName` and `AppInfo.appName` instead of the lowercased package name `receipt_vault`).
- **Data Protection & Version Control Hardening**: `.gitignore` was updated with explicit rules for local SQLite databases (`*.sqlite`, `*.sqlite-*`), settings files (`app_settings.json`), cached images (`receipt_images/`), and exported files (`*.csv`) to prevent accidental commits of local device state.
- **Placeholder Code Audit**: `PlaceholderScreen` in `lib/shared/widgets/placeholder_screen.dart` is currently unmounted since all 5 navigation branches and sub-routes are fully implemented; it is preserved as an unmounted utility widget for future phase placeholders.

**Last verified check results:**
- `dart format` → All 61 source & test files formatted cleanly (0 changed).
- `flutter analyze` → **No issues found.** (ran cleanly in 2.7s).
- `flutter test` → **All 145/145 tests passing** across all unit, repository, service, screen, and integration test suites.

---

## What Does NOT Exist Yet

- **All 5 Shell Tabs Complete** — All 5 bottom navigation tabs (`Receipts`, `Warranties`, `Add`, `Alerts`, `Settings`) are now fully implemented with real UI and persistence.
- **No OCR** — Automated text/receipt parsing is not yet implemented (Phase 10).
- **No push notifications** — No operating system push notifications or scheduled local notifications (Phase 7).
- **No Inter font** — System font is used.
- **No cloud image storage/sync** — Local persistent storage only (as designed for privacy and offline speed).
- **No statistics/analytics** — `lib/features/statistics/` directory is empty (Phase 9).

---

## Installed Dependencies (from `pubspec.yaml`)

### Runtime
| Package | Version | Used? |
|---------|---------|-------|
| `flutter` | SDK | ✅ Yes |
| `cupertino_icons` | ^1.0.8 | ✅ (Material icons used instead) |
| `flutter_riverpod` | ^3.4.3 | ✅ Yes (ProviderScope + databaseProvider + receiptsStreamProvider + receiptImageServiceProvider) |
| `go_router` | ^18.0.2 | ✅ Yes |
| `drift` | ^2.35.2 | ✅ Yes (AppDatabase + Receipts table + DriftReceiptsRepository) |
| `sqlite3_flutter_libs` | ^0.6.0+eol | ✅ Yes (SQLite native library) |
| `path_provider` | ^2.1.6 | ✅ Yes (getApplicationDocumentsDirectory for DB & receipt images) |
| `path` | ^1.9.1 | ✅ Yes (Database and receipt image path joining) |
| `image_picker` | ^1.2.4 | ✅ Yes (Camera capture & gallery photo selection) |
| `riverpod_annotation` | ^4.0.7 | ❌ Available for future providers |

### Dev
| Package | Version | Used? |
|---------|---------|-------|
| `flutter_test` | SDK | ✅ Yes |
| `flutter_lints` | ^6.0.0 | ✅ Yes |
| `build_runner` | ^2.15.1 | ✅ Yes (Generated code up to date) |
| `riverpod_generator` | ^4.0.9 | ❌ Available for future providers |
| `drift_dev` | ^2.35.1 | ✅ Yes (Generated app_database.g.dart) |
