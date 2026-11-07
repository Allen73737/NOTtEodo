<div align="center">

<!-- LIVE HERO APP SHOWCASE -->
<a href="https://github.com/Allen73737/NOTtEodo">
  <img src="assets/animations/hero_app_showcase.svg" alt="Notteodo Live Bento Interface" width="100%" />
</a>

<br/><br/>

# Notteodo

### *Notes · Tasks · Habits · Expenses · Wardrobe · Moodboards*
#### **The Aesthetic Personal Sanctuary & Life Dashboard**

<p align="center">
  <em>One beautiful, distraction-free space for your thoughts, daily routines, personal spending, and aesthetic inspiration.</em>
</p>

<!-- DYNAMIC BRAND SHIELDS (ZERO BLUE / ZERO TEAL) -->
<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.24.5-000000?style=for-the-badge&logo=flutter&logoColor=D4AF37" alt="Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.5.4-000000?style=for-the-badge&logo=dart&logoColor=E8927C" alt="Dart" /></a>
  <a href="#-the-notteodo-palette"><img src="https://img.shields.io/badge/Canvas-Warm_Cream_%23FEF9EE-FEF9EE?style=for-the-badge&labelColor=000000&logoColor=D4AF37" alt="Warm Cream" /></a>
  <a href="#-the-notteodo-palette"><img src="https://img.shields.io/badge/OLED_Dark-Obsidian_%23000000-000000?style=for-the-badge&logoColor=D4AF37" alt="Obsidian Dark" /></a>
  <a href="#-duolingo-style-animated-notifications"><img src="https://img.shields.io/badge/Notifications-Duolingo_Style-D9725B?style=for-the-badge&logoColor=FEF9EE" alt="Duolingo Notifications" /></a>
  <a href="#-aesthetic-pinterest-homescreen-widgets"><img src="https://img.shields.io/badge/Widgets-Pinterest_Aesthetic-D9725B?style=for-the-badge&logo=pinterest&logoColor=FEF9EE" alt="Pinterest Widgets" /></a>
  <a href="https://github.com/Allen73737/NOTtEodo/actions"><img src="https://img.shields.io/badge/Tests-129%20Passing%20(100%25)-000000?style=for-the-badge&logo=githubactions&logoColor=7E998A" alt="Tests" /></a>
  <a href="#-license"><img src="https://img.shields.io/badge/License-MIT-000000?style=for-the-badge&logo=open-source-initiative&logoColor=FEF9EE" alt="MIT" /></a>
</p>

<!-- REAL-TIME HIGHLIGHTS TICKER -->
<p align="center">
  <code>✦ 100% LOCAL-FIRST</code> &nbsp;•&nbsp;
  <code>🔥 DUOLINGO NOTIFICATIONS</code> &nbsp;•&nbsp;
  <code>🦉 NODO AI COMPANION</code> &nbsp;•&nbsp;
  <code>📌 PINTEREST WIDGETS</code> &nbsp;•&nbsp;
  <code>🔒 ZERO SUBSCRIPTIONS</code> &nbsp;•&nbsp;
  <code>☕ WARM CREAM &amp; OLED OBSIDIAN</code>
</p>

<br/>

