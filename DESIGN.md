# NOTtEodo — Master Product Design & Experience Specification (`DESIGN.md`)

> **Design System Name:** Archival Editorial & Obsidian Luxe  
> **Source Project:** NOTtEodo Aesthetic Productivity Suite  
> **Brand Identity:** NOTtEodo — *Notes. Tasks. Life.* (`Curate your everyday.`)  
> **Aesthetic Philosophy:** Swiss Typographic Editorial ("Words on Paper") & High-Contrast Pitch Black OLED Bento Curation  

---

## 1. CORE PRODUCT PHILOSOPHY & FOUNDATIONAL PRINCIPLES

**NOTtEodo** is a completely free, premium personal lifestyle and productivity application that unifies:
$$\text{Notes} + \text{Tasks} + \text{Planner} + \text{Wardrobe} + \text{Expenses} + \text{Expense Splitting} + \text{Shopping} + \text{Habits} + \text{Journal} + \text{Moodboard} + \text{Travel} + \text{Documents}$$

### Fundamental Guarantees
- **100% Free & Unrestricted:** No subscriptions, no premium tier, no advertisements, no paywalls, no artificial credit system.
- **Local-First & Sovereign Privacy:** Data lives on device. Zero external tracking. Encrypted on-device vault backed by hardware keys and cryptographic derivation.
- **The Core Cycle:**
  $$\text{Capture} \longrightarrow \text{Curate} \longrightarrow \text{Plan} \longrightarrow \text{Live} \longrightarrow \text{Remember}$$

---

## 2. BRAND IDENTITY & TYPOGRAPHY RULES

### Brand Name & Typographic Convention
In all brand references (**NOTtEodo**), the lowercase **'t'** and **'e'** are typeset in *italics* (`NOT`*t**e*`odo`) using the primary serif font (**Bodoni Moda**) to emphasize the creative, unconventional nature of the application.

### Font Pairing
```
Editorial / Headline Serif: Bodoni Moda (High stroke contrast luxury serif)
Body & System UI Sans:    DM Sans (Clean geometric sans-serif for scanning legibility)
```

| Type Token | Font Family | Size | Weight | Line Height | Letter Spacing | Applied Elements |
|---|---|---|---|---|---|---|
| `display-lg` | Bodoni Moda | 42px–48px | 600–700 | 1.05–1.1 | `-0.8px` / `-0.02em` | Masthead hero titles & magazine anchors |
| `headline-lg` | Bodoni Moda | 28px–32px | 600 | 1.15–1.2 | Normal | Section headers & editorial titles |
| `headline-md` | Bodoni Moda | 22px | 600 | 1.2 | Normal | Pod titles & subheadings |
| `figure` | Bodoni Moda | 36px | 500 | 1.0 | Normal | Counters, totals & momentum figures |
| `body-lg` | DM Sans | 17.5px–18px | 400 | 1.6 | `0.01em` | Featured note body text & editorial reading |
| `body-md` | DM Sans | 14.5px–16px | 400 | 1.6 | `0.01em` | Standard text, inputs & items |
| `label-sm` | DM Sans | 12.5px | 700 | 1.2 | `1.6px` / `0.08em` | Small caps architectural kickers & section labels |
| `meta` | DM Sans | 14.5px | 400 | 1.4 | Normal | Secondary subtitles, timestamps & gutter annotations |

---

## 3. COLOR SYSTEM & MODULE-SPECIFIC TONAL IDENTITIES

The NOTtEodo palette is anchored in **Archival Warm Ivory** for light mode, **True Pitch Black OLED (`#000000`)** for dark mode, and **Deep Oxblood** as the primary accent.
**Strict Rule:** *Zero Green, Zero Teal, Zero Blue, Zero Neon, Zero Terracotta.*

### 3.1 Core Color Palette

#### Light Mode (Warm Ivory & Obsidian Ink)
| Token Name | Hex Code | Purpose & Usage |
|---|---|---|
| **Background / Canvas** | `#F7F3EE` | Warm Archival Ivory ("paper-like" surface) |
| **Primary (Obsidian Charcoal)** | `#1A1614` / `#1D1C15` | Grounding headers, primary typography, dark iconography |
| **Primary Container** | `#292524` | Warm Stone Obsidian |
| **Secondary (Deep Oxblood)** | `#7A1F2B` | Primary accent, CTA buttons, active state indicators |
| **Secondary Container** | `#B5505E` | Rosewood Oxblood container fill & highlights |
| **Tertiary (Warm Dark Charcoal)** | `#262621` | Dark neutral accents & sub-panels |
| **Surface Dim** | `#E2DDD7` | Muted paper surface |
| **Surface Container** | `#EFE8E1` | Card surface fill base |
| **Surface Container High** | `#E8DFD6` | Elevated card container background |
| **Surface Lowest** | `#FFFFFF` | Pure white inner cards and high-contrast accents |
| **On-Surface Variant** | `#6B605A` / `#424849` | Muted text & secondary timestamps |
| **Outline / Border** | `#EDE6DF` / `#E5DDD0` | Warm parchment hairline border (1px) |
| **Error** | `#BA1A1A` | Subdued error / deletion indicator |

#### Dark Mode (True Pitch Black OLED & Deep Oxblood)
| Token Name | Hex Code | Purpose & Usage |
|---|---|---|
| **Dark Background** | `#000000` | Pure Pitch Black OLED (0-nit power efficiency) |
| **Dark Surface** | `#000000` | True Black card base |
| **Dark Surface High** | `#0A0A0A` / `#0F0D0D` | Ultra-deep obsidian elevated cards |
| **Primary Text** | `#F6F3ED` / `#FFFFFF` | Crisp Linen White primary typography |
| **Secondary / Action Fill** | `#8E2433` | Deep Oxblood buttons, bars, and active fills |
| **Accent Text / Badges** | `#D0485A` | Oxblood Blush for accent text, glowing indicators on black |
| **Secondary Container** | `#2A0E12` / `#2A1F21` | Oxblood-tinted chip & track fill |
| **Muted Text** | `#A89C9C` / `#B3B3B3` | Crisp high-contrast subtext |
| **Dark Border** | `#1E1E1E` / `#221C1D` | Crisp obsidian hairline divider (1px) |

