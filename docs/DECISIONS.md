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

## D-006: Riverpod Not Yet Wired Up

**Decision:** `flutter_riverpod` is installed but `ProviderScope` is not wrapping the app yet.

**Reason:** There is no state to manage yet — all screens are placeholders. Introducing Riverpod without any providers would be noise.

**Action Required:** When the first real feature is built (Receipts screen + data model), wrap `runApp` with `ProviderScope`:

```dart
void main() {
  runApp(const ProviderScope(child: ReceiptVaultApp()));
}
```

---

## D-007: Drift Database Not Yet Created

**Decision:** `drift` and `sqlite3_flutter_libs` are installed but no database code exists.

**Reason:** Database schema cannot be designed responsibly before the data model is defined. The Receipts feature is the first place to introduce the DB.

**Action Required (next task):**
1. Create `lib/core/storage/app_database.dart` with Drift `@DriftDatabase`.
2. Define `ReceiptsTable` with columns: id, productName, storeName, purchaseDate, totalAmount, warrantyDurationDays, notes, imagePath, category, createdAt.
3. Run `flutter pub run build_runner build` to generate `.g.dart` files.
4. Create a `DatabaseProvider` in Riverpod to expose the DB instance.

---

## D-008: Primary Colour Discrepancy Between Sources

**Decision:** Document the conflict; do not silently resolve it.

**Details:**
- `design/DESIGN.md` prose states Primary = `#2563EB`.
- `design/DESIGN.md` YAML front-matter and all mockup HTML files use `primary: #004AC6` and `primary-container: #2563EB`.
- `lib/app/theme/app_theme.dart` was implemented using `#2563EB` as primary (matching prose, not YAML).

**Resolution Needed:** Before building real screens, compare the `screen.png` images to both values and pick the closest match. Update `AppColors.primary` and the `ColorScheme` in `app_theme.dart` accordingly.

---

## D-009: App Name Discrepancy in Design File

**Decision:** Ignore "Lumina Ledger" references in `design/DESIGN.md` YAML front-matter.

**Details:** The YAML front-matter in `design/DESIGN.md` says `name: Lumina Ledger`. This appears to be a leftover from an earlier draft. The Flutter package name is `receipt_vault`, the app title in `main.dart` is "Receipt Vault", and all other references use that name.

**Constraint:** Never rename the package or any code file to "Lumina Ledger".

---

## D-010: `build_runner` Has Not Been Run

**Decision:** Code generation has not been executed yet.

**Impact:** `riverpod_generator` and `drift_dev` cannot produce `.g.dart` files until `build_runner` runs. No generated code currently exists.

**Action Required:** After creating the first Drift table or Riverpod provider annotation, run:
```
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## D-011: Decoupled UI & Presentation Data for Receipts Screen

**Decision:** Implemented `ReceiptsScreen` with modular presentation components (`ReceiptCard`, `ReceiptSearchBar`, `CategoryFilterRow`, `ReceiptsEmptyState`), `WarrantyStatus` enum in `lib/shared/enums/`, and a pure presentation entity `ReceiptCardData` in `lib/features/receipts/domain/entities/`. No fake receipt data is hardcoded into the app runtime; by default the screen displays the pristine empty state.

**Reason:** Enables thorough visual and interaction testing (search, category filtering, expired strikethrough, active/expiring badges, tap callbacks) without hardcoding mock data or prematurely coupling the UI to a specific database ORM implementation. When Drift and Riverpod repositories are introduced in the next phase, the screen simply maps domain receipts to `ReceiptCardData` or directly consumes the repository stream.
