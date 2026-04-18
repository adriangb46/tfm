---
description: refine_ui
---

# Workflow: /refine-ui

## Trigger

Invoked with `/refine-ui` from the Antigravity chat.

## Purpose

Iterate on any screen or modal with the user through a **preview-first loop**:
1. Read the screen spec from `ui_screens.md`.
2. Generate a static HTML preview the user can see immediately.
3. Wait for feedback.
4. Apply confirmed changes to the actual Angular component.

This workflow is designed so the user can refine the UI visually with minimal coding.

---

## Step 1 — Identify the target screen

Ask the user (or read from the prompt):

1. **Which screen or modal** are you refining? (e.g. "modal de tropas", "gamePage", "signIn")
2. **What do you want to change?** Options:
   - Layout / structure
   - Specific element (button, list, modal, progress bar)
   - Behaviour / interaction
   - Style / colors (requires `front_color_guide.md` — check if available)
   - All of the above (first iteration from scratch)

If the screen name is ambiguous, match it against the entries in `ui_screens.md` and confirm before proceeding.

---

## Step 2 — Read the screen spec

Open `.agents/ui_screens.md` and locate the entry for the target screen.

Extract:
- Layout elements
- All defined actions and their results
- Any notes or TBD items relevant to the requested change

**Do not add or remove any behaviour that is not described in `ui_screens.md` without explicitly asking the user first.**

---

## Step 3 — Generate the static HTML preview

Before touching any Angular file, produce a **self-contained HTML preview** that:

- Renders in a browser without any build step (no Angular, no Node)
- Accurately represents the layout described in `ui_screens.md`
- Uses inline CSS — no external dependencies except optionally a Google Font
- Applies the viking dark aesthetic from the mockup:
  - Background: `#1a1a2e` or similar dark navy/charcoal
  - Accent: `#c9a84c` (gold) for titles, borders, CTAs
  - Text: `#e8e0d0` (parchment off-white)
  - Danger/error: `#8b2222` (dark red)
  - If `front_color_guide.md` exists in `.agents/`, use those exact values instead
- Marks interactive elements (buttons, inputs, modals) visually but does not need real JS logic
- Is clearly labelled: `<!-- PREVIEW ONLY — not production code -->`

### Preview file naming

Save the preview as: `.agents/previews/<screen-name>-preview.html`

Present the file to the user and say:
> "Aquí tienes el preview de [screen name]. Dime qué quieres cambiar antes de que toque el componente Angular."

---

## Step 4 — Iterate on the preview

Repeat the following loop until the user confirms the preview is correct:

1. User describes what to change ("mueve el botón abajo", "quiero que la lista tenga scroll", "el color del título no me gusta")
2. Agent applies the change to the HTML preview file only
3. Agent presents the updated preview
4. Agent asks: "¿Algo más que cambiar, o lo llevamos al componente Angular?"

**Rules during iteration:**
- Only modify the preview file. Do NOT touch any Angular component during this phase.
- If the requested change contradicts the spec in `ui_screens.md`, flag it to the user:
  > "En ui_screens.md esto no está especificado así. ¿Quieres que actualicemos también la especificación?"
- If the user wants to change defined behaviour (not just style), update `ui_screens.md` first, then apply.

---

## Step 5 — Apply confirmed changes to the Angular component

Once the user confirms the preview, apply the design to the real Angular component.

### Locate the component

Match the screen name to its Angular component using the table in `ui_screens.md`:

| Screen | Component |
|--------|-----------|
| signUp | `SignUpComponent` |
| signIn | `SignInComponent` |
| lobby | `LobbyComponent` |
| crearPartida | `CrearPartidaModalComponent` |
| unirsePartida | `UnirsePartidaModalComponent` |
| lobbyPrevia | `LobbyPreviaComponent` |
| gamePage | `GamePageComponent` |
| tropas | `TropasModalComponent` |
| entrenarTropas | `EntrenarTropasModalComponent` |
| arbolTecnologico | `ArbolTecnologicoModalComponent` |
| modalTecnologia | `ModalTecnologiaComponent` |
| log | `LogModalComponent` |
| atacar | `AtacarModalComponent` |
| añadirTropaAtaque | `AñadirTropaAtaqueModalComponent` |
| estadísticas | `EstadisticasComponent` |
| userConfig | `UserConfigComponent` |
| cambiarContraseña | `CambiarContraseñaModalComponent` |
| adminPage | `AdminPageComponent` |

### Apply the changes following the Angular good practices rules

- Use Angular 20 standalone component conventions (see `angular_good_practices.md`)
- Template: `@if`, `@for`, `@switch` — never structural directives
- State: signals (`signal`, `computed`, `input`, `output`)
- Styles: `.scss` file — use CSS custom properties, not hardcoded colors
- No logic in the template beyond signal reads and event bindings

### Only modify files within the scope of this component

- The component `.ts` file
- The component `.html` template
- The component `.scss` styles

**Do NOT modify other components, services, or routing unless explicitly requested.**

---

## Step 6 — Report changes

After applying to Angular, list:

```
Preview generated:
  .agents/previews/<screen>-preview.html

Files modified:
  src/app/features/.../component.ts      → [what changed]
  src/app/features/.../component.html    → [what changed]
  src/app/features/.../component.scss    → [what changed]

Files NOT touched: everything else
```

Then ask:
> "¿Quieres refinar otra pantalla o ajustar algo de esta?"

---

## Quick-start examples

```
/refine-ui modal de tropas — primera iteración completa
/refine-ui gamePage — quiero reorganizar el sidebar
/refine-ui signIn — el formulario necesita validación visual de errores
/refine-ui arbolTecnologico — los nodos del árbol deben mostrar progreso
```
