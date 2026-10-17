# Receipt Vault – Architecture

## Technology Stack

| Layer            | Technology                                                                                                                                                      |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Language         | Dart 3 (SDK ^3.12.0)                                                                                                                                            |
| UI Framework     | Flutter (Material 3)                                                                                                                                            |
| Routing          | go_router ^18.0.2                                                                                                                                               |
| State Management | flutter_riverpod ^3.4.3 (ProviderScope + databaseProvider + receiptsStreamProvider + receiptImageServiceProvider + settingsServiceProvider + themeModeProvider + warrantyNotificationServiceProvider) |
| Local Database   | Drift ^2.35.2 (SQLite, NativeDatabase isolate)                                                                                                                  |
| Media / Storage  | image_picker ^1.2.4 (Camera capture & gallery selection), path_provider ^2.1.6                                                                                  |
| Notifications    | flutter_local_notifications ^22.3.2, timezone ^0.11.2, flutter_timezone ^5.1.1                                                                 |
| Code Generation  | build_runner ^2.15.1, drift_dev ^2.35.1                                                                                                                         |
| Testing          | flutter_test (181 unit, repository, service, screen, and widget tests)                                                                                          |

## Folder Structure

```
lib/
├── main.dart                           ← App entry point (ProviderScope + ReceiptVaultApp)
├── app/
│   ├── constants/
│   │   └── app_constants.dart          ← AppInfo metadata (appName, version, description)
│   ├── router/
│   │   ├── app_router.dart             ← GoRouter config + AppRoutes constants
│   │   └── app_shell.dart              ← NavigationBar shell widget (5 destinations)
│   └── theme/
│       └── app_theme.dart              ← AppColors, AppShapes, AppTheme.light/dark (resolved M3 tokens)
├── core/
│   ├── services/
│   │   └── warranty_notification_service.dart ← WarrantyNotificationService, LocalWarrantyNotificationService, and FakeWarrantyNotificationService
│   ├── storage/
│   │   ├── app_database.dart           ← Drift AppDatabase & Receipts table definition
│   │   ├── app_database.g.dart         ← Generated Drift code ($ReceiptsTable, Receipt, companion)
│   │   ├── app_settings_service.dart   ← AppSettingsService abstraction, LocalFileAppSettingsService (JSON), InMemoryAppSettingsService
│   │   ├── database_provider.dart      ← Riverpod databaseProvider singleton
│   │   └── receipt_image_service.dart  ← Photo picker abstraction, persistent storage copy, and safe file management
│   ├── utils/                          ← (empty — future helpers)
│   └── widgets/                        ← (empty — future core-level widgets)
├── features/                           ← Feature-first organization
│   ├── alerts/
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── warranty_alert.dart  ← WarrantyAlert entity & relative urgency label computation
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── alerts_providers.dart ← Riverpod alertsStreamProvider, AlertFilter, & deterministic sorting
│   │       ├── alerts_screen.dart       ← Real Alerts screen with section headers and reactive stream
│   │       └── widgets/
│   │           ├── alert_card.dart      ← Card with 48x48 icon, product title (strikethrough when expired), urgency badge, & mini progress bar
│   │           ├── alert_filter_row.dart← Reusable choice chips with dynamic category counts
│   │           └── alerts_empty_state.dart ← Contextual empty state ("All Clear" & filtered empty states)
│   ├── home/
│   │   └── presentation/
│   │       └── add_receipt_screen.dart ← Real Add Receipt form UI, photo selection/preview, validation, and SQLite persistence
│   ├── receipts/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── drift_receipts_repository.dart ← Concrete ReceiptsRepository using Drift AppDatabase
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── receipt_card_data.dart ← ReceiptCardData presentation entity + fromReceipt factory
│   │   │   │   └── receipt_sort_option.dart ← ReceiptSortOption enum with 5 sorting strategies
│   │   │   ├── repositories/
│   │   │   │   └── receipts_repository.dart ← ReceiptsRepository interface
│   │   │   └── services/
│   │   │       ├── receipt_discovery_service.dart ← Pure domain service for multi-field search and deterministic sorting
│   │   │       └── warranty_calculator.dart ← Reusable warranty calculation & category icon mapper
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── receipts_providers.dart ← Riverpod receiptsRepositoryProvider, receiptsStreamProvider, receiptDetailStreamProvider
│   │       ├── receipts_screen.dart    ← ConsumerStatefulWidget with discovery, search, sorting, and reactive stream
│   │       ├── receipt_detail_screen.dart ← Full-screen detail view with SQLite stream by ID, warranty progress, photo preview, edit action, and deletion flow with confirmation & safe image cleanup
│   │       └── widgets/
│   │           ├── category_filter_row.dart ← Reusable pill category filter chips
│   │           ├── receipt_card.dart        ← Reusable receipt item card with status badge
│   │           ├── receipt_search_bar.dart  ← Reusable search field with clear action
│   │           ├── receipt_sort_filter_bar.dart ← Result count, inline clear button, and sort popup menu
│   │           └── receipts_empty_state.dart← Contextual empty state with search and category explanations
│   ├── settings/
│   │   ├── domain/
│   │   │   └── services/
│   │   │       └── receipt_export_service.dart ← RFC 4180 CSV export generator, escaping, timestamping, & safe directory resolution
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── settings_providers.dart ← Riverpod settingsServiceProvider, initialThemeModeProvider, ThemeModeNotifier, themeModeProvider
│   │       ├── settings_screen.dart    ← SettingsScreen with Appearance, Data Management, Privacy, and About sections
│   │       └── widgets/
│   │           ├── about_app_card.dart  ← App title, version badge, description, and build metadata
│   │           ├── data_export_card.dart ← Data export card tile with CSV action and photo disclaimer
│   │           ├── export_receipts_dialog.dart ← Modal export dialog with destination selector, filename editor, copy clipboard, & progress
│   │           ├── notifications_setting_card.dart ← Warranty notifications switch with permission handling and SnackBar feedback
│   │           ├── privacy_note_card.dart ← Privacy assurance card explaining 100% offline local storage
│   │           ├── settings_section.dart← Reusable section wrapper with title and subtitle
│   │           └── theme_selection_card.dart ← Radio selector for System Default, Light, and Dark modes
│   ├── statistics/                     ← (empty — low priority feature)
│   └── warranty/
│       ├── domain/
│       │   └── entities/
│       │       └── warranty_item.dart  ← WarrantyItem domain entity wrapping Receipt & WarrantyInfo
│       └── presentation/
│           ├── providers/
│           │   └── warranty_providers.dart ← Riverpod warrantiesStreamProvider, filterAndSortWarrantyItems
│           ├── warranty_screen.dart    ← Real Warranties tracking screen backed by reactive stream
│           └── widgets/
│               ├── warranty_card.dart  ← Warranty item card with category icon, status badge, dates, & progress bar
│               ├── warranty_filter_row.dart ← Choice chips with counts (All, Active, Expiring Soon, Expired)
│               └── warranty_empty_state.dart ← Contextual empty state (pristine & filtered)
└── shared/
    ├── enums/
    │   └── warranty_status.dart        ← Shared WarrantyStatus enum (active, expiringSoon, expired, none)
    └── widgets/
        └── placeholder_screen.dart     ← Reusable PlaceholderScreen widget (unmounted utility preserved for future extension)

design/                                 ← Design assets (never modify)
docs/                                   ← Project documentation & knowledge base
test/
├── widget_test.dart                    ← Navigation bar smoke, Add flow, Details/Edit/Delete, Warranties, Alerts, and Settings end-to-end integration tests
├── core/
│   └── storage/
│       ├── app_database_test.dart      ← Drift database CRUD and stream tests (in-memory)
│       └── database_provider_test.dart ← Riverpod databaseProvider override tests
└── features/
    ├── alerts/
    │   └── alerts_screen_test.dart     ← Entity calculations, urgency sorting, filter chips, tap navigation, and dark mode tests
    ├── home/
    │   └── add_receipt_screen_test.dart ← AddReceiptScreen UI, validation, photo selection/preview, SQLite persistence, and edit mode tests
    ├── receipts/
    │   ├── receipts_repository_test.dart ← Repository, warranty calculation, and mapping unit tests
    │   ├── receipt_detail_screen_test.dart ← ReceiptDetailScreen states, loading, error, missing record, progress value, and reactivity tests
    │   ├── receipt_discovery_test.dart ← Multi-field search, category filtering, 5 sorting options, and empty states
    │   └── receipts_screen_test.dart   ← Widget tests: UI states, dark mode, loading, error, stream reactivity
    ├── settings/
    │   ├── data_export_card_test.dart  ← Data export widget tests, empty states, copy clipboard, and file write states
    │   ├── receipt_export_service_test.dart ← RFC 4180 CSV escaping, timestamping, directory resolution, and privacy tests
    │   └── settings_screen_test.dart   ← Theme mode persistence, selection, privacy notes, and about section tests
    └── warranty/
        └── warranty_screen_test.dart   ← Progress calculation, sorting, filtering, empty state, and dark mode tests
```

