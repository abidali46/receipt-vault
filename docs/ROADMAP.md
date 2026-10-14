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

### Task 1A: Resolve the primary colour conflict (D-008)

Before building any real UI:
1. Open `design/mockups/my_receipts_home_updated_nav/screen.png` and compare visually.
2. Decide whether primary is `#004AC6` or `#2563EB`.
3. Update `AppColors.primary` and the `ColorScheme` in `app_theme.dart` if needed.
4. Run `flutter analyze` to confirm no regressions.

### Task 1B: Add Inter font

1. Add `google_fonts: ^6.x.x` to `pubspec.yaml`.
2. Update `AppTheme._buildTextTheme` to use `GoogleFonts.interTextTheme(...)`.
3. Run `flutter pub get` and `flutter analyze`.

### Task 1C: Define the Receipt data model

1. Create `lib/core/storage/app_database.dart`:
   - `@DriftDatabase` class `AppDatabase`
   - `ReceiptsTable` with columns:
     - `id` — `IntColumn`, auto-increment, primary key
     - `productName` — `TextColumn`
     - `storeName` — `TextColumn`, nullable
     - `category` — `TextColumn`, nullable (Electronics, Food, etc.)
     - `purchaseDate` — `DateTimeColumn`
     - `totalAmount` — `RealColumn` (decimal as double)
     - `warrantyDurationDays` — `IntColumn`, nullable (0 or null = no warranty)
     - `notes` — `TextColumn`, nullable
     - `imagePath` — `TextColumn`, nullable (local file path)
     - `createdAt` — `DateTimeColumn`, auto-set on insert
2. Run `build_runner`:
   ```
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
3. Create `lib/core/storage/database_provider.dart` — Riverpod provider for `AppDatabase`.
4. Wrap `runApp` with `ProviderScope` in `main.dart`.

---

## 🔲 Phase 2 — Receipts Screen (UI Complete, DB Wiring Pending)

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
- [ ] **Task 2A: ReceiptsRepository & Database integration**
  - Wire repository provider → `AsyncValue<List<Receipt>>` to populate `ReceiptCardData` from Drift once Phase 1 is done

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
