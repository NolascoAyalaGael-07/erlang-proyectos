---
name: P17 Tactical Grid
colors:
  surface: '#0f131e'
  surface-dim: '#0f131e'
  surface-bright: '#353945'
  surface-container-lowest: '#0a0e19'
  surface-container-low: '#171b27'
  surface-container: '#1b1f2b'
  surface-container-high: '#262a36'
  surface-container-highest: '#313441'
  on-surface: '#dfe2f2'
  on-surface-variant: '#bec8d2'
  inverse-surface: '#dfe2f2'
  inverse-on-surface: '#2c303c'
  outline: '#88929b'
  outline-variant: '#3e4850'
  surface-tint: '#89ceff'
  primary: '#89ceff'
  on-primary: '#00344d'
  primary-container: '#0ea5e9'
  on-primary-container: '#003751'
  inverse-primary: '#006591'
  secondary: '#ffb2b7'
  on-secondary: '#67001b'
  secondary-container: '#b50036'
  on-secondary-container: '#ffc2c4'
  tertiary: '#4cd7f6'
  on-tertiary: '#003640'
  tertiary-container: '#00aac6'
  on-tertiary-container: '#003943'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#c9e6ff'
  primary-fixed-dim: '#89ceff'
  on-primary-fixed: '#001e2f'
  on-primary-fixed-variant: '#004c6e'
  secondary-fixed: '#ffdadb'
  secondary-fixed-dim: '#ffb2b7'
  on-secondary-fixed: '#40000d'
  on-secondary-fixed-variant: '#92002a'
  tertiary-fixed: '#acedff'
  tertiary-fixed-dim: '#4cd7f6'
  on-tertiary-fixed: '#001f26'
  on-tertiary-fixed-variant: '#004e5c'
  background: '#0f131e'
  on-background: '#dfe2f2'
  surface-variant: '#313441'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
  display-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  title-md:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Space Grotesk
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  cell-indicator:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 18px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-lg: 1.5rem
  margin: 1rem
  margin-md: 1.5rem
  margin-lg: 2.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The brand personality is competitive, sleek, and high-tech, engineered specifically for real-time multiplayer board gaming. It merges the focused precision of competitive esports interfaces with tactical minimalism: no visual clutter, immediate readability, and vivid visual feedback for turn-based combat.

Target audiences include casual to competitive players seeking low-friction, high-engagement multiplayer sessions across mobile and desktop interfaces. The visual language conveys tactical tension and modern digital craftsmanship.

The design movement combines **Minimalism** with **Modern Tactile Gaming accents**: deep, dark space surfaces paired with luminous, neon-charged tokens that stand out like projected light arrays. Atmospheric depth is generated through low-contrast midnight surfaces, crisp structural dividers, and targeted glow treatments for active interactive states.

## Colors

The color architecture is built strictly on an OLED-friendly dark palette designed to reduce eye strain and maximize game state differentiation:

- **Surface Base (`#0b0f1a`)**: The deep midnight canvas providing maximum visual contrast for vibrant game elements.
- **Card & Container (`#192338`)**: Elevated functional panels and boards, paired with precise boundary borders (`#263554`).
- **Primary Action (`#0ea5e9` base, `#38bdf8` hover/active)**: Vivid electric cyan reserved for primary CTA buttons, matchmaking states, and system notifications.
- **Ficha X / Jugador 1 (`#f43f5e`)**: Neon crimson/coral communicating decisive attack, speed, and player 1 sovereignty.
- **Ficha O / Jugador 2 (`#06b6d4`)**: High-luminance neon cyan/teal providing an unmistakable chromatic counterpart for player 2.
- **Muted Cell / Guide (`#64748b`)**: Subtle slate used exclusively for unselected cell coordinate indicators (1–9), secondary micro-copy, and inactive dividers.
- **Feedback & State Indicators**:
  - Success / Match Victory: `#10b981` (Emerald).
  - Warning / Turn Timeout: `#f59e0b` (Amber).
  - Disconnected / Neutral Draw: `#94a3b8` (Muted silver).

## Typography

Typography reinforces the technical, game-engine discipline:

- **Space Grotesk** governs all match banners, numerical displays, player badges, scoreboards, and CTA labels. Its geometric precision and mechanical inflections project an unmistakable tactical identity.
- **Manrope** anchors informational content, match history logs, chat bubbles, settings, and player profiles. It provides balanced humanist clarity against dark backgrounds without visual fatigue.
- Cell indicators (1–9) leverage tabular figures within `Space Grotesk` to center precisely within unplayed grid tiles.

## Layout & Spacing

The layout is built around a centralized, game-first viewport utilizing a structured 12-column fluid grid for desktop and tablet, collapsing to a single-column structured stack on mobile:

- **Desktop (>= 1024px)**: Centralized 3x3 battle arena (locked to a max width of 520px) flanked by player status pods, server telemetry, and round statistics. Side gutters maintain a steady `gutter-lg` (1.5rem) rhythm.
- **Tablet (768px – 1023px)**: Stacked format where player status header sits directly above the game arena, with action consoles and game-chat anchored below with a `1.5rem` outer canvas margin.
- **Mobile (< 768px)**: Edge-to-edge compact layout with `1rem` outer canvas padding. The 3x3 grid remains square using aspect-ratio constraints (`1:1`), maintaining minimum touch targets of 48px per cell.

