---
description: auditar el db_server
---

# Workflow: /audit-db-server

## Trigger

Invoked with `/audit-db-server` from the Antigravity chat.

## Purpose

Audit the `db-server` implementation against the project's architecture and rules.
Read-only — never modifies any file.

---

## Step 1 — Load reference documents

Read these files in full before scanning any code:

| File | Relevant sections |
|------|------------------|
| `.agents/proyect_arquitecture.md` | Sections 2.3, 3.2, 4, 5, 6, 12 |
| `.agents/rules/java_good_practices.md` | All |
| `.agents/rules/security.md` | Sections 1, 2, 3, 4, 5, 8, 11, 12 |
| `.agents/db_server_sprints.md` | All — to know what is expected per sprint |

---

## Step 2 — Scan checklist

For each item record: ✅ PASS / ❌ FAIL / 🔶 PARTIAL / ⚪ NOT FOUND
Every FAIL and PARTIAL must include: file path, line (if applicable), what was found, what was expected, fix.

---

### BLOCK A — Project structure & configuration

```
A-01  Folder structure matches: config/, security/, api/, api/dto/,
      domain/model/, domain/service/, domain/repository/,
      infrastructure/persistence/, infrastructure/mongodb/
      REF: java_good_practices.md#project-structure

A-02  spring.jpa.hibernate.ddl-auto is NOT 'create' or 'update' in any non-local profile
      REF: java_good_practices.md#persistence

A-03  All configuration values loaded from environment variables — no hardcoded secrets
      REF: security.md#section-7, proyect_arquitecture.md#section-12

A-04  All env vars from architecture Section 12 that apply to db-server are present
      in application.yml or .env.example:
      PORT, DB_HANDSHAKE_SECRET, POSTGRES_URL, MONGODB_URL
      REF: proyect_arquitecture.md#section-12

A-05  .env is in .gitignore
      REF: security.md#section-7

A-06  Flyway is used for all schema changes
      REF: java_good_practices.md#persistence
```

---

### BLOCK B — Database schema (Flyway migrations)

```
B-01  V1 migration exists and creates all 5 tables:
      users, characters, games, game_participants, game_state_dumps
      REF: proyect_arquitecture.md#section-5

B-02  users table has columns:
      id (UUID PK), username (VARCHAR 50 UNIQUE NOT NULL),
      email (VARCHAR 255 UNIQUE NOT NULL), password_hash (VARCHAR 255 NOT NULL),
      avatar_url (VARCHAR 512 nullable), created_at (TIMESTAMPTZ NOT NULL DEFAULT now())
      REF: proyect_arquitecture.md#section-5

B-03  characters table has columns:
      id (UUID PK), user_id (UUID FK → users), clan_id (VARCHAR 50 NOT NULL),
      name (VARCHAR 100 NOT NULL), created_at (TIMESTAMPTZ NOT NULL DEFAULT now())
      REF: proyect_arquitecture.md#section-5

B-04  games table has columns:
      id (UUID PK), status (VARCHAR 20 DEFAULT 'waiting'),
      max_players (SMALLINT CHECK 2-6), created_at, started_at, ended_at,
      winner_character_id (UUID FK → characters nullable)
      REF: proyect_arquitecture.md#section-5

B-05  game_participants table has:
      UNIQUE constraint on (game_id, character_id)
      REF: proyect_arquitecture.md#section-5

B-06  game_state_dumps table has:
      state_json (JSONB NOT NULL)
      Index on game_id: idx_game_state_dumps_game_id
      REF: proyect_arquitecture.md#section-5

B-07  No manual DDL outside Flyway migrations
      REF: java_good_practices.md#persistence
```

---

### BLOCK C — Security layer

```
C-01  HandshakeJwtFilter extends OncePerRequestFilter
      REF: proyect_arquitecture.md#section-3.2

C-02  HandshakeJwtFilter validates JWT signature using DB_HANDSHAKE_SECRET from env
      (not hardcoded)
      REF: security.md#section-7, proyect_arquitecture.md#section-3.2

C-03  HandshakeJwtFilter returns 401 with ErrorResponse body on invalid/missing token
      (no redirect, no Spring default error page)
      REF: security.md#section-5

C-04  shouldNotFilter() exempts ONLY POST /internal/auth/handshake
      REF: proyect_arquitecture.md#section-3.2

C-05  SecurityConfig: stateless session, CSRF disabled, all requests authenticated
      except the handshake endpoint
      REF: java_good_practices.md#security

C-06  Security headers set: X-Content-Type-Options, X-Frame-Options, Referrer-Policy
      REF: security.md#section-6

C-07  X-Powered-By equivalent not exposed (Spring Boot banner disabled in prod or
      server info hidden)
      REF: security.md#section-6
```

