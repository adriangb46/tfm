---
description: auditar el middle
---

# Workflow: /audit-middle

## Trigger

Invoked with `/audit-middle` from the Antigravity chat.

## Purpose

Audit the `middle` server implementation against the project's architecture and rules.
Read-only — never modifies any file.

---

## Step 1 — Load reference documents

| File | Relevant sections |
|------|------------------|
| `.agents/proyect_arquitecture.md` | Sections 2.2, 2.5, 3.1, 3.2, 3.3, 4, 10, 11, 12 |
| `.agents/rules/javascript_good_practices.md` | All |
| `.agents/rules/security.md` | All |

---

## Step 2 — Scan checklist

---

### BLOCK A — Project structure & module system

```
A-01  Folder structure matches documented layout:
      config/, auth/, http/, socket/, game/engine/, game/state/,
      game/phases/, db/, utils/
      REF: javascript_good_practices.md#module-system

A-02  ES Modules throughout: "type": "module" in package.json
      REF: javascript_good_practices.md#module-system

A-03  No require() calls anywhere in the codebase
      REF: javascript_good_practices.md#module-system

A-04  All configuration from environment variables — single frozen config object exported
      REF: javascript_good_practices.md#environment-and-configuration

A-05  All required env vars validated at startup — process exits with clear message if missing
      REF: javascript_good_practices.md#environment-and-configuration

A-06  All env vars from architecture Section 12 that apply to the Middle are present
      in config or .env.example:
      PORT, MIDDLE_JWT_SECRET, DB_HANDSHAKE_SECRET, DB_SERVER_URL,
      REDIS_URL, RATE_LIMIT_*, MINIO_*, POSTGRES_DUMP_INTERVAL_MS,
      MONGODB_DUMP_INTERVAL_MS, TIME_WHEEL_TICK_MS, ADVANTAGE_MULTIPLIER
      REF: proyect_arquitecture.md#section-12

A-07  .env is in .gitignore — no secrets committed
      REF: security.md#section-7

A-08  Structured logger (pino) used — no console.log in production paths
      REF: javascript_good_practices.md#general-rules, security.md#section-11

A-09  ESLint configured (flat config eslint.config.js) — no lint errors
      REF: javascript_good_practices.md#general-rules
```

---

### BLOCK B — JWT — user tokens

```
B-01  JWT issued on login with payload:
      { userId, characterId, clanId, jti (UUID), iat, exp }
      REF: security.md#section-2, proyect_arquitecture.md#section-3.1

B-02  MIDDLE_JWT_SECRET loaded from env — never hardcoded
      REF: security.md#section-7

B-03  jti is a UUID — unique per token, not a sequential number
      REF: security.md#section-2

B-04  On logout: jti written to Redis blacklist with TTL = remaining token validity
      REF: security.md#section-2, proyect_arquitecture.md#section-2.5

B-05  Auth middleware: verifies JWT signature first, then checks Redis blacklist
      (order matters — signature check is cheap, Redis call is network I/O)
      REF: security.md#section-2

B-06  JWT contents (full token string) never logged at any log level
      REF: security.md#section-11

B-07  Token stored in memory on the client side — middleware never reads tokens
      from query params or cookies
      REF: security.md#section-1
```

---

### BLOCK C — JWT — handshake token (Middle → DB Server)

```
C-01  On startup: Middle calls POST /internal/auth/handshake to get handshake token
      before processing any requests
      REF: proyect_arquitecture.md#section-3.2

C-02  Handshake token attached as Authorization: Bearer on every outbound HTTP call
      to the DB Server
      REF: proyect_arquitecture.md#section-3.2

C-03  On 401 from DB Server: Middle automatically re-requests handshake token
      and retries the original call once
      REF: proyect_arquitecture.md#section-3.2

C-04  Handshake token stored in memory only — not persisted to disk or Redis
      REF: security.md#section-7
```

---

### BLOCK D — Redis (JWT blacklist + rate limiting)

```
D-01  Redis connection uses REDIS_URL from env
      REF: proyect_arquitecture.md#section-12

D-02  JWT blacklist entries stored with TTL = remaining token validity time
      (Redis auto-expires — entries do not accumulate forever)
      REF: proyect_arquitecture.md#section-2.5

D-03  Rate limiting uses express-rate-limit + rate-limit-redis as store
      REF: proyect_arquitecture.md#section-2.5

D-04  Rate limiting applied to ALL public HTTP endpoints
      REF: proyect_arquitecture.md#section-2.5

D-05  Per-endpoint limits configured (or global default applied):
      login ≤ 10 / 60s, register ≤ 5 / 60s, join ≤ 20 / 60s, others ≤ 60 / 60s
      REF: proyect_arquitecture.md#section-2.5

D-06  429 response includes Retry-After header
      REF: proyect_arquitecture.md#section-2.5

D-07  Game state is NOT stored in Redis (lives in GameStore only)
      REF: proyect_arquitecture.md#section-2.5
```

