# Project Architecture — Viking Clan Wars

> **Living document.** All sections marked `[PROPOSED]` are provisional decisions subject to change.
> Before modifying any implementation detail in this file, ask the team first.

---

## 1. System Overview

The system is composed of three independent services that communicate over HTTP and WebSockets.

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT                               │
│                   Angular 20 (SPA)                          │
│         HTTPS (login, join)  |  Socket.IO (game)            │
└─────────────────┬────────────┴──────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────────────────────┐
│                    MIDDLE SERVER                             │
│              Node.js + Express + Socket.IO                   │
│                                                              │
│  - Issues and validates user JWTs                            │
│  - Holds ALL active game state in memory                     │
│  - Runs the Time Wheel (game loop)                           │
│  - Dumps state to DB Server periodically                     │
│                                                              │
│              HTTP REST (internal JWT)                        │
└─────────────────┬────────────────────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────────────────────┐
│                     DB SERVER                                │
│              Java 25 + Spring Boot                           │
│                                                              │
│  - Issues startup handshake token to Middle                  │
│  - Persists data to PostgreSQL (every ~15 min)               │
│  - Writes analytics snapshots to MongoDB (every ~2 h)        │
│                                                              │
│        PostgreSQL (main)  |  MongoDB (analytics)             │
└──────────────────────────────────────────────────────────────┘
```

**Key principle:** The Middle Server is the single source of truth for live game state.
The DB Server is the persistence layer only — it never drives game logic.

---

## 2. Service Details

### 2.1 Frontend — Angular 20

- Single-page application. No server-side rendering.
- Communicates with the Middle via:
  - **HTTPS** for: user login, character creation, creating/joining a game.
  - **Socket.IO** (authenticated via JWT) for: all in-game events, real-time state updates.
- Stores the JWT in memory (not `localStorage`). On page reload, the user must re-authenticate.
- All game state displayed is derived from events pushed by the Middle. The frontend never calculates game outcomes.

### 2.2 Middle Server — Node.js + Express + Socket.IO

- Central game engine. Authoritative source for all live game data.
- All active games live in a `GameStore` (in-memory `Map<gameId, GameState>`).
- The **Time Wheel** (see Section 8) drives all timed game events.
- On startup, requests a handshake JWT from the DB Server and stores it for outbound requests.
- Dumps game state to the DB Server on two schedules:
  - **PostgreSQL dump:** every ~15 minutes (full game state as JSON blob).
  - **MongoDB dump:** every ~2 hours (analytics snapshot).
- On restart: fetches active game states from the DB Server and resumes the Time Wheel with the recovered events.

### 2.3 DB Server — Java 25 + Spring Boot

- Pure persistence layer. Exposes a REST API consumed only by the Middle Server.
- On startup, issues a signed handshake JWT to the Middle Server upon request.
- Manages two databases:
  - **PostgreSQL:** users, characters, games, participants, state dumps.
  - **MongoDB:** analytics snapshots for statistics queries.
- Validates the handshake JWT on every inbound request from the Middle.

---

## 3. Communication & Security

### 3.1 JWT — User Tokens (Frontend ↔ Middle)

- Issued by the Middle Server when a user logs in.
- Signed with `MIDDLE_JWT_SECRET` (environment variable, never committed).
- Payload: `{ userId, characterId, clanId, iat, exp }`.
- Attached as `Authorization: Bearer <token>` on HTTPS requests and in the Socket.IO handshake.
- Validated by Socket.IO middleware on every connection and reconnection.

### 3.2 JWT — Handshake Token (Middle ↔ DB Server)

- Issued by the DB Server on the `POST /internal/auth/handshake` endpoint, called once by the Middle on startup.
- Signed with `DB_HANDSHAKE_SECRET` (environment variable on both services).
- The Middle attaches it as `Authorization: Bearer <token>` on every outbound HTTP call to the DB Server.
- The DB Server validates it with a `OncePerRequestFilter`. All requests without a valid token return `401`.
- If the Middle receives a `401`, it requests a new token automatically.

### 3.3 Communication Flows

```
LOGIN:
  Front  --HTTPS POST /auth/login-->  Middle
  Middle --JWT response + opens socket-->  Front

