---
name: Serene Clinical Haven
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#434655'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#3755c3'
  on-secondary: '#ffffff'
  secondary-container: '#708cfd'
  on-secondary-container: '#00217a'
  tertiary: '#485767'
  on-tertiary: '#ffffff'
  tertiary-container: '#606f80'
  on-tertiary-container: '#e9f2ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#dde1ff'
  secondary-fixed-dim: '#b8c4ff'
  on-secondary-fixed: '#001453'
  on-secondary-fixed-variant: '#173bab'
  tertiary-fixed: '#d5e4f8'
  tertiary-fixed-dim: '#b9c8db'
  on-tertiary-fixed: '#0e1d2b'
  on-tertiary-fixed-variant: '#3a4858'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-md-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1.5rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system embodies a psycho-oncology sanctuary: clinical precision softened by profound emotional warmth. The aesthetic balances medical reliability with empathetic clarity, serving cancer patients and their primary caregivers who frequently navigate cognitive fatigue, emotional vulnerability, and high cognitive loads.

### Visual Aesthetic & Philosophy
The approach marries **Warm Minimalism** with **Subtle Tonal Layering**. Visual clutter, aggressive micro-interactions, and abrasive contrasts are eliminated to prevent sensory overload. Interfaces prioritize breathing room, deliberate spatial pacing, and soft tactile affordances that communicate safety, discretion, and quiet strength.

### Tone of Voice (Indonesian Copy Guidelines)
Copywriting speaks with compassionate authority—calm, non-patronizing, clear, and reassuring:
- **Nada Bicara:** Menenangkan, empatik, terstruktur, dan transparan.
- **Prinsip Utama:** Hindari istilah medis yang menakutkan tanpa penjelasan; gunakan sapaan inklusif dan suportif seperti *"Ruang Teduh Anda"*, *"Mari kita mulai pelan-pelan"*, atau *"Catatan Perasaan Hari Ini"*.

## Colors

The palette leverages restorative blues and supportive neutrals, systematically mapped to convey calm and accessibility:

### Palette Mapping
- **Primary Blue (`#2563EB`):** Main interactive anchor used for primary actions, critical state indicators, and active conversational prompts.
- **Deep Blue (`#1E40AF`):** Foundation for focused states, deep navigation elements, and high-emphasis visual anchors.
- **Soft Blue (`#DBEAFE`):** Interactive accents, progress fills, and conversational bubble backgrounds for external/AI context.
- **Very Light Blue (`#EFF6FF`):** Tonal surface containers, card highlights, and user reflection prompts.
- **Background Tint (`#F8FAFF`):** Base canvas offering softer illumination than clinical stark white.
- **Text Hierarchy:**
  - **Primary Text (`#172033`):** High legibility without the harshness of pure black (`#000000`).
  - **Secondary Text (`#64748B`):** Supportive captions, metadata, and passive instructions.
- **Borders & Dividers (`#E2E8F0`):** Soft structural definition that delineates touch targets without introducing visual noise.

## Typography

Typography relies entirely on **Plus Jakarta Sans**, chosen for its friendly, humanistic geometric balance, rounded counters, and exceptional legibility across varying reading conditions. 

### Typographic Rhythm
- Line heights remain open (`1.4` to `1.6`) to accommodate patient eye fatigue and cognitive pacing.
- Long paragraphs must be avoided; layout templates break therapeutic guidance and AI responses into short, scannable units.
- Numbered tracking values are conservative to ensure optimal contrast against gentle background washes.

## Layout & Spacing

A mobile-first philosophy based on a standard 390px baseline viewport width, scaling progressively to tablet and desktop screens.

### Spatial Architecture
- **Mobile Grid (390px Viewport):** 4-column fluid layout with `12px` gutters and `16px` outer safety margins (`margin-mobile`), ensuring one-handed reachability and thumb-zone safety.
- **Desktop/Tablet Breakpoints:** 
  - Tablet (`768px`): 8-column layout, `16px` gutters, `24px` margins.
  - Desktop (`1024px+`): Single-column conversational central canal (max-width `480px` for conversational contexts, `768px` for reflective dashboards) centered within the screen to preserve intimacy and reduce horizontal saccades.
- **Rhythm:** Spacing follows an 8px grid cadence (`space-sm` = 8px, `space-md` = 16px, `space-lg` = 24px, `space-xl` = 32px), with `space-xs` (4px) reserved exclusively for internal icon-to-label alignment.

