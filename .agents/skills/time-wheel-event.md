---
name: time-wheel-event
description: Use this skill when the user wants to add a new type of timed event to the game loop, modify an existing Time Wheel event, or change how the scheduler processes events. Triggers on phrases like "nuevo evento de tiempo", "añadir temporizador", "evento de la rueda", "programar tarea", "tick de juego", "evento recurrente", or any request involving the Time Wheel scheduler.
---

# Skill: Time Wheel — New or Modified Event

## Context

- The Time Wheel is the **only** source of timed execution in the Middle Server.
- It uses a **min-heap priority queue** sorted by `executeAt` timestamp.
- A single `setInterval` ticks every `TIME_WHEEL_TICK_MS` (env var, default 500 ms) and processes all due events across all active games.
- Events are **idempotent**: processing the same event twice must not corrupt game state.
- Events are persisted in `GameState.eventQueue` and survive server restarts.
- Read `proyect_arquitecture.md` Section 10 (Time Wheel) before making any change.

---

## Step 1 — Clarify the new event

Before writing any code, confirm with the user:

1. **Event name** — must be added to the `GameEventType` enum/constant.
2. **Trigger condition** — when is the event scheduled?
   - One-shot: triggered once by a game action (e.g. troop deployed)
   - Recurring: re-schedules itself after execution (e.g. resource tick, DB dump)
3. **Payload** — what data does the event carry? (minimum: `gameId`)
4. **Is it persisted in `GameState.eventQueue`?**
   - Yes (default) — survives restarts, stored in the state dump.
   - No — only `DB_DUMP_*` events are NOT persisted (re-scheduled from constants on restart).
5. **Side effects** — does it mutate game state? call the DB Server? emit a socket event?

Do not proceed until all five points are confirmed.

---

## Step 2 — Register the new event type

Location: `middle/src/game/engine/timeWheel.js` (or `gameEventTypes.js`)

```js
// Tipos de eventos de la rueda de tiempo
export const GameEventType = Object.freeze({
  TROOP_TRAINING_COMPLETE : 'TROOP_TRAINING_COMPLETE',
  TROOP_ARRIVAL           : 'TROOP_ARRIVAL',
  RESOURCE_TICK           : 'RESOURCE_TICK',
  PHASE_TRANSITION_WAR    : 'PHASE_TRANSITION_WAR',
  PHASE_TRANSITION_END    : 'PHASE_TRANSITION_END',
  DB_DUMP_POSTGRES        : 'DB_DUMP_POSTGRES',
  DB_DUMP_MONGODB         : 'DB_DUMP_MONGODB',
  // ← añadir aquí el nuevo tipo
  NEW_EVENT_TYPE          : 'NEW_EVENT_TYPE',
});
```

---

## Step 3 — Define the event factory function

Every event is created by a factory function that ensures the correct shape.

```js
/**
 * Crea un nuevo evento de tipo <NEW_EVENT_TYPE>
 * @param {string} gameId
 * @param {number} executeAt  — timestamp en ms (Date.now() + delay)
 * @param {Object} payload    — datos específicos del evento
 * @returns {GameEvent}
 */
export function create<NewEventType>Event(gameId, executeAt, payload) {
  return {
    id        : crypto.randomUUID(),
    gameId,
    type      : GameEventType.NEW_EVENT_TYPE,
    executeAt,
    payload,
  };
}
```

---

## Step 4 — Implement the event handler

Location: `middle/src/game/engine/eventHandlers.js`

