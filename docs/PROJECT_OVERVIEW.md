# Receipt Vault – Project Overview

## What Is This App?

**Receipt Vault** is a Flutter mobile application for Android and iOS that lets users:

1. **Capture and store purchase receipts** — by photographing a paper receipt, importing an image from the gallery, or entering details manually.
2. **Track product warranties** — by linking warranty durations to receipts and computing expiry dates automatically.
3. **Receive warranty alerts** — proactive notifications before warranties expire.
4. **Browse and search receipts** — with category filtering, search, and status badges.

The design philosophy is described in `design/DESIGN.md` as **"Digital Peace of Mind"** — a minimalist-modern aesthetic targeting busy professionals who need a reliable, clutter-free way to manage high-value purchases.

## Project Name Discrepancy

> ⚠️ **Note:** `design/DESIGN.md` calls the app "Lumina Ledger" in its YAML front-matter but describes "Receipt Vault" throughout the prose. The Flutter package name is `receipt_vault`. All code uses "Receipt Vault". Treat "Lumina Ledger" as a legacy draft artefact — do NOT rename files or the package to match it.

## Goals

- Simple, intuitive UX for non-technical users.
- Fully offline-first — all data stored locally with Drift (SQLite).
- Light and dark mode support from launch.
- No authentication, cloud sync, or account system in the initial version.

## Target Platforms

- **Primary:** Android, iOS
- **Secondary (low priority):** The Flutter project includes Windows, macOS, Linux, and Web platform scaffolding — these exist by default and are not targeted for development.

## Key Features Planned

| # | Feature | Status |
|---|---------|--------|
| 1 | Bottom navigation shell (5 tabs) | ✅ Implemented |
| 2 | App theme (Material 3, light/dark) | ✅ Implemented |
| 3 | go_router navigation with StatefulShellRoute | ✅ Implemented |
| 4 | Receipts screen (real UI) | ⬜ Not started |
| 5 | Receipt data model (Drift) | ⬜ Not started |
| 6 | Receipt creation / capture flow | ⬜ Not started |
| 7 | Receipt detail screen | ⬜ Not started |
| 8 | Warranty tracker screen | ⬜ Not started |
| 9 | Alerts / notifications screen | ⬜ Not started |
| 10 | Settings screen | ⬜ Not started |
| 11 | Local push notifications | ⬜ Not started |
| 12 | OCR receipt scanning | ⬜ Not started |

## Design References

All design assets live in the `design/` directory at the project root. **Do not move or duplicate them.**

```
design/
├── DESIGN.md                          ← Design tokens, colour palette, typography, components
├── component-specs/
│   ├── all components of the app.docx ← Component-level specifications
│   └── Receipt keeper full details.docx ← Full product requirements / detailed spec
└── mockups/
    ├── my_receipts_home/              ← Receipts list screen (original nav: 3 tabs)
    ├── my_receipts_home_updated_nav/  ← Receipts list screen (UPDATED nav: 5 tabs) ← USE THIS
    ├── receipt_details_samsung_mobile/← Receipt detail / warranty progress screen
    ├── active_warranties/             ← Warranties tab screen
    ├── add_receipt/                   ← Add receipt form screen
    ├── alerts/                        ← Alerts / notifications screen
    └── settings/                      ← Settings screen
```

Each mockup directory contains:
- `screen.png` — Visual reference image
- `code.html` — Reference HTML/Tailwind implementation (for visual and colour reference only — do NOT copy HTML/Tailwind to Flutter)
