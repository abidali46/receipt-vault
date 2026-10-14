---
name: receipt-vault-flutter
description: >
  Working instructions for AI coding assistants continuing development on
  Receipt Vault — a Flutter Android/iOS app for storing receipts and tracking
  warranties. Read this before writing any code.
---

# Receipt Vault – Developer Skill

## 1. Always Inspect First

Before editing any file:

1. Read `docs/CURRENT_STATUS.md` to know exactly what is implemented and what is not.
2. Read `docs/ARCHITECTURE.md` to understand the folder structure and patterns.
3. Read `docs/DECISIONS.md` for the reasons behind key choices — especially before changing routing, theme, or database structure.
4. Open the relevant design mockup in `design/mockups/<screen>/screen.png` for the visual reference.
5. Read the mockup HTML in `design/mockups/<screen>/code.html` for colour and layout tokens — but do NOT copy HTML/Tailwind to Flutter.

Do not assume anything is implemented. `CURRENT_STATUS.md` is the source of truth.

---

## 2. Follow the Existing Architecture

### Folder Structure (Feature-First)

```
lib/features/<feature>/
  data/         ← Drift tables, repository implementations
  domain/       ← Entities, repository interfaces
  presentation/ ← Screens, feature widgets, Riverpod providers
lib/shared/     ← Shared widgets, enums (used by 2+ features)
lib/core/       ← Services, DB, utilities (infrastructure, no UI)
lib/app/        ← Router, theme, app-level constants
```

### Theme

- All colors: `AppColors.*` (in `lib/app/theme/app_theme.dart`) or `Theme.of(context).colorScheme.*`.
- All shapes: `AppShapes.*`.
- **Never hardcode hex values or `BorderRadius` values in widget files.**
- Access the running theme via `Theme.of(context)`, never instantiate `ThemeData` in widget code.

### Navigation

- Route paths are `AppRoutes.*` constants — never raw strings.
- Navigation: `context.go(AppRoutes.receipts)` to switch tab, `context.push('/receipts/:id')` for detail screens.
- The Add button (index 2 in NavigationBar) pushes `/add` — it does NOT switch branches.

### State Management (when adding)

- Wrap `runApp` with `ProviderScope` before creating any Riverpod providers.
- Use `@riverpod` annotation + `build_runner` for code generation.
- Screens: use `ConsumerWidget` or `ConsumerStatefulWidget`.
- After adding/modifying providers: run `flutter pub run build_runner build --delete-conflicting-outputs`.

### Database (when adding)

- Tables defined in `lib/core/storage/app_database.dart`.
- Run `build_runner` after any schema change.
- All DB access through repository classes — never call Drift DAOs directly from a widget.

---

## 3. Design Reference Priority

When implementing a screen:

1. **Mockup PNG** (`design/mockups/<screen>/screen.png`) — primary visual reference.
2. **Mockup HTML** (`design/mockups/<screen>/code.html`) — color values and layout details.
3. **DESIGN.md** (`design/DESIGN.md`) — brand tokens and component rules.
4. **Component specs** (`design/component-specs/`) — detailed specs in .docx files.

The most current navigation mockup is `my_receipts_home_updated_nav` (5-tab version). The original `my_receipts_home` has an older 3-tab nav — ignore that nav pattern.

> ⚠️ There is a known colour conflict: `AppColors.primary` is `#2563EB` (from prose spec) but mockup HTML uses `#004AC6`. See `docs/DECISIONS.md` D-008 before building real screens.

---

## 4. Step-by-Step Workflow for Every Change

1. **Inspect** — read the relevant docs and source files.
2. **Plan** — outline what files will be created/modified. State any conflicts clearly.
3. **Implement** — follow existing patterns, keep each change focused.
4. **Format** — `dart format <changed files>`.
5. **Analyze** — `flutter analyze`. Fix all issues before claiming success.
6. **Test** — `flutter test`. Fix failures before claiming success.
7. **Document** — update `docs/CURRENT_STATUS.md` to reflect the new state.

**Never claim a step passed unless you actually ran the command and read the output.**

---

## 5. Things to Avoid

- **Do not hardcode colors, padding values, or border radii** outside `app_theme.dart`.
- **Do not use `StatefulWidget` for simple screens** — prefer `StatelessWidget`, `ConsumerWidget`, or `HookConsumerWidget`.
- **Do not add packages without checking `pubspec.yaml` first** — many needed packages are already installed.
- **Do not run `build_runner` unless you have added a `@riverpod` or `@DriftDatabase` annotation** — it is slow and unnecessary otherwise.
- **Do not put feature-specific code in `lib/core/` or `lib/shared/`** — those are for infrastructure and cross-feature utilities.
- **Do not modify files in `design/`** — they are reference assets only.
- **Do not rename anything to "Lumina Ledger"** — that name in `design/DESIGN.md` YAML is a legacy artefact.
- **Do not implement multiple features in one task** — complete one feature fully (analyze passes, tests pass) before starting the next.

---

## 6. Next Task (as of last update)

**Task 1A: Resolve the primary colour conflict** — see `docs/ROADMAP.md` Phase 1.

Before building any real screen, compare `design/mockups/my_receipts_home_updated_nav/screen.png` against both `#2563EB` and `#004AC6` and update `AppColors` in `app_theme.dart` to match the visual reference.

After that: **Task 1B** (Inter font) → **Task 1C** (Drift data model) → **Task 2** (Receipts screen).

---

## 7. Key File Locations

| What | Where |
|------|-------|
| App entry | `lib/main.dart` |
| Theme | `lib/app/theme/app_theme.dart` |
| Router | `lib/app/router/app_router.dart` |
| Shell | `lib/app/router/app_shell.dart` |
| Receipts screen | `lib/features/receipts/presentation/receipts_screen.dart` |
| Warranties screen | `lib/features/warranty/presentation/warranty_screen.dart` |
| Alerts screen | `lib/features/alerts/presentation/alerts_screen.dart` |
| Settings screen | `lib/features/settings/presentation/settings_screen.dart` |
| Add receipt screen | `lib/features/home/presentation/add_receipt_screen.dart` |
| Shared placeholder widget | `lib/shared/widgets/placeholder_screen.dart` |
| Smoke test | `test/widget_test.dart` |
| Design tokens | `design/DESIGN.md` |
| Latest receipts mockup | `design/mockups/my_receipts_home_updated_nav/` |
| Receipt detail mockup | `design/mockups/receipt_details_samsung_mobile/` |
| Warranties mockup | `design/mockups/active_warranties/` |
| Add receipt mockup | `design/mockups/add_receipt/` |
| Alerts mockup | `design/mockups/alerts/` |
| Settings mockup | `design/mockups/settings/` |
