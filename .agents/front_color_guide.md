# Front Color Guide — Viking Clan Wars

> Single source of truth for all colors in the frontend.
> Every color used in any Angular component MUST come from this file.
> Never hardcode hex values in component `.scss` files.
> When this file changes, run the workflow `/update-color-guide`.

---

## Implementation

### 1. Global CSS Custom Properties

File: `front/src/styles/tokens.scss`

This file defines the CSS custom properties for both themes on the `:root` selector,
with `prefers-color-scheme` as the default and a `[data-theme]` attribute override for manual toggle.

```scss
// ============================================================
// DARK THEME (default)
// ============================================================
:root,
[data-theme="dark"] {

  // --- Backgrounds ---
  --color-bg-primary:   #0d0c18;   // void — deepest background
  --color-bg-secondary: #1a1830;   // dark navy — page surface
  --color-bg-tertiary:  #141220;   // between primary and secondary
  --color-bg-card:      #211f38;   // card / panel surface
  --color-bg-modal:     #252342;   // modal surface
  --color-bg-overlay:   rgba(0, 0, 0, 0.72); // scrim behind modals

  // --- Text ---
  --color-text-primary:   #e8e0d0; // parchment — main readable text
  --color-text-secondary: #b8a898; // aged parchment — supporting text
  --color-text-disabled:  #5a5068; // muted — disabled states
  --color-text-inverse:   #0d0c18; // text on gold/light backgrounds

  // --- Gold Accent (primary brand color) ---
  --color-gold:        #c9a84c;               // main gold
  --color-gold-light:  #e8c96a;               // hover / highlight gold
  --color-gold-dark:   #9a7a30;               // pressed / active gold
  --color-gold-muted:  rgba(201, 168, 76, 0.15); // subtle gold tint (backgrounds)

  // --- Borders ---
  --color-border-strong:  #c9a84c;            // gold border — emphasis, active states
  --color-border-default: #3a3555;            // subtle border — cards, inputs
  --color-border-faint:   #252342;            // barely visible — dividers

  // --- Semantic ---
  --color-success:     #2d8a4e;
  --color-success-bg:  rgba(45, 138, 78, 0.15);
  --color-error:       #c0392b;
  --color-error-bg:    rgba(192, 57, 43, 0.15);
  --color-warning:     #c9a84c;               // gold doubles as warning
  --color-warning-bg:  rgba(201, 168, 76, 0.15);
  --color-info:        #4a90d9;
  --color-info-bg:     rgba(74, 144, 217, 0.15);

  // --- Phase indicators ---
  --color-phase-preparation: #4a90d9; // blue — calm, no combat
  --color-phase-war:         #c0392b; // red — active combat
  --color-phase-end:         #c9a84c; // gold — endgame

  // --- Clan colors ---
  --color-clan-fury:   #c0392b; // FURY   — Berserkers  (blood red)
  --color-clan-divine: #4a90d9; // DIVINE — Valkirias   (sky blue)
  --color-clan-iron:   #8a9ba8; // IRON   — Jarls       (steel grey)
  --color-clan-song:   #8b5cf6; // SONG   — Skalds      (violet)
  --color-clan-rune:   #10b981; // RUNE   — Seidr       (emerald)
  --color-clan-death:  #7c6b9e; // DEATH  — Draugr      (dark violet)

  // --- Progress bars ---
  --color-progress-track:    #3a3555;
  --color-progress-health:   #2d8a4e; // green — troop health
  --color-progress-training: #4a90d9; // blue  — training queue
  --color-progress-research: #8b5cf6; // violet — research progress

  // --- Scrollbars (webkit) ---
  --color-scrollbar-track:  #1a1830;
  --color-scrollbar-thumb:  #3a3555;
}

// ============================================================
// LIGHT THEME
// ============================================================
@media (prefers-color-scheme: light) {
  :root:not([data-theme="dark"]) {
    @include light-theme-vars;
  }
}

[data-theme="light"] {
  @include light-theme-vars;
}

@mixin light-theme-vars {

  // --- Backgrounds ---
  --color-bg-primary:   #f8f2e8;   // warm parchment — deepest background
  --color-bg-secondary: #ede4d5;   // aged parchment — page surface
  --color-bg-tertiary:  #e4d8c6;   // darker parchment
  --color-bg-card:      #fdf8f0;   // cream — card / panel surface
  --color-bg-modal:     #fff9f0;   // ivory — modal surface
  --color-bg-overlay:   rgba(30, 20, 10, 0.50);

  // --- Text ---
  --color-text-primary:   #1a1410; // dark charcoal
  --color-text-secondary: #4a3f35; // warm brown
  --color-text-disabled:  #9a8878;
  --color-text-inverse:   #f8f2e8; // text on dark/gold backgrounds

  // --- Gold Accent ---
  --color-gold:        #8a6020;               // darkened gold for legibility on light bg
  --color-gold-light:  #c9a84c;               // hover
  --color-gold-dark:   #5a3a10;               // pressed
  --color-gold-muted:  rgba(138, 96, 32, 0.12);

  // --- Borders ---
  --color-border-strong:  #8a6020;
  --color-border-default: #c8b898;
  --color-border-faint:   #ddd0bc;

  // --- Semantic ---
  --color-success:     #1e6b35;
  --color-success-bg:  rgba(30, 107, 53, 0.12);
  --color-error:       #8b1e1e;
  --color-error-bg:    rgba(139, 30, 30, 0.12);
  --color-warning:     #8a6020;
  --color-warning-bg:  rgba(138, 96, 32, 0.12);
  --color-info:        #1a5fa0;
  --color-info-bg:     rgba(26, 95, 160, 0.12);

  // --- Phase indicators ---
  --color-phase-preparation: #1a5fa0;
  --color-phase-war:         #8b1e1e;
  --color-phase-end:         #8a6020;

  // --- Clan colors ---
  --color-clan-fury:   #8b1e1e;
  --color-clan-divine: #1a5fa0;
  --color-clan-iron:   #4a5e6e;
  --color-clan-song:   #5b34d6;
  --color-clan-rune:   #0a7a54;
  --color-clan-death:  #5a4880;

  // --- Progress bars ---
  --color-progress-track:    #c8b898;
  --color-progress-health:   #1e6b35;
  --color-progress-training: #1a5fa0;
  --color-progress-research: #5b34d6;

  // --- Scrollbars ---
  --color-scrollbar-track:  #ede4d5;
  --color-scrollbar-thumb:  #c8b898;
}
```

