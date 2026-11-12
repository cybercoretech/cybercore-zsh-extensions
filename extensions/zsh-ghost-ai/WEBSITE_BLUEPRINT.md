# zsh-ghost-ai — GitHub Pages Website Blueprint

**Product:** zsh-ghost-ai  
**URL:** `cybercoretech.github.io/zsh-ghost-ai`  
**Aesthetic:** Cyberpunk Terminal / AI Command Center — polished developer tools, not overdone neon  
**Core promise:** Your terminal knows what comes next.

---

## 1. Design System

### Color Palette

| Element | Hex | Usage |
|---------|-----|-------|
| Background (primary) | `#080B10` | Page body, hero base |
| Background (secondary) | `#101722` | Cards, sections, modal surfaces |
| Surface (elevated) | `#17202E` | Hover states, active inputs |
| Primary accent | `#00F0FF` | Electric cyan — CTAs, links, active cursor |
| Secondary accent | `#39FF14` | Ghost green — ghost text, accept state |
| Tertiary accent | `#0088FF` | Electric blue — subtle glows, secondary links |
| Text (primary) | `#E5EDF5` | Headings, primary body |
| Text (muted) | `#8493A5` | Captions, secondary info |
| Ghost text | `#5C7087` dimmed | AI suggestion preview (30–40% opacity) |
| Border | `#1F2A3B` | Subtle dividers |
| Grid | `#141C29` fine lines | Background technical texture |

### Typography

| Role | Family | Weight | Size | Usage |
|------|--------|--------|------|-------|
| Headings | Space Grotesk | 600–700 | 2.5rem → 1.25rem | Page title, section headers |
| Body | Inter (or system sans) | 400–500 | 1rem | Paragraphs, feature descriptions |
| Code | JetBrains Mono | 400–500 | 0.875rem–1rem | Commands, file paths, inline code |
| Terminal UI | JetBrains Mono | 400 | 0.9375rem | Demo terminal text |

### Layout & Shape

| Property | Value |
|----------|-------|
| Border radius | 8–12px (cards, buttons, inputs) |
| Container max-width | 1200px |
| Section padding | 6rem 1.5rem |
| Grid columns | 12 (flexbox/grid fallback) |
| Animation | Subtle, smooth, purposeful; `ease-out` preferred |

---

## 2. Page Architecture (SPA, Single-Page)

All content lives on one HTML file with sticky navigation and smooth scroll anchors. No page reloads.

### Navigation (Sticky, Compact)

```
GHOST AI  ·  Features  ·  Demo  ·  Installation  ·  GitHub
```

- Left: logo + wordmark ("GHOST AI")
- Right: feature anchors + external GitHub link (opens in new tab)
- Stays visible on scroll; scrolls smoothly to section on click
- Mobile: hamburger → vertical list

### Sections (in order)

1. **Hero** — Ghost Effect animation + interactive terminal demo
2. **Features** — 4-column grid (Local AI / Multiple providers / In control / Zero disruption)
3. **Installation** — one-line curl + copy button + walkthrough
4. **Footer** — GitHub link, license, version, back-to-top

---

## 3. Hero Section — "The Ghost Effect"

This is the centerpiece. It must communicate speed and non-interruption.

### Layout

```
┌─────────────────────────────────────────────────────────────┐
│  GHOST AI                      Features · Demo · Install · GH│
│                                                             │
│  Your terminal knows what comes next.                      │
│  AI-powered command prediction for Zsh. Type naturally.    │
│  Watch your next command appear. Press → to accept. Never  │
│  interrupts your workflow.                                  │
│                                                             │
│  [ INSTALL NOW  ]  [ VIEW ON GITHUB ]   ● Ollama  ● OpenAI  │
│                                                          ● Claude│
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ > git che                                              │  │
│  │   ┌──── ghost: ckout main ───┐                         │  │
│  │  │  █  (soft cursor pulse)      │                         │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### The Ghost Effect (Signature Animation)

**Duration:** 2–3 seconds, non-blocking (visitor can scroll/click immediately)

**Sequence:**

1. **t = 0ms** — Blank terminal line with blinking cursor `> _`
2. **t = 300–800ms** — Types `git che` character by character (soft typewriter sound optional, no audio by default)
3. **t = 900ms** — Cursor pauses; dim ghost text `ckout main` materializes character by character at reduced opacity
4. **t = 1400ms** — Simulated right-arrow press: ghost text snaps into the buffer, cursor moves to end
5. **t = 1800ms** — Terminal fades slightly; hero content fully revealed; visitor can interact

**Interaction during animation:** Visitor can scroll or click at any time; animation gracefully yields.

### Interactive Terminal Demo

After the Ghost Effect plays once (or is skipped), the hero becomes an interactive sandbox:

| Interaction | Behavior |
|-------------|----------|
| Typing in the demo input | Real keystrokes update the buffer |
| Pause > 300ms | Ghost suggestion appears dimmed after cursor (if model would predict) |
| Press `→` / `End` | Accept: suggestion folds into buffer, cursor advances |
| Press `Esc` | Dismiss: suggestion vanishes, line stays |
| Press any other key | Suggestion clears, new prediction may start |

**Visual fidelity:** The suggestion text must be dimmed (~35% opacity), same as the real Zsh plugin. The accepted portion snaps in with no flash.

**Fallback:** If JavaScript is disabled or the demo fails to load, show a static GIF/MP4 loop of the same sequence.

---

## 4. Feature Sections (4 columns)

Each feature is a card: icon + title + short description + subtle hover lift.

| Column | Title | Description |
|--------|-------|-------------|
| 1 | **Local AI first** | Ollama-powered predictions without requiring a cloud AI service. |
| 2 | **Multiple AI providers** | Ollama, OpenAI-compatible endpoints, and Claude. You remain in control. |
| 3 | **In control** | Suggestions never execute automatically. You decide what gets accepted. |
| 4 | **Zero workflow disruption** | Non-blocking suggestions that stay out of your way. |

**Styling:** Cards on `#101722`, border `#1F2A3B`, hover lifts to `#17202E` with a soft cyan glow on the left border.