```js
/**
 * Procesa el evento NEW_EVENT_TYPE
 * Este handler debe ser IDEMPOTENTE: ejecutarlo dos veces no debe corromper el estado
 * @param {GameEvent} event
 * @param {GameState} game     — estado en memoria (mutar directamente)
 * @param {Object} context     — { gameStore, io, dbClient }
 */
export async function handle<NewEventType>(event, game, context) {
  const { payload } = event;

  // 1. Validar que el evento sigue siendo relevante (el estado puede haber cambiado)
  //    Si ya no aplica, retornar sin hacer nada (comportamiento idempotente)
  if (/* condición de invalidación */) {
    return;
  }

  // 2. Aplicar la lógica de negocio sobre `game` (estado en memoria)

  // 3. Si es un evento recurrente, re-encolar el siguiente
  if (/* es recurrente */) {
    const nextEvent = create<NewEventType>Event(
      game.id,
      Date.now() + INTERVAL_MS,
      payload,
    );
    game.eventQueue.push(nextEvent);  // min-heap push
  }

  // 4. Emitir socket event si el estado visible para el frontend cambió
  // context.io.to(game.id).emit('game:state-update', buildClientState(game));

  // 5. Si requiere llamada al DB server, usar el cliente HTTP (operación async, no bloquear)
  // context.dbClient.updateSomething(payload).catch(err => logger.error(err));
}
```

---

## Step 5 — Register the handler in the Time Wheel dispatcher

Location: `middle/src/game/engine/timeWheel.js` — in the `processEvent` switch/map:

```js
async function processEvent(event, game, context) {
  switch (event.type) {
    case GameEventType.TROOP_TRAINING_COMPLETE: return handleTroopTrainingComplete(event, game, context);
    case GameEventType.TROOP_ARRIVAL:           return handleTroopArrival(event, game, context);
    case GameEventType.RESOURCE_TICK:           return handleResourceTick(event, game, context);
    case GameEventType.PHASE_TRANSITION_WAR:    return handlePhaseTransitionWar(event, game, context);
    case GameEventType.PHASE_TRANSITION_END:    return handlePhaseTransitionEnd(event, game, context);
    case GameEventType.DB_DUMP_POSTGRES:        return handleDbDumpPostgres(event, game, context);
    case GameEventType.DB_DUMP_MONGODB:         return handleDbDumpMongodb(event, game, context);
    // ← añadir aquí
    case GameEventType.NEW_EVENT_TYPE:          return handle<NewEventType>(event, game, context);
    default:
      logger.warn(`Tipo de evento desconocido: ${event.type}`); // nunca lanzar aquí
  }
}
```

---

## Step 6 — Handle restart recovery (if the event is persisted)

Location: `middle/src/game/engine/timeWheel.js` — in the restart recovery logic:

If the event is persisted in `GameState.eventQueue`, it is automatically recovered on restart because the full `eventQueue` is deserialised from the DB Server state dump. No additional code is needed unless the event has special recovery logic.

If the event is **not** persisted (like DB dump events), add re-scheduling in the startup function:

```js
// Re-programa los eventos de volcado al arrancar (no se persisten en GameState)
export function scheduleNonPersistedEvents(game, context) {
  // DB_DUMP_POSTGRES y DB_DUMP_MONGODB ya están aquí — añadir el nuevo si aplica
}
```

---

## Step 7 — Write unit tests

Location: `middle/src/game/engine/eventHandlers.test.js`

Test the handler function directly with a mock `game` state and mock `context`.

Minimum cases:
- [ ] Normal execution — game state mutated correctly.
- [ ] Idempotent execution — running it twice produces the same final state as running it once.
- [ ] Invalid/stale event — handler returns early without corrupting state.
- [ ] Recurring event — next event is enqueued with correct `executeAt`.

---

## Step 8 — Checklist before finishing

- [ ] New type added to `GameEventType` constant.
- [ ] Factory function created for the new event.
- [ ] Handler is idempotent — explicitly documented and tested.
- [ ] Handler registered in the dispatcher switch.
- [ ] Restart recovery handled (persisted automatically OR re-scheduled from constants).
- [ ] No bare `setTimeout`/`setInterval` calls added outside the Time Wheel.
- [ ] Unit tests cover normal, idempotent, and stale-event cases.
- [ ] Files modified listed at the end of the response.