---

### 2. SCSS Variables (for use inside component `.scss` files)

File: `front/src/styles/variables.scss`

Wraps every custom property in an SCSS variable so components can use `$color-gold` instead of `var(--color-gold)` where SCSS operations are needed.

```scss
// Backgrounds
$color-bg-primary:   var(--color-bg-primary);
$color-bg-secondary: var(--color-bg-secondary);
$color-bg-tertiary:  var(--color-bg-tertiary);
$color-bg-card:      var(--color-bg-card);
$color-bg-modal:     var(--color-bg-modal);
$color-bg-overlay:   var(--color-bg-overlay);

// Text
$color-text-primary:   var(--color-text-primary);
$color-text-secondary: var(--color-text-secondary);
$color-text-disabled:  var(--color-text-disabled);
$color-text-inverse:   var(--color-text-inverse);

// Gold
$color-gold:       var(--color-gold);
$color-gold-light: var(--color-gold-light);
$color-gold-dark:  var(--color-gold-dark);
$color-gold-muted: var(--color-gold-muted);

// Borders
$color-border-strong:  var(--color-border-strong);
$color-border-default: var(--color-border-default);
$color-border-faint:   var(--color-border-faint);

// Semantic
$color-success:     var(--color-success);
$color-success-bg:  var(--color-success-bg);
$color-error:       var(--color-error);
$color-error-bg:    var(--color-error-bg);
$color-warning:     var(--color-warning);
$color-warning-bg:  var(--color-warning-bg);
$color-info:        var(--color-info);
$color-info-bg:     var(--color-info-bg);

// Phases
$color-phase-preparation: var(--color-phase-preparation);
$color-phase-war:         var(--color-phase-war);
$color-phase-end:         var(--color-phase-end);

// Clans
$color-clan-fury:   var(--color-clan-fury);
$color-clan-divine: var(--color-clan-divine);
$color-clan-iron:   var(--color-clan-iron);
$color-clan-song:   var(--color-clan-song);
$color-clan-rune:   var(--color-clan-rune);
$color-clan-death:  var(--color-clan-death);

// Progress
$color-progress-track:    var(--color-progress-track);
$color-progress-health:   var(--color-progress-health);
$color-progress-training: var(--color-progress-training);
$color-progress-research: var(--color-progress-research);
```

---

### 3. Theme Toggle Service

File: `front/src/app/core/theme/theme.service.ts`