JOIN/CREATE GAME:
  Front  --HTTPS POST /games-->  Middle
  Middle --HTTPS POST /internal/games-->  DB Server (persist)
  Middle --socket emit game:joined-->  Front

IN-GAME (all subsequent events):
  Front  --socket emit game:action-->  Middle
  Middle --processes in memory-->
  Middle --socket broadcast game:state-update-->  Front(s)

PERSISTENCE DUMP (background, every 15 min):
  Middle  --HTTPS PUT /internal/games/{id}/state-->  DB Server
  DB Server --persists to PostgreSQL-->

ANALYTICS DUMP (background, every 2 h):
  Middle  --HTTPS POST /internal/analytics/snapshots-->  DB Server
  DB Server --writes to MongoDB-->
```

---

## 4. REST API — Middle ↔ DB Server

> All endpoints are prefixed `/internal/`. They are not exposed to the internet.
> All requests must carry the handshake JWT. All responses follow the structure:
> `{ data: T }` on success, `{ code: string, message: string, timestamp: string }` on error.

### Auth

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/internal/auth/handshake` | Middle requests startup token. Body: `{ secret }`. Returns `{ token }`. |

### Users

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/internal/users` | Create user (registration). |
| `GET` | `/internal/users/{id}` | Get user by ID. |
| `GET` | `/internal/users/by-username/{username}` | Find user by username (for login validation). |

### Characters

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/internal/characters` | Create character for a user. |
| `GET` | `/internal/characters/{id}` | Get character by ID. |
| `GET` | `/internal/characters/by-user/{userId}` | List all characters for a user. |

### Games

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/internal/games` | Create a new game record. |
| `GET` | `/internal/games/{id}` | Get game record (used on Middle restart to recover state). |
| `GET` | `/internal/games/active` | List all games with status not `finished` (used on restart recovery). |
| `PUT` | `/internal/games/{id}/state` | Full game state dump. Body: `{ stateJson }`. |
| `POST` | `/internal/games/{id}/end` | Mark game as finished. Body: `{ winnerCharacterId }`. |

### Analytics

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/internal/analytics/snapshots` | Write a full game state snapshot to MongoDB. |

---

## 5. PostgreSQL Schema

```sql
-- Usuarios del sistema
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username      VARCHAR(50)  UNIQUE NOT NULL,
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Personajes (un usuario puede tener varios)
CREATE TABLE characters (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES users(id),
  clan_id    VARCHAR(50) NOT NULL,  -- 'berserkers' | 'valkirias' | 'jarls' | 'skalds' | 'seidr' | 'draugr'
  name       VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Registro de partidas
CREATE TABLE games (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status               VARCHAR(20) NOT NULL DEFAULT 'waiting', -- waiting | preparation | war | end | finished
  max_players          SMALLINT    NOT NULL CHECK (max_players BETWEEN 2 AND 6),
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at           TIMESTAMPTZ,
  ended_at             TIMESTAMPTZ,
  winner_character_id  UUID REFERENCES characters(id)
);

-- Participantes de cada partida
CREATE TABLE game_participants (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id          UUID    NOT NULL REFERENCES games(id),
  character_id     UUID    NOT NULL REFERENCES characters(id),
  join_order       SMALLINT NOT NULL,
  eliminated       BOOLEAN NOT NULL DEFAULT false,
  eliminated_at    TIMESTAMPTZ,
  UNIQUE (game_id, character_id)
);

-- Volcados periódicos del estado de partida (cada ~15 min)
CREATE TABLE game_state_dumps (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id     UUID  NOT NULL REFERENCES games(id),
  state_json  JSONB NOT NULL,
  dumped_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_game_state_dumps_game_id ON game_state_dumps(game_id);
```

---

## 6. MongoDB Schema (Analytics)

Two collections, written by the DB Server every ~2 hours from the Middle's snapshot payload.

### `game_snapshots`
Full state snapshot of every active game.