## Architecture Pattern

The project uses **feature-first** folder organization. Each feature follows a layered structure:

```
features/<feature_name>/
├── data/
│   ├── models/         ← Data classes / Drift table definitions
│   └── repositories/   ← Repository implementations
├── domain/
│   ├── entities/       ← Business logic and presentation entities
│   ├── repositories/   ← Repository interfaces
│   └── services/       ← Feature-level domain services (e.g. WarrantyCalculator)
└── presentation/
    ├── screens/        ← Screen widgets
    ├── widgets/        ← Feature-specific reusable widgets
    └── providers/      ← Riverpod providers for this feature
```

> ℹ️ Status:
>
> - **Storage Layer**: Implemented (`lib/core/storage/`). Provides persistent Drift SQLite storage and Riverpod `databaseProvider`.
> - **Receipts Feature**: Fully implemented end-to-end. Drift database rows are exposed as reactive streams through `ReceiptsRepository`, mapped into presentation models using `WarrantyCalculator`, and consumed reactively by `ReceiptsScreen` via `receiptsStreamProvider`.
> - **Other Features**: Clean placeholder stubs ready for future development phases.

## Data Flow: SQLite to UI

The reactive pipeline follows unidirectional data flow:

```
SQLite Database (receipt_vault.sqlite)
        │
        ▼ (Drift watch() on background isolate)
AppDatabase.receipts Stream
        │
        ▼
DriftReceiptsRepository.watchReceiptCards()
        │
        ▼ (Maps raw Receipt → ReceiptCardData via WarrantyCalculator)
StreamProvider: receiptsStreamProvider
        │
        ▼ (ref.watch in ConsumerStatefulWidget)
ReceiptsScreen
   ├── AsyncLoading → Center(child: CircularProgressIndicator())
   ├── AsyncError   → Center(child: _buildErrorState(error))
   └── AsyncData    → Filter by search & category
         ├── Empty  → ReceiptsEmptyState(pristine or filtered)
         └── Non-empty → ListView.separated(ReceiptCard)
```