```typescript
import { Injectable, signal, effect } from '@angular/core';

type Theme = 'dark' | 'light';

@Injectable({ providedIn: 'root' })
export class ThemeService {

  // Estado del tema — dark por defecto si el sistema no indica preferencia
  readonly #theme = signal<Theme>(this.#getInitialTheme());
  readonly theme = this.#theme.asReadonly();

  constructor() {
    // Aplicar el atributo data-theme al <html> cuando cambie el signal
    effect(() => {
      document.documentElement.setAttribute('data-theme', this.#theme());
      localStorage.setItem('theme', this.#theme());
    });
  }

  toggle(): void {
    this.#theme.update(t => t === 'dark' ? 'light' : 'dark');
  }

  setTheme(theme: Theme): void {
    this.#theme.set(theme);
  }

  #getInitialTheme(): Theme {
    const stored = localStorage.getItem('theme') as Theme | null;
    if (stored === 'dark' || stored === 'light') return stored;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
}
```

---

## Color Reference Table

### Backgrounds

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `--color-bg-primary` | `#0d0c18` | `#f8f2e8` | Deepest background, body |
| `--color-bg-secondary` | `#1a1830` | `#ede4d5` | Page surface, sections |
| `--color-bg-tertiary` | `#141220` | `#e4d8c6` | Subtle layer between primary/secondary |
| `--color-bg-card` | `#211f38` | `#fdf8f0` | Cards, panels, sidebars |
| `--color-bg-modal` | `#252342` | `#fff9f0` | Modals, drawers |
| `--color-bg-overlay` | `rgba(0,0,0,0.72)` | `rgba(30,20,10,0.50)` | Scrim behind modals |

### Text

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `--color-text-primary` | `#e8e0d0` | `#1a1410` | Body text, main content |
| `--color-text-secondary` | `#b8a898` | `#4a3f35` | Labels, metadata, descriptions |
| `--color-text-disabled` | `#5a5068` | `#9a8878` | Disabled inputs and buttons |
| `--color-text-inverse` | `#0d0c18` | `#f8f2e8` | Text on gold/bright backgrounds |

### Gold Accent

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `--color-gold` | `#c9a84c` | `#8a6020` | Titles, CTAs, borders on focus |
| `--color-gold-light` | `#e8c96a` | `#c9a84c` | Hover states |
| `--color-gold-dark` | `#9a7a30` | `#5a3a10` | Pressed / active states |
| `--color-gold-muted` | `rgba(201,168,76,0.15)` | `rgba(138,96,32,0.12)` | Subtle highlight backgrounds |

### Clan Colors

| Clan | Archetype | Token | Dark | Light |
|------|-----------|-------|------|-------|
| Berserkers | FURY | `--color-clan-fury` | `#c0392b` | `#8b1e1e` |
| Valkirias | DIVINE | `--color-clan-divine` | `#4a90d9` | `#1a5fa0` |
| Jarls | IRON | `--color-clan-iron` | `#8a9ba8` | `#4a5e6e` |
| Skalds | SONG | `--color-clan-song` | `#8b5cf6` | `#5b34d6` |
| Seidr | RUNE | `--color-clan-rune` | `#10b981` | `#0a7a54` |
| Draugr | DEATH | `--color-clan-death` | `#7c6b9e` | `#5a4880` |

### Phase Colors

| Phase | Token | Dark | Light | Meaning |
|-------|-------|------|-------|---------|
| Preparation | `--color-phase-preparation` | `#4a90d9` | `#1a5fa0` | Calm, no combat |
| War | `--color-phase-war` | `#c0392b` | `#8b1e1e` | Active combat |
| End | `--color-phase-end` | `#c9a84c` | `#8a6020` | Endgame, glory |

---

## Usage Rules

1. **Never hardcode hex values in component `.scss` files.** Always use `var(--color-*)` or `$color-*`.
2. **Every new UI element** must use an existing token. If no token fits, propose a new one here first.
3. **Clan colors** are only used for clan-specific UI elements (borders, badges, territory highlights). Do not use them as general accent colors.
4. **Gold is the primary brand accent.** Use it for: titles, CTA buttons, active borders, progress fills on research. Do not use it for error or info states.
5. **Never use `--color-gold` as text color on a light background** — use `--color-gold` (dark value) instead. The SCSS tokens handle this automatically via CSS custom properties.
6. **Always test both themes** when creating or modifying a component. Use the `ThemeService.toggle()` method in development.
