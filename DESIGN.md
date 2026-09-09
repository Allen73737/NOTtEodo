# NOTtEodo — Master Product Design & Experience Specification (`DESIGN.md`)

> **Design System Name:** Serene Curation  
> **Source Project:** NOTtEodo Aesthetic Productivity Suite (Stitch Project ID: `17727394288348772398`)  
> **Brand Identity:** NOTtEodo — *Notes. Tasks. Life.* (`Curate your everyday.`)  
> **Aesthetic Philosophy:** Editorial Glassmorphism, Pinterest-Inspired Visual Discovery & Organic Bento Curation

---

## 1. CORE PRODUCT PHILOSOPHY & FOUNDATIONAL PRINCIPLES

**NOTtEodo** is a completely free, premium personal lifestyle and productivity application that unifies:
$$\text{Notes} + \text{Tasks} + \text{Planner} + \text{Wardrobe} + \text{Expenses} + \text{Expense Splitting} + \text{Shopping} + \text{Habits} + \text{Journal} + \text{Moodboard} + \text{Travel} + \text{Documents}$$

### Fundamental Guarantees
- **100% Free & Unrestricted:** No subscriptions, no premium tier, no advertisements, no paywalls, no artificial credit system.
- **Local-First & Optional Contextual AI:** AI is an optional contextual research assistant, not the core identity of the app. The app remains 100% functional offline without AI.
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
| `display-lg` | Bodoni Moda | 48px | 700 | 1.1 | `-0.02em` | Hero section titles & magazine anchors |
| `headline-lg` | Bodoni Moda | 32px | 600 | 1.2 | Normal | Desktop section headers |
| `headline-lg-mobile` | Bodoni Moda | 28px | 600 | 1.2 | Normal | Mobile section headers |
| `body-lg` | DM Sans | 18px | 400 | 1.6 | `0.01em` | Featured note body text |
| `body-md` | DM Sans | 16px | 400 | 1.6 | `0.01em` | Standard text, inputs & items |
| `label-sm` | DM Sans | 12px | 500 | 1.0 | `0.08em` | Uppercase architectural tracking labels |

---

## 3. COLOR SYSTEM & MODULE-SPECIFIC TONAL IDENTITIES

The core palette relies on warm neutrals, deep grounding teals, and soft terracotta highlights. Individual modules feature subtle tonal identities while remaining anchored to the central visual system.

### Core Color Palette

| Token Name | Hex Code | Purpose & Usage |
|---|---|---|
| **Canvas / Background** | `#FEF9EE` | Warm Cream base canvas ("paper-like" surface) |
| **Primary (Midnight Teal)** | `#16282C` | Grounding headers, primary typography, dark iconography |
| **Primary Container** | `#2C3E42` | Deep Slate Teal for primary buttons & active cards |
| **Secondary (Deep Terracotta)** | `#9C432F` / `#D9725B` | Accent highlights, CTA buttons, active state indicators |
| **Secondary Container** | `#FE8F77` | Soft terracotta container fill for featured alerts |
| **Tertiary (Warm Charcoal)** | `#262621` | Dark neutral cards & dark mode accents |
| **Surface Dim** | `#DEDACF` | Sand / Muted shadow surfaces |
| **Surface Container** | `#F3EDE2` | Glassmorphic card surface fill (70%–80% opacity) |
| **Surface Container High** | `#EDE8DD` | Elevated card container background |
| **Surface Container Lowest**| `#FFFFFF` | Pure white inner glows and high-contrast card accents |
| **On-Surface** | `#1D1C15` | Deep charcoal primary text color |
| **On-Surface Variant** | `#424849` | Muted gray secondary text color |
| **Outline / Border** | `#727879` | Standard subtle card outline |
| **Outline Variant** | `#C2C7C9` | Muted divider line color |

### Module Tonal Identity Matrix

