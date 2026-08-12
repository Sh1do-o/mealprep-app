---
name: DormDish
colors:
  surface: '#f4fbf4'
  surface-dim: '#d4dcd5'
  surface-bright: '#f4fbf4'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eef6ee'
  surface-container: '#e8f0e9'
  surface-container-high: '#e3eae3'
  surface-container-highest: '#dde4dd'
  on-surface: '#161d19'
  on-surface-variant: '#3c4a42'
  inverse-surface: '#2b322d'
  inverse-on-surface: '#ebf3eb'
  outline: '#6c7a71'
  outline-variant: '#bbcabf'
  surface-tint: '#006c49'
  primary: '#006c49'
  on-primary: '#ffffff'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#4edea3'
  secondary: '#9d4300'
  on-secondary: '#ffffff'
  secondary-container: '#fd761a'
  on-secondary-container: '#5c2400'
  tertiary: '#a43a3a'
  on-tertiary: '#ffffff'
  tertiary-container: '#fc7c78'
  on-tertiary-container: '#711419'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#ffdbca'
  secondary-fixed-dim: '#ffb690'
  on-secondary-fixed: '#341100'
  on-secondary-fixed-variant: '#783200'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3af'
  on-tertiary-fixed: '#410005'
  on-tertiary-fixed-variant: '#842225'
  background: '#f4fbf4'
  on-background: '#161d19'
  surface-variant: '#dde4dd'
  leaf-green: '#059669'
  yolk-orange: '#FB923C'
  price-tag-yellow: '#FDE047'
  surface-muted: '#F8FAFC'
  border-low: '#E2E8F0'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  price-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  container-margin: 16px
  gutter: 12px
  component-gap: 8px
  section-gap: 24px
---

## Brand & Style

The brand identity is built on the concept of "Culinary Optimism." It recognizes the very real constraints of student life—limited space, money, and time—and responds not with austerity, but with vibrant energy. The design style is a blend of **Modern / Corporate** reliability (to build trust in budget calculations) and **Tactile** warmth (to make cooking feel accessible and homey).

The personality is:
- **Approachable:** No complex jargon; instructions are like a text from a friend.
- **Budget-Friendly:** High-value visuals that don't feel "cheap," but prioritize smart spending.
- **Energetic:** Driven by high-contrast accents and fluid motion to keep up with a busy student schedule.

We use generous white space to prevent the UI from feeling cluttered on small mobile screens, ensuring that the "poverty-meal" ingredients feel like part of a curated, healthy lifestyle.

## Colors

The palette is rooted in a "Fresh & Fire" narrative. 
- **Primary (Vibrant Green):** Represents freshness and health. Used for primary actions, success states, and the "What Can I Cook" engine.
- **Secondary (Warm Orange):** Evokes heat, cooking, and appetite. Used for sliders, budget alerts, and highlighting equipment requirements.
- **Neutral:** A clean, cool-gray base (`#F8FAFC`) keeps the app feeling organized and modern, ensuring the vibrant brand colors don't overwhelm the user during high-utility tasks like grocery shopping.
- **Price Tag Yellow:** Specifically reserved for "Palengke Price" updates and budget-saving tips to draw the eye immediately to financial value.

## Typography

Typography is optimized for the "on-the-go" student. 
- **Plus Jakarta Sans** is used for headlines to provide a friendly, rounded, and welcoming feel. Its high x-height ensures excellent legibility even when bolded.
- **Be Vietnam Pro** handles the body text and labels. It was chosen for its contemporary, clean aesthetic that feels native to mobile-first apps.
- **Scale:** On mobile, we avoid massive displays to maximize content density. Use `headline-lg-mobile` for page titles and `price-display` for all monetary values to ensure they stand out as critical data points.

## Layout & Spacing

This is a **fluid-grid** system designed specifically for narrow viewports (360px - 420px). 

- **The 8pt Rhythm:** All spacing is a multiple of 4px, but primary components use 8px and 16px increments to create a clear vertical rhythm.
- **Margins:** A consistent 16px side margin ensures content doesn't hit the edge of the device frame.
- **Density:** Because students often have long lists (ingredients, recipes), we use a "Compact-Comfortable" hybrid. Cards use 12px internal padding to maximize screen real estate while maintaining touch-target safety.
- **Transitions:** Layouts should reflow vertically; side-scrolling (carousels) is reserved specifically for "Suggested Recipes" to keep the main navigation flow strictly vertical.

## Elevation & Depth

To maintain a "budget-friendly" and "approachable" feel, the design system avoids heavy shadows or complex skeuomorphism. Instead, it uses **Tonal Layers** and **Low-Contrast Outlines**:

- **Surface Levels:** The background is the lowest level (`#F8FAFC`). Cards and containers sit on top in pure white (`#FFFFFF`).
- **Depth through Borders:** Instead of shadows, use 1px solid borders in `#E2E8F0` for most cards. 
- **Active Elevation:** When a card is "selected" (e.g., picking a meal for the plan), use a soft, tinted shadow (Primary color at 10% opacity) rather than a gray shadow to maintain the energetic brand feel.
- **Floating Actions:** The "What Can I Cook" button uses a distinct elevation with a 12% opacity primary-colored shadow to signify its status as the core app action.

## Shapes

The shape language is **Rounded**, reflecting the "Soft & Welcoming" brand pillar. 
- **Standard Elements:** Buttons, input fields, and cards use a 0.5rem (8px) corner radius.
- **Interactive Chips:** Ingredient tags and equipment chips use a **Pill-shaped** (100px) radius to make them look "tappable" and distinct from static content cards.
- **Image Treatment:** Recipe thumbnails should always have a 12px radius to avoid the "sharp" feel of industrial food apps.

## Components

### Buttons & Toggles
- **Primary Button:** Filled with `primary_color_hex`, white text, 8px radius. High-energy and prominent.
- **Equipment Chips:** Outline-style when unselected, solid primary color with a check icon when active. 
- **Quick Toggles:** Used for dietary restrictions. Use a "Switch" pattern with the `leaf-green` color for the 'on' state.

### Sliders
- **Budget Slider:** Uses the `secondary_color_hex` for the track and handle. The handle should be large (24px x 24px) to ensure easy thumb-sliding on mobile.

### Cards
- **Meal Suggestion Card:** A white surface with a 1px border. The top half is a recipe image; the bottom half contains the title, a "time-to-cook" badge (using `surface-muted`), and a "missing ingredients" warning in `brand-red` if applicable.
- **Inventory Card:** Compact rows with a "use by" indicator light (green/yellow/red dots).

### Input Fields
- **Ingredient Search:** A soft-gray filled bar with a magnifying glass icon. No border unless focused; upon focus, use a 2px `primary_color_hex` border.

### List Items
- **Shopping List:** Interactive rows with a custom checkbox. Tapping the row triggers a striethrough and dims the text to 50% opacity.