---
name: Lumina Ledger
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#434655'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#505f76'
  on-secondary: '#ffffff'
  secondary-container: '#d0e1fb'
  on-secondary-container: '#54647a'
  tertiary: '#006242'
  on-tertiary: '#ffffff'
  tertiary-container: '#007d55'
  on-tertiary-container: '#bdffdb'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-max: 1200px
  gutter: 16px
---

## Brand & Style

The design system is centered on the concept of "Digital Peace of Mind." It targets busy professionals and homeowners who require a dependable, clutter-free environment to manage high-value purchases and legal documents. 

The aesthetic is **Minimalist-Modern**, prioritizing clarity and functional density without visual noise. By utilizing expansive whitespace and a restrained color palette, the UI directs focus toward document legibility and status indicators. The goal is to evoke a sense of professional organization and institutional trust, ensuring the user feels their data is secure and easily retrievable.

## Colors

This design system utilizes a high-clarity light mode palette to maintain a clean, "paper-like" digital workspace.

- **Primary (#2563EB):** A confident soft blue used for primary actions, active states, and brand emphasis. It signals utility and reliability.
- **Secondary (#64748B):** A slate blue-gray reserved for secondary information, icons, and supporting text.
- **Tertiary (#10B981):** An emerald green used exclusively for positive status indicators, such as "Active Warranty" or "Verified Receipt."
- **Neutral (#F9FAFB):** The foundation color for the background to reduce eye strain and provide a soft canvas for cards.
- **Accent Red (#EF4444):** Reserved for expiring warranties or critical alerts.

## Typography

The system relies exclusively on **Inter** to leverage its exceptional legibility and systematic feel. 

Typography is utilized to create a clear information hierarchy. **Display** styles are used for dashboard overviews and total value counts. **Headline** styles identify specific receipt items or store names. **Body** styles are optimized for metadata (dates, prices, serial numbers). **Label-caps** are used for metadata headers and small category tags to differentiate them from interactive text.

## Layout & Spacing

The layout follows a **Fixed-Fluid Hybrid** model. On desktop, content is contained within a 1200px centered track. On mobile and tablet, the system transitions to a fluid 4-column and 8-column grid respectively.

- **Rhythm:** A strict 4px/8px baseline grid ensures vertical harmony.
- **Margins:** Standard page margins are 24px on desktop and 16px on mobile.
- **Grouping:** Use 16px (md) spacing between related cards and 32px (xl) between distinct logical sections (e.g., "Expiring Soon" vs "Recent Uploads").

## Elevation & Depth

To maintain a clean and professional look, the design system avoids heavy shadows and instead uses **Tonal Layering** combined with subtle **Ambient Shadows**.

- **Level 0 (Background):** #F9FAFB.
- **Level 1 (Cards):** Pure White (#FFFFFF) with a very soft, diffused shadow (0px 2px 4px rgba(0,0,0,0.05)).
- **Level 2 (Modals/Overlays):** Pure White (#FFFFFF) with a medium-diffused shadow (0px 10px 25px rgba(0,0,0,0.1)).
- **Interactions:** On hover, cards should lift slightly by increasing shadow depth and applying a 1px border stroke of #E2E8F0 to enhance focus.

## Shapes

The shape language is structured yet friendly. 

- **Cards & Input Fields:** Use a consistent 0.5rem (8px) radius to suggest approachability while maintaining a professional, box-organized structure.
- **Interactive Elements:** Buttons and Filter Chips use the **Pill-shaped (Full Round)** style. This distinct contrast between the rectangular structure of the data (cards) and the rounded nature of the actions (buttons) helps users quickly identify interactive zones.

## Components

- **Buttons:** Primary buttons are Solid Blue (#2563EB) with white text and a pill-shaped radius. Secondary buttons use a Subtle Gray ghost style with #475569 text.
- **Receipt Cards:** Use a white background, 8px corner radius, and a 1px #F1F5F9 border. The price should be right-aligned in `headline-md`, and the store name left-aligned.
- **Filter Chips:** Pill-shaped, using #F1F5F9 backgrounds with #475569 text for inactive states. When active, transition to Primary Blue with white text.
- **Input Fields:** 8px radius, white fill, and a 1px #D1D5DB border. On focus, the border transitions to Primary Blue with a 3px soft blue glow.
- **Status Badges:** Small, pill-shaped tags (e.g., "Warranty Active"). Use a low-saturation background of the status color (e.g., Light Green background with Dark Green text).
- **Progress Bars:** Thin 4px bars used to show warranty time remaining. Use a grey track with a Primary Blue or Red (if <30 days) fill.