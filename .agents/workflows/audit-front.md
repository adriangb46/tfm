---
description: auditar el front
---

# Workflow: /audit-front

## Trigger

Invoked with `/audit-front` from the Antigravity chat.

## Purpose

Audit the Angular frontend implementation against the project's architecture, rules, and UI spec.
Read-only — never modifies any file.

---

## Step 1 — Load reference documents

| File | Relevant sections |
|------|------------------|
| `.agents/proyect_arquitecture.md` | Sections 2.1, 3.1, 3.3 |
| `.agents/rules/angular_good_practices.md` | All |
| `.agents/rules/typescript_good_practices.md` | All |
| `.agents/rules/security.md` | Sections 1, 4, 5, 7, 8, 11 |
| `.agents/ui_screens.md` | All — component names, routes, actions |
| `.agents/front_color_guide.md` | All — tokens, ThemeService, no hardcoded hex |

---

## Step 2 — Scan checklist

---

### BLOCK A — Project structure & TypeScript config

```
A-01  strict: true in tsconfig.json
      REF: typescript_good_practices.md#compiler-configuration

A-02  noUncheckedIndexedAccess: true in tsconfig.json
      REF: typescript_good_practices.md#compiler-configuration

A-03  exactOptionalPropertyTypes: true in tsconfig.json
      REF: typescript_good_practices.md#compiler-configuration

A-04  Path aliases configured in tsconfig.json — no ../../../ relative imports
      REF: typescript_good_practices.md#modules-and-imports

A-05  Target ES2022 or higher
      REF: typescript_good_practices.md#compiler-configuration

A-06  Folder structure matches documented layout:
      core/, shared/, features/lobby/, features/game/board|troops|tech-tree|clans/,
      features/end-screen/
      REF: angular_good_practices.md#file-and-folder-structure

A-07  ESLint with @typescript-eslint configured — no lint errors
      REF: typescript_good_practices.md#general-rules

A-08  No any type anywhere in the codebase
      REF: typescript_good_practices.md#any-and-unknown
```

---

### BLOCK B — Angular 20 component conventions

```
B-01  All components have standalone: true
      REF: angular_good_practices.md#component-architecture

B-02  All components have ChangeDetectionStrategy.OnPush
      REF: angular_good_practices.md#component-architecture

B-03  All dependencies injected via inject() — no constructor injection
      REF: angular_good_practices.md#dependency-injection

B-04  All inputs use input() or input.required() — no @Input() decorator
      REF: angular_good_practices.md#inputs-and-outputs

B-05  All outputs use output() — no @Output() EventEmitter
      REF: angular_good_practices.md#inputs-and-outputs

B-06  Templates use @if, @for, @switch — no *ngIf, *ngFor, *ngSwitch
      REF: angular_good_practices.md#template-syntax

B-07  All @for blocks have a track expression with a unique stable field
      REF: angular_good_practices.md#template-syntax

B-08  No NgModules anywhere in the codebase
      REF: angular_good_practices.md#component-architecture

B-09  No DOM manipulation — no document.getElementById, no ElementRef.nativeElement
      direct manipulation
      REF: angular_good_practices.md#general-rules
```

---

### BLOCK C — Signals

```
C-01  Signals used as primary reactive primitive for local state (signal, computed, effect)
      REF: angular_good_practices.md#signals

C-02  No BehaviorSubject or Subject used for component-level state
      REF: angular_good_practices.md#signals

C-03  Singleton services expose state as readonly signals: asReadonly()
      REF: angular_good_practices.md#signals

C-04  Socket.IO observables bridged to signals at component boundary via toSignal()
      REF: angular_good_practices.md#signals, angular_good_practices.md#socketio-integration

C-05  takeUntilDestroyed() used on any manual subscription
      REF: angular_good_practices.md#signals
```

---

### BLOCK D — Routing

```
D-01  All feature routes are lazy loaded (loadComponent)
      REF: angular_good_practices.md#routing

D-02  Functional guards used (CanActivateFn) — no class-based guards
      REF: angular_good_practices.md#routing

D-03  withComponentInputBinding() configured in provideRouter()
      REF: angular_good_practices.md#routing

D-04  Routes match the paths defined in ui_screens.md:
      /signup, /signin, /lobby, /game/:gameId/lobby, /game/:gameId,
      /stats/user, /stats/game/:gameId, /config, /admin
      REF: ui_screens.md (all screen entries)
```

---

### BLOCK E — HTTP & authentication

