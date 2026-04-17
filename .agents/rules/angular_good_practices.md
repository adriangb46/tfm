# Angular 20 Good Practices

## Component Architecture

- Always use **standalone components**. Never use NgModules.
- Declare components with `standalone: true` (default in Angular 20, but be explicit for clarity).
- Keep components small and single-responsibility. If a component exceeds ~200 lines, split it.
- Use **OnPush change detection** by default on every component: `changeDetection: ChangeDetectionStrategy.OnPush`.
- Prefer **zoneless change detection** when possible using `provideExperimentalZonelessChangeDetection()`.

## Signals — State Management

- Use **signals** as the primary reactive primitive for local component state: `signal()`, `computed()`, `effect()`.
- Never use `BehaviorSubject` or `Subject` for component-level state. Reserve RxJS for async streams (HTTP, WebSocket events).
- Expose state from services as `readonly` signals: `readonly count = this.#count.asReadonly()`.
- Use `linkedSignal()` for derived writable state.
- Use `toSignal()` to bridge RxJS observables into signals at the boundary layer (e.g. Socket.IO event streams from the middle server).
- Use `toObservable()` when you need to pass a signal value into an RxJS pipeline.
- Use `resource()` or `httpResource()` for async data fetching tied to signal inputs.

## Dependency Injection

- Always use the `inject()` function. Never use constructor injection.
  ```typescript
  // ✅ Correcto
  private readonly gameService = inject(GameService);

  // ❌ Incorrecto
  constructor(private gameService: GameService) {}
  ```
- Use `providedIn: 'root'` for singleton services (auth, socket, game state).
- Scope services to a specific route or component tree using `providers: []` in the route or component when the service must not be shared globally.

## Template Syntax

- Use the **new control flow syntax** exclusively. Never use structural directives.
  ```html
  <!-- ✅ Correcto -->
  @if (isLoading()) {
    <app-spinner />
  } @else {
    <app-game-board [state]="gameState()" />
  }

  @for (troop of troops(); track troop.id) {
    <app-troop-card [troop]="troop" />
  } @empty {
    <p>No troops deployed</p>
  }

  @switch (phase()) {
    @case ('preparation') { <app-preparation-panel /> }
    @case ('war') { <app-war-panel /> }
    @case ('end') { <app-end-panel /> }
  }
  ```
- Use `@defer` blocks for heavy components (tech tree, statistics panels) to improve initial load time.
- Always provide a `track` expression in `@for` using a unique, stable identifier (e.g. `troop.id`, `clan.id`).

## Inputs & Outputs

- Use **signal inputs**: `input()`, `input.required()`.
- Use **model inputs** for two-way binding: `model()`.
- Use `output()` for event emitting. Never use `@Output() EventEmitter`.
  ```typescript
  // ✅ Correcto
  readonly troopId = input.required<string>();
  readonly selected = output<Troop>();
  ```

## Routing

- Use **lazy loading** for all feature routes.
- Define routes as constants with the `Routes` type. Never inline route objects without typing.
- Use **functional route guards** (`CanActivateFn`, `CanMatchFn`). Never use class-based guards.
- Use `withComponentInputBinding()` so route params are automatically bound to signal inputs.

## HTTP Communication

- Use `HttpClient` with full generic typing on all requests.
- Use `httpResource()` for data that maps naturally to a signal-based resource lifecycle.
- All HTTP calls to the middle server must include the JWT in the `Authorization: Bearer <token>` header via an `HttpInterceptorFn`.
- Handle errors at the service level using `catchError`. Never let raw HTTP errors propagate to components.

## Socket.IO Integration

- Wrap the Socket.IO client in a dedicated `SocketService` (singleton, `providedIn: 'root'`).
- Expose socket events as RxJS `Observable`s and convert them to signals at the component boundary using `toSignal()`.
- Always unsubscribe / destroy signal effects when a component is destroyed. Use `DestroyRef` with `takeUntilDestroyed()`.

## File & Folder Structure

```
src/
  app/
    core/           # Singleton services, interceptors, guards
    shared/         # Reusable standalone components, pipes, directives
    features/
      lobby/
      game/
        board/
        troops/
        tech-tree/
        clans/
      end-screen/
```

## Naming Conventions

- Files: `kebab-case` — e.g. `troop-card.component.ts`, `game-state.service.ts`
- Classes: `PascalCase` — e.g. `TroopCardComponent`, `GameStateService`
- Signals and variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Code in **English**. Comments in **Spanish**.

## General Rules

- Enable **strict mode** in `tsconfig.json`: `"strict": true`.
- Never use `any`. Use `unknown` and narrow with type guards.
- Always add explicit return types to public service methods.
- Do not manipulate the DOM directly. Use Angular APIs or signals.
- Do not store sensitive data (JWT, user info) in `localStorage`. Use memory or a secure cookie strategy agreed with the middle server team.