Spacing follows strict 4px/8px multiples. Grid gaps inside the 3x3 playfield use `space-sm` (0.5rem) to maintain distinct separation without breaking board cohesion.

## Elevation & Depth

Visual hierarchy does not use murky drop-shadows. Instead, elevation is communicated through **Tonal Layering**, **Crisp Outlines**, and **Color Luminance**:

- **Canvas Ground (Level 0)**: Pure midnight navy `#0b0f1a`. Uninteractive, absorbing background.
- **Card / Deck Surface (Level 1)**: Tone `#192338` edged with a 1px boundary of `#263554`. This houses player profile cards, matchmaking queues, and stats drawers.
- **Active Interactive Surface (Level 2)**: Game board tiles and buttons sit on `#1f2d48`. Hover states elevate with an ambient inner stroke highlight (`#38bdf8` at 20% opacity) and a micro-glow (`box-shadow: 0 0 16px rgba(14, 165, 233, 0.15)`).
- **Player State Glow (Focus Tier)**:
  - When Player 1 (X) controls the turn, their panel and active cell targets emit a directional crimson halo (`0 0 20px rgba(244, 63, 94, 0.25)`).
  - When Player 2 (O) controls the turn, their panel emits a cyan halo (`0 0 20px rgba(6, 182, 212, 0.25)`).
- **Modals & Overlays**: `#192338` elevated above a backdrop-filter blur (`8px`) with a high-contrast `#38bdf8` accent outline.

## Shapes

The design system embraces a **Rounded (`2`)** shape profile:
- Primary buttons, text inputs, and individual 3x3 grid cells apply a consistent `0.5rem` (8px) corner radius.
- Cards, board frames, and panel dialogs employ `rounded-lg` (1rem / 16px) for an armored yet modern technological aesthetic.
- Status badges, micro-chips, and player turn avatars leverage `rounded-xl` (1.5rem) or full pills to distinguish categorical metadata from interactive structural panels.

## Components

### 1. Game Grid (3x3 Tres en Raya)
- **Cell Container**: Square aspect ratio (`1:1`), background `#192338`, border `1px solid #263554`, border-radius `0.5rem`.
- **Empty State**: Centered number (1–9) rendered in `Space Grotesk` 18px font in `#64748b` at 60% opacity. Hovering over an empty cell reveals a faint ghost preview of the active player's glyph (X or O) at 30% opacity.
- **Occupied State (X)**: Neon crimson `#f43f5e` vector glyph with subtle self-glow (`filter: drop-shadow(0 0 8px rgba(244, 63, 94, 0.6))`).
- **Occupied State (O)**: Neon cyan `#06b6d4` vector glyph with matching teal glow (`filter: drop-shadow(0 0 8px rgba(6, 182, 212, 0.6))`).
- **Winning Line**: A continuous neon streak connecting the 3 winning tiles with a pulse animation lasting 1.2s.

### 2. Buttons
- **Primary Action (Start, Rematch, Play)**: Background `#0ea5e9`, text `#0b0f1a` (bold Space Grotesk), `rounded-md` (0.5rem). Hover state shifts background to `#38bdf8` with `box-shadow: 0 0 18px rgba(14, 165, 233, 0.45)`. Focus ring uses `#38bdf8` with a 2px offset.
- **Secondary / Ghost (Surrender, Settings)**: Background transparent, border `1px solid #263554`, text `#94a3b8`. Hover shifts border to `#38bdf8` and text to `#ffffff`.
- **Icon Buttons**: 40x40px or 48x48px hit areas with centered glyphs, matching secondary button borders.

### 3. Status Indicators & Player Badges
- **Active Turn Tracker**: Card frame with an animated bottom border line corresponding to the current player's color (`#f43f5e` or `#06b6d4`).
- **Connection Dot**: 8px circular indicator with green (`#10b981`) for stable ping (<60ms), amber (`#f59e0b`) for unstable ping, and red (`#f43f5e`) for disconnected. Accompanied by numeric latency text in `#64748b`.
- **Turn Timer**: Crisp circular or linear progress bar that transitions from `#0ea5e9` to `#f43f5e` when remaining turn time drops under 5 seconds.

### 4. Chips & Match Tags
- Compact pills with padding `4px 10px`, background `#192338`, border `1px solid #263554`.
- Text styled in `label-md` Space Grotesk in `#94a3b8`. Used for match formats (`Ranked 1v1`, `Casual`, `Round 3/5`).

### 5. Input Fields (Lobby Code / Nickname)
- Container background `#0b0f1a`, border `1px solid #263554`, text `#f8fafc`, placeholder text `#64748b`.
- On focus: border shifts to `#0ea5e9`, with an outer focus glow `0 0 0 3px rgba(14, 165, 233, 0.2)`.

### 6. Cards & Containers
- Master board enclosure and player stat containers use background `#192338`, border `1px solid #263554`, and radius `rounded-lg` (1rem).
- Headers within cards are punctuated by a subtle separator line (`#263554`) with `space-md` internal padding.