```
E-01  All HTTP calls to Middle include Authorization: Bearer in header
      via an HttpInterceptorFn (not manually per-call)
      REF: angular_good_practices.md#http-communication

E-02  JWT stored in memory only — NOT in localStorage or sessionStorage
      REF: security.md#section-7, angular_good_practices.md#general-rules

E-03  Errors handled at service level via catchError — no raw HTTP errors in components
      REF: angular_good_practices.md#http-communication

E-04  HttpClient calls are fully typed with generics — no untyped requests
      REF: angular_good_practices.md#http-communication
```

---

### BLOCK F — Socket.IO integration

```
F-01  Socket.IO client wrapped in a singleton SocketService (providedIn: 'root')
      REF: angular_good_practices.md#socketio-integration

F-02  Socket events exposed as RxJS Observables in SocketService
      REF: angular_good_practices.md#socketio-integration

F-03  Observables converted to signals at component boundary via toSignal()
      (not subscribed to directly in components)
      REF: angular_good_practices.md#socketio-integration

F-04  JWT attached in Socket.IO handshake (auth option)
      REF: proyect_arquitecture.md#section-3.1

F-05  Socket.off() called on observable teardown (no memory leaks)
      REF: angular_good_practices.md#socketio-integration
```

---

### BLOCK G — Screen coverage (from ui_screens.md)

For each screen verify: component file exists, component name matches, route is correct.

```
G-01  signUp      → SignUpComponent        @ /signup
G-02  signIn      → SignInComponent        @ /signin
G-03  lobby       → LobbyComponent         @ /lobby
G-04  crearPartida        → CrearPartidaModalComponent       (modal)
G-05  unirsePartida       → UnirsePartidaModalComponent      (modal)
G-06  lobbyPrevia         → LobbyPreviaComponent             @ /game/:gameId/lobby
G-07  gamePage            → GamePageComponent                @ /game/:gameId
G-08  tropas              → TropasModalComponent             (modal)
G-09  entrenarTropas      → EntrenarTropasModalComponent     (modal)
G-10  arbolTecnologico    → ArbolTecnologicoModalComponent   (modal)
G-11  modalTecnologia     → ModalTecnologiaComponent         (modal)
G-12  log                 → LogModalComponent                (modal)
G-13  atacar              → AtacarModalComponent             (modal)
G-14  añadirTropaAtaque   → AñadirTropaAtaqueModalComponent  (modal)
G-15  estadísticas        → EstadisticasComponent            @ /stats/user | /stats/game/:gameId
G-16  userConfig          → UserConfigComponent              @ /config
G-17  cambiarContraseña   → CambiarContraseñaModalComponent  (modal)
G-18  adminPage           → AdminPageComponent               @ /admin

REF: ui_screens.md (all entries)
```

---

### BLOCK H — Screen behaviour (from ui_screens.md)

Spot-check: for each screen that IS implemented, verify its defined actions are present.

```
H-01  signUp: username + password + repeat-password fields, "REGISTRARSE" CTA,
      link to signIn, inline validation errors shown
      REF: ui_screens.md#1-signup

H-02  signIn: username + password fields, "INICIAR SESIÓN" CTA,
      generic error on wrong credentials (not field-specific)
      REF: ui_screens.md#2-signin, security.md#section-3

H-03  lobby: active games list shows Entrar + Salir buttons,
      finished games list shows Estadísticas + Borrar buttons,
      Salir (active) shows confirmation modal before abandoning
      REF: ui_screens.md#3-lobby

H-04  lobbyPrevia: Iniciar Partida button disabled for non-host,
      player list updates in real time (Socket.IO, no polling)
      REF: ui_screens.md#6-lobbyprevia

H-05  gamePage: attacks disabled during Preparation phase,
      all state from Socket.IO push (no frontend calculation of outcomes)
      REF: ui_screens.md#7-gamepage, proyect_arquitecture.md#section-2.1

H-06  entrenarTropas: Entrenar button disabled when insufficient credits or
      troop requires unresearched tech
      REF: ui_screens.md#9-entrenar-tropas

H-07  arbolTecnologico: nodes show correct state
      (locked / available / in-progress / completed)
      REF: ui_screens.md#10-arbol-tecnologico

H-08  atacar: ATACAR button disabled with no troops selected
      REF: ui_screens.md#13-atacar

H-09  adminPage: only rendered/accessible if user has admin role
      (not just hidden — route guard prevents access)
      REF: ui_screens.md#18-adminpage, security.md#section-5
```

---

### BLOCK I — Color system