[Overview & Abstract](#-about-notteodo) •
[Why Notteodo?](#-why-notteodo) •
[Duolingo-Style Notifications](#-duolingo-style-animated-notifications) •
[Nodo AI Companion](#-nodo-ai-companion--personality) •
[Pinterest Homescreen Widgets](#-aesthetic-pinterest-homescreen-widgets) •
[Core Life Modules](#-core-life-modules) •
[Help, Privacy & Settings](#-help-privacy--settings-subpages) •
[Admin Dashboard & Controls](#-built-in-admin-dashboard) •
[The Color Palette](#-the-notteodo-palette) •
[Quickstart Runbook](#-quickstart-guide) •
[License](#-license)

<br/>

<img src="assets/animations/gold_divider.svg" width="100%" alt="Gold Divider" />

</div>

<br/>

## 📖 About Notteodo

> *"Make space for what matters."*

**Notteodo** is a free, beautifully crafted personal life dashboard built with Flutter. It unifies your notes, daily to-dos, habit streaks, personal finances, wardrobe curation, and Pinterest-style visual moodboards into one fast, private, distraction-free app.

Whether you're jotting down quick ideas, organizing your week, splitting dinner expenses with friends, planning your seasonal outfits, or checking your daily goals right from your phone's home screen, Notteodo makes everyday organization feel calm, tactile, and rewarding.

---

<br/>

## 💡 Why Notteodo?

Modern productivity apps have become cluttered, bloated, and full of monthly paywalls:

| The Old Way | The Notteodo Way |
| :--- | :--- |
| **5 to 10 disconnected apps** (one for notes, one for to-dos, another for budgeting, another for habits) | **One cohesive, beautiful dashboard** where all your daily routines live together seamlessly |
| **Pricy monthly subscriptions** leasing your own thoughts and lists back to you | **100% Free & Open Source** forever — no paywalls, no tiers, no locked features |
| **Cloud surveillance & trackers** scanning your personal entries for targeted ads | **Offline-first privacy** — your data lives safely on your device with military-grade AES-256 GCM encryption |
| **Sterile corporate grey grids** and overwhelming dopamine notifications | **Pinterest & Watchmaker aesthetic** with warm paper cream, pure OLED pitch black, Breguet focus dials, and warm terracotta accents |

---

<br/>

<div align="center">
<img src="assets/animations/gold_divider.svg" width="100%" alt="Gold Divider" />
</div>

<br/>

## 🔔 Duolingo-Style Animated Notifications

Notteodo reimagines productivity notifications with playful, visually addictive, Duolingo-style graphics that keep you engaged and protect your daily momentum:

<div align="center">

| Component | Visual & Interactive Character | Technical Implementation |
| :--- | :--- | :--- |
| **🔥 Native Dynamic Mascot** | 128×128 circular canvas badge with warm terracotta/gold radial gradient, executive gold rim, and emoji mascot (`🔥` for streak, `🦉` for Nodo) | Android native `createMascotLargeIcon()` in `NotificationReceiver.kt` |
| **⚡ 1-Tap Shade Actions** | Direct action buttons inside the Android shade: `"🔥 Check In"` to save daily streak or `"⚡ Focus 25m"` to launch Pomodoro timer | Intent extras dispatched directly into Flutter via MethodChannels |
| **🦉 In-App Floating HUD** | Tactile floating banner with animated breathing aura glow, bobbing mascot avatar (`🔥`, `🦉`, `⚡`, `🛡️`), and spring bounce entrance (`Curves.easeOutBack`) | Custom `SanctuaryAnimatedNotificationCard` with `TickerProviderStateMixin` |
| **⏳ Depleting Progress Line** | Smooth dual-gradient progress countdown bar running along the bottom border showing exact remaining notification lifetime | Reactive `AnimationController` binding (`widget.lifeController`) |
| **⏰ 3-Hour OS Exact Cadence** | Android `AlarmManager` wakeups triggering thoughtful reflection prompts, witty reality checks, and streak shields even if the app is closed | Android `AlarmManager.AlarmClockInfo` with automatic re-scheduling |

</div>

---

<br/>

<div align="center">
<img src="assets/animations/gold_divider.svg" width="100%" alt="Gold Divider" />
</div>

<br/>

## 🦉 Nodo AI Companion & Personality

Notteodo features **Nodo**, an empathetic, on-device AI companion designed to feel like a thoughtful partner rather than a sterile chatbot:

- **Context-Aware Memory:** Automatically synchronizes with your profile display name, bio motto, active habit streaks, and pending tasks so every response feels personal.
- **Dual Companion Modes:**
  - 🌟 **"Inspire Me":** Philosophical, calming maxims designed to re-center your attention and ground your daily intentions.
  - 🔥 **"Roast My Focus":** Witty, affectionate, tough-love reality checks that push you to stop over-planning and conquer your top open priority right now.
- **Autonomous Note-to-Workflow:** Intelligently extracts actionable tasks and financial disbursements from unstructured notes.
- **Weekly Executive Dossier:** Synthesizes cross-module velocity into a clean executive summary every week.

---

<br/>

<div align="center">
<img src="assets/animations/gold_divider.svg" width="100%" alt="Gold Divider" />
</div>

<br/>

## 📌 Aesthetic Pinterest Homescreen Widgets

Bring the cozy, aesthetic vibe of Notteodo directly onto your phone's home screen. With our built-in **Interactive Widget Studio**, you can preview, customize, and pin 8 distinctive home screen widgets on Android and iOS:

<div align="center">

| Widget Type | What it Shows | Aesthetic Details |
| :--- | :--- | :--- |
| 📝 **Sticky Note & Memo** | Latest thought, pinned note excerpt, or quote | Textured paper card, serrated washi tape strip, editorial Bodoni title |
| ✅ **Daily Ritual Checklist** | Top tasks due today + habit streak progress | Checkbox progress counter (`4/5 DONE`), strikethrough typography |
| 🖼️ **Polaroid Inspiration Pin** | Highlighted image from your moodboards | Authentic Polaroid white photo border with handwritten italic caption |
| 👗 **Outfit of the Day** | Current season look, silhouettes, and fabric swatches | Clean editorial layout, temperature indicator, and palette dots |
| 💰 **Treasury & Budget Meter** | Monthly spend pacing and today's outflows | Minimal cash meter, currency symbol, and burn rate progress bar |
| 🎙️ **Voice Note Memo** | Quick voice note title, audio waveform, and duration | Retro cassette tape reels with red recording indicator |
| ✈️ **Travel Boarding Pass** | Next trip destination and departure countdown | Perforated airline ticket border with airport code route (`CDG ✈ HND`) |
| ⏱️ **Focus Clock & Quote** | Live system time + rotating daily reflection prompt | Classic horological dial with clean typography |

</div>

> [!TIP]
> Open the in-app **Widget Studio** anytime from **Settings $\rightarrow$ Homescreen Widget Studio** to preview paper styles, choose washi tape colors, and instantly test how each widget looks on your home screen.

---

<br/>

<div align="center">
<img src="assets/animations/gold_divider.svg" width="100%" alt="Gold Divider" />
</div>

<br/>

## 🌌 Core Life Modules

Notteodo is organized into cohesive spaces so you can navigate your day effortlessly:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                NOTTEODO DASHBOARD                               │
├─────────────────────┬─────────────────────┬─────────────────────┬───────────────┤
│  01. HOME BENTO     │  02. SMART NOTES    │  03. TASKS & HABITS │  04. EXPENSES │
│  Daily Overview     │  Rich Markdown & AI │  Priority Checklist │  Personal &   │
│  & Morning Briefing │  Media Attachments  │  Streak Habit Rings │  Group Splits │
├─────────────────────┼─────────────────────┼─────────────────────┼───────────────┤
│  05. WARDROBE       │  06. MOODBOARDS     │  07. TRAVEL SPACES  │  08. ADMIN    │
│  Outfit Planner &   │  Pinterest Masonry  │  Packing Lists &    │  System       │
│  Garment Inventory  │  Visual Aesthetics  │  Itinerary Passports│  Control Room │
└─────────────────────┴─────────────────────┴─────────────────────┴───────────────┘
```

1. **Home Bento & Morning Briefing:** A serene morning overview displaying your top priorities, active habit streaks, planned outfit, and budget pacing without any stressful clutter.
2. **Watchmaker Focus Dial:** Swiss horology-inspired Pomodoro dial with animated Breguet hands sweeping over an ivory chapter ring with custom ambient soundscapes (rain on parchment, fireplace, coffee shop).
3. **Notes & Documents:** Clean markdown writing with rich formatting, document tags, photo attachments, and a grounded AI assistant that answers questions directly from your own notes.
4. **Tasks & Habits:** Keep track of urgent to-dos and daily habits. Build positive streaks through 5 evolutionary flame tiers (Kindling Spark $\rightarrow$ Golden Phoenix).
5. **Expenses & Bill Splitting:** Log everyday expenses, track monthly budgets, and easily calculate fair group splits with friends without needing a separate split app.
6. **Wardrobe & Outfits:** Catalog your clothes, build seasonal outfit pairings, and plan what to wear based on weather and events.
7. **Moodboards & Aesthetics:** Infinite visual pinboards for interior design, fashion inspiration, typography, architecture, and creative projects.
8. **Travel & Trips:** Trip planners with flight itinerary cards, packing matrices, and shared travel spending ledgers.

---

<br/>

<div align="center">
<img src="assets/animations/gold_divider.svg" width="100%" alt="Gold Divider" />
</div>

<br/>

## ⚙️ Help, Privacy & Settings Subpages

Every category in the Settings screen expands into an interactive, dedicated subpage:

- **❓ Help & Support (`HelpSupportSubpage`):**
  - **18 Comprehensive FAQs** covering streaks, vault PINs, timer soundscapes, budget burn rates, calendar exports, and sync.
  - **Real-Time Search & Category Filters:** Live text filtering and category pills (*Streaks & Habits*, *Privacy & Security*, *AI Companion*, *Focus & Timer*, *Backup & Sync*, *Budget & Expenses*).
  - **Interactive Accordion:** Copy answer to clipboard and submit helpful feedback with one tap.
- **🛡️ Privacy & Data Safety (`PrivacySafetySubpage`):**
  - **100% Local-First Transparency:** Transparent audit showing local SQLite encryption, opt-in cloud sync, and 0 third-party tracking SDKs.
  - **Data Sovereignty Controls:** Instant 1-tap "Export Full Archive (JSON)", "Clear Temporary Cache", and "Permanently Erase All Data" with verification safeguards.
- **ℹ️ About NOTtEodo (`AboutNotteodoSubpage`):**
  - Craftsmanship philosophy, technical specifications grid (Flutter 3.x, SQLite, AES-256 GCM, Tuscan Warmth), and `v2.5.0 Production Edition` badge.
- **💬 Feedback & Feature Suggestions:**
  - Direct form in the navigation drawer allowing users to send feature suggestions and bug reports directly to the Admin Command Center with real-time status tracking (*Pending*, *Reviewed*, *In Progress*, *Resolved*).

---

<br/>

<div align="center">
<img src="assets/animations/gold_divider.svg" width="100%" alt="Gold Divider" />
</div>

<br/>

## 👑 Built-in Admin Dashboard

Notteodo includes a dedicated **Administrative Command Center** built right into the universal login page. It gives administrators full visibility and control over app infrastructure, storage quotas, and security policies.

### Sovereign Administrator Access

Administrative access is configured securely via environment variables in your private `.env` file (refer to `.env.example`):

- **Private Configuration:** Set `ADMIN_EMAIL` and `ADMIN_PASSWORD` in your local `.env`.
- **Universal Sign-In Gateway:** Sign in with your designated administrator account on the standard login screen to automatically unlock the Sovereign Administrative Command Center.
- **Zero Exposed Secrets:** Administrative credentials and master keys are kept private in your environment and are never published in public documentation.

### Administrative Controls Overview

- **Overview & Live Telemetry:** Real-time health check across all database tables, active records count, system uptime, and cryptographic verification.
- **User Feedback & Suggestions Console:** Review and triage incoming user feature requests and feedback directly with resolution tags.
- **Cloudinary Media Vault Governance:** Monitor media storage on your connected Cloudinary cloud, run automated orphan media scans, and evict stale image disk caches.
- **Ledger & Database Compaction:** Re-verify SHA-256 tamper-evident audit chains, trigger database VACUUM defragmentation, and export encrypted full-database JSON backups.
- **AI & Neural Engine Governance:** Switch active LLMs (Groq LLaMA 3.3 70B Versatile, Mixtral 8x7B), toggle the Strict Archival Anti-Slop Filter, and flush daily briefing cache.
- **System Maintenance & Live Logs:** Publish global broadcast advisory banners and view the circular ring buffer terminal with level filters (`AUDIT`, `ERROR`, `WARN`, `INFO`), PII redaction, and one-click JSONL export.

---

<br/>

<div align="center">
<img src="assets/animations/gold_divider.svg" width="100%" alt="Gold Divider" />
</div>

<br/>

## 🎨 The Notteodo Palette

Notteodo's visual design is strictly free of corporate blues, harsh cyans, and artificial neon gradients. It transitions seamlessly between **Serene Warm Cream** for daytime clarity and **Pure Pitch Black OLED** for nighttime focus.

<div align="center">
  <img src="assets/animations/palette_harmony_ribbon.svg" alt="Notteodo Signature Palette" width="100%" />
</div>

<br/>

<div align="center">

| Color Token | Hex Code | Visual Character & App Role |
| :--- | :---: | :--- |
| `AppColors.darkBackground` | `#000000` | **Pitch Black OLED:** True 100% black pixels for battery saving and night comfort |
| `AppColors.darkSurfaceHigh` | `#0A0A0A` | **Obsidian Charcoal:** High-contrast solid dark surfaces for bento cards |
| `AppColors.darkBorder` | `#1E1E1E` | **Titanium Hairline:** Subtle, clean card borders in dark mode |
| `AppColors.onSurface` | `#1D1C15` | **Warm Charcoal Ink:** Editorial typography for daylight reading |
| `AppColors.background` | `#FEF9EE` | **Warm Paper Cream:** Natural washi paper base canvas for daytime reading |
| `AppColors.secondary` | `#D9725B` | **Terracotta Red:** Primary buttons, active tabs, and completed checkmarks |
| `AppColors.goldPrimary` | `#D4AF37` | **Imperial Gold:** Focus timer accents, crown admin badges, and gold seals |
| `AppColors.themePlanner` | `#7E998A` | **Forest Sage:** Habit streaks, calm productivity lanes, and calendar milestones |
| `AppColors.themeExpenses` | `#6B7A63` | **Muted Olive:** Expense categories, budget meters, and treasury balances |
| `AppColors.themeSplitter` | `#C88552` | **Warm Amber:** Group debt settlement cards and shared expenses |
| `AppColors.themeJournal` | `#C28E8E` | **Dusty Rose:** Personal journal entries and mood reflections |
| `AppColors.themeTravel` | `#9E7B56` | **Antique Saddle Bronze:** Travel passports, departure cards, and packing lists |

</div>

---

<br/>

<div align="center">
<img src="assets/animations/gold_divider.svg" width="100%" alt="Gold Divider" />
</div>

<br/>

## 🛠️ Quickstart Guide

### Prerequisites
- **Flutter SDK:** `3.24` or newer ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK:** `3.5` or newer
- **Browser, Android Device / Emulator, or iOS Simulator**

### 1. Clone & Setup
```bash
# Clone the repository
git clone https://github.com/Allen73737/NOTtEodo.git
cd NOTtEodo

# Configure your local environment variables
cp .env.example .env
```

### 2. Run the App
```bash
# Move to the Flutter frontend directory
cd frontend

# Install dependencies
flutter pub get

# Run on Chrome / Web
flutter run -d chrome

# Or run on Android / iOS
flutter run -d android
flutter run -d ios
```

### 3. Verification & Testing
```bash
# Run static code analysis (0 errors, 0 warnings, 0 infos)
flutter analyze lib

# Run the complete test suite (129 passing tests across all modules)
flutter test
```

---

<br/>

<div align="center">
<img src="assets/animations/gold_divider.svg" width="100%" alt="Gold Divider" />
</div>

<br/>

## ⚖️ License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for full details.

<br/>

<div align="center">

```
  ✦ · ✦ · ✦
  "Make space for what matters."
  Notteodo · Notes · Tasks · Habits · Expenses · Life
```

<img src="assets/animations/gold_divider.svg" width="50%" alt="Gold Divider" />

</div>