## Warranties Reactive Pipeline Architecture

The **Warranties Screen** (`lib/features/warranty/presentation/warranty_screen.dart`) is backed by a reactive Drift query stream mapped through the pure domain calculation pipeline:

```
SQLite (Drift Receipts table)
        │
        ▼ (watch() reactive stream sorted by purchaseDate & id DESC)
DriftReceiptsRepository.watchReceipts()
        │
        ▼ (filterAndSortWarrantyItems strictly excludes non-warranty receipts,
        │  computes centralized progress & status via WarrantyCalculator,
        │  and sorts soonest-to-expire first)
StreamProvider: warrantiesStreamProvider
        │
        ▼ (ref.watch in WarrantyScreen ConsumerStatefulWidget)
WarrantyScreen
   ├── AsyncLoading → Center(child: CircularProgressIndicator())
   ├── AsyncError   → Center(child: _buildErrorBody(error))
   └── AsyncData    → Filter by WarrantyFilter (_selectedFilter: all, active, expiringSoon, expired)
         ├── Empty  → WarrantyEmptyState (pristine "No Warranties" or filtered "No Expired...")
         └── Non-empty → ListView.builder(WarrantyCard)
                             │
                             ▼ (tap card)
                         context.push(AppRoutes.receiptDetailPath(item.receipt.id))
```

## Alerts Reactive Pipeline Architecture

The **Alerts Screen** (`lib/features/alerts/presentation/alerts_screen.dart`) is backed by a reactive Drift query stream mapped into actionable warranty alerts:

```
SQLite (Drift Receipts table)
        │
        ▼ (watch() reactive stream sorted by purchaseDate & id DESC)
DriftReceiptsRepository.watchReceipts()
        │
        ▼ (generateWarrantyAlerts:
        │  - Strictly excludes non-warranty and safe active receipts (> 30 days)
        │  - Encapsulates WarrantyInfo & relative urgencyLabel ("Expires today", "Expires in 7 days", "Expired 2 days ago")
        │  - Deterministic sort: Expiring Soon before Expired; soonest expiry first; most recently expired first; id DESC tie-breaker)
StreamProvider: alertsStreamProvider
        │
        ▼ (ref.watch in AlertsScreen ConsumerStatefulWidget)
AlertsScreen
   ├── AsyncLoading → Center(child: CircularProgressIndicator())
   ├── AsyncError   → Center(child: _buildErrorBody(error))
   └── AsyncData    → Filter by AlertFilter (_selectedFilter: all, expiringSoon, expired)
         ├── Empty  → AlertsEmptyState (pristine "All Clear" or filtered contextual state)
         └── Non-empty → ListView with section headers ("Expiring Soon", "Expired")
                             │
                             ▼ (tap alert card)
                         context.push(AppRoutes.receiptDetailPath(alert.receipt.id))
```

## Deletion Flow & Referential Safe Image Cleanup

The receipt deletion workflow enforces strict confirmation, concurrency locking, and referential safety:

```
User taps Delete (AppBar icon or bottom button)
        │
        ▼
Confirmation AlertDialog ("Delete Receipt?", identifies product, warns permanent)
        ├── User cancels → Dialog closes; no changes made
        └── User confirms
                │
                ▼
        _isDeleting = true (disables buttons, locks PopScope back gestures)
                │
                ▼
        ReceiptsRepository.deleteReceipt(id)
                │
                ├── On Failure / Exception:
                │       _isDeleting = false
                │       Show error SnackBar with failure details
                │       Keep view on detail screen (no navigation, no success SnackBar)
                │
                └── On Success:
                        │
                        ▼
                ReceiptImageService.deleteImageIfUnreferenced(imagePath, repository)
                        ├── If imagePath null: no-op
                        ├── If repository null: leave file intact (safe fallback)
                        ├── If any other receipt references imagePath: leave file intact
                        └── If unreferenced: safely delete orphaned image file from disk
                        │
                        ▼
                Show success SnackBar ("Receipt deleted successfully.")
                        │
                        ▼
                Navigator.pop() / context.pop() back to ReceiptsScreen
                        │
                        ▼ (Drift watch() reactive pipeline)
                ReceiptsScreen automatically updates; deleted card disappears
```

## Navigation Architecture

**go_router** with `StatefulShellRoute.indexedStack`:

- 5-branch indexed stack for the bottom NavigationBar.
- Each branch maintains its own independent navigation stack.
- Branch 2 (Add) is a dummy branch — `AppShell` intercepts index 2 taps and performs `context.push('/add')` instead of switching branches. This keeps the previously-active tab visually selected after returning from Add.
- The `/add`, `/receipts/:id`, and `/receipts/:id/edit` routes are **top-level** GoRoutes configured with `parentNavigatorKey: rootNavigatorKey` (outside the shell), so they push full-screen over the bottom navigation bar.

```
GoRouter
├── StatefulShellRoute (AppShell)    ← Persistent bottom nav
│   ├── Branch 0: /receipts          ← Receipts list
│   ├── Branch 1: /warranties        ← Active warranties
│   ├── Branch 2: /add-placeholder   ← Intercepted by shell to push /add
│   ├── Branch 3: /alerts            ← Expiry alerts
│   └── Branch 4: /settings          ← App settings
├── GoRoute: /add                    ← Full-screen push, no bottom nav
├── GoRoute: /receipts/:id           ← Full-screen push receipt details, no bottom nav
└── GoRoute: /receipts/:id/edit      ← Full-screen push edit receipt form, no bottom nav
```

## State Management Architecture

Riverpod is wired up at the application root:

1. `ProviderScope` wraps `ReceiptVaultApp` in `lib/main.dart` and `test/widget_test.dart`.
2. Database provider `databaseProvider` lives in `lib/core/storage/database_provider.dart` with automatic lifecycle disposal.
3. Feature repository provider `receiptsRepositoryProvider`, `receiptsStreamProvider`, and `rawReceiptsStreamProvider` live in `lib/features/receipts/presentation/providers/receipts_providers.dart`.
4. Warranty stream provider `warrantiesStreamProvider` lives in `lib/features/warranty/presentation/providers/warranty_providers.dart` and maps raw receipts into sorted `WarrantyItem` domain entities.
5. Alerts stream provider `alertsStreamProvider` lives in `lib/features/alerts/presentation/providers/alerts_providers.dart` and maps raw receipts into deterministically sorted `WarrantyAlert` reminder entities.
6. Receipt detail stream provider `receiptDetailStreamProvider` is an `autoDispose.family` stream provider loading single receipts by primary key ID.
7. Presentation widgets (`ReceiptsScreen`, `WarrantyScreen`, `AlertsScreen`, `ReceiptDetailScreen`, `SettingsScreen`) consume reactive providers using `ref.watch(...)`.
8. Settings and Theme providers: `settingsServiceProvider` provides the local file-backed `AppSettingsService`, while `themeModeProvider` (`NotifierProvider<ThemeModeNotifier, ThemeMode>`) manages theme state and persists user preferences asynchronously to disk.

## Settings & Theme Persistence Architecture

Theme selection and app-wide preference persistence are architectured without heavyweight dependencies:

- **Zero-Dependency Persistence**: Rather than adding `shared_preferences` (which introduces additional native platform dependencies and method channel mocking overhead in tests), `LocalFileAppSettingsService` (`lib/core/storage/app_settings_service.dart`) stores key-value pairs directly in `getApplicationDocumentsDirectory() / app_settings.json` using the already-installed `path_provider` package.
- **Resilient Fallback**: Corrupted, empty, or unreadable JSON files automatically fall back to `ThemeMode.system` without crashing or throwing errors.
- **Flicker-Free Startup**: `main()` preloads `initialThemeMode` asynchronously via `settingsService.getThemeMode()` before `runApp()`. It injects `initialThemeModeProvider.overrideWithValue(initialMode)` into the root `ProviderScope`, guaranteeing that `ReceiptVaultApp` and `MaterialApp.router` render the user's preferred theme mode from the very first frame without UI theme flickering.
- **Flutter 3.32+ Deprecation Compliance**: `ThemeSelectionCard` wraps radio options in `RadioGroup<ThemeMode>(groupValue: currentThemeMode, onChanged: ...)` and omits `groupValue`/`onChanged` on individual `Radio<ThemeMode>` widgets, adhering to current Flutter M3 standards with 0 analyzer warnings.

## Database Architecture (Drift + SQLite)

The local SQLite database foundation is fully implemented:

- **Schema**: Defined in `lib/core/storage/app_database.dart` with `@DriftDatabase(tables: [Receipts])`.
  - `id`: Auto-increment integer primary key
  - `productName`: Text, required
  - `storeName`: Text, nullable
  - `category`: Text, nullable
  - `purchaseDate`: DateTime, required
  - `totalAmount`: Real (double), required
  - `warrantyDurationDays`: Integer, nullable (null = no warranty)
  - `notes`: Text, nullable
  - `imagePath`: Text, nullable
  - `createdAt`: DateTime, default `currentDateAndTime`
- **Isolate Concurrency**: Uses `NativeDatabase.createInBackground(File)` in `getApplicationDocumentsDirectory() / receipt_vault.sqlite`. Database operations run in a dedicated background isolate to avoid UI thread stutters.
- **Testing**: `AppDatabase` accepts an optional `QueryExecutor`. Tests instantiate `AppDatabase(NativeDatabase.memory())` for rapid, hermetic testing.

## Theme Architecture

All colors, shapes, and component styles are defined in a single file:
`lib/app/theme/app_theme.dart`

- `AppColors` — Static `const Color` values (M3 tokens resolved against mockups: primary `#004AC6`, primaryContainer `#2563EB`, secondaryContainer `#D0E1FB`).
- `AppShapes` — Static `const BorderRadius` values.
- `AppTheme.light` / `AppTheme.dark` — Full `ThemeData` instances. Access via `Theme.of(context)`.

