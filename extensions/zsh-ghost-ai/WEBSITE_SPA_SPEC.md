# zsh-ghost-ai — GitHub Pages SPA Specification

**Status:** Implementation-ready blueprint  
**Target:** `cybercoretech.github.io/zsh-ghost-ai`  
**Stack:** Vanilla HTML/CSS/JS, GitHub Pages (static, no build step)  
**Aesthetic:** Cyberpunk Terminal / AI Command Center — polished dev tools, not overdone neon  
**Core promise:** "Your terminal knows what comes next."

---

## 1. Global Design System

### Colors (CSS custom properties)

```css
:root {
  /* Backgrounds */
  --bg-primary: #080B10;     /* page body, hero base */
  --bg-secondary: #101722;   /* cards, section surfaces */
  --bg-elevated: #17202E;    /* hover states, active inputs */
  --bg-grid: #141C29;        /* fine background grid lines */

  /* Accents */
  --accent-primary: #00F0FF;   /* electric cyan — CTAs, links, active cursor */
  --accent-secondary: #39FF14; /* ghost green — ghost text, accept state */
  --accent-tertiary: #0088FF;  /* electric blue — subtle glows, secondary links */

  /* Text */
  --text-primary: #E5EDF5;   /* headings, primary body */
  --text-secondary: #B9C4D0; /* secondary body */
  --text-muted: #8493A5;     /* captions, secondary info */
  --text-ghost: #5C7087;     /* dimmed AI suggestion (35-40% opacity) */

  /* Borders & UI */
  --border: #1F2A3B;         /* subtle dividers */
  --border-focus: #00F0FF;   /* focus ring */
  --shadow-sm: 0 1px 3px rgba(0,0,0,0.4);
  --shadow-md: 0 4px 12px rgba(0,0,0,0.5);

  /* Radius */
  --radius-sm: 6px;
  --radius-md: 10px;
  --radius-lg: 14px;

  /* Typography */
  --fs-heading: 2.75rem;
  --fs-lead: 1.375rem;
  --fs-body: 1rem;
  --fs-code: 0.875rem;
  --fs-terminal: 0.9375rem;
}
```

### Typography Stack

| Role | Family | Weights | Use |
|------|--------|---------|-----|
| Headings | Space Grotesk | 500, 600, 700 | Page title, section headers |
| Body | Inter, system-ui, sans-serif | 400, 500 | Paragraphs, descriptions |
| Code | JetBrains Mono, monospace | 400, 500 | Commands, inline code, terminal |
| Terminal | JetBrains Mono, monospace | 400 | Demo terminal output |

Font loading: Google Fonts (`JetBrains Mono`, `Space Grotesk`) with `font-display: swap`.

### Breakpoints

| Name | Min-width | Use |
|------|-----------|-----|
| `--bp-xs` | 480px | Phones |
| `--bp-sm` | 640px | Small tablets |
| `--bp-md` | 900px | Laptops, small desktops |
| `--bp-lg` | 1200px | Desktops |

Container max-width: `1200px` (`.container`).

### Spacing Scale

- Section padding: `6rem 1rem` (desktop), `4rem 1rem` (mobile)
- Component gap: `1.5rem`
- Card padding: `1.5rem`

---

## 2. File Structure (GitHub Pages)

```
zsh-ghost-ai/
├── docs/                          # GitHub Pages source
│   ├── index.html                 # SPA — all sections in one file
│   ├── css/
│   │   ├── variables.css          # Design tokens (colors, type, breakpoints)
│   │   ├── reset.css              # Light reset
│   │   ├── layout.css             # Container, nav, sections, grid
│   │   ├── components.css         # Buttons, pills, cards, terminal
│   │   └── animations.css         # Keyframes, reduced-motion overrides
│   ├── js/
│   │   ├── nav.js                 # Sticky nav, mobile toggle, smooth scroll
│   │   ├── ghost-effect.js        # The Ghost Effect signature animation
│   │   ├── terminal-demo.js       # Interactive terminal sandbox
│   │   └── utils.js               # Copy-to-clipboard, intersection observer
│   └── assets/
│       └── terminal-fallback.mp4  # Static fallback if JS fails
├── install.sh                     # Existing installer
├── README.md                      # Existing README
├── LICENSE
└── WEBSITE_SPA_SPEC.md            # This document
```