| Module | Tonal Accent | Visual Character |
|---|---|---|
| **Notes & Documents** | Cream & Paper Neutrals (`#FEF9EE` / `#F3EDE2`) | Literary, quiet, paper-like tactile feel |
| **Tasks & Flow** | Soft Terracotta Accents (`#D9725B`) | Structured, calm, clear priorities |
| **Planner & Rhythm** | Muted Sage & Leaf Tones (`#7E998A`) | Rhythmic, temporal, schedule harmony |
| **Wardrobe & Studio** | Warm Sand & Fashion Editorial (`#E9E4D9`) | High-fashion editorial, clean studio grid |
| **Expenses & Ledger**| Muted Olive & Earthy Tones (`#6B7A63`) | Sophisticated, analytical personal finance |
| **Expense Splitter** | Warm Amber & Terracotta (`#C88552`) | Social, conversational settlement cards |
| **Journal & Diary** | Dusty Rose & Soft Blush (`#C28E8E`) | Intimate, personal, emotional space |
| **Moodboard** | Image-Led Neutral Canvas (`#1D1C15` overlays) | Visual, Pinterest-inspired masonry |
| **Travel Space** | Sun-Washed Coastal Tones (`#4F7D8C`) | Adventurous, photographic, unified space |
| **Documents / RAG** | Ivory & Slate Archival Tones (`#EDE8DD`) | Academic, structured, citation-focused |

---

## 4. GLOBAL UI PRINCIPLES & COMPOSITION

1. **Editorial Hierarchy:** Large visual title $\rightarrow$ supporting context $\rightarrow$ content $\rightarrow$ actions.
2. **Asymmetry & Dynamic Spacing:**
   - Offset cards, masonry grids, overlapping imagery, and large editorial whitespace.
   - Generous margins (minimum `2rem` outer padding on desktop).
3. **Organic Geometry:**
   - Soft rounded corners (`xl` 24px main pods, `lg` 16px interactive controls).
   - Occasional asymmetrical radii (e.g., `2rem 1.5rem 1.5rem 2rem`) on featured cards.
4. **Pinterest-Inspired Collectible Composition:**
   - Image-first layouts, magazine collages, moodboard tiles, layered cards.

---

## 5. WEIGHTED MOTION SYSTEM

Motion is calm, weighted, and story-driven.

- **Page Entrances:** Staggered sequential entrance (`fade-in` + `slide-up` 12px with 40ms stagger between elements).
- **Tactile Cards:** Subtle scale on hover (`scale(1.02)`), gentle lift with weighted ambient shadow, press feedback (`scale(0.98)`).
- **Navigation & Chapter Transitions:** Morphing cards, cross-fades, shared-element hero transitions (e.g., a wardrobe item thumbnail expands directly into the Wardrobe Detail page).
- **List Rearrangements:** Smooth layout animations when completing tasks, reordering items, or moving between sections.
- **Parallax & Scroll Effects:** Scroll-triggered header compression, subtle image zoom (`scale(1.05)` on hover), and section reveals.

---

## 6. GLOBAL NAVIGATION & RADIAL QUICK ADD

### Translucent Glassmorphic Bottom Bar
Floating, translucent navigation bar with `backdrop-filter: blur(30px)`, elevated ambient shadow, and soft 1px border.

**Primary Destinations:**
1. **Home** (The Curation)
2. **Notes** (The Journal & Documents)
3. **Planner** (The Rhythm & Calendar)
4. **Wardrobe** (The Studio Edit)
5. **More / Life** (Expenses, Shopping, Journal, Moodboard, Travel, Settings)

### Radial Quick Add (`+` Button)
Centrally positioned in the floating navigation bar. Tapping `+` unfolds a spring-animated radial menu:
- 📝 **Note**
- ✅ **Task**
- 📅 **Event**
- 💰 **Expense**
- 👕 **Wardrobe Item**
- 🛒 **Shopping Item**
- 📔 **Journal Entry**
- 🎙️ **Voice Capture**

---

## 7. MODULE-BY-MODULE DETAILED SPECIFICATIONS