**Rule:** Never hardcode colors or shapes outside `app_theme.dart`. Always use `Theme.of(context).colorScheme.*` or `AppColors.*` / `AppShapes.*`.

## Receipt Discovery & Sorting Architecture

Receipt search, filtering, and sorting are implemented using a lightweight, reactive in-memory pipeline:

- **Client-Side Stream Filtering**: Rather than executing repeated, debounced SQL queries over native method channels on every keystroke, the app reads the reactive `receiptsStreamProvider`. Search and category filtering are performed in-memory using `ReceiptDiscoveryService.filterReceipts`. This guarantees instantaneous UI updates without query latency or DB roundtrip overhead.
- **Multi-Field Case-Insensitive Search**: Search terms match against `productName`, `storeName`, and `category` using case-insensitive substring matching (`String.contains(query.toLowerCase())`).
- **Deterministic Multi-Attribute Sorting**: `ReceiptSortOption` provides 5 sorting strategies:
  1. `newestPurchase`: Newest purchase date first (ties broken by descending ID).
  2. `oldestPurchase`: Oldest purchase date first (ties broken by ascending ID).
  3. `productName`: Alphabetical product name A–Z (ties broken by descending ID).
  4. `amountHighToLow`: Highest price first (ties broken by descending ID).
  5. `amountLowToHigh`: Lowest price first (ties broken by descending ID).
- **Contextual Empty States**: `ReceiptsEmptyState` distinguishes between a completely empty database (pristine vault) and an empty filtered subset. When filtering matches zero receipts, the view dynamically explains whether the search query, category filter, or both produced the empty result, providing clear "Reset filters" and inline "Clear" buttons.

## User-Controlled CSV Export & Backup Architecture

The backup and export feature is implemented as a 100% offline, local-only service following strict privacy, compatibility, and RFC 4180 standards:

```
SettingsScreen (Data Management Section)
       │
       ▼ (tap tile or button)
DataExportCard
       │
       ▼ (showDialog)
ExportReceiptsDialog
       ├── Empty State Check (0 receipts in SQLite → "Receipt Vault is Empty" info prompt)
       └── Export Configuration Form:
             ├── Photo Disclaimer Notice ("Metadata only; photos stored locally")
             ├── Destination Selector (Downloads vs Documents folder)
             ├── Filename Input (pre-populated timestamped: receipt_vault_export_YYYYMMDD_HHMMSS.csv)
             └── Action Options:
                   ├── "Copy CSV": Copies full RFC 4180 CSV text directly to Clipboard
                   └── "Save File":
                         │
                         ▼
                   ReceiptExportService.resolveDirectory(destination)
                         │ (uses getDownloadsDirectory with safe fallback to documents)
                         ▼
                   ReceiptExportService.generateCsv(receipts)
                         │ (RFC 4180 escaping, omit imagePath, Has Photo: Yes/No)
                         ▼
                   ReceiptExportService.saveToFile(csvContent, directory, fileName)
                         │ (flushes to persistent storage, ensures directory exists)
                         ▼
                   Success State View:
                         ├── Displays full saved file path
                         ├── "Copy File Path" button (copies path to clipboard)
                         ├── "Copy CSV" button (copies CSV text to clipboard)
                         └── "Done" button (dismisses dialog)
```

- **RFC 4180 Compliant Generator** (`ReceiptExportService`): Generates UTF-8 encoded, CRLF (`\r\n`) delimited CSV tables with standard headers. Escapes commas, double quotes, line feeds (`\n`), and carriage returns (`\r`) by wrapping fields in quotes and doubling internal quotes (`""`).
- **Privacy Guarantees**: Does not output private device file system paths (e.g., `/data/user/0/...` or `C:\Users\...`). Formats an un-leaked `Has Photo: Yes/No` column instead.
- **Prominent Photo Disclaimer**: Explicitly notifies the user in both the Settings card and modal dialog that photo attachments remain in local app-owned storage and are not embedded in CSV files.
- **Zero New Dependencies & No Cloud Sync**: Strictly relies on existing packages (`path_provider`, `path`, `drift`) and Flutter SDK (`dart:io`, `Clipboard`). No cloud sync, external accounts, or automatic background uploads.