---

## 5. Installation Section

**Headline:** Install in one line.

**Install block:**

```
curl -fsSL https://raw.githubusercontent.com/cybercoretech/zsh-ghost-ai/main/install.sh | bash
```

- Copy button to the right of the code block (tooltip: "Copied!")
- Below: numbered walkthrough (1. Run the command, 2. Restart your shell `exec zsh`, 3. Type and press `→`)
- Provider badges: Ollama (default), OpenAI Compatible, Claude

---

## 6. Visual Design Specifications

### Hero

- Background: `#080B10` with a very fine `#141C29` grid (1–2px, 40px spacing)
- Terminal card: `#101722`, 12px radius, subtle border `#1F2A3B`
- Cursor: 2px wide block, electric cyan `#00F0FF`, soft pulse animation (1s cycle)
- Ghost text: `#5C7087` at 35% opacity, JetBrains Mono

### Buttons

| State | Background | Text | Border |
|-------|------------|------|--------|
| Primary (Install Now) | `#00F0FF` | `#080B10` | none |
| Secondary (View on GitHub) | transparent | `#E5EDF5` | `#1F2A3B` 1px |
| Hover (primary) | `#33F5FF` | `#080B10` | none |

### Section Transitions

- Intersection Observer: fade-in + slight translate-y as sections enter viewport
- Duration: 0.6s, `ease-out`
- Never block content; animations are enhancements

---

## 7. Technical Implementation Notes

### Stack (keep it lightweight, GitHub Pages compatible)

- **HTML5** semantic structure
- **CSS3** custom properties for the design system
- **Vanilla JavaScript** (no framework) — terminal demo, Ghost Effect, copy button, smooth scroll
- **Fonts:** Space Grotesk + JetBrains Mono via Google Fonts (or self-hosted)
- **Hosting:** GitHub Pages from `/docs` or root of `main` branch

### File Structure

```
zsh-ghost-ai/
├── docs/                     # GitHub Pages source
│   ├── index.html            # SPA (all sections)
│   ├── css/
│   │   └── main.css          # Design system + components
│   ├── js/
│   │   ├── ghost-effect.js   # Signature animation
│   │   ├── terminal-demo.js  # Interactive terminal sandbox
│   │   └── nav.js            # Sticky nav + smooth scroll
│   └── assets/
│       └── (optional static fallback video)
├── WEBSITE_BLUEPRINT.md      # This document
├── install.sh                # Existing installer
└── README.md                 # Existing README
```

### GitHub Pages Deployment

Enable Pages in repo settings: Source = `main` branch, folder = `/docs` (or root).  
Custom domain optional: `zsh-ghost-ai.cybercoretech.dev` or GitHub Pages default.

---

## 8. Copy & Content

### Hero Headline
> GHOST AI  
> Your terminal knows what comes next.

### Hero Subhead
AI-powered command prediction for Zsh. Type naturally. Watch your next command appear. Press → to accept. Never interrupts your workflow.

### CTAs
- `INSTALL NOW` → scrolls to Installation section
- `VIEW ON GITHUB` → `https://github.com/cybercoretech/zsh-ghost-ai`

### Feature Cards

**Local AI first**  
Ollama-powered predictions without requiring a cloud AI service.

**Multiple AI providers**  
Ollama, OpenAI-compatible endpoints, and Claude. You remain in control.

**In control**  
Suggestions never execute automatically. You decide what gets accepted.

**Zero workflow disruption**  
Non-blocking suggestions that stay out of your way.

### Installation Copy

**Install in one line.**

```
curl -fsSL https://raw.githubusercontent.com/cybercoretech/zsh-ghost-ai/main/install.sh | bash
```

Walkthrough:
1. Paste the command into your terminal and press Enter.
2. Restart your shell: `exec zsh`
3. Start typing — press `→` to accept a suggestion.

### Footer

zsh-ghost-ai v0.1.0 · MIT License · [GitHub](https://github.com/cybercoretech/zsh-ghost-ai)

---

## 9. Success Criteria

- Visitor understands the product within 3 seconds (hero + Ghost Effect)
- Interactive demo works without installing anything
- Install command is copy-pasteable and clearly visible
- Page loads fast (< 2s on 3G), no framework bloat
- Accessible: keyboard navigable, sufficient contrast, reduced-motion support

---

## 10. Next Steps

1. Create `docs/` directory in `zsh-ghost-ai` repo
2. Write `index.html`, `css/main.css`, `js/ghost-effect.js`, `js/terminal-demo.js`
3. Add Ghost Effect + interactive terminal sandbox
4. Deploy to GitHub Pages
5. Link from `README.md` and plugin `install.sh`