**GitHub Pages setting:** Source = `main` branch, folder = `/docs`.

---

## 3. Section Layouts (Exact HTML Structure)

### 3.1 Navigation (Sticky)

```html
<nav class="nav" id="nav">
  <div class="nav-inner container">
    <a href="#" class="nav-logo" aria-label="GHOST AI home">GH<span class="accent">OST</span> AI</a>
    <div class="nav-links" id="nav-links">
      <a href="#features">Features</a>
      <a href="#demo">Demo</a>
      <a href="#install">Installation</a>
      <a href="https://github.com/cybercoretech/zsh-ghost-ai" target="_blank" rel="noopener" class="nav-gh">GitHub</a>
    </div>
    <button class="nav-toggle" id="nav-toggle" aria-expanded="false" aria-controls="nav-links" aria-label="Toggle menu">
      <span class="bar"></span><span class="bar"></span><span class="bar"></span>
    </button>
  </div>
</nav>
```

**Behavior:**
- Fixed at top, `z-index: 50`, transparent initially
- On scroll past 60px: gains `--bg-elevated` bg + subtle border-bottom
- Mobile (< 640px): links hidden behind hamburger; toggle opens vertical list
- Active link gets `--accent-primary` underline
- Smooth scroll to anchors

---

### 3.2 Hero Section

```html
<section class="hero" id="hero" aria-labelledby="hero-title">
  <div class="hero-grid">
    <!-- Left: copy -->
    <div class="hero-copy">
      <span class="hero-badge">v0.1.0 · MIT</span>
      <h1 id="hero-title">GH<span class="accent">OST</span> AI</h1>
      <p class="hero-lead">Your terminal knows what comes next.</p>
      <p class="hero-desc">AI-powered command prediction for Zsh. Type naturally. Watch your next command appear. Press &rarr; to accept. Never interrupts your workflow.</p>
      
      <div class="hero-cta">
        <a href="#install" class="btn btn-primary">Install now</a>
        <a href="https://github.com/cybercoretech/zsh-ghost-ai" target="_blank" rel="noopener" class="btn btn-outline">View on GitHub</a>
      </div>

      <div class="provider-pills" role="group" aria-label="Supported providers">
        <span class="pill"><span class="pill-dot"></span> Ollama</span>
        <span class="pill"><span class="pill-dot"></span> OpenAI Compatible</span>
        <span class="pill"><span class="pill-dot"></span> Claude</span>
      </div>
    </div>

    <!-- Right: terminal demo -->
    <div class="hero-demo-wrap">
      <div class="terminal-card" id="terminal-card">
        <div class="terminal-header">
          <div class="terminal-dots">
            <span class="dot dot-red" title="close"></span>
            <span class="dot dot-yellow" title="minimize"></span>
            <span class="dot dot-green" title="maximize"></span>
          </div>
          <span class="terminal-title">zsh · ghost-ai</span>
        </div>
        <div class="terminal-body" id="terminal-body">
          <!-- Lines injected by JS during Ghost Effect -->
          <div class="line line-input" id="line-input">
            <span class="prompt">&gt; </span>
            <span class="typed" id="typed"></span>
            <span class="cursor blink" id="cursor">▋</span>
          </div>
          <div class="line line-ghost hidden" id="line-ghost">
            <span class="prompt">&gt; </span>
            <span class="typed-ghost" id="typed-ghost"></span>
            <span class="ghost-caret">▋</span>
          </div>
          <div class="line line-hint hidden" id="line-hint">
            <span class="hint-text">Press <kbd>&rarr;</kbd> to accept &nbsp;·&nbsp; Esc to dismiss</span>
          </div>
        </div>
        <div class="terminal-status">
          <span class="status-indicator"></span>
          <span class="status-text">Ready</span>
        </div>
      </div>
      <div class="demo-hint">Interactive demo — type to see predictions appear</div>
    </div>
  </div>
</section>
```