---

### BLOCK D — Auth endpoint

```
D-01  POST /internal/auth/handshake exists in AuthController
      REF: proyect_arquitecture.md#section-4

D-02  Endpoint validates the submitted secret against DB_HANDSHAKE_SECRET from env
      (constant-time comparison preferred — no simple String.equals on secrets)
      REF: security.md#section-2

D-03  Returns ApiResponse<{ token }> on success, ErrorResponse on failure
      REF: proyect_arquitecture.md#section-4

D-04  Wrong secret → 401, never 403 or 500
      REF: security.md#section-3

D-05  Failed handshake attempts logged with timestamp + IP, NOT the submitted secret
      REF: security.md#section-11
```

---

### BLOCK E — User endpoints

```
E-01  POST /internal/users — creates user, hashes password with bcrypt cost >= 12
      REF: security.md#section-3, proyect_arquitecture.md#section-4

E-02  password_hash is NEVER returned in any UserResponseDto
      REF: security.md#section-3, security.md#section-8

E-03  GET /internal/users/{id} — uses UUID, not auto-increment ID
      REF: security.md#section-1

E-04  GET /internal/users/by-username/{username} — returns UserResponseDto (no hash)
      REF: proyect_arquitecture.md#section-4

E-05  PUT /internal/users/{id}/avatar — persists avatar_url, nothing else
      REF: proyect_arquitecture.md#section-4

E-06  Duplicate username or email → 409 ConflictException, not 500
      REF: java_good_practices.md#exception-handling

E-07  All request DTOs use records with Bean Validation annotations
      REF: java_good_practices.md#rest-controllers
```

---

### BLOCK F — Character endpoints

```
F-01  POST /internal/characters — creates character with valid clan_id
      REF: proyect_arquitecture.md#section-4

F-02  clan_id validated against the 6 known values:
      berserkers | valkirias | jarls | skalds | seidr | draugr
      REF: clans.yml, proyect_arquitecture.md#section-7.1

F-03  GET /internal/characters/{id} — UUID in path, not auto-increment
      REF: security.md#section-1

F-04  GET /internal/characters/by-user/{userId} — returns List<CharacterResponseDto>
      REF: proyect_arquitecture.md#section-4

F-05  All request DTOs use records with Bean Validation
      REF: java_good_practices.md#rest-controllers
```

---

### BLOCK G — Game endpoints

```
G-01  POST /internal/games — creates game + participants records
      REF: proyect_arquitecture.md#section-4

G-02  GET /internal/games/{id} — includes latest state dump
      (queries game_state_dumps ORDER BY dumped_at DESC LIMIT 1)
      REF: proyect_arquitecture.md#section-4

G-03  GET /internal/games/active — returns all games WHERE status != 'finished'
      REF: proyect_arquitecture.md#section-4

G-04  PUT /internal/games/{id}/state — INSERTS new row in game_state_dumps
      (does NOT update — history is kept)
      REF: proyect_arquitecture.md#section-4

G-05  state_json stored as opaque String — DB Server never deserializes it
      REF: proyect_arquitecture.md#section-4

G-06  POST /internal/games/{id}/end — sets status='finished', winner_character_id
      REF: proyect_arquitecture.md#section-4

G-07  All request DTOs use records with Bean Validation
      REF: java_good_practices.md#rest-controllers
```

---

### BLOCK H — Analytics endpoint

```
H-01  POST /internal/analytics/snapshots exists
      REF: proyect_arquitecture.md#section-4

H-02  Controller returns 202 Accepted immediately (fire-and-forget)
      REF: proyect_arquitecture.md#section-2.3

H-03  MongoDB write is @Async — does not block the HTTP response
      REF: proyect_arquitecture.md#section-2.3

H-04  MongoDB failure is logged but NOT propagated to the caller
      REF: java_good_practices.md#service-layer

H-05  GameSnapshot document fields match architecture Section 6:
      gameId, snapshotAt, phase, players[]
      REF: proyect_arquitecture.md#section-6

H-06  BattleEvent document fields match architecture Section 6
      REF: proyect_arquitecture.md#section-6
```

---

### BLOCK I — Code conventions