### 7.1 Home — "The Curation"
- **Editorial Greeting:** *"Good evening, Allen."* $\cdot$ *Sunday, August 24* $\cdot$ *"Make space for what matters."*
- **Organic Bento Layout:**
  - **Today's Rhythm:** Morning, Afternoon, Evening schedule breakdown.
  - **Active Intentions:** 2–4 high-priority tasks (no overwhelming task dumps).
  - **Today's Outfit:** Visual wardrobe card preview.
  - **Spending Snapshot:** Elegant monthly expense progress bar & category breakdown.
  - **Recent Notes:** Paper-texture note cards with typography previews.
  - **Personal Reflection / Mood:** Quick daily journal prompt widget.

### 7.2 Notes & Documents — "The Journal"
- **Library Layout:** Editorial shelf with cover previews, cover colors, tags, and search.
- **Distraction-Free Editor:** Rich-text support for headings, checklists, tables, quotes, code snippets, images, audio clips, PDFs, and DOCX attachments.
- **Documents & Spaces / Collections:**
  - Ability to create dedicated **Spaces** (e.g., *Computer Networks — Unit 1*, *Goa Trip 2026*, *Final Year Project*).
  - A Space aggregates PDFs, notes, tasks, docx files, and resources into a single visual ecosystem.

### 7.3 Contextual AI & Scoped RAG System
- **Strict Scope Boundaries:** AI is scoped to the active container.
  - **Note AI:** Answers strictly based on the current note.
  - **Space AI / Collection AI:** RAG engine over all PDFs/DOCX files in the Space.
  - **Document AI:** PDF citation assistant (e.g., *"What is TCP congestion control?"* $\rightarrow$ Answer + Citation `OSI_Model.pdf · Page 12`).
- **AI Design Language:** Quiet, non-intrusive ✨ indicators that inherit the host module's color palette (no generic ChatGPT clones or neon gradients).

### 7.4 Tasks — "The Flow" & Task Detail
- **Structure:** Categorized into *Morning*, *Afternoon*, *Evening*, and *Later*.
- **Circles of Intent:** Checkboxes are thin Midnight Teal circles that fill with a soft terracotta wash when checked. Completed tasks drop to 40% opacity (no harsh strikethroughs).
- **Task Workspace Detail:** Progress indicators (e.g., `80%`), subtask list, linked Notes, files, and calendar events.

### 7.5 Planner — "The Rhythm" & Daily Planner
- **Views:** Day, Week, Month, Agenda.
- **Daily Planner View:** Schedule timeline integrated with focus goals, planned outfit preview, spending alerts, and habit check-ins.

### 7.6 Wardrobe & Outfit Studio — "The Studio Edit"
- **Wardrobe Library:** Pinterest-style masonry grid across categories (*Shirts, Pants, Jeans, Shoes, Jackets, Accessories*). Each item tracks photo, brand, color, season, price, and purchase date.
- **Outfit Studio Canvas:** Drag-and-drop builder (*Top $\rightarrow$ Bottom $\rightarrow$ Shoes $\rightarrow$ Accessories*) resulting in a shareable Outfit Card.
- **Outfit Calendar:** Schedule outfits for upcoming dates (*College Casual*, *Formal Meeting*, *Travel*).

### 7.7 Expenses & Expense Splitter — "The Ledger" & "The Settlement"
- **Personal Ledger:** Monthly spend overview, category breakdowns (*Food, Transport, Clothing, Shopping*).
- **Cross-Module Intelligence:** An expense entry for a jacket includes a one-tap option: *"Add to Wardrobe"*.
- **Expense Splitter:** Create groups (*Goa Trip 2026*), add shared expenses with custom/equal splits, and generate simplified settlement paths (*Rahul $\rightarrow$ Allen ₹400*).

### 7.8 Shopping, Journal, Habits & Moodboard
- **Shopping:** Lists with item pricing and one-tap conversion (*Shopping $\rightarrow$ Expense $\rightarrow$ Wardrobe*).
- **Journal:** Intimate diary view with large date headers, photo attachments, voice notes, and mood tags.
- **Habits:** Visual streak trackers using soft colored indicators instead of gamified cartoons.
- **Moodboard:** Pinterest-inspired masonry image gallery for saving visual references, architecture, fashion clips, and color palettes.

