---
name: new-angular-component
description: Use this skill when the user wants to create a new Angular component, page, or UI element. Triggers on phrases like "nuevo componente", "crear pantalla", "vista de juego", "panel de tropas", "componente angular", "nueva página", or any request to build a frontend UI piece.
---

# Skill: New Angular 20 Standalone Component

## Context

- **Angular 20**, standalone components only. No NgModules.
- State management via **signals** (`signal`, `computed`, `effect`, `input`, `output`, `model`).
- Dependency injection via `inject()` — never constructor injection.
- `ChangeDetectionStrategy.OnPush` on every component.
- New control flow syntax: `@if`, `@for`, `@switch`, `@defer`.
- Code in **English**. Comments in **Spanish**.

---

## Step 1 — Clarify the component

Before generating any file, confirm with the user:

1. **Name and purpose** — what does this component do? One sentence.
2. **Location** — which feature folder does it belong to?
   ```
   front/src/app/features/
     lobby/
     game/
       board/
       troops/
       tech-tree/
       clans/
     end-screen/
   ```
3. **Inputs** — what data does it receive from its parent? Define types.
4. **Outputs** — what events does it emit to its parent?
5. **Services it needs** — `GameStateService`? `SocketService`? Others?
6. **Does it subscribe to Socket.IO events?** If yes, which ones?

Do not generate files until these are confirmed.

---

## Step 2 — Generate the component file

Location: `front/src/app/features/<feature>/<component-name>/<component-name>.component.ts`

```typescript
import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';
import { CommonModule } from '@angular/common'; // solo si se necesita algún pipe
// importar servicios y tipos necesarios

@Component({
  selector: 'app-<component-name>',
  standalone: true,
  imports: [
    // solo los módulos y componentes realmente usados en el template
  ],
  templateUrl: './<component-name>.component.html',
  styleUrl: './<component-name>.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class <ComponentName>Component {

  // --- Dependencias (inject, no constructor) ---
  // private readonly gameService = inject(GameStateService);

  // --- Inputs ---
  // readonly troopId = input.required<string>();
  // readonly isSelected = input<boolean>(false);

  // --- Outputs ---
  // readonly selected = output<string>();

  // --- Estado local ---
  // readonly #count = signal(0);
  // readonly count = this.#count.asReadonly();

  // --- Derivados (computed) ---
  // readonly displayLabel = computed(() => `Tropa: ${this.troopId()}`);

  // --- Handlers ---
  // onSelect(): void {
  //   this.selected.emit(this.troopId());
  // }
}
```

---

## Step 3 — Generate the template file

Location: `./<component-name>.component.html`

```html
<!-- <ComponentName>: <descripción breve en español> -->

@if (/* condición */) {
  <!-- contenido cuando la condición es verdadera -->
} @else {
  <!-- contenido alternativo -->
}

@for (item of items(); track item.id) {
  <!-- elemento de lista -->
} @empty {
  <p>No hay elementos</p>
}
```

Rules:
- Never use `*ngIf`, `*ngFor`, `*ngSwitch`. Use `@if`, `@for`, `@switch`.
- Always provide `track` with a unique stable field in `@for`.
- Never access a signal in the template without calling it: `signal()` not `signal`.
- Use `@defer` for heavy sub-components (e.g. tech tree, statistics panel).

---

## Step 4 — Generate the style file

Location: `./<component-name>.component.scss`

- Use CSS custom properties from the design system (defined in `styles/tokens.scss` or equivalent).
- Do not use inline styles in the template.
- Keep styles scoped — Angular's view encapsulation handles this by default.

---

## Step 5 — Socket.IO integration (if the component needs real-time data)

If the component displays data pushed by the Middle Server:

```typescript
// En el componente, convertir el Observable del SocketService a signal
private readonly socketService = inject(SocketService);

// Escuchar un evento socket y exponerlo como signal
readonly battleResult = toSignal(
  this.socketService.onBattleResult(),   // Observable<BattleResult>
  { initialValue: null },
);
```

Rules:
- Always use `toSignal()` to bridge observables to signals at the component boundary.
- If subscribing manually (not via `toSignal`), use `takeUntilDestroyed()` with `DestroyRef`.
- Never subscribe to a socket event in a service and then push to a component via a `Subject`. Use the signal pattern above.

---

## Step 6 — Register the component where it is used

The component is standalone — add it to the `imports` array of the parent component or to the route definition:

```typescript
// En el componente padre
imports: [
  // ...otros imports
  <ComponentName>Component,
],
```

Or in the route for a routed component:

```typescript
{
  path: '<path>',
  loadComponent: () =>
    import('./<component-name>/<component-name>.component').then(m => m.<ComponentName>Component),
}
```

---

## Step 7 — Generate a basic spec file

Location: `./<component-name>.component.spec.ts`

Apply the `create_unit_test` workflow to generate the test. At minimum:
- Component instantiates without errors.
- Signal inputs produce correct `computed` outputs.
- Output emitters fire correctly on user interaction.

---

## Step 8 — Checklist before finishing

- [ ] `standalone: true` declared.
- [ ] `ChangeDetectionStrategy.OnPush` set.
- [ ] All dependencies via `inject()`, not constructor.
- [ ] All inputs use `input()` or `input.required()`.
- [ ] All outputs use `output()`, not `@Output() EventEmitter`.
- [ ] Template uses `@if`/`@for`/`@switch`, not structural directives.
- [ ] `@for` has a `track` expression.
- [ ] Socket.IO observables bridged to signals via `toSignal()`.
- [ ] No `any` in the component or its types.
- [ ] Component registered in the parent imports or as a lazy route.
- [ ] Basic spec file created.
- [ ] Files modified listed at the end of the response.
