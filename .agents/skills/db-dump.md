---
name: db-dump
description: Use this skill when the user wants to implement, modify, or debug the game state persistence dumps — either the PostgreSQL dump (every ~15 min) or the MongoDB analytics snapshot (every ~2 h). Triggers on phrases like "volcado de estado", "persistir partida", "dump a postgres", "snapshot de mongodb", "guardar estado en base de datos", "recuperar partida tras reinicio", or any request involving data persistence from the middle to the DB server.
---

# Skill: DB Dump (PostgreSQL & MongoDB)

## Context

- The Middle Server holds all live game state **in memory**.
- Two periodic dump mechanisms push data to the DB Server:
  - **PostgreSQL dump** — every ~15 min (`POSTGRES_DUMP_INTERVAL_MS`). Full game state as JSON blob per active game.
  - **MongoDB dump** — every ~2 h (`MONGODB_DUMP_INTERVAL_MS`). Analytics snapshot across all active games.
- Both dumps are scheduled by the **Time Wheel** (`DB_DUMP_POSTGRES` and `DB_DUMP_MONGODB` events).
- Dumps are **asynchronous and non-blocking** — they must never pause game processing.
- On failure, log the error and retry once. Do not crash the process.
- Read `proyect_arquitecture.md` Sections 4 (REST API), 5 (PostgreSQL schema), 6 (MongoDB schema), and 10 (Time Wheel) before making any change.

---

## Step 1 — Clarify the change

Before writing any code, confirm with the user:

1. **Which dump** is being modified — PostgreSQL, MongoDB, or both?
2. **What is changing** — the payload shape, the interval, the retry logic, the recovery logic, or the DB Server endpoint?
3. **If the payload shape changes** — does the PostgreSQL schema or MongoDB collection schema also change? (If yes, a Flyway migration is needed on the DB Server.)

Do not proceed until these are confirmed.

---

## Step 2 — Middle Server: PostgreSQL dump flow

### Time Wheel event handler

Location: `middle/src/game/engine/eventHandlers.js`

```js
/**
 * Realiza el volcado del estado de todas las partidas activas a PostgreSQL
 * Se ejecuta cada ~15 minutos, gestionado por la rueda de tiempo
 * @param {GameEvent} event
 * @param {GameState} game
 * @param {{ dbClient: DbClient, gameStore: GameStore }} context
 */
export async function handleDbDumpPostgres(event, game, context) {
  // Serializar el estado en memoria a JSON
  const stateJson = serializeGameState(game);

  // Enviar al DB server de forma no bloqueante
  context.dbClient.dumpGameState(game.id, stateJson)
    .catch(async (err) => {
      // Registrar error y reintentar una vez
      logger.error({ gameId: game.id, err }, 'Error en volcado PostgreSQL — reintentando');
      try {
        await context.dbClient.dumpGameState(game.id, stateJson);
      } catch (retryErr) {
        logger.error({ gameId: game.id, err: retryErr }, 'Reintento fallido — volcado descartado');
      }
    });

  // Re-encolar el siguiente evento (no se persiste en GameState)
  // La re-programación ocurre en scheduleNonPersistedEvents al arrancar
}
```

### Serialization function

```js
/**
 * Serializa el estado de la partida a JSON para almacenamiento
 * IMPORTANTE: el resultado debe ser deserializable sin pérdida de datos
 * @param {GameState} game
 * @returns {string}
 */
export function serializeGameState(game) {
  // Transformar estructuras no-JSON (Map, Set, MinHeap) a arrays
  return JSON.stringify({
    ...game,
    // Si eventQueue es un MinHeap, exportar como array ordenado
    eventQueue: game.eventQueue.toArray(),
  });
}

/**
 * Deserializa el estado de partida desde JSON (usada al recuperar tras reinicio)
 * @param {string} json
 * @returns {GameState}
 */
export function deserializeGameState(json) {
  const raw = JSON.parse(json);
  return {
    ...raw,
    // Reconstruir el MinHeap desde el array
    eventQueue: MinHeap.fromArray(raw.eventQueue, (a, b) => a.executeAt - b.executeAt),
  };
}
```

---

## Step 3 — Middle Server: MongoDB dump flow

### Time Wheel event handler

Location: `middle/src/game/engine/eventHandlers.js`

