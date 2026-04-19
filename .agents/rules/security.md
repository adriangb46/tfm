# Security Good Practices

> These rules apply to ALL layers of the project — Angular, Node.js, Java, SQL, Docker.
> Every piece of code generated must comply with this file.
> When in doubt about a security decision, stop and ask the user before implementing.

---

## 1. IDs and Sensitive Data in URLs

- **Never put internal database IDs in URLs.** A URL like `/api/games/42` exposes your auto-increment sequence and allows enumeration attacks.
- Use **UUIDs** for all public-facing identifiers. UUIDs are already defined in the PostgreSQL schema — enforce them at every layer.
- **Never put sensitive data in query parameters** — tokens, emails, passwords, or any personal data. Query parameters are logged by proxies, servers, and browsers.
- Game codes sent to join a game go in the **request body**, not in the URL.

```
✅ GET /api/games/550e8400-e29b-41d4-a716-446655440000
❌ GET /api/games/42
❌ GET /api/users?email=user@example.com
❌ GET /auth/verify?token=eyJhbGci...
```

---

## 2. Authentication & JWT

- Every JWT must contain a `jti` field (UUID). This enables blacklisting on logout and ban.
- JWT payload: `{ userId, characterId, clanId, jti, iat, exp }`. Nothing else — no passwords, no emails, no sensitive profile data.
- **Never log JWT contents.** Log only the `jti` if needed for audit trails.
- Token expiry must be short. `[PROPOSED — define exp duration, suggest 2h]`
- The JWT secret (`MIDDLE_JWT_SECRET`) must be at least 256 bits of entropy. Generate with `openssl rand -hex 32`. Never commit it.
- On logout: write the `jti` to Redis blacklist immediately. Do not rely on token expiry alone.
- On user ban: invalidate all active tokens by writing their `jti` values to Redis.
- The Socket.IO handshake must validate the JWT before the connection is accepted. Reject unauthenticated connections at the middleware level — never inside individual event handlers.

---

## 3. Passwords

- Never store plain text passwords. Use **bcrypt** with a cost factor of at least `12`.
- Never return `password_hash` from any endpoint, ever — not even to admin routes.
- Password validation on registration: minimum length `[PROPOSED — define, suggest 8 chars]`. Enforce server-side, never only client-side.
- Password change requires the current password to be provided and verified before accepting the new one.
- On failed login: always return the same generic message — `"Invalid username or password"`. Never say which field was wrong.
- Rate limit login attempts via Redis (already defined in the architecture — enforce it).

---

## 4. Input Validation & Injection

- **Validate all input server-side.** Client-side validation is UX only — never a security boundary.
- In Java (DB Server): use Bean Validation (`@NotNull`, `@Size`, `@Pattern`) on every DTO. Never trust raw request bodies.
- In Node.js (Middle): validate all Socket.IO payloads and HTTP request bodies before processing. Reject unknown fields.
- **Never build SQL queries by string concatenation.** Use JPA/JPQL named parameters or Spring Data derived queries only.
- **Never use `eval()`** or `new Function()` in Node.js or Angular.
- Sanitize all user-provided strings that will be displayed in the UI to prevent stored XSS. Angular's template engine escapes by default — never bypass it with `innerHTML` or `[innerHTML]` bindings on user-provided content.
- Game code input (join game): validate server-side that it matches the expected format (length, charset) before querying.

---

## 5. Authorization

- Every protected endpoint must verify **both** authentication (valid JWT) and authorization (does this user have permission to perform this action?).
- A user can only read and modify their own data. Validate `userId` from the JWT, never from the request body or URL.
- A user can only interact with games they are a participant of. Validate `gameId` membership server-side on every Socket.IO event.
- Admin routes (`/admin`, ban actions) must check the `isAdmin` flag from the database, not from the JWT payload. JWT payloads can be crafted.
- The `[data-theme]` toggle and all client-side UI state are cosmetic only — never use them to show/hide security-sensitive data. Access control lives on the server.

---

## 6. HTTP Headers & CORS

- Set the following headers on all Middle Server HTTP responses:
  ```
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Referrer-Policy: strict-origin-when-cross-origin
  ```
