# Receipt Vault – Architecture

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Language | Dart 3 (SDK ^3.12.0) |
| UI Framework | Flutter (Material 3) |
| Routing | go_router ^18.0.2 |
| State Management | flutter_riverpod ^3.4.3 (ProviderScope + databaseProvider + receiptsStreamProvider) |
| Local Database | Drift ^2.35.2 (SQLite, NativeDatabase isolate) |
| Code Generation | build_runner ^2.15.1, drift_dev ^2.35.1 |
| Testing | flutter_test (34 unit, repository, and widget tests) |

## Folder Structure

```
lib/
├── main.dart                           ← App entry point (ProviderScope + ReceiptVaultApp)
├── app/
│   ├── constants/                      ← (empty — future app-wide constants)
│   ├── router/
│   │   ├── app_router.dart             ← GoRouter config + AppRoutes constants
│   │   └── app_shell.dart              ← NavigationBar shell widget (5 destinations)
│   └── theme/
│       └── app_theme.dart              ← AppColors, AppShapes, AppTheme.light/dark (resolved M3 tokens)
├── core/
│   ├── services/                       ← (empty — future services: notifications, OCR)
│   ├── storage/
│   │   ├── app_database.dart           ← Drift AppDatabase & Receipts table definition
│   │   ├── app_database.g.dart         ← Generated Drift code ($ReceiptsTable, Receipt, companion)
│   │   └── database_provider.dart      ← Riverpod databaseProvider singleton
│   ├── utils/                          ← (empty — future helpers)
│   └── widgets/                        ← (empty — future core-level widgets)
├── features/                           ← Feature-first organization
│   ├── alerts/
│   │   └── presentation/
│   │       └── alerts_screen.dart      ← Placeholder stub
│   ├── home/
│   │   └── presentation/
│   │       └── add_receipt_screen.dart ← Placeholder stub
│   ├── receipts/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── drift_receipts_repository.dart ← Concrete ReceiptsRepository using Drift AppDatabase
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── receipt_card_data.dart ← ReceiptCardData presentation entity + fromReceipt factory
│   │   │   ├── repositories/
│   │   │   │   └── receipts_repository.dart ← ReceiptsRepository interface
│   │   │   └── services/
│   │   │       └── warranty_calculator.dart ← Reusable warranty calculation & category icon mapper
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── receipts_providers.dart ← Riverpod receiptsRepositoryProvider & receiptsStreamProvider
│   │       ├── receipts_screen.dart    ← ConsumerStatefulWidget connected to receiptsStreamProvider
│   │       └── widgets/
│   │           ├── category_filter_row.dart ← Reusable pill category filter chips
│   │           ├── receipt_card.dart        ← Reusable receipt item card with status badge
│   │           ├── receipt_search_bar.dart  ← Reusable search field with clear action
│   │           └── receipts_empty_state.dart← Reusable pristine & filtered empty state
│   ├── settings/
│   │   └── presentation/
│   │       └── settings_screen.dart    ← Placeholder stub
│   ├── statistics/                     ← (empty — low priority feature)
│   └── warranty/
│       └── presentation/
│           └── warranty_screen.dart    ← Placeholder stub
└── shared/
    ├── enums/
    │   └── warranty_status.dart        ← Shared WarrantyStatus enum (active, expiringSoon, expired, none)
    └── widgets/
        └── placeholder_screen.dart     ← Reusable PlaceholderScreen widget

design/                                 ← Design assets (never modify)
docs/                                   ← Project documentation & knowledge base
test/
├── widget_test.dart                    ← Navigation bar smoke test (with in-memory database)
├── core/
│   └── storage/
│       ├── app_database_test.dart      ← Drift database CRUD and stream tests (in-memory)
│       └── database_provider_test.dart ← Riverpod databaseProvider override tests
└── features/
    └── receipts/
        ├── receipts_repository_test.dart ← Repository, warranty calculation, and mapping unit tests
        └── receipts_screen_test.dart   ← Widget tests: UI states, dark mode, loading, error, stream reactivity
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

## Navigation Architecture

**go_router** with `StatefulShellRoute.indexedStack`:

- 5-branch indexed stack for the bottom NavigationBar.
- Each branch maintains its own independent navigation stack.
- Branch 2 (Add) is a dummy branch — `AppShell` intercepts index 2 taps and performs `context.push('/add')` instead of switching branches. This keeps the previously-active tab visually selected after returning from Add.
- The `/add` route is a **top-level** GoRoute (outside the shell), so it covers the shell entirely.

```
GoRouter
├── StatefulShellRoute (AppShell)    ← Persistent bottom nav
│   ├── Branch 0: /receipts
│   ├── Branch 1: /warranties
│   ├── Branch 2: /add-placeholder   ← Never actually navigated to
│   ├── Branch 3: /alerts
│   └── Branch 4: /settings
└── GoRoute: /add                    ← Full-screen push, no bottom nav
```

## State Management Architecture

Riverpod is wired up at the application root:

1. `ProviderScope` wraps `ReceiptVaultApp` in `lib/main.dart` and `test/widget_test.dart`.
2. Database provider `databaseProvider` lives in `lib/core/storage/database_provider.dart` with automatic lifecycle disposal.
3. Feature repository provider `receiptsRepositoryProvider` and reactive stream provider `receiptsStreamProvider` live in `lib/features/receipts/presentation/providers/receipts_providers.dart`.
4. Presentation widgets (`ReceiptsScreen`) consume streams using `ref.watch(receiptsStreamProvider)`.

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
