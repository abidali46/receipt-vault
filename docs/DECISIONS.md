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
     - >= 365 days left: `active`, "X year(s) left".
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