## Elevation & Depth

Visual hierarchy uses subtle ambient shadows, translucent surfaces, and low-contrast borders rather than heavy drop shadows, reinforcing a weightless, gentle spatial atmosphere.

### Elevation Levels
- **Ground (Base Canvas):** Flat `#F8FAFF`.
- **Level 1 (Cards, Chat Clusters, List Panels):** Background `#FFFFFF` bordered with solid `1px` `#E2E8F0` and layered over an ambient blue-tinted drop: `0px 4px 16px -2px rgba(37, 99, 235, 0.04)`.
- **Level 2 (Floating Action Trays, Overlays, Active Prompts):** Background `#FFFFFF` with `0px 10px 24px -4px rgba(30, 64, 175, 0.08)` and `1px` `#DBEAFE` border.
- **Level 3 (Modals, Crisis Support Overlays):** Background `#FFFFFF`, ambient drop `0px 20px 32px -8px rgba(23, 32, 51, 0.12)`, supported by a soft frosted backdrop (`rgba(23, 32, 51, 0.25)` with `8px` blur).

## Shapes

The design uses generous, organic curves that feel approachable and calming. Corner radii scale between 16px (`rounded-lg`) and 24px (`rounded-xl`):

- **Interactive Cards & Surface Modules:** `rounded-xl` (24px) to soften rectangular edges completely.
- **Buttons, Action Trays, & Inputs:** `rounded-lg` (16px) for tactile, pill-adjacent touch targets.
- **Tags, Badges, & Mood Selectors:** Fully rounded pill shapes (`9999px`) to emphasize warmth, playfulness, and low pressure.

## Components

### Buttons
- **Primary:** Background `#2563EB`, text `#FFFFFF`, radius `16px`, height `52px` (mobile touch target). States: Active/Hover `#1E40AF`, Disabled `#DBEAFE` with `#64748B` text. Shadow: `0px 4px 12px rgba(37, 99, 235, 0.2)`.
- **Secondary / Soft:** Background `#EFF6FF`, text `#2563EB`, border `1px` `#DBEAFE`, radius `16px`. Active: `#DBEAFE`.
- **Ghost:** Background transparent, text `#64748B`, border none, hover/press text `#172033`.

### Input Fields
- Container height `52px`, background `#FFFFFF`, border `1.5px` `#E2E8F0`, corner radius `16px`, padding `0 16px`.
- Typography: `16px` to prevent automatic zoom on iOS devices.
- Focused state: Border `#2563EB`, ambient ring shadow `0 0 0 3px rgba(37, 99, 235, 0.12)`.
- Helper & Error text: Indonesian validation messages (e.g., *"Mohon tuliskan apa yang Anda rasakan"*), error state uses warm brick `#E11D48` instead of harsh red.

### Conversational Interface (AI Companion)
- **AI Bubble:** Background `#EFF6FF`, border `1px` `#DBEAFE`, text `#172033`, radius `20px 20px 20px 4px`, padding `16px`.
- **Patient/Caregiver Bubble:** Background `#2563EB`, text `#FFFFFF`, radius `20px 20px 4px 20px`, padding `16px`.
- **Quick Emotional Prompts (Chips):** Pill-shaped, background `#FFFFFF`, border `1px` `#DBEAFE`, padding `8px 16px`, text `#2563EB`, font size `14px`.

### Cards & Mood Loggers
- Surface cards use `#FFFFFF`, `1px` solid `#E2E8F0` border, `24px` radius, and `16px` to `20px` internal padding.
- Empathy indicators (e.g., mood checkpoints: *"Tenang"*, *"Cemas"*, *"Lelah"*, *"Berharap"*) use circular or soft-square target zones with subtle hover transitions and `#DBEAFE` background fills when selected.

### Checkboxes & Radios
- Size `22px x 22px`, corner radius `6px` for checkboxes, circular for radios.
- Unchecked: Border `1.5px` `#E2E8F0`, background `#FFFFFF`.
- Checked: Border `#2563EB`, background `#2563EB`, inner check/bullet `#FFFFFF`.

### Specialized Crisis / Escalation Card
- High-visibility yet reassuring card for oncology emergency or acute psychological distress.
- Background: `#FFFFFF`, left accent rail `4px` solid `#2563EB`, border `1px` `#E2E8F0`. Includes instant direct actions: *"Hubungi Tim Medis"* or *"Bicara dengan Konselor"*.