---
name: Culinary Dark Mode System
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#bbcabf'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#86948a'
  outline-variant: '#3c4a42'
  surface-tint: '#4edea3'
  primary: '#4edea3'
  on-primary: '#003824'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#006c49'
  secondary: '#45dfa4'
  on-secondary: '#003825'
  secondary-container: '#00bd85'
  on-secondary-container: '#00452e'
  tertiary: '#f9bd22'
  on-tertiary: '#402d00'
  tertiary-container: '#ce9a00'
  on-tertiary-container: '#4a3500'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#68fcbf'
  secondary-fixed-dim: '#45dfa4'
  on-secondary-fixed: '#002114'
  on-secondary-fixed-variant: '#005137'
  tertiary-fixed: '#ffdf9f'
  tertiary-fixed-dim: '#f9bd22'
  on-tertiary-fixed: '#261a00'
  on-tertiary-fixed-variant: '#5c4300'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Work Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Work Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  coach-dialogue:
    fontFamily: Be Vietnam Pro
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
  nutrition-value:
    fontFamily: Work Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.05em
  nutrition-label:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 12px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 64px
---

## Brand & Style
The design system focuses on a high-performance, health-conscious culinary experience for students. It balances the energy of a professional kitchen with the accessibility of a personal wellness coach. 

The style is **Modern/Minimalist** with a focus on **Tonal Layering**. By utilizing deep charcoal surfaces and vibrant green accents, the UI evokes a "dark mode kitchen" aesthetic—clean, organized, and premium. The emotional response should be one of focused health and effortless meal management.

## Colors
The palette is rooted in a "Forest Charcoal" theme. 
- **Primary (#10b981):** Used for primary actions, success states, and key nutritional highlights.
- **Secondary (#34d399):** A brighter mint used for hover states and active icons to ensure visibility against dark backgrounds.
- **Tertiary (#fbbf24):** A warm amber for "Pro Tips," warnings, or high-calorie highlights.
- **Neutral/Background:** The base uses `#0f172a` (Slate 950) for the deepest background, while cards and containers use `#111827` and `#1f2937` to create depth without relying on pure black, maintaining a soft, sophisticated feel.

## Typography
This design system employs a tri-font strategy to balance authority and friendliness:
- **Plus Jakarta Sans** provides a modern, rounded geometric feel for headlines that remains approachable.
- **Work Sans** ensures high legibility for long-form nutritional data and ingredient lists.
- **Be Vietnam Pro** is reserved for the "Friendly Coach" dialogue and UI labels. The coach style should always be rendered with slightly increased leading and a medium weight to feel conversational.

**Nutritional Labeling:** Use `nutrition-value` for the numbers and `nutrition-label` for the descriptors (e.g., PROTEIN, CARBS). These should be rendered in high-contrast white or primary green against the dark surfaces.

## Layout & Spacing
The layout follows a **Fluid Grid** with a standard 8px stepping system. 
- **Mobile:** 4-column grid with 16px margins. 
- **Desktop:** 12-column grid with 24px gutters and 64px side margins.

Content should be grouped into "Meal Cards" or "Data Clusters" using `md` (16px) padding. Use `xl` (40px) vertical spacing between major sections (e.g., Breakfast vs. Lunch) to provide clear visual breathing room in the dark interface.

## Elevation & Depth
In this dark theme, elevation is defined by **Tonal Tiers** and **Subtle Inner Glows** rather than heavy shadows.
- **Level 0 (Base):** `#0f172a` — The main canvas.
- **Level 1 (Cards):** `#111827` — Slightly lighter to pop from the background.
- **Level 2 (Modals/Popovers):** `#1f2937` — Use a 1px border of `#374151` to define edges.

Shadows should be avoided unless used as a subtle "Green Glow" (`0 4px 20px rgba(16, 185, 129, 0.15)`) for active primary buttons or featured healthy meals.

## Shapes
A **Rounded (0.5rem)** approach is used to maintain a friendly, organic feel appropriate for food. 
- **Standard UI (Buttons/Inputs):** 0.5rem (8px).
- **Meal Cards:** 1rem (16px) for a more substantial, "plate-like" appearance.
- **Nutrition Chips:** Pill-shaped (fully rounded) to differentiate data points from actionable buttons.

## Components
- **Buttons:** Primary buttons use the `#10b981` background with white text. Secondary buttons should be ghost-style with a 1px primary border.
- **Nutrition Labels:** Horizontal "capsule" chips. Use a dark background (`#374151`) with the value in the primary color.
- **Coach Dialogue Box:** A unique component with a subtle gradient border (Primary to Secondary) and `coach-dialogue` typography. Include a small "Chef Avatar" icon to anchor the dialogue.
- **Inputs:** Fields use the `#111827` background with a 1px border. On focus, the border transitions to the primary green with a soft 2px outer glow.
- **Progress Bars (Macro Tracking):** Use a thick 8px track height with rounded caps. The track color should be `#1f2937` and the fill should be the primary green.