- Configure CORS to allow only the known frontend origin. Never use `Access-Control-Allow-Origin: *` in production.
- Do not expose server version information. Disable the `X-Powered-By: Express` header: `app.disable('x-powered-by')`.

---

## 7. Secrets & Environment Variables

- **Zero secrets in code or in git.** This includes: JWT secrets, DB passwords, MinIO keys, Redis URLs, handshake tokens.
- All secrets live in environment variables loaded at runtime. Use `.env` files for local development only, and add `.env` to `.gitignore` immediately.
- Never log environment variables at startup, even at debug level.
- The `DB_HANDSHAKE_SECRET` shared between Middle and DB Server must be rotated if either service is compromised.
- MinIO access key and secret key are credentials — treat them with the same care as database passwords.

---

## 8. Data Exposure

- API responses must return **only the fields the client needs**. Never return full entity objects from the database.
- In Java: always map entities to DTOs before returning from a controller. Never expose JPA entities directly.
- In Node.js: always map `GameState` to a sanitised client DTO before emitting via Socket.IO. A client must never receive another player's socket ID, internal event queue, or server-side timestamps.
- Error responses must not expose stack traces, SQL errors, internal paths, or library versions. Use the global error handler to return only `{ code, message }`.
- MongoDB analytics data is internal — never expose raw analytics documents to the frontend.

---

## 9. File Uploads (Avatars — MinIO)

- Validate file type server-side by inspecting the **magic bytes** (file header), not just the `Content-Type` header or file extension. Accept only `image/jpeg`, `image/png`, and `image/webp`.
- Enforce a maximum file size before processing. `[PROPOSED — suggest 5 MB]`
- Resize to 200×200 px with `sharp` before storing. This also strips any malicious EXIF metadata embedded in the image.
- Store avatars with a randomised filename (UUID), never the original filename provided by the user.
- The MinIO `avatars` bucket is public-read for objects, but write access is restricted to the Middle Server credentials only. Never expose MinIO credentials to the frontend.

---

## 10. Docker & Infrastructure

- No container runs as `root`. Define a non-root user in each `Dockerfile`.
- The MinIO console port (`9001`) and Redis port (`6379`) must not be exposed to the public internet — bind them to `127.0.0.1` or use Docker internal networking only.
- The DB Server (`db-server`) port must not be exposed publicly — it is only reachable by the Middle Server within the Docker network.
- PostgreSQL and MongoDB ports must not be exposed publicly.
- Only the Middle Server (`3000`) and the Angular/nginx frontend (`80`/`443`) are exposed to the public.
- MinIO API port (`9000`) is exposed publicly only if avatar URLs are served directly from it. If possible, proxy avatar delivery through nginx instead.
- Use Docker secrets or a `.env` file mounted at runtime for credentials. Never hardcode credentials in `docker-compose.yml`.

---

## 11. Logging

- Log enough to debug, not enough to leak. The following must **never** appear in logs:
  - Passwords or password hashes
  - JWT tokens (full token strings)
  - MinIO or Redis credentials
  - Full request bodies on auth endpoints
- Log the `jti` of rejected tokens (blacklist hits), not the token itself.
- Log failed login attempts with the IP address (for abuse detection), not the attempted password.
- Use a structured logger (`pino` in Node.js) so logs are parseable. Avoid `console.log` in production paths.

---

## 12. Quick Checklist (apply before every PR)

Before generating or reviewing any piece of code, verify:

- [ ] No IDs in URLs — UUIDs only, in path segments, never auto-increments
- [ ] No sensitive data in query parameters
- [ ] All inputs validated server-side
- [ ] No raw SQL string concatenation
- [ ] No secrets hardcoded or committed
- [ ] Passwords hashed with bcrypt (cost ≥ 12)
- [ ] JWT contains `jti`, logout writes to Redis blacklist
- [ ] API response contains only necessary fields (DTO, not raw entity)
- [ ] File uploads validated by magic bytes, resized, renamed to UUID
- [ ] Error responses contain no stack traces or internal details
- [ ] No `console.log` with sensitive data