---

### BLOCK E — Socket.IO

```
E-01  Socket.IO auth middleware validates JWT before any event handler runs
      (io.use() middleware, not inside individual handlers)
      REF: javascript_good_practices.md#socketio, security.md#section-2

E-02  Unauthenticated connections rejected at middleware level — socket never opens
      REF: security.md#section-2

E-03  Event names follow domain:action pattern
      (e.g. game:attack, troop:deploy, phase:change)
      REF: javascript_good_practices.md#socketio

E-04  No raw GameState objects emitted to clients — sanitised client DTO only
      REF: javascript_good_practices.md#socketio, security.md#section-8

E-05  On user disconnect: game continues running, only socket reference cleared
      REF: javascript_good_practices.md#socketio, proyect_arquitecture.md#section-2.2

E-06  userId / characterId read from JWT (socket.data), never from event payload
      REF: security.md#section-5
```

---

### BLOCK F — GameStore (in-memory state)

```
F-01  Single GameStore instance — Map<gameId, GameState>
      REF: javascript_good_practices.md#in-memory-game-state

F-02  GameState shape matches architecture Section 11:
      id, phase, startedAt, players{}, eventQueue[]
      REF: proyect_arquitecture.md#section-11

F-03  GameState is serialisable (no functions, no circular references)
      REF: javascript_good_practices.md#in-memory-game-state

F-04  Concurrent writes to same game state are serialised
      (async queue or mutex per game — no race conditions)
      REF: javascript_good_practices.md#in-memory-game-state

F-05  No game state stored in Redis, MongoDB, or any external store directly
      (only via Time Wheel dump events)
      REF: proyect_arquitecture.md#section-2.2
```

---

### BLOCK G — Time Wheel

```
G-01  Single setInterval for the entire Time Wheel — no scattered
      setTimeout/setInterval calls in other modules
      REF: javascript_good_practices.md#time-wheel

G-02  Tick interval controlled by TIME_WHEEL_TICK_MS env var
      REF: proyect_arquitecture.md#section-12

G-03  All event types from architecture Section 10 registered in dispatcher switch:
      TROOP_TRAINING_COMPLETE, TROOP_ARRIVAL, RESOURCE_TICK,
      PHASE_TRANSITION_WAR, PHASE_TRANSITION_END,
      DB_DUMP_POSTGRES, DB_DUMP_MONGODB
      REF: proyect_arquitecture.md#section-10

G-04  All event handlers are idempotent
      (processing the same event twice does not corrupt state)
      REF: proyect_arquitecture.md#section-10

G-05  DB_DUMP_POSTGRES and DB_DUMP_MONGODB events are NOT stored in GameState.eventQueue
      (re-scheduled from constants on every restart)
      REF: proyect_arquitecture.md#section-10

G-06  On server restart: recoverActiveGames() called before opening socket to clients
      REF: proyect_arquitecture.md#section-10

G-07  Overdue events (executeAt <= now) processed in batch on restart
      REF: proyect_arquitecture.md#section-10

G-08  unknown event type in dispatcher: logged as warning, never throws
      REF: javascript_good_practices.md#time-wheel
```

---

### BLOCK H — Persistence dumps

```
H-01  PostgreSQL dump fires every POSTGRES_DUMP_INTERVAL_MS via Time Wheel
      REF: proyect_arquitecture.md#section-2.2

H-02  MongoDB dump fires every MONGODB_DUMP_INTERVAL_MS via Time Wheel
      REF: proyect_arquitecture.md#section-2.2

H-03  Dump handlers are non-blocking — no await in the tick processing path
      REF: javascript_good_practices.md#persistence-dumps

H-04  On dump failure: error logged, retried once — process does not crash
      REF: javascript_good_practices.md#persistence-dumps

H-05  serializeGameState() handles MinHeap → array conversion
      REF: javascript_good_practices.md (db-dump skill)

H-06  deserializeGameState() reconstructs MinHeap from array on recovery
      REF: javascript_good_practices.md (db-dump skill)
```

---

### BLOCK I — HTTP client to DB Server

```
I-01  All endpoints called match those defined in architecture Section 4
      No undocumented calls to the DB Server
      REF: proyect_arquitecture.md#section-4

I-02  All outbound calls attach Authorization: Bearer <handshakeToken>
      REF: proyect_arquitecture.md#section-3.2

I-03  401 response triggers token refresh + one retry (not infinite loop)
      REF: proyect_arquitecture.md#section-3.2

I-04  Non-OK responses throw typed AppError — no raw fetch failures propagated
      REF: javascript_good_practices.md#async-error-handling
```

