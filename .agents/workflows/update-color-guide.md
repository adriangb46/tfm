---
description: a workflow that upgrade the colors of the front based in the color guide
---

# Workflow: /update-color-guide

## Trigger

Invoked with `/update-color-guide` from the Antigravity chat.

## Purpose

Propagate color changes from `front_color_guide.md` to all affected files in the Angular project.
Ensures no component ever has a stale or hardcoded color after a palette update.

---

## Step 1 — Identify what changed

Ask the user before touching anything:

1. **Which token(s) changed?** (e.g. `--color-gold`, `--color-clan-fury`, a whole group)
2. **Is this a value change** (same token name, new hex) or a **rename** (token name itself changed)?
3. **Is a new token being added**, or an existing one removed?
4. **Does the change affect dark mode, light mode, or both?**

> Do not modify any file until the scope is confirmed.

---

## Step 2 — Update `front_color_guide.md`

Location: `.agents/front_color_guide.md`

Apply the change to:
- The CSS custom properties block (`:root` / `[data-theme="dark"]` and `@mixin light-theme-vars`)
- The SCSS variables block
- The Color Reference Table at the bottom

If a token is **renamed**: update every occurrence of the old name in this file before touching any other file.
If a token is **removed**: flag it — removing a token requires verifying that no component references it.

---

## Step 3 — Update `tokens.scss`

Location: `front/src/styles/tokens.scss`

This file must mirror `front_color_guide.md` exactly.

- Value change → update the hex value in both `:root`/`[data-theme="dark"]` and `@mixin light-theme-vars`.
- Rename → find and replace the old CSS custom property name (`--color-old-name` → `--color-new-name`) in both theme blocks.
- New token → add to both theme blocks under the appropriate group comment.
- Removed token → delete from both theme blocks. Then proceed to Step 4 to verify no component breaks.

---

## Step 4 — Update `variables.scss`

Location: `front/src/styles/variables.scss`

This file wraps every custom property in an SCSS variable.

- Value change → no change needed here (the SCSS variable just points to the custom property).
- Rename → update the SCSS variable name AND the `var(--color-*)` reference inside it.
- New token → add the new SCSS variable pointing to the new custom property.
- Removed token → delete the SCSS variable.

---

## Step 5 — Scan for affected component files

Run a search across the Angular project for any references to the changed token(s).

Search targets:
- All `*.scss` files under `front/src/`
- All `*.html` files (inline styles, rarely)
- All `*.ts` files (ThemeService, dynamic style bindings)

Search for:
- The old CSS custom property: `var(--color-old-name)`
- The old SCSS variable: `$color-old-name`
- **Hardcoded hex values** matching the old color (flag these — they should not exist per the color rules, but verify)

Present the list of affected files to the user before making any changes:

```
Archivos afectados por el cambio de --color-gold → --color-brand:
- front/src/app/features/game/game-page/game-page.component.scss  (2 referencias)
- front/src/app/shared/button/button.component.scss               (1 referencia)
- front/src/styles/tokens.scss                                     (ya actualizado)
- front/src/styles/variables.scss                                  (ya actualizado)

¿Procedo a actualizar todos?
```

Wait for explicit confirmation before editing component files.

---

## Step 6 — Update affected component files

For each confirmed file:

- **Value change**: no action needed in component files — custom properties cascade automatically.
- **Rename**: replace old token name with new token name everywhere it appears.
- **New token**: only touch files where the user explicitly says to use the new token.
- **Removed token**: replace with the correct alternative token, or flag if unclear what the replacement should be.

Apply changes one file at a time. Do NOT batch-edit all files in a single tool call — each file must be individually verified.

**Collaboration rule:** Only touch files listed in the confirmed affected list. If during editing you notice an issue in a nearby file not on the list, report it as a suggestion — do not fix it unilaterally.

---

## Step 7 — Update `front_color_guide.md` preview (if it exists)

Location: `.agents/previews/color-guide-preview.html`

If a preview file exists for the color guide, update the hardcoded hex values in it to reflect the new palette.

---

## Step 8 — Update UI screen previews (if affected)

Location: `.agents/previews/*.html`

If any screen preview files exist AND the changed color was used in them (check for the old hex value):
- List the affected previews.
- Ask the user: "¿Actualizo también los previews de pantalla?"
- Only update if confirmed.

---

## Step 9 — Final checklist

- [ ] `front_color_guide.md` updated (source of truth)
- [ ] `tokens.scss` updated (both dark and light theme blocks)
- [ ] `variables.scss` updated (if rename or new/removed token)
- [ ] All component `.scss` files updated (if rename)
- [ ] No hardcoded hex values introduced
- [ ] Both dark and light mode values updated (never one without the other)
- [ ] Screen previews updated if applicable
- [ ] Files modified listed in the response

---

## Quick reference — token groups

When a user says "update the gold color" or "change the error color", these are the tokens in each group:

| Group | Tokens |
|-------|--------|
| Gold accent | `--color-gold`, `--color-gold-light`, `--color-gold-dark`, `--color-gold-muted` |
| Backgrounds | `--color-bg-primary/secondary/tertiary/card/modal/overlay` |
| Text | `--color-text-primary/secondary/disabled/inverse` |
| Borders | `--color-border-strong/default/faint` |
| Semantic | `--color-success/error/warning/info` + `-bg` variants |
| Phases | `--color-phase-preparation/war/end` |
| Clans | `--color-clan-fury/divine/iron/song/rune/death` |
| Progress | `--color-progress-track/health/training/research` |