```js
/**
 * Genera un snapshot de analytics de todas las partidas activas y lo envía a MongoDB
 * Se ejecuta cada ~2 horas, gestionado por la rueda de tiempo
 * @param {GameEvent} event
 * @param {GameState} game
 * @param {{ dbClient: DbClient, gameStore: GameStore }} context
 */
export async function handleDbDumpMongodb(event, game, context) {
  // Construir el snapshot de analytics (subconjunto del estado completo)
  const snapshot = buildAnalyticsSnapshot(game);

  context.dbClient.saveAnalyticsSnapshot(snapshot)
    .catch(async (err) => {
      logger.error({ gameId: game.id, err }, 'Error en snapshot MongoDB — reintentando');
      try {
        await context.dbClient.saveAnalyticsSnapshot(snapshot);
      } catch (retryErr) {
        logger.error({ gameId: game.id, err: retryErr }, 'Reintento de snapshot fallido');
      }
    });
}

/**
 * Construye el objeto de snapshot de analytics desde el estado en memoria
 * Solo incluye los campos relevantes para estadísticas — no el estado operacional completo
 * @param {GameState} game
 * @returns {AnalyticsSnapshot}
 */
function buildAnalyticsSnapshot(game) {
  return {
    gameId      : game.id,
    snapshotAt  : new Date().toISOString(),
    phase       : game.phase,
    players     : Object.values(game.players).map(p => ({
      characterId        : p.characterId,
      clanId             : p.clanId,
      economicCredits    : p.economicCredits,
      researchCredits    : p.researchCredits,
      capitalHealth      : p.capitalHealth,
      troops             : p.troops.map(t => ({
        troopId       : t.id,
        typeId        : t.typeId,
        currentPoints : t.currentPoints,
        deployed      : t.deployed,
      })),
      unlockedResearches : p.unlockedResearches,
      eliminated         : p.eliminated,
    })),
  };
}
```

---

## Step 4 — DB Server: REST endpoints called by the dumps

### PostgreSQL dump endpoint

Already defined in `proyect_arquitecture.md`:
`PUT /internal/games/{id}/state` — Body: `{ stateJson: string }`

The DB Server persists this in the `game_state_dumps` table (see schema in architecture doc).

### MongoDB snapshot endpoint

`POST /internal/analytics/snapshots` — Body: the `AnalyticsSnapshot` object.

The DB Server writes to the `game_snapshots` MongoDB collection.

If either endpoint needs to be created or modified, apply the `new-rest-endpoint` skill.

---

## Step 5 — Restart recovery (PostgreSQL → Middle)

When the Middle Server starts, it must recover all active games from PostgreSQL:

Location: `middle/src/game/engine/recoveryService.js`

```js
/**
 * Recupera todas las partidas activas del DB server y las carga en el GameStore
 * Se llama una vez al arrancar, antes de abrir el socket a los clientes
 * @param {{ dbClient: DbClient, gameStore: GameStore, timeWheel: TimeWheel }} context
 */
export async function recoverActiveGames(context) {
  const activeGames = await context.dbClient.getActiveGames(); // GET /internal/games/active

  for (const gameRecord of activeGames) {
    // Obtener el último dump de estado
    const latestDump = await context.dbClient.getLatestStateDump(gameRecord.id);
    if (!latestDump) {
      logger.warn({ gameId: gameRecord.id }, 'Partida activa sin dump — omitiendo');
      continue;
    }

    // Deserializar y cargar en memoria
    const gameState = deserializeGameState(latestDump.stateJson);
    context.gameStore.set(gameRecord.id, gameState);

    // Procesar eventos vencidos inmediatamente (executeAt <= now)
    await context.timeWheel.processOverdueEvents(gameRecord.id);

    logger.info({ gameId: gameRecord.id }, 'Partida recuperada correctamente');
  }

  // Re-programar los eventos no persistidos (DB_DUMP_*)
  scheduleNonPersistedEvents(context);
}
```

---

## Step 6 — Checklist before finishing

- [ ] Dump handlers are non-blocking (no `await` on the dump call in the tick path).
- [ ] One automatic retry on failure, logged clearly.
- [ ] `serializeGameState` handles all non-JSON-safe structures (Map, Set, MinHeap).
- [ ] `deserializeGameState` correctly reconstructs the MinHeap and all complex structures.
- [ ] Restart recovery processes overdue events before opening the socket.
- [ ] `DB_DUMP_*` events are NOT in `GameState.eventQueue` (re-scheduled from constants on restart).
- [ ] If payload shape changed: DB Server schema updated + Flyway migration created.
- [ ] Files modified listed at the end of the response.
