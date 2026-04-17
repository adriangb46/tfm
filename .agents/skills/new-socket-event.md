---
name: new-socket-event
description: Use this skill when the user wants to create a new Socket.IO event between the Angular frontend and the Node.js middle server. Triggers on phrases like "añadir evento socket", "nuevo evento de juego", "emitir evento desde el front", "escuchar evento en el middle", or any request that involves real-time communication between front and middle.
---

# Skill: New Socket.IO Event

## Context

- **Frontend:** Angular 20 with Socket.IO client wrapped in `SocketService`.
- **Middle:** Node.js + Express + Socket.IO server. Events are authenticated via JWT middleware.
- All game events go through Socket.IO. HTTPS is only used for login and game creation.
- Event names follow the pattern `domain:action` (e.g. `game:attack`, `troop:deploy`, `phase:change`).
- Code in **English**. Comments in **Spanish**.

---

## Step 1 — Clarify the event

Before writing any code, confirm with the user:

1. **Event name** — propose a `domain:action` name if not given. Ask for confirmation.
2. **Direction** — who emits and who listens?
   - `front → middle` (user action, e.g. deploying troops)
   - `middle → front` (server push, e.g. combat result)
   - `middle → all fronts in game` (broadcast, e.g. phase change)
3. **Payload shape** — what data travels in the event? Define it explicitly before coding.
4. **Does the middle need to call the DB Server as a result?** If yes, apply the `new-rest-endpoint` skill for that call.

Do not proceed until these four points are confirmed.

---

## Step 2 — Define the shared TypeScript types

Create or update the shared types file. All Socket.IO payloads must be fully typed.

Location: `front/src/app/core/socket/socket-events.types.ts`

```typescript
// Evento: <event-name>
// Emisor: <front | middle>
// Descripción: <what this event does>

export interface <EventName>Payload {
  // campos del payload
}

export interface <EventName>Response {
  // campos de la respuesta (si el middle emite de vuelta)
}
```

If a type already exists for part of the payload (e.g. `Troop`, `GamePhase`), import it — never duplicate.

---

## Step 3 — Middle Server: register the event handler

Location: `middle/src/socket/<domain>.handlers.js`

```js
/**
 * Registra el handler para el evento '<event-name>'
 * @param {import('socket.io').Socket} socket
 * @param {import('../game/state/GameStore.js').GameStore} gameStore
 */
export function register<EventName>Handler(socket, gameStore) {
  socket.on('<event-name>', async (payload) => {
    // 1. Validar payload — rechazar si faltan campos obligatorios
    if (!payload.<requiredField>) {
      socket.emit('error', { code: 'INVALID_PAYLOAD', message: '...' });
      return;
    }

    // 2. Obtener el gameId del estado del socket (adjunto en el middleware de auth)
    const { characterId } = socket.data;

    // 3. Leer estado del juego desde GameStore
    const game = gameStore.get(payload.gameId);
    if (!game) {
      socket.emit('error', { code: 'GAME_NOT_FOUND' });
      return;
    }

    // 4. Aplicar lógica de negocio (delegar al módulo correspondiente)
    // const result = await someGameEngine.process(game, payload);

    // 5. Emitir respuesta
    // socket.emit('<response-event>', result);           // solo al emisor
    // socket.to(payload.gameId).emit('<event>', result); // al resto de la sala
    // io.to(payload.gameId).emit('<event>', result);     // a todos incluido emisor
  });
}
```

Register the handler in the main socket setup file: `middle/src/socket/index.js`

```js
io.on('connection', (socket) => {
  // ... otros handlers
  register<EventName>Handler(socket, gameStore);
});
```

---

## Step 4 — Angular: update SocketService

Location: `front/src/app/core/socket/socket.service.ts`

Add a method to emit and/or listen to the new event:

```typescript
// Emitir el evento al middle (si el front es el emisor)
emit<EventName>(payload: <EventName>Payload): void {
  this.socket.emit('<event-name>', payload);
}

// Escuchar el evento desde el middle (si el front es el receptor)
on<EventName>(): Observable<<EventName>Response> {
  return new Observable(observer => {
    this.socket.on('<event-name>', (data: <EventName>Response) => observer.next(data));
    return () => this.socket.off('<event-name>');
  });
}
```

---

## Step 5 — Angular: use the event in the component or service

- Call `emit<EventName>()` from a component method triggered by user interaction.
- Convert `on<EventName>()` to a signal at the component boundary:
  ```typescript
  private readonly socketService = inject(SocketService);
  readonly eventData = toSignal(this.socketService.on<EventName>(), { initialValue: null });
  ```
- Use `takeUntilDestroyed()` if subscribing manually.

---

## Step 6 — Checklist before finishing

- [ ] TypeScript types defined and exported.
- [ ] Middle handler validates the payload before processing.
- [ ] Middle handler reads from `GameStore`, never from the DB Server directly.
- [ ] Middle emits back with the correct scope (single socket / room / broadcast).
- [ ] Angular `SocketService` has the new emit/on methods.
- [ ] No raw `any` types anywhere in the event pipeline.
- [ ] Files modified listed at the end of the response.
