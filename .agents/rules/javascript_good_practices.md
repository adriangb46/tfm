# JavaScript / Node.js Good Practices (Middle Server)

## Role of the Middle Server

The middle server is the **central game engine**. It is responsible for:
- Authenticating users and issuing JWTs to the frontend.
- Managing all active game sessions **in memory**.
- Running the **time wheel** that drives game events (troop deployment timers, phase transitions, resource ticks).
- Persisting game state to the DB server (PostgreSQL dump every ~15 min, MongoDB dump every ~2 h).
- Communicating with the frontend via Socket.IO and with the DB server via HTTP REST.

Keep this role explicit in mind when making architectural decisions. All game logic lives here, not in the frontend.

## Module System

- Use **ES Modules** (`import`/`export`) exclusively. Never use `require()` / CommonJS.
- Set `"type": "module"` in `package.json`.
- Organise the codebase into clear layers:

```
src/
  config/         # Environment config, constants
  auth/           # JWT issuance and validation
  http/           # Express router definitions
  socket/         # Socket.IO event handlers
  game/
    engine/       # Game loop, time wheel, combat resolution
    state/        # In-memory game state store
    phases/       # Preparation, War, End phase logic
  db/             # HTTP client to the DB server
  utils/          # Shared utilities
```

## Async / Error Handling

- Use **`async/await`** everywhere. Never use raw `.then().catch()` chains unless composing streams.
- Wrap all `async` Express route handlers with an error-forwarding wrapper to avoid unhandled promise rejections:
  ```js
  // Envuelve handlers async para propagar errores al middleware de Express
  const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
  ```
- Define a **centralised Express error middleware** (4-argument function) as the last middleware. All errors must flow through it.
- Never swallow errors silently. Always log and either handle or re-throw.
- Use **custom error classes** that extend `Error` and carry an HTTP status code:
  ```js
  export class AppError extends Error {
    constructor(message, statusCode = 500) {
      super(message);
      this.statusCode = statusCode;
    }
  }
  ```

## Environment & Configuration

- Load all configuration from environment variables using `dotenv` (dev) or the container's env (production).
- Never hardcode secrets, ports, or URLs.
- Export a single frozen config object at startup:
  ```js
  // config/index.js
  export const config = Object.freeze({
    port: Number(process.env.PORT) || 3000,
    jwtSecret: process.env.JWT_SECRET,
    dbServerUrl: process.env.DB_SERVER_URL,
    dbHandshakeToken: process.env.DB_HANDSHAKE_TOKEN,
  });
  ```
- Validate required env variables at startup. Crash fast with a clear message if any are missing.

## JWT — Frontend Authentication

- Issue a **JWT per user** on the initial HTTPS login request.
- Sign tokens with a secret from the environment. Never commit secrets.
- Validate the JWT on every incoming Socket.IO connection and on every HTTP request that requires authentication, using middleware.
- Token payload must contain at minimum: `userId`, `characterId`, `clanType`, `iat`, `exp`.

## JWT — DB Server Handshake

- On startup, request a handshake token from the DB server via HTTP.
- Attach this token as `Authorization: Bearer <token>` on every outbound HTTP request to the DB server.
- Re-request the token automatically if it expires or if a `401` is received from the DB server.

## Socket.IO

- Authenticate Socket.IO connections in the `io.use()` middleware by validating the user's JWT.
- Namespace game events logically (e.g. `game:attack`, `game:troop-deployed`, `game:phase-change`).
- Never broadcast raw internal state objects to clients. Always map to a sanitised **client DTO** before emitting.
- When a user disconnects, do **not** stop their game. The game continues running. Only clean up the socket reference.

## In-Memory Game State

- Store all active games in a **singleton `GameStore`** (a `Map<gameId, GameState>`).
- `GameState` is a plain JS object / class instance. Keep it serialisable (no functions, no circular references) so it can be easily dumped to JSON for persistence.
- Never let two concurrent async operations mutate the same game state without coordination. Use an async queue or mutex per game to serialise writes.
- Log a warning if a game state object exceeds a reasonable memory threshold.

## Time Wheel

- Implement the game time wheel as a **single, centralised scheduler** (do not create `setInterval` / `setTimeout` calls scattered across the codebase).
- The time wheel ticks at a fixed interval and processes due events for all active games.
- Each game has an ordered queue of scheduled events (troop arrivals, phase transitions, resource ticks).
- Events must be **idempotent**: processing the same event twice must not corrupt state.
- On server restart, reload pending events from the DB server and re-schedule them.

## Persistence Dumps

- Schedule PostgreSQL dumps every ~15 minutes using the time wheel.
- Schedule MongoDB dumps every ~2 hours using the time wheel.
- Dumps must be **non-blocking**: run asynchronously and never pause game processing.
- If a dump fails, log the error and retry once. Do not crash the process.

## Naming Conventions

- Files: `camelCase.js` or `kebab-case.js` — pick one and apply it consistently across the project.
- Functions and variables: `camelCase`.
- Classes: `PascalCase`.
- Constants: `SCREAMING_SNAKE_CASE`.
- Code in **English**. Comments in **Spanish**.

## General Rules

- Use **JSDoc** on all exported functions with `@param` and `@returns` tags.
- Keep functions small (< 40 lines). Extract when they grow.
- Do not mutate function arguments. Treat them as immutable.
- Use `const` by default. Use `let` only when reassignment is required. Never use `var`.
- Log with a structured logger (e.g. `pino`). Never use `console.log` in production paths.
- Lint with **ESLint** (flat config, `eslint.config.js`). All lint errors must be resolved before committing.