```
I-01  Constructor injection only (@RequiredArgsConstructor) — no @Autowired on fields
      REF: java_good_practices.md#dependency-injection

I-02  @Transactional on all write service methods
      REF: java_good_practices.md#service-layer

I-03  @Transactional(readOnly=true) on all read service methods
      REF: java_good_practices.md#service-layer

I-04  No FetchType.EAGER on any collection
      REF: java_good_practices.md#persistence

I-05  No raw SQL string concatenation anywhere (use JPQL named params or derived queries)
      REF: security.md#section-4

I-06  Records used for all DTOs — no mutable classes for data transfer
      REF: java_good_practices.md#modern-java-25-features

I-07  All controllers are thin (no business logic — immediate delegation to service)
      REF: java_good_practices.md#rest-controllers

I-08  No entity objects returned directly from any controller method
      REF: java_good_practices.md#rest-controllers, security.md#section-8

I-09  sealed classes or enums used for closed domain sets (GameStatus, ClanId)
      REF: java_good_practices.md#modern-java-25-features

I-10  Code in English, comments in Spanish
      REF: proyect_arquitecture.md (conventions)
```

---

### BLOCK J — Error handling & responses

```
J-01  GlobalExceptionHandler (@RestControllerAdvice) exists
      REF: java_good_practices.md#exception-handling

J-02  All error responses use ErrorResponse record: { code, message, timestamp }
      REF: proyect_arquitecture.md#section-4

J-03  No stack trace, SQL error, internal path, or library version in any error response
      REF: security.md#section-8

J-04  MethodArgumentNotValidException → 400 with field-level errors
      REF: java_good_practices.md#exception-handling

J-05  EntityNotFoundException → 404
      REF: java_good_practices.md#exception-handling

J-06  Catch-all Exception → 500 with generic message, full error logged server-side
      REF: java_good_practices.md#exception-handling
```

---

### BLOCK K — Testing

```
K-01  Unit tests exist for: HandshakeService, UserService, CharacterService,
      GameService, GameDumpService, AnalyticsService
      REF: java_good_practices.md#testing

K-02  Test naming follows: methodName_givenContext_shouldExpectedBehavior
      REF: java_good_practices.md#testing

K-03  @ExtendWith(MockitoExtension.class) used in unit tests (not @SpringBootTest)
      REF: java_good_practices.md#testing

K-04  Integration tests use Testcontainers (real PostgreSQL + MongoDB, not H2)
      REF: java_good_practices.md#testing

K-05  Flyway migrations run automatically in integration test context
      REF: java_good_practices.md#testing

K-06  No test depends on execution order (all tests isolated)
      REF: java_good_practices.md#testing
```

---

### BLOCK L — Docker

```
L-01  Dockerfile exists for db-server
      REF: proyect_arquitecture.md#section-1 (docker compose)

L-02  Container does not run as root (non-root user defined in Dockerfile)
      REF: security.md#section-10

L-03  db-server port not exposed publicly in docker-compose
      (only reachable by middle on internal Docker network)
      REF: security.md#section-10, proyect_arquitecture.md#section-1
```

---

## Step 3 — Score

| Result | Points |
|--------|--------|
| ✅ PASS | +0 |
| 🔶 PARTIAL | -3 |
| ❌ FAIL | -8 |
| ⚪ NOT FOUND | -5 |

Start at **100**. Deductions cumulative, no cap per block.

---

## Step 4 — Report format

```
╔══════════════════════════════════════════════════════╗
║         DB SERVER AUDIT — Viking Clan Wars           ║
║                   [DATE / SCOPE]                     ║
╚══════════════════════════════════════════════════════╝

SCORE: [X / 100]

  ❌ FAIL      [N]   ·   🔶 PARTIAL  [N]
  ⚪ NOT FOUND [N]   ·   ✅ PASS     [N]

BLOCKS:
  A - Structure & Config     [score/total]
  B - DB Schema              [score/total]
  C - Security Layer         [score/total]
  D - Auth Endpoint          [score/total]
  E - User Endpoints         [score/total]
  F - Character Endpoints    [score/total]
  G - Game Endpoints         [score/total]
  H - Analytics Endpoint     [score/total]
  I - Code Conventions       [score/total]
  J - Error Handling         [score/total]
  K - Testing                [score/total]
  L - Docker                 [score/total]

──────────────────────────────────────────────────────
❌ FAILURES
[F-01] Title
  Check:    <check id, e.g. C-02>
  File:     <path> (line N)
  Found:    <what the code does>
  Expected: <what the doc says>
  Fix:      <concrete action>

🔶 PARTIAL
[P-01] ...

⚪ NOT FOUND
[N-01] <what is missing>
  Expected at: <path>
  Defined in:  <doc + section>

✅ PASSING  ([N] checks)
<one line per passing check>
──────────────────────────────────────────────────────
```

After the report ask:
> "¿Quieres que genere las tareas de corrección para los ❌ FAIL ordenadas por impacto?"

---

## Rules for this workflow

- Read-only. Never modifies any file.
- Every finding cites its check ID (e.g. C-02) and the reference document + section.
- TBD items in the architecture doc → mark as ⚪ NOT EVALUATED — TBD, not as FAIL.
- Does not count as a file modification per collaboration.md.
