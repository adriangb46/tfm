---
description: check the arquitecture
---

# Workflow: /arch-audit

## Trigger

Invoked with `/arch-audit` from the Antigravity chat.

## Purpose

Verify that the actual codebase matches what is documented in the project's reference files.
Acts as a technical reviewer checking for drift between documentation and implementation.
Read-only — never modifies any file. All findings are reported, never auto-fixed.

---

## Step 1 — Load all reference documents

Read the following files in full before scanning any code:

| File | What it defines |
|------|----------------|
| `.agents/proyect_arquitecture.md` | Services, communication flows, REST API, DB schema, Time Wheel, GameStore shape, env vars |
| `.agents/rules/security.md` | Security rules that must be enforced at every layer |
| `.agents/rules/angular_good_practices.md` | Angular 20 conventions |
| `.agents/rules/java_good_practices.md` | Java 25 + Spring Boot conventions |
| `.agents/rules/javascript_good_practices.md` | Node.js + Express + Socket.IO conventions |
| `.agents/rules/typescript_good_practices.md` | TypeScript conventions |
| `.agents/ui_screens.md` | Frontend screen definitions, routes, component names |
| `.agents/front_color_guide.md` | Color tokens, theme system, ThemeService |

Do not begin scanning code until all reference documents are loaded.

---

## Step 2 — Scope definition

Ask the user before starting:

1. **Full audit** (default) — all layers and all reference files.
2. **Partial audit** — user specifies a layer or document (e.g. "only check the Middle Server against the architecture", "only check the frontend against ui_screens.md").

---

## Step 3 — Scan each layer against its reference

For each check, record:
- **Reference** — which document and section defines the expected behaviour
- **File path** — where the implementation was found (or not found)
- **Status** — ✅ PASS / ❌ FAIL / ⚪ NOT FOUND / 🔶 PARTIAL
- **Finding** — what is wrong or missing (only for FAIL / PARTIAL)
- **Fix** — concrete action needed to align with the documentation

---

### 3.1 — Global Architecture (from `proyect_arquitecture.md`)

**Services & Docker**
- [ ] All six services exist and are configured: `front`, `middle`, `db-server`, `postgres`, `mongodb`, `minio`, `redis`
- [ ] Internal services (postgres, mongodb, redis, minio:9001, db-server) are not exposed publicly
- [ ] Only `front` (80/443) and `middle` are exposed to the public network
- [ ] No container runs as root

**Environment variables**
- [ ] All variables listed in Section 12 of the architecture doc are present in `.env.example` or equivalent
- [ ] No variable from Section 12 is hardcoded anywhere in source code
- [ ] `.env` is in `.gitignore`

---

### 3.2 — Middle Server (from `proyect_arquitecture.md` + `javascript_good_practices.md`)

**Structure**
- [ ] Folder structure matches the documented layout (`config/`, `auth/`, `http/`, `socket/`, `game/engine/`, `game/state/`, `game/phases/`, `db/`, `utils/`)
- [ ] ES Modules used throughout (`import`/`export`, `"type": "module"` in `package.json`)
- [ ] No `require()` calls anywhere

**JWT & Auth**
- [ ] JWT issued with `jti` field (UUID)
- [ ] JWT payload contains exactly: `{ userId, characterId, clanId, jti, iat, exp }`
- [ ] Socket.IO auth middleware validates JWT before any event handler runs
- [ ] Logout writes `jti` to Redis blacklist
- [ ] `MIDDLE_JWT_SECRET` loaded from env

**Handshake token**
- [ ] On startup, Middle requests handshake token from DB Server (`POST /internal/auth/handshake`)
- [ ] Handshake token attached as `Authorization: Bearer` on every outbound call to DB Server
- [ ] On `401` from DB Server, Middle re-requests the token automatically

**Rate limiting**
- [ ] `express-rate-limit` + `rate-limit-redis` installed and configured
- [ ] Rate limiting applied to all public HTTP endpoints
- [ ] Limits per endpoint match Section 2.5 of the architecture doc (or documented deviation)

**GameStore**
- [ ] Single `GameStore` instance (`Map<gameId, GameState>`)
- [ ] `GameState` shape matches Section 11 of the architecture doc
- [ ] No game state stored in Redis, PostgreSQL, or MongoDB directly from the Middle (only via dump events)

**Time Wheel**
- [ ] Single `setInterval` — no scattered `setTimeout`/`setInterval` in other modules
- [ ] All event types from Section 10 are registered in the dispatcher switch
- [ ] `DB_DUMP_POSTGRES` and `DB_DUMP_MONGODB` events are NOT stored in `GameState.eventQueue`
- [ ] On startup, `recoverActiveGames()` is called before opening the socket

**Persistence dumps**
- [ ] PostgreSQL dump fires every `POSTGRES_DUMP_INTERVAL_MS` via Time Wheel
- [ ] MongoDB dump fires every `MONGODB_DUMP_INTERVAL_MS` via Time Wheel
- [ ] Both dump handlers are non-blocking (no `await` in the tick path)
- [ ] One retry on failure, logged clearly