### 7.9 Travel Space
- **Unified Space:** Combines itinerary, packing lists, travel wardrobe, trip budget, shared split expenses, notes, tickets/PDFs, and Trip AI assistant in one coastal-themed dashboard.

### 7.10 Universal Search & Command Palette (`Ctrl + K`)
- Instant search across Notes, PDFs, Tasks, Wardrobe, Expenses, Journal, and Trips with grouped visual results.

---

## 8. COMPLETE 76-SCREEN INVENTORY TAXONOMY

The application UI suite encompasses 76 interconnected screens across 10 functional domains:

### Core (1–8)
1. Splash Screen
2. Onboarding Flow
3. Home ("The Curation")
4. Universal Search
5. Radial Quick Add Overlay
6. Notifications Center
7. Profile Space
8. Settings Dashboard

### Notes, Documents & Collections (9–20)
9. Notes Library Home
10. Note Collection View
11. Distraction-Free Note Editor
12. Note Detail View
13. Document Library (PDF/DOCX)
14. PDF Reader & Annotator
15. DOCX Document Reader
16. Document Metadata & Detail
17. Collection / Space Detail (*Computer Networks*)
18. Collection Space AI Chat (*Scoped RAG*)
19. Note AI Assistant
20. Document Citation AI

### Tasks & Projects (21–25)
21. Tasks Home ("The Flow")
22. Task Workspace Detail
23. Project Detail View
24. Subtasks & Checklist Manager
25. Completed Tasks Archive

### Planner & Rhythm (26–31)
26. Day Schedule View
27. Week Rhythm View
28. Month Calendar View
29. Agenda View
30. Event Detail & Location
31. Daily Planning Assistant

### Wardrobe & Outfit Studio (32–39)
32. Wardrobe Home & Catalog
33. Category View (Shirts, Shoes, Pants)
34. Clothing Item Detail
35. Add Clothing Item
36. Outfit Studio Canvas (Drag & Drop)
37. Outfit Card Detail
38. Outfit Calendar Planner
39. Wardrobe Insights & Most Worn

### Expenses & Financial Settlement (40–49)
40. Expense Dashboard ("The Ledger")
41. Add Expense Entry
42. Expense Detail View
43. Budget Allocations
44. Monthly Spending Analytics
45. Expense Categories Manager
46. Expense Splitter Home
47. Split Group View (*Goa Trip*)
48. Add Group Shared Expense
49. Settlement Calculation View

### Shopping (50–53)
50. Shopping Home & Lists
51. Active Shopping List
52. Add Shopping Item
53. Item Detail & Price Comparison

### Life & Reflections (54–59)
54. Journal Home & Timeline
55. Distraction-Free Journal Entry
56. Habit Tracker Dashboard
57. Habit Streak & History Detail
58. Important Dates & Anniversaries
59. Memories & Retrospectives

### Moodboard & Visual Discovery (60–63)
60. Inspiration Gallery (Masonry Grid)
61. Moodboard Collection Detail
62. Add Visual Reference
63. Fullscreen Image Viewer

### Travel Spaces (64–71)
64. Travel Space Home
65. Trip Overview (*Goa 2026*)
66. Trip Itinerary Planner
67. Trip Packing Checklist
68. Trip Budget & Expenses
69. Trip Planned Wardrobe
70. Trip Documents & Tickets
71. Trip AI Assistant

### Privacy & System Controls (72–76)
72. AI Context Scope Settings
73. Privacy & Data Control
74. Local Data Export & Backup
75. Cloud Sync & Device Pair
76. Voice & Speech Settings

---

## 9. ACCESSIBILITY & RESPONSIVE DESIGN

- **Contrast Ratios:** Text meets WCAG AA (4.5:1 minimum for body text, 3:1 for headlines).
- **Touch Targets:** Minimum 48px $\times$ 48px touch targets for all buttons and quick-add actions.
- **Dynamic Type & Motion:** Supports OS text scaling and `prefers-reduced-motion` settings.
- **Desktop Command Palette:** Full keyboard accessibility (`Ctrl + K` palette, `Tab` navigation).