**Hero layout (CSS Grid):**
- Desktop (≥ 900px): 2 columns — copy `1fr`, terminal `1.4fr`, gap `3rem`, vertically centered
- Mobile (< 900px): single column — copy on top, terminal below, gap `2rem`

---

### 3.3 Features Section

```html
<section class="features" id="features" aria-labelledby="features-title">
  <div class="container">
    <div class="section-head">
      <h2 id="features-title">How it works</h2>
      <p>Four ideas. One goal: your terminal, faster.</p>
    </div>
    <div class="feature-grid">
      <article class="feature-card">
        <div class="feature-icon">⚡</div>
        <h3>Local AI first</h3>
        <p>Ollama-powered predictions without requiring a cloud AI service. Your commands stay local.</p>
      </article>
      <article class="feature-card">
        <div class="feature-icon">🌐</div>
        <h3>Multiple AI providers</h3>
        <p>Ollama, OpenAI-compatible endpoints, and Claude. You remain in control of the backend.</p>
      </article>
      <article class="feature-card">
        <div class="feature-icon">🛡️</div>
        <h3>You stay in control</h3>
        <p>Suggestions never execute automatically. You decide what gets accepted with &rarr;.</p>
      </article>
      <article class="feature-card">
        <div class="feature-icon">🧭</div>
        <h3>Zero disruption</h3>
        <p>Non-blocking suggestions that stay out of your way until you want them.</p>
      </article>
    </div>
  </div>
</section>
```

**Feature layout:**
- Desktop: 4-column grid (`repeat(4, 1fr)`), gap `1.5rem`
- Tablet (640–899px): 2-column grid
- Mobile (< 640px): 1-column stack

**Card hover:** translateY(-4px), left border glow `--accent-primary`, shadow increases.

---

### 3.4 Installation Section

```html
<section class="install" id="install" aria-labelledby="install-title">
  <div class="container">
    <div class="section-head">
      <h2 id="install-title">Install in one line</h2>
      <p>Drop it into your zshrc, restart your shell, and start typing.</p>
    </div>
    <div class="install-card">
      <div class="install-code">
        <span class="code-dollar">$</span>
        <span class="code-text">curl -fsSL https://raw.githubusercontent.com/cybercoretech/zsh-ghost-ai/main/install.sh | bash</span>
        <button class="btn-copy" id="btn-copy" aria-label="Copy install command">Copy</button>
      </div>
      <ol class="install-steps">
        <li>Run the command above in your terminal.</li>
        <li>Restart your shell: <code>exec zsh</code></li>
        <li>Start typing — press <kbd>&rarr;</kbd> to accept a suggestion.</li>
      </ol>
    </div>
  </div>
</section>
```

**Install layout:**
- Centered install-card (max-width 700px, centered)
- Code block full-width within card, copy button aligned right
- Steps numbered list below

---

### 3.5 Footer

```html
<footer class="footer" aria-label="Site footer">
  <div class="container footer-inner">
    <div class="footer-brand">GH<span class="accent">OST</span> AI</div>
    <div class="footer-copy">
      v0.1.0 · MIT License · 
      <a href="https://github.com/cybercoretech/zsh-ghost-ai" target="_blank" rel="noopener">GitHub</a>
    </div>
    <a href="#hero" class="btn btn-outline top">Top &uarr;</a>
  </div>
</footer>
```

---

## 4. Component Specifications

### Buttons

