# Receipt Vault

Receipt Vault is a minimalist, privacy-first mobile application designed to store purchase receipts and keep track of product warranties. Built with Flutter, it operates strictly offline-first, storing all data and receipt photos directly on your device with no required accounts, cloud services, or tracking.

---

## What Receipt Vault Does

Receipt Vault gives you digital peace of mind by centralizing your receipts and actively calculating warranty coverage:
- **Receipt Organization**: Capture paper receipts using your camera or import images from your gallery, storing essential metadata like product name, store, category, purchase date, price, and custom notes.
- **Warranty Tracking**: Track coverage periods with standard presets (6 months, 1 year, 2 years, 3 years) or custom day intervals.
- **Dynamic Status Computation**: Automatically computes warranty expiration dates, remaining days, and status (`Active`, `Expiring Soon` within 30 days, `Expired`, or `None`).
- **Discovery & Search**: Find any purchase instantly with multi-field search and 5-way sorting.
- **In-App Alerts**: Review calculated warranty reminders grouped by urgency directly in the app.
- **Data Portability**: Export your receipt catalog anytime to standard CSV (RFC 4180 compliant) for spreadsheets or personal records.

---

## Implemented Features

### 1. Receipts Screen (`/receipts`)
- **Reactive Receipt Feed**: Live stream backed by local Drift SQLite database.
- **Multi-Field Search**: Real-time, case-insensitive search matching product name, store name, and category.
- **Category Filter Chips**: Quick filtering by "All", "Electronics", "Food", "Clothing", "Home", and "Others".
- **5-Way Sorting**:
  - Purchase Date: Newest First (default)
  - Purchase Date: Oldest First
  - Total Amount: High to Low
  - Total Amount: Low to High
  - Product Name: A to Z
- **Dedicated Empty States**: Distinct visual feedback when your vault is empty versus when no receipts match an active search or filter.

### 2. Receipt Details & Management (`/receipts/:id`)
- **Comprehensive Summary**: Product title, category chip, warranty status badge, store, purchase date, total amount, duration, and expiration date.
- **Photo Viewer**: Persistent receipt photo display with thumbnail preview and tap-to-expand full-screen dialog with pan/zoom support.
- **Safe Deletion**: Two-step confirmation dialog with safe image cleanup that never removes photos shared by other records.
- **Edit Navigation**: One-tap transition to pre-populated edit form.

### 3. Add & Edit Flows (`/add`, `/receipts/:id/edit`)
- **Receipt Capture**: Camera capture or gallery selection using `image_picker`, saved to private app storage.
- **Form Validation**: Strict validation for required product name, valid non-negative price, and optional custom warranty durations.
- **Edit Resilience**: Full support for editing existing receipts by record or ID, featuring clear loading states, "Receipt Not Found" screens, and retryable error handling.
- **Unsaved Changes Guard**: Prevents accidental data loss with a discard confirmation dialog when navigating away from modified forms.

### 4. Warranties Screen (`/warranties`)
- **Segmented Filter Tabs**: Filter warranties by `Active`, `Expiring Soon`, and `Expired`.
- **Warranty Count Badges**: Live count indicators on each filter tab.
- **Expiration Countdowns**: Displays humanized remaining days or elapsed expiration time.
- **Direct Navigation**: Tap any warranty card to open the receipt's full details.

### 5. In-App Alerts Screen (`/alerts`)
- **Urgency Grouping**: Categorizes warranties into "Expiring Soon" and "Recently Expired".
- **Deterministic Prioritization**: Sorted by impending expiry date so the most urgent items appear first.
- **"All Clear" State**: Friendly reassurance and direct link back to warranties when no alerts require attention.
- **Complementary to Local Push Notifications**: Provides an in-app visual hub for reviewing expiring warranties, complementing scheduled system notifications.

### 6. Settings & System Notifications (`/settings`)
- **Warranty Notifications Toggle**: Turn scheduled local warranty notifications on or off with system permission handling and graceful denial feedback.
- **Theme Selection**: Seamless switching between System Default, Light, and Dark mode.
- **Local Settings Persistence**: Settings preferences persisted in local storage (`app_settings.json`) across app restarts.
- **RFC 4180 CSV Export**: User-controlled export with proper comma, quote, and newline escaping.
- **Storage Choice**: Save directly to device Downloads or Documents folders, or copy CSV content to the clipboard.
- **Privacy Disclosure**: Transparent privacy notice confirming all data and images remain strictly on the device.