```json
{
  "_id": "ObjectId",
  "gameId": "uuid",
  "snapshotAt": "ISODate",
  "phase": "preparation | war | end",
  "players": [
    {
      "characterId": "uuid",
      "clanId": "berserkers",
      "economicCredits": 340,
      "researchCredits": 80,
      "capitalHealth": 1200,
      "troops": [
        { "troopId": "uuid", "typeId": "frenzied_warrior", "currentPoints": 60, "deployed": false }
      ],
      "unlockedResearches": ["berserkers_res_1", "berserkers_res_2"],
      "eliminated": false
    }
  ]
}
```

### `battle_events`
Individual battle outcomes for win-rate and damage statistics.

```json
{
  "_id": "ObjectId",
  "gameId": "uuid",
  "timestamp": "ISODate",
  "attackerCharacterId": "uuid",
  "attackerClanId": "berserkers",
  "defenderCharacterId": "uuid",
  "defenderClanId": "jarls",
  "attackerTotalPoints": 480,
  "defenderTotalPoints": 310,
  "outcome": "ATTACKER_WIN | DEFENDER_WIN",
  "advantageApplied": true,
  "advantageMultiplier": 1.25,
  "attackerTroopsLost": ["uuid1", "uuid2"],
  "defenderTroopsLost": ["uuid3"]
}
```

---

## 7. Game Domain Model

### 7.1 Clans

Six clans, each with a unique archetype that determines type advantages.
Game data is loaded from `clans.yml` at Middle Server startup. This file is the single source of truth for troop stats, spell stats, and research trees.

| Clan | Archetype | Base Troop(s) |
|------|-----------|---------------|
| Berserkers | FURY | Guerrero Frenético (ATK, 60 power) |
| Valkirias | DIVINE | Doncella Escudera (ATK, 50 power), Sanadora Divina (HEAL, 30 power) |
| Jarls | IRON | Huscarle Pesado (ATK, 75 power) |
| Skalds | SONG | Vanguardia Inspirada (ATK, 40 power), Bardo Sanador (HEAL, 20 power) |
| Seidr | RUNE | Acólito Rúnico (ATK, 30 power — high AP cost, slow but resilient) |
| Draugr | DEATH | Campeón Renacido (ATK, 150 power — very high cost and long training) |

### 7.2 Clan Advantage Cycle [PROPOSED]

A closed 6-way cycle, similar to a type-advantage system. Each clan deals bonus damage against the next clan in the chain.

```
FURY → IRON → RUNE → DIVINE → DEATH → SONG → FURY
```

| Attacker | Advantage over | Lore reason |
|----------|----------------|-------------|
| FURY (Berserkers) | IRON (Jarls) | Berserk rage shatters iron discipline |
| IRON (Jarls) | RUNE (Seidr) | Cold steel disrupts runic focus |
| RUNE (Seidr) | DIVINE (Valkirias) | Ancient runes unravel divine light |
| DIVINE (Valkirias) | DEATH (Draugr) | Sacred light banishes undeath |
| DEATH (Draugr) | SONG (Skalds) | Death silences every song |
| SONG (Skalds) | FURY (Berserkers) | Bardic chants soothe berserker fury |

**Advantage multiplier:** `[PROPOSED — TBD]` Applied to the advantaged clan's total troop points before battle resolution. Suggested value: `×1.25`. Must be confirmed by the team.

### 7.3 Troop Structure

Each troop instance in a live game:

```json
{
  "id": "uuid",                      // instancia única de tropa
  "typeId": "frenzied_warrior",      // referencia a clans.yml
  "clanId": "berserkers",
  "maxPoints": 60,                   // power base del yml
  "currentPoints": 60,               // puede bajar tras combate (tropa dañada)
  "deployed": false,                 // false = en capital (cuenta como defensa)
  "travelTargetGameId": null,        // gameId del jugador objetivo
  "arrivalAt": null                  // timestamp de llegada (seteado por el Time Wheel)
}
```

**Troop states:**
- `deployed: false` → in capital → counts as **defense**.
- `deployed: true, arrivalAt > now` → **traveling** → neither attacking nor defending.
- `deployed: true, arrivalAt <= now` → **fighting** → combat is resolved by the Time Wheel event.

