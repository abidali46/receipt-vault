# Receipt Vault – Architecture

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Language | Dart 3 (SDK ^3.12.0) |
| UI Framework | Flutter (Material 3) |
| Routing | go_router ^18.0.2 |
| State Management | flutter_riverpod ^3.4.3 (installed, not yet wired) |
| Local Database | Drift ^2.35.2 (SQLite, installed, not yet used) |
| Code Generation | build_runner, riverpod_generator, drift_dev (all installed, not yet run) |
| Testing | flutter_test |

## Folder Structure

```
lib/
├── main.dart                           ← App entry point (ReceiptVaultApp)
├── app/
│   ├── constants/                      ← (empty — future app-wide constants)
│   ├── router/
│   │   ├── app_router.dart             ← GoRouter config + AppRoutes constants
│   │   └── app_shell.dart              ← NavigationBar shell widget
│   └── theme/
│       └── app_theme.dart              ← AppColors, AppShapes, AppTheme.light/dark
├── core/
│   ├── services/                       ← (empty — future services: DB, notifications)
│   ├── storage/                        ← (empty — future Drift database)
│   ├── utils/                          ← (empty — future helpers)
│   └── widgets/                        ← (empty — future core-level widgets)
├── features/                           ← Feature-first organization
│   ├── alerts/
│   │   └── presentation/
│   │       └── alerts_screen.dart      ← Placeholder
│   ├── home/
│   │   └── presentation/
│   │       └── add_receipt_screen.dart ← Placeholder
│   ├── receipts/
│   │   └── presentation/
│   │       └── receipts_screen.dart    ← Placeholder
│   ├── settings/
│   │   └── presentation/
│   │       └── settings_screen.dart    ← Placeholder
│   ├── statistics/                     ← (empty — low priority feature)
│   └── warranty/
│       └── presentation/
│           └── warranty_screen.dart    ← Placeholder
└── shared/
    ├── enums/                          ← (empty — future shared enums)
    └── widgets/
        └── placeholder_screen.dart     ← Reusable PlaceholderScreen widget

design/                                 ← Design assets (never modify)
docs/                                   ← This documentation
test/
└── widget_test.dart                    ← Navigation bar smoke test
```

## Architecture Pattern

The project uses **feature-first** folder organization. Each feature will eventually follow a layered structure:

```
features/<feature_name>/
├── data/
│   ├── models/         ← Data classes / Drift table definitions
│   └── repositories/   ← Repository implementations
├── domain/
│   ├── entities/       ← Business logic entities
│   └── repositories/   ← Repository interfaces
└── presentation/
    ├── screens/        ← Screen widgets
    ├── widgets/        ← Feature-specific widgets
    └── providers/      ← Riverpod providers for this feature
```

> ⚠️ Currently only the `presentation/` layer exists for any feature. Data and domain layers are empty folders awaiting the database task.

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

## State Management Plan

When Riverpod is wired up:

1. Wrap `runApp(const ReceiptVaultApp())` with `ProviderScope` in `main.dart`.
2. Use `@riverpod` annotation with code generation (`build_runner`) for all providers.
3. Screen widgets extend `ConsumerWidget` or `ConsumerStatefulWidget` (not `StatelessWidget`/`StatefulWidget`).
4. Repository providers live in `features/<feature>/presentation/providers/`.
5. Database providers live in `core/storage/`.

## Database Plan (Drift)

The local SQLite database will be introduced in the Receipts task:

- Define tables in `core/storage/app_database.dart`.
- Use `DriftDatabase` annotation and run `build_runner` for generated code.
- Tables planned: `receipts`, `warranties` (linked to receipts by foreign key).
- A `ReceiptsRepository` in `features/receipts/data/repositories/` will abstract database access.

## Theme Architecture

All colors, shapes, and component styles are defined in a single file:
`lib/app/theme/app_theme.dart`

- `AppColors` — Static `const Color` values. Use these, not hardcoded hex.
- `AppShapes` — Static `const BorderRadius` values.
- `AppTheme.light` / `AppTheme.dark` — Full `ThemeData` instances. Access via `Theme.of(context)`.

**Rule:** Never hardcode colors or shapes outside `app_theme.dart`. Always use `Theme.of(context).colorScheme.*` or `AppColors.*` / `AppShapes.*`.