---

### BLOCK J — Avatar upload

```
J-01  POST /users/avatar endpoint exists (multipart)
      REF: proyect_arquitecture.md#section-3.3

J-02  sharp used for resize to 200×200 px before storing
      REF: proyect_arquitecture.md#section-2.4

J-03  File stored in MinIO bucket 'avatars' with UUID filename
      REF: security.md#section-9

J-04  File type validated by magic bytes — not just Content-Type header
      REF: security.md#section-9

J-05  File size limit enforced before processing
      REF: security.md#section-9

J-06  After MinIO upload: PUT /internal/users/{id}/avatar called on DB Server
      REF: proyect_arquitecture.md#section-3.3
```

---

### BLOCK K — Combat resolution

```
K-01  resolveCombat() is a pure function — no side effects, no I/O, no GameStore access
      REF: .agents/skills/combat-resolution/SKILL.md

K-02  CLAN_ADVANTAGES constant matches architecture Section 7.2:
      FURY→IRON, IRON→RUNE, RUNE→DIVINE, DIVINE→DEATH, DEATH→SONG, SONG→FURY
      REF: proyect_arquitecture.md#section-7.2

K-03  ADVANTAGE_MULTIPLIER loaded from env — not hardcoded
      REF: proyect_arquitecture.md#section-12

K-04  Casualty resolution order: damaged troops first (currentPoints < maxPoints),
      then weakest base tier first
      REF: proyect_arquitecture.md#section-9

K-05  Ultimate troop path (power: 0, ultimate: true) handled separately
      REF: proyect_arquitecture.md#section-9
```

---

### BLOCK L — Code conventions

```
L-01  const by default — let only when reassignment needed — no var
      REF: javascript_good_practices.md#general-rules

L-02  async/await throughout — no raw .then().catch() chains
      REF: javascript_good_practices.md#async-error-handling

L-03  Centralised Express error middleware (4-argument function) as last middleware
      REF: javascript_good_practices.md#async-error-handling

L-04  asyncHandler wrapper used on all async Express route handlers
      REF: javascript_good_practices.md#async-error-handling

L-05  All exported functions have JSDoc with @param and @returns
      REF: javascript_good_practices.md#general-rules

L-06  Error responses: { code, message } only — no stack traces
      REF: security.md#section-8

L-07  No console.log in any production path
      REF: javascript_good_practices.md#general-rules

L-08  Code in English, comments in Spanish
      REF: proyect_arquitecture.md (conventions)
```

---

### BLOCK M — Testing

```
M-01  Unit tests exist for: combat.js, time wheel event handlers, GameStore,
      serializeGameState/deserializeGameState, hasAdvantage()
      REF: javascript_good_practices.md (create_unit_test workflow)

M-02  jest.useFakeTimers() used for Time Wheel tests
      REF: .agents/skills/time-wheel-event/SKILL.md

M-03  All mocks restored after each test (jest.restoreAllMocks() in afterEach)
      REF: javascript_good_practices.md (create_unit_test workflow)

M-04  No test depends on execution order
      REF: javascript_good_practices.md (create_unit_test workflow)
```

---

### BLOCK N — Docker

```
N-01  Dockerfile exists for middle server
      REF: proyect_arquitecture.md#section-1

N-02  Container does not run as root
      REF: security.md#section-10

N-03  Only middle server port is exposed publicly
      (Redis, MinIO:9001, db-server on internal Docker network only)
      REF: security.md#section-10
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
║        MIDDLE SERVER AUDIT — Viking Clan Wars        ║
║                   [DATE / SCOPE]                     ║
╚══════════════════════════════════════════════════════╝

SCORE: [X / 100]

  ❌ FAIL      [N]   ·   🔶 PARTIAL  [N]
  ⚪ NOT FOUND [N]   ·   ✅ PASS     [N]

BLOCKS:
  A - Structure & Config     [score/total]
  B - JWT User Tokens        [score/total]
  C - JWT Handshake          [score/total]
  D - Redis                  [score/total]
  E - Socket.IO              [score/total]
  F - GameStore              [score/total]
  G - Time Wheel             [score/total]
  H - Persistence Dumps      [score/total]
  I - HTTP Client            [score/total]
  J - Avatar Upload          [score/total]
  K - Combat Resolution      [score/total]
  L - Code Conventions       [score/total]
  M - Testing                [score/total]
  N - Docker                 [score/total]

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
- TBD items in architecture doc → ⚪ NOT EVALUATED — TBD.
- Does not count as a file modification per collaboration.md.