### 3.2 Curated Editorial Accent Spectrum (`EditorialMode.accent`)
For the editorial reading experience, five curated high-contrast pairs are available (minimum 4.5:1 contrast):
1. **Oxblood (Default):** `#7A1F2B` (Light) / `#D0485A` (Dark)
2. **Ink:** `#1C1917` (Light) / `#F6F3ED` (Dark)
3. **Ruby:** `#9B1B30` (Light) / `#E0475C` (Dark)
4. **Plum:** `#7A3B5E` (Light) / `#B86A97` (Dark)
5. **Wine:** `#5C1620` (Light) / `#C86A78` (Dark)

### 3.3 Module Tonal Identities
- **Notes & Documents:** Archival Ivory & Ink (`#F7F3EE` / `#1A1614`)
- **Tasks & Flow:** Deep Oxblood (`#7A1F2B` / `#D0485A`)
- **Planner & Rhythm:** Deep Oxblood (`#7A1F2B` / `#D0485A`)
- **Wardrobe & Studio:** Warm Sand (`#E9E4D9` / `#0A0A0A`)
- **Expenses & Ledger:** Muted Oxblood Clay (`#9B3B47`)
- **Expense Splitter:** Deep Oxblood (`#7A1F2B` / `#8E2433`)
- **Journal & Diary:** Rosewood Oxblood (`#B5505E`)
- **Travel Space:** Antique Warm Bronze (`#9E7B56`)

---

## 4. DUAL VIEW ARCHITECTURE: EDITORIAL VS. CARDS

The application provides two complementary visual paradigms, toggleable globally or via fluid gesture:

### 1. Editorial View ("Words on Paper")
- **Visuals:** Zero cards, zero background boxes, zero drop shadows.
- **Hierarchy:** Purely communicated through typography size, weight, letter spacing, and whitespace.
- **Dividers:** Razor hairlines (`#EDE6DF` light / `#1E1E1E` dark) separate sections and entries.
- **Marginalia / Gutter Callouts:** Timestamps, roman numeral markers (`I`, `II`), and task status ticks are placed cleanly in the left/right margin gutter rather than inside chip badges.

### 2. Cards View ("Architectural Bento")
- **Visuals:** Modular pods with rounded chamfers (14px–24px), subtle obsidian/ivory surface fills, and gentle tactile depth.
- **Complications:** Hero chips, category badges, progress meters, and bento grids.

---

## 5. SIGNATURE MICRO-INTERACTIONS & LUXURY RITUALS

1. **"The Daily Edition" Dynamic Masthead:**
   - Optional living publication header (configurable in Settings, off by default).
   - In Editorial mode: small-caps edition tracking (`NOTTEODO · ISSUE NO. X · VOL. IV`), temporal cadence stamp (`DAWN EDITION` $\rightarrow$ `NOCTURNE EDITION`), and date in italicized Bodoni Moda.
   - In Cards mode: an elevated archival card with an oxblood status dot and collapsible poetic daily summary.
2. **Fluid Pinch-to-Flatten Gesture:**
   - Two-finger pinch inward on Cards mode fluidly melts cards into Editorial mode with crisp haptic detent.
   - Two-finger spread outward on Editorial mode restores tactile Bento Cards.
3. **Oxblood Luminescence Focus Scrubbing:**
   - Deep focus mode dims non-active content to 25% opacity while the active sentence/task breathes with a calm 4-second oxblood luminescence halo (`#2A0E12` / `#D0485A`).
4. **Monogrammed Wax Seal Gestures:**
   - Used for Vault PIN verification and sealing private notes into the encrypted archival vault.
   - Molten wax compression in Deep Oxblood (`#8E2433`) with brass monogram impression and haptic thud.
   - Differentiated: tactile 3D seal in Cards mode; minimalist paper deboss seal in Editorial mode.

---

## 6. GLOBAL NAVIGATION & RADIAL QUICK ADD

- **Translucent Navigation Bar:** High-blur dock with 1px hairline border and zero neon highlights.
- **Radial Quick Add (`+` Button):** Smooth spring-animated fan menu in Deep Oxblood & Linen for instant capture:
  - 📝 Note · ✅ Task · 📅 Event · 💰 Expense · 👕 Wardrobe · 🛒 Shopping · 📔 Journal · 🎙️ Voice
- **Universal Search (`Ctrl + K`):** Instant search across all modules with grouped archival typography results.

---

## 7. MODULE SPECIFICATIONS & ENCRYPTION VAULT

- **Notes & Distraction-Free Editor:** Rich typography, markdown, checklists, inline media, and space grouping.
- **Tasks & Flow:** Morning, Afternoon, Evening, and Later prioritization. Completion fills thin circles with Deep Oxblood (`#7A1F2B`).
- **Planner & Rhythm:** Daily timeline with Breguet-inspired horological clock hands.
- **Wardrobe Studio:** Pinterest-style editorial grid and canvas outfit builder.
- **Expenses & Settlement:** Personal ledger with monthly ceiling and group settlement algorithms.
- **Encrypted Vault:** Zero-knowledge on-device AES-256 encryption using PBKDF2/Argon2 derived keys from the 4-to-6 digit PIN.