```
I-01  tokens.scss exists and defines ALL custom properties from front_color_guide.md
      Both dark and light theme blocks present
      REF: front_color_guide.md#implementation

I-02  variables.scss exists and wraps all tokens as SCSS variables
      REF: front_color_guide.md#implementation

I-03  ThemeService exists with:
      - signal-based theme state
      - reads initial theme from localStorage + prefers-color-scheme
      - applies data-theme attribute to document.documentElement
      - persists choice to localStorage
      REF: front_color_guide.md#implementation

I-04  No hardcoded hex values in any component .scss file
      (scan all .scss files for #[0-9a-fA-F]{3,6} not inside tokens.scss/variables.scss)
      REF: front_color_guide.md#usage-rules

I-05  Both dark and light modes visually correct
      (check that all text tokens are readable on their respective backgrounds)
      REF: front_color_guide.md#color-reference-table

I-06  Clan colors used only for clan-specific UI elements
      (not as general accent colors)
      REF: front_color_guide.md#usage-rules
```

---

### BLOCK J — TypeScript conventions

```
J-01  interface used for object shapes, type used for unions/intersections
      REF: typescript_good_practices.md#types-vs-interfaces

J-02  const object + typeof pattern used instead of TypeScript enum
      REF: typescript_good_practices.md#enums

J-03  No non-null assertion operator (!) without an explanatory comment
      REF: typescript_good_practices.md#null-safety

J-04  All exported/public functions have explicit return types
      REF: typescript_good_practices.md#functions

J-05  No default exports (except where Angular requires)
      REF: typescript_good_practices.md#modules-and-imports

J-06  unknown used instead of any for truly unknown data —
      type guards written for Socket.IO payloads and HTTP responses
      REF: typescript_good_practices.md#any-and-unknown
```

---

### BLOCK K — Security (frontend-specific)

```
K-01  No user-provided content rendered via [innerHTML] binding
      REF: security.md#section-4

K-02  No eval() or new Function() anywhere in the codebase
      REF: security.md#section-4

K-03  JWT not stored in localStorage or sessionStorage
      REF: security.md#section-7

K-04  Game outcomes never calculated on the frontend
      (all resolution done by Middle, frontend only displays results)
      REF: proyect_arquitecture.md#section-2.1

K-05  Admin route (/admin) protected by a route guard that checks server-side role,
      not a JWT payload claim
      REF: security.md#section-5

K-06  No sensitive data (userId, characterId, gameId internal details) in URL query params
      REF: security.md#section-1
```

---

### BLOCK L — Testing

```
L-01  Unit tests exist for all components with business logic
      (signal inputs produce correct computed outputs, output emitters fire correctly)
      REF: .agents/workflows/create_unit_test.md

L-02  SocketService mocked in component tests — no real socket connections in unit tests
      REF: angular_good_practices.md#socketio-integration

L-03  HttpTestingController used for HTTP service tests
      REF: angular_good_practices.md#http-communication

L-04  No test depends on execution order (fully isolated)
      REF: .agents/workflows/create_unit_test.md
```

---

## Step 3 — Score

| Result | Points |
|--------|--------|
| ✅ PASS | +0 |
| 🔶 PARTIAL | -3 |
| ❌ FAIL | -8 |
| ⚪ NOT FOUND | -5 |

Start at **100**.

---

## Step 4 — Report format

```
╔══════════════════════════════════════════════════════╗
║          FRONTEND AUDIT — Viking Clan Wars           ║
║                   [DATE / SCOPE]                     ║
╚══════════════════════════════════════════════════════╝

SCORE: [X / 100]

  ❌ FAIL      [N]   ·   🔶 PARTIAL  [N]
  ⚪ NOT FOUND [N]   ·   ✅ PASS     [N]

BLOCKS:
  A - Project Structure & TS Config    [score/total]
  B - Angular Component Conventions    [score/total]
  C - Signals                          [score/total]
  D - Routing                          [score/total]
  E - HTTP & Auth                      [score/total]
  F - Socket.IO Integration            [score/total]
  G - Screen Coverage                  [score/total]
  H - Screen Behaviour                 [score/total]
  I - Color System                     [score/total]
  J - TypeScript Conventions           [score/total]
  K - Security                         [score/total]
  L - Testing                          [score/total]

──────────────────────────────────────────────────────
[same finding format as /audit-db-server]
──────────────────────────────────────────────────────
```

After the report ask:
> "¿Quieres que genere las tareas de corrección para los ❌ FAIL ordenadas por impacto?"

---

## Rules

- Read-only. Never modifies any file.
- Every finding cites its check ID and reference document + section.
- TBD items in architecture doc or ui_screens.md → ⚪ NOT EVALUATED — TBD.
- Screen behaviour checks (Block H) only apply to screens that ARE implemented —
  mark unimplemented screens as ⚪ NOT FOUND in Block G, not as FAIL in Block H.
- Does not count as a file modification per collaboration.md.