| Variant | bg | text | border | hover |
|---------|----|------|--------|-------|
| `.btn-primary` | `--accent-primary` (#00F0FF) | `--bg-primary` (#080B10) | none | `#33F5FF` |
| `.btn-outline` | transparent | `--text-primary` | `--border` 1px | bg `--bg-elevated` |

- Padding: `0.875rem 1.5rem`
- Radius: `var(--radius-md)`
- Font: Inter, 500, `0.95rem`
- Transition: all `0.2s ease`

### Pills

```html
<span class="pill"><span class="pill-dot"></span> Ollama</span>
```
- Pill: inline-flex, bg `--bg-elevated`, border `--border`, radius `999px`, padding `0.25rem 0.75rem`, font `0.8rem` JetBrains Mono
- Dot: 6px circle, `--accent-secondary`, inline-block, margin-right `0.5rem`

### Terminal Card

- Container: `#101722`, radius `var(--radius-lg)`, border `--border`, shadow `--shadow-md`
- Header: macOS-style dots (red/yellow/green 10px circles), title left of center
- Body: monospace terminal, black-ish inner bg, padding `1.5rem`
- Lines: `display: flex`, gap `0.5rem`, prompt in `--text-muted`, typed text `--text-primary`
- Ghost line: `--text-ghost`, opacity `0.4`, `font-style: italic` optional
- Cursor: 2px wide block, `--accent-primary`, `blink` 1s infinite alternate

### Status Bar (terminal bottom)

- Flex row, indicator dot (10px, `--accent-secondary`), text `--text-muted` `0.75rem`

---

## 5. Animation Specifications

### 5.1 The Ghost Effect (Signature Animation)

**File:** `js/ghost-effect.js`  
**Duration:** ~2.6 seconds  
**Reduced motion:** Skip animation, show final state immediately  
**Interruptible:** Visitor can scroll/click at any time; animation yields

**Sequence:**

| Time | Action |
|------|--------|
| 0ms | Terminal empty, cursor `> ▋` blinking |
| 300–800ms | Type `git che` — one char every ~100ms with slight variance |
| 900ms | Pause 150ms |
| 1050–1500ms | Materialize ghost text `ckout main` — dim, one char every ~90ms |
| 1600ms | Ghost text fully visible, hint line fades in: "Press → to accept · Esc to dismiss" |
| 2000ms | Simulated accept: ghost text snaps into typed buffer, cursor moves to end, ghost line hides |
| 2300ms | Animation complete; terminal transitions to interactive mode |

**CSS keyframes:**

```css
@keyframes cursor-blink {
  0%, 49% { opacity: 1; }
  50%, 100% { opacity: 0; }
}
@keyframes type-char {
  from { opacity: 0; transform: translateX(-2px); }
  to { opacity: 1; transform: translateX(0); }
}
@keyframes ghost-appear {
  from { opacity: 0; transform: translateX(-1px); }
  to { opacity: 0.4; transform: translateX(0); }
}
@keyframes accept-snap {
  from { opacity: 0.4; }
  to { opacity: 1; }
}
```

### 5.2 Page Load Reveals

- **Trigger:** `IntersectionObserver` with `threshold: 0.15`
- **Animation:** `opacity: 0 → 1`, `transform: translateY(20px) → 0`, duration `0.7s`, `ease-out`
- **Stagger:** Hero (0s), Features (0.15s), Install (0.3s), Footer (0.45s)
- **Reduced motion:** `@media (prefers-reduced-motion: reduce)` — disable all motion, show elements immediately

### 5.3 Hover / Micro-interactions

- Feature cards: `translateY(-4px)` on hover, `0.3s ease`
- Buttons: scale `1.02` on hover, active `scale 0.98`
- Pills: subtle bg lift on hover
- Nav links: underline grows from center on hover

---

## 6. Interactive Terminal Demo (Hero)

**File:** `js/terminal-demo.js`

**Behavior:**

| Interaction | Result |
|-------------|--------|
| Typing | Characters appended to `#typed`, cursor stays at end |
| Pause > 300ms (debounce) | If buffer matches a known pattern (demo-only: `git che`, `npm inst`, `docker run`, `kubectl get`), dim ghost suggestion materializes after cursor |
| `→` / `End` | Accept: ghost text appends to `#typed`, ghost line hides, cursor advances |
| `Esc` | Dismiss: ghost line hides, `#typed-ghost` cleared |
| Any other key during ghost visible | Ghost clears, new prediction may restart after debounce |

**Demo predictions (hardcoded for the website, no backend):**

| User types | Ghost suggestion |
|------------|------------------|
| `git che` | `ckout main` |
| `npm inst` | `all` |
| `docker run` | ` -it nginx` |
| `kubectl get` | ` pods` |
| `cargo bu` | `ild` |

**Visual rules:**
- Ghost text dimmed (`--text-ghost`, opacity `0.4`)
- Cursor always after typed text, never overlapping ghost
- Accept produces no page navigation — just buffer update

**Fallback:** If JS disabled, show static HTML with `git che` + `ckout main` ghost visible as a screenshot-like illustration.

---

## 6. Copy-to-Clipboard

**File:** `js/utils.js` + `nav.js`

- Button `#btn-copy` next to install command
- On click: `navigator.clipboard.writeText()` the full command text
- Button text changes to `Copied!` for 2s, then reverts
- Fallback for older browsers: create temp `<textarea>`, select, `execCommand('copy')`

---

## 7. Responsive Behavior

| Breakpoint | Layout changes |
|------------|----------------|
| **≥ 1200px** | Hero 2-col (copy 1fr, terminal 1.4fr), Features 4-col, container 1200px |
| **900–1199px** | Hero 2-col (copy 1fr, terminal 1.25fr), Features 4-col or 2-col |
| **640–899px** | Hero single col, Features 2-col, container 90% |
| **< 640px** | Hero single col, Features 1-col, container 90%, nav hamburger, font sizes slightly smaller (`--fs-heading 2rem`) |

**Mobile nav:**
- Hamburger button appears < 640px
- Click opens full-height overlay or slide-from-right panel with links
- Clicking a link closes the menu
- Esc closes menu

**Terminal card on mobile:**
- Full width of card, font size `0.875rem`, padding `1rem`
- Hero copy text centered

---

## 7. Accessibility (a11y)

- All images/decorative elements: `aria-hidden="true"` or empty alt
- Nav toggle: `aria-expanded`, `aria-controls`
- Buttons: clear text labels
- Code blocks: readable by screen readers (plain text in DOM)
- Focus visible: `:focus-visible` outline `--accent-primary` 2px
- Skip link (optional): "Skip to content" at top of DOM
- Color contrast: `--text-primary` on `--bg-primary` > 7:1; ghost text is decorative only, not sole information carrier
- Reduced motion: all animations disabled via `prefers-reduced-motion`

---

## 7. Implementation Checklist

- [ ] Create `docs/` directory
- [ ] `css/variables.css` — design tokens
- [ ] `css/reset.css` — box-sizing, margins, font-smoothing
- [ ] `css/layout.css` — container, nav, section headers, grids
- [ ] `css/components.css` — buttons, pills, cards, terminal, install card
- [ ] `css/animations.css` — keyframes, intersection-observer reveals, reduced motion
- [ ] `index.html` — full SPA markup (hero, features, install, footer)
- [ ] `js/utils.js` — copy-to-clipboard, helpers
- [ ] `js/nav.js` — sticky nav, mobile menu, smooth scroll
- [ ] `js/ghost-effect.js` — The Ghost Effect signature animation
- [ ] `js/terminal-demo.js` — interactive terminal sandbox
- [ ] Add `terminal-fallback.mp4` (optional static fallback)
- [ ] Test: 138 zsh tests unaffected (separate repo concern)
- [ ] Enable GitHub Pages: Settings → Pages → main /docs
- [ ] Link from README.md

---

## 7. What "Done" Looks Like

A visitor lands on `cybercoretech.github.io/zsh-ghost-ai` and within 3 seconds:
1. Sees the Ghost Effect animation (cursor → types `git che` → dim suggestion `ckout main` → accepts)
2. Reads "Your terminal knows what comes next."
3. Can click "Install now" or scroll to Features
4. Can interact with the terminal demo themselves
5. Copies the one-line install command with one click

The site feels like a premium CyberCore product — dark charcoal terminal aesthetic, electric cyan/green accents, monospace + sans-serif mix, smooth purposeful motion, no framework bloat.