**Socket.IO**
- [ ] All game events use `domain:action` naming pattern
- [ ] No raw `GameState` objects emitted to clients — client DTOs only
- [ ] On user disconnect, game continues (socket reference cleared, game not stopped)

**HTTP client to DB Server**
- [ ] All endpoints called match those defined in Section 4 of the architecture doc
- [ ] No endpoint called that is not documented
- [ ] `401` from DB Server triggers token refresh + one retry

**Code conventions**
- [ ] No `console.log` in production paths — structured logger (`pino`) used
- [ ] All exported functions have JSDoc with `@param` and `@returns`
- [ ] `const` used by default, `let` only when reassignment needed, no `var`
- [ ] `async/await` used — no raw `.then().catch()` chains
- [ ] Centralised Express error middleware present (4-argument function)

---

### 3.3 — DB Server (from `proyect_arquitecture.md` + `java_good_practices.md`)

**Structure**
- [ ] Folder structure matches the documented layout (`config/`, `security/`, `api/`, `api/dto/`, `domain/model/`, `domain/service/`, `domain/repository/`, `infrastructure/persistence/`, `infrastructure/mongodb/`)

**REST API**
- [ ] All endpoints in Section 4 of the architecture doc are implemented
- [ ] No endpoint exists that is not documented (ask user before flagging — may be intentional)
- [ ] All controllers are thin (no business logic — immediate delegation to service)
- [ ] All request DTOs use records with Bean Validation annotations
- [ ] No entity objects returned directly from controllers

**Security**
- [ ] `OncePerRequestFilter` validates handshake JWT on every request
- [ ] Handshake token issued on `POST /internal/auth/handshake`
- [ ] `DB_HANDSHAKE_SECRET` loaded from env

**PostgreSQL**
- [ ] All tables from Section 5 of the architecture doc exist in Flyway migrations
- [ ] `users` table has `avatar_url` column
- [ ] `game_state_dumps` table has index on `game_id`
- [ ] No `FetchType.EAGER` on any collection
- [ ] No `spring.jpa.hibernate.ddl-auto=create` in non-local profiles
- [ ] Flyway migrations used — no manual DDL outside migrations

**MongoDB**
- [ ] `game_snapshots` collection matches the schema in Section 6
- [ ] `battle_events` collection matches the schema in Section 6
- [ ] MongoDB writes are async (non-blocking)

**Code conventions**
- [ ] Constructor injection only (`@RequiredArgsConstructor`) — no `@Autowired` on fields
- [ ] `@Transactional` on all write service methods
- [ ] `@Transactional(readOnly = true)` on read-only service methods
- [ ] Records used for all DTOs
- [ ] No `any`-equivalent (raw types) in Java generics

---

### 3.4 — Frontend (from `angular_good_practices.md` + `ui_screens.md` + `typescript_good_practices.md`)

**Angular 20 conventions**
- [ ] All components are standalone (`standalone: true`)
- [ ] All components use `ChangeDetectionStrategy.OnPush`
- [ ] All dependencies injected via `inject()` — no constructor injection
- [ ] All inputs use `input()` or `input.required()` — no `@Input()`
- [ ] All outputs use `output()` — no `@Output() EventEmitter`
- [ ] Templates use `@if`, `@for`, `@switch` — no `*ngIf`, `*ngFor`, `*ngSwitch`
- [ ] All `@for` blocks have a `track` expression
- [ ] Socket.IO observables bridged to signals via `toSignal()`
- [ ] No `any` type anywhere in the codebase
- [ ] Path aliases used — no `../../..` relative imports

**Routing**
- [ ] All feature routes are lazy-loaded
- [ ] Functional guards used — no class-based guards
- [ ] Routes match the paths defined in `ui_screens.md`

**Screen coverage (from `ui_screens.md`)**

For each screen, verify the Angular component exists and matches the documented component name:

| Screen | Expected component | Route |
|--------|-------------------|-------|
| signUp | `SignUpComponent` | `/signup` |
| signIn | `SignInComponent` | `/signin` |
| lobby | `LobbyComponent` | `/lobby` |
| crearPartida | `CrearPartidaModalComponent` | modal |
| unirsePartida | `UnirsePartidaModalComponent` | modal |
| lobbyPrevia | `LobbyPreviaComponent` | `/game/:gameId/lobby` |
| gamePage | `GamePageComponent` | `/game/:gameId` |
| tropas | `TropasModalComponent` | modal |
| entrenarTropas | `EntrenarTropasModalComponent` | modal |
| arbolTecnologico | `ArbolTecnologicoModalComponent` | modal |
| modalTecnologia | `ModalTecnologiaComponent` | modal |
| log | `LogModalComponent` | modal |
| atacar | `AtacarModalComponent` | modal |
| añadirTropaAtaque | `AñadirTropaAtaqueModalComponent` | modal |
| estadísticas | `EstadisticasComponent` | `/stats/user` or `/stats/game/:gameId` |
| userConfig | `UserConfigComponent` | `/config` |
| cambiarContraseña | `CambiarContraseñaModalComponent` | modal |
| adminPage | `AdminPageComponent` | `/admin` |