**HEAL type troops:** `[TBD]` Troops of type `HEAL` exist (e.g. divine_healer, healer_bard). Their role in combat resolution (do they add to defense total? do they restore points to other troops?) is not yet defined. Must be decided before implementing combat logic.

### 7.4 Ultimate Troops

Ultimate troops (`ultimate: true`, `power: 0` in yml) deal damage equal to **1/3 of the target capital's total health** at the moment of impact. Usable only in the End phase. Their `currentPoints` is not used in the standard combat sum — they trigger a special resolution path.

### 7.5 Research Tree

Each clan has 6 research nodes (res_1 → res_5 + res_ult). Each node:
- Costs `rpCost` research points and takes `researchTimeSeconds` to complete.
- May require a prerequisite research (`prerequisiteResearchId`).
- On completion, unlocks either a troop type or a spell (`unlocksId`), tracked with `unlocksType`.

The research tree per clan is linear with one branch:
```
res_1 ──► res_2 ──► res_4 ──► res_ult
     └──► res_3 ──► res_5
```

---

## 8. Game Phases

### Phase 1 — Preparation (fixed 5 minutes)

- Attacks are **not allowed**.
- All players receive **100% of max economic credits** and **100% of max research credits**.
- Players can research their first technology immediately.
- Phase ends automatically after 5 minutes → transitions to War.

### Phase 2 — War (random resource ticks)

- Attacks are **allowed**.
- Every **30–60 seconds** (random interval per tick, decided at tick time), each player receives a **percentage of the maximum monetary value** `[PROPOSED — TBD: exact % formula]`.
- Research credits are awarded based on **battle damage dealt** (war weariness mechanic) `[TBD — exact formula not yet defined]`.
- Phase ends when only 2 players remain → transitions to End.
- Special case: in 2-player games, the War phase lasts a **minimum of 10 minutes** before elimination can trigger the End phase.

### Phase 3 — End

- Only 2 players remain.
- Ultimate troops (`ultimate: true`) become usable in this phase.
- The phase ends when one player's capital reaches 0 health (or 0 total troop points).

---

## 9. Combat Resolution Algorithm

```
GIVEN:
  attackerTroops   = list of deployed troops arriving at target
  defenderTroops   = all troops with deployed=false in the target capital
  attackerClan     = clan of the attacking character
  defenderClan     = clan of the defending character

STEP 1 — Calculate totals with advantage
  advantageMultiplier = 1.25 if attackerClan has advantage over defenderClan, else 1.0
  [NOTE: reverse advantage (defender over attacker) is not currently modelled — TBD]
  attackerTotal = sum(troop.currentPoints for troop in attackerTroops) × advantageMultiplier
  defenderTotal = sum(troop.currentPoints for troop in defenderTroops)

STEP 2 — Determine outcome
  diff = attackerTotal - defenderTotal
  if diff > 0 → ATTACKER_WIN
  if diff ≤ 0 → DEFENDER_WIN (ties go to defender)

STEP 3 — Resolve surviving troops (same algorithm for both sides)
  pointsToAbsorb = abs(diff)  // the losing side absorbs the full diff, winner absorbs none
  
  Sort losing side troops by priority (ascending):
    1. Damaged troops first (currentPoints < maxPoints), sorted by currentPoints ASC
    2. Then healthy troops, sorted by maxPoints ASC (weakest base tier first)
  
  For each troop in sorted list:
    if troop.currentPoints <= pointsToAbsorb:
      troop dies, pointsToAbsorb -= troop.currentPoints
    else:
      troop.currentPoints -= pointsToAbsorb
      pointsToAbsorb = 0
      break

STEP 4 — Post-battle
  ATTACKER_WIN:
    - Surviving attacker troops return home (deployed=false, travelTargetGameId=null)
    - Target capital health is reduced (mechanism TBD — not yet specified)
  DEFENDER_WIN:
    - Surviving defender troops remain in capital
    - Attacker troops that died are removed
    - Surviving attacker troops... [TBD — do they return home damaged?]

SPECIAL CASE — Eliminated player's troops:
  If a player is eliminated while troops are traveling, those troops continue their journey
  and resolve combat normally upon arrival.
  EXCEPTION: If only 2 players remain, orphan troops do not resolve (to avoid mutual elimination).
```