### 7. Scheduled Local Warranty Notifications
- **Background Reminders**: Scheduled reminders sent 30 days and 7 days prior to warranty expiration at 9:00 AM local time, even when the app is closed.
- **Full Lifecycle Synchronization**: Automatically schedules, updates, or cancels reminders when receipts are added, edited, or deleted.
- **Battery-Friendly Scheduling**: Uses inexact alarms (`AndroidScheduleMode.inexactAllowWhileIdle`) on Android to conserve battery while respecting Google Play policies.

---

## Technology Stack & Architecture

- **Framework**: Flutter 3.x / Dart 3.x
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) with `StatefulShellRoute` for independent tab stacks
- **Database & Persistence**: [Drift](https://drift.simonbinder.eu/) (type-safe SQLite abstraction) with `sqlite3_flutter_libs`
- **Local Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) with [timezone](https://pub.dev/packages/timezone) for local time-zone-aware scheduling
- **Media Storage**: Local file system management via `path_provider` and private persistent storage
- **Design System**: Material 3 with tailored light and dark color schemes (`AppTheme`, `AppColors`, `AppTypography`, `AppShapes`)

### Directory Structure

```text
lib/
├── app/                  # Application bootstrap, routing, shell, and theme
│   ├── router/           # GoRouter config, tab shell, and route constants
│   └── theme/            # Material 3 design tokens and theme data
├── core/                 # Shared storage, database, and infrastructure
│   ├── services/         # Settings persistence service
│   └── storage/          # Drift SQLite database and image storage service
├── features/             # Feature-first modular packages
│   ├── alerts/           # In-app computed warranty reminders
│   ├── home/             # Add and edit receipt forms
│   ├── receipts/         # Receipt list, cards, search, filters, details
│   ├── settings/         # Theme toggles, CSV export service and dialogs
│   └── warranty/         # Warranty tracker screen and status grouping
└── shared/               # Shared models, enums, and widgets
```

---

## Prerequisites & Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.12.0` or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / Xcode (with simulators/emulators configured)
- Git

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/abidali46/receipt-vault.git
   cd receipt-vault
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate code (optional / if models change)**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

---

## How to Run the App & Tests

### Running the App
Connect a physical device or start an emulator, then execute:
```bash
flutter run
```

### Running Static Analysis
Verify that all code conforms to strict linting rules:
```bash
flutter analyze
```

### Running the Test Suite
Run the full automated test suite (including database, repository, service, and widget regression tests):
```bash
flutter test
```

### Code Formatting
Ensure all Dart code follows official styling guidelines:
```bash
dart format .
```

---

## Current Limitations & Planned Features

### Current Limitations (v1.0)
- **Local-Only Scheduling**: Reminders are delivered via on-device local notifications; no remote push notification server (APNs/FCM) or account system is used, by design.
- **CSV Metadata Export vs Full Backup**: The export feature outputs structured receipt metadata as an RFC 4180 CSV file suitable for spreadsheets. It does not export receipt image files as a bundled zip archive.
- **Currency**: Amounts are currently represented with standard dollar currency formatting (`$`).
- **Manual Data Entry**: Receipt fields are filled manually; automatic OCR camera parsing is not yet implemented.
- **Local-Only**: Data is stored solely on the current device. There is no cloud sync or multi-device account synchronization.

### Roadmap & Planned Features
- **Phase 8 — OCR Receipt Scanning**: Automatic extraction of store name, purchase date, and total amount using on-device text recognition.
- **Phase 9 — Statistics & Analytics**: Overview dashboards and expense breakdown charts.
- **Multi-Currency Support**: User-configurable currency symbol and formatting via Settings.
- **Full Archive Backup**: Export and import complete zip archives containing both SQLite metadata and attached receipt photos.

---

## License

This project is open-source and available under the terms of the [MIT License](LICENSE).