**Color system (from `front_color_guide.md`)**
- [ ] `tokens.scss` exists and defines all tokens from the color guide
- [ ] `variables.scss` exists and wraps all tokens as SCSS variables
- [ ] `ThemeService` exists with signal-based theme toggle
- [ ] No hardcoded hex values in any component `.scss` file
- [ ] Both dark and light theme blocks are defined

---

### 3.5 — Game Data (from `clans.yml` + `proyect_arquitecture.md`)

- [ ] `clans.yml` is loaded at Middle Server startup
- [ ] All 6 clans defined in `clans.yml` are handled by the clan loader
- [ ] Clan advantage matrix (`CLAN_ADVANTAGES` constant) matches Section 7.2 of the architecture doc
- [ ] `ADVANTAGE_MULTIPLIER` loaded from env, not hardcoded
- [ ] Ultimate troop resolution path exists and is separate from standard combat

---

### 3.6 — Avatar Upload (from `proyect_arquitecture.md` Section 2.4)

- [ ] Middle Server has `POST /users/avatar` endpoint (multipart)
- [ ] `sharp` used for resize to 200×200 px
- [ ] File stored in MinIO bucket `avatars` with UUID filename
- [ ] `PUT /internal/users/{id}/avatar` called on DB Server after successful upload
- [ ] File type validated by magic bytes (not Content-Type)
- [ ] File size limit enforced before processing

---

## Step 4 — Scoring

| Status | Points impact |
|--------|--------------|
| ✅ PASS | +0 (expected baseline) |
| 🔶 PARTIAL | -3 pts |
| ❌ FAIL | -8 pts |
| ⚪ NOT FOUND | -5 pts (component/file does not exist yet) |

Score starts at **100**. Deductions are cumulative with no cap per category.

---

## Step 5 — Produce the report

```
╔══════════════════════════════════════════════════════╗
║        ARCHITECTURE AUDIT — Viking Clan Wars         ║
║                   [DATE / SCOPE]                     ║
╚══════════════════════════════════════════════════════╝

GLOBAL SCORE: [X / 100]

  ❌ FAIL        [N]  —  implementation contradicts documentation
  🔶 PARTIAL     [N]  —  partially implemented or partially documented
  ⚪ NOT FOUND   [N]  —  component or file not yet created
  ✅ PASS        [N]  —  fully aligned

──────────────────────────────────────────────────────

❌ FAILURES  (implementation contradicts documentation)
───────────────────────────────────────────────────────

[F-01] <Short title>
  Reference:  <doc file> — Section N
  File:       <path/to/file> (line N)
  Found:      <what the code actually does>
  Expected:   <what the documentation says it should do>
  Fix:        <concrete action>

...

──────────────────────────────────────────────────────

🔶 PARTIAL  (incomplete implementation)
────────────────────────────────────────

[P-01] <Short title>
  Reference:  <doc file> — Section N
  File:       <path/to/file>
  Status:     <what is done / what is missing>
  Fix:        <what needs to be completed>

...

──────────────────────────────────────────────────────

⚪ NOT FOUND  (not yet implemented)
─────────────────────────────────────

[N-01] <Component or file name>
  Expected at:  <path where it should exist>
  Defined in:   <doc file> — Section N
  Note:         <any relevant context — e.g. "blocked by TBD in architecture doc">

...

──────────────────────────────────────────────────────

✅ PASSING CHECKS ([N] total)
──────────────────────────────
<brief list — one line per passing check>

──────────────────────────────────────────────────────

DOCUMENTATION GAPS DETECTED
─────────────────────────────
List any implementation found in the code that is NOT documented
in any reference file. These are not necessarily bugs — they may
be intentional additions — but they should be documented.

[D-01] <What was found in code but not in docs>
  File:  <path>
  Action: Add to the relevant reference document, or remove if unintentional.

──────────────────────────────────────────────────────

RECOMMENDED ACTION ORDER
──────────────────────────
1. Resolve ❌ FAIL items — code contradicts the agreed design.
2. Resolve 🔶 PARTIAL items — incomplete implementations may cause runtime issues.
3. Plan ⚪ NOT FOUND items — schedule implementation.
4. Review DOCUMENTATION GAPS — decide whether to document or remove.
```

---

## Step 6 — Rules for this workflow

- **Read-only.** Never modifies, creates, or deletes any file.
- **Reference-anchored.** Every finding must cite the specific document and section that defines the expected behaviour. No generic "best practice" findings — those belong to `/security-audit`.
- **Documentation gaps are not failures.** Code that exists but is not documented is flagged separately — it may be intentional. The user decides.
- **TBD items in the architecture doc are not failures.** If a section is marked `[TBD]` or `[PROPOSED]`, skip that check and note it as `⚪ NOT EVALUATED — TBD in architecture doc`.
- **Collaboration rule:** this workflow only reads files. It does not count as a modification for the purposes of `collaboration.md`.
- After the report, ask: "¿Quieres que genere tareas concretas para los items ❌ FAIL ordenadas por impacto?"