---

## 10. Time Wheel

The Time Wheel is the **central game scheduler** in the Middle Server. It is the only source of `setTimeout`/`setInterval` calls for game logic.

### Architecture

```
GameStore (Map<gameId, GameState>)
  └── each GameState has: eventQueue: MinHeap<GameEvent>

TimeWheel
  └── setInterval(processTick, TICK_INTERVAL_MS)  // e.g. 500ms
        └── for each game in GameStore:
              while eventQueue.peek().executeAt <= now:
                process(eventQueue.pop())
```

### Event Types

| Event | Trigger | Action |
|-------|---------|--------|
| `TROOP_TRAINING_COMPLETE` | `now + trainingTimeSeconds` | Adds troop to player's capital |
| `TROOP_ARRIVAL` | `now + travelTimeSeconds` | Triggers combat resolution |
| `RESOURCE_TICK` | Random 30–60 s during War | Distributes economic credits |
| `PHASE_TRANSITION_WAR` | `gameStart + 300s` | Preparation → War |
| `PHASE_TRANSITION_END` | On combat: players remaining = 2 | War → End |
| `DB_DUMP_POSTGRES` | Recurring every 900 s (~15 min) | Sends state dump to DB Server |
| `DB_DUMP_MONGODB` | Recurring every 7200 s (~2 h) | Sends analytics snapshot to DB Server |

### GameEvent Structure

```json
{
  "id": "uuid",
  "gameId": "uuid",
  "type": "TROOP_ARRIVAL",
  "executeAt": 1748000000000,
  "payload": {
    "troopId": "uuid",
    "attackerCharacterId": "uuid",
    "targetCharacterId": "uuid"
  }
}
```

### Rules

- Events are **idempotent**: re-processing the same event must not corrupt state.
- On Middle Server restart: fetch all active games from DB Server, deserialise `state_json`, and re-enqueue all pending events whose `executeAt` is in the future.
- Events past their `executeAt` on restart are processed immediately in one batch before opening the socket to clients.
- `DB_DUMP_*` events are **not stored** in `state_json` — they are re-scheduled from constants on every startup.

---

## 11. In-Memory Game State Shape

The `GameState` object that lives in `GameStore` and is serialised for DB dumps:

```json
{
  "id": "uuid",
  "phase": "preparation | war | end",
  "startedAt": 1748000000000,
  "players": {
    "<characterId>": {
      "characterId": "uuid",
      "userId": "uuid",
      "clanId": "berserkers",
      "economicCredits": 500,
      "researchCredits": 80,
      "capitalHealth": 1000,
      "connectedSocketId": "abc123 | null",
      "eliminated": false,
      "troops": [...],
      "unlockedResearches": ["berserkers_res_1"],
      "researchInProgress": {
        "researchId": "berserkers_res_2",
        "completesAt": 1748000045000
      }
    }
  },
  "eventQueue": [
    { "id": "uuid", "type": "TROOP_ARRIVAL", "executeAt": 1748000060000, "payload": {} }
  ]
}
```

---

## 12. Configuration Reference

All values stored in environment variables. No hardcoded secrets or URLs.

| Variable | Service | Description |
|----------|---------|-------------|
| `PORT` | Middle, DB Server | HTTP listen port |
| `MIDDLE_JWT_SECRET` | Middle | Secret for signing user JWTs |
| `DB_HANDSHAKE_SECRET` | Middle + DB Server | Shared secret for the startup handshake |
| `DB_SERVER_URL` | Middle | Base URL of the DB Server |
| `POSTGRES_URL` | DB Server | PostgreSQL connection string |
| `MONGODB_URL` | DB Server | MongoDB connection string |
| `POSTGRES_DUMP_INTERVAL_MS` | Middle | Default: `900000` (15 min) |
| `MONGODB_DUMP_INTERVAL_MS` | Middle | Default: `7200000` (2 h) |
| `TIME_WHEEL_TICK_MS` | Middle | Default: `500` |
| `ADVANTAGE_MULTIPLIER` | Middle | Default: `1.25` [PROPOSED] |
