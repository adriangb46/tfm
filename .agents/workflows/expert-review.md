---
description: expert-view
---

# Workflow: /expert-review

## Trigger

Invoked with `/expert-review` from the Antigravity chat.

## Purpose

Evaluate the entire project as a senior fullstack engineer would before a production release.
This is NOT a rules compliance check — that is what `/audit-db-server`, `/audit-middle`,
and `/audit-front` are for.

This workflow asks: **"Is this project ready for production, and how good is it really?"**

It evaluates architecture quality, engineering decisions, observability, resilience,
scalability potential, developer experience, and overall code health — the things that
separate a project that works from a project that is maintainable and trustworthy.

Read-only. Never modifies any file.

---

## Step 1 — Load context

Read these files before scanning any code:

| File | Purpose |
|------|---------|
| `.agents/proyect_arquitecture.md` | Full architecture — all sections |
| `.agents/rules/security.md` | Security baseline |
| `.agents/db_server_sprints.md` | What was planned vs what exists |
| `.agents/ui_screens.md` | Frontend scope |
| `.agents/front_color_guide.md` | Frontend design system |

Then scan the actual codebase. Treat the `.agents` files as the spec and the code as the implementation.

---

## Step 2 — Evaluation dimensions

Evaluate the project across **10 dimensions**. Each dimension is scored 0–10.
Final score = average of all dimensions × 10 = score out of 100.

---

### DIMENSION 1 — Architecture & Design (0–10)

Evaluate whether the architectural decisions are sound, coherent, and appropriate for the project's scale.

```
1.1  Service boundaries are well-defined and respected
     (Middle does not do persistence logic, DB Server does not do game logic)

1.2  Communication contracts are explicit and stable
     (REST API shape, Socket.IO event names, JWT payload shape — documented and enforced)

1.3  The in-memory + periodic dump strategy is correctly implemented
     (no game state leaking to DB Server outside of dump events,
      recovery on restart is complete and tested)

1.4  The Time Wheel is the single scheduler — no scattered timers

1.5  Dependency direction is correct in the Java service
     (Controller → Service → Repository, never reversed)

1.6  The architecture is appropriate for the project's scale
     (not over-engineered for a 2-person TFG, not under-engineered for the stated requirements)

1.7  No circular dependencies between modules in any service

1.8  The chosen tech stack is coherent and each piece earns its place
     (Redis for ephemeral state, MinIO for files, MongoDB for analytics — each justified)

SCORE THIS DIMENSION: X/10
EVIDENCE: list specific findings that drove the score up or down
```

---

### DIMENSION 2 — API Design (0–10)

Evaluate the quality of the REST API and Socket.IO interface as contracts.

```
2.1  REST endpoints are resource-oriented and use correct HTTP methods
     (no POST /internal/games/getActive, no GET /internal/doSomething)

2.2  HTTP status codes are semantically correct
     (404 for not found, 409 for conflict, 422 for validation, 401 for auth, 403 for authz)

2.3  Error responses are consistent across all endpoints
     (same { code, message, timestamp } shape everywhere)

2.4  API versioning strategy exists or is intentionally omitted with justification
     (the /internal/ prefix is not versioning — is there a plan for breaking changes?)

2.5  Socket.IO events have a consistent naming convention and are documented
     (domain:action pattern — are all events listed somewhere?)

2.6  API responses return only the data the client needs
     (no overfetching — no fields returned that are never used)

2.7  Pagination exists or is planned for list endpoints that could grow
     (GET /internal/games/active could return many games — is there a limit?)

2.8  Input validation is thorough — edge cases covered
     (empty strings, null values, out-of-range numbers, invalid UUIDs)

SCORE THIS DIMENSION: X/10
```

---

### DIMENSION 3 — Resilience & Error Handling (0–10)

Evaluate how well the system handles failures, partial outages, and unexpected states.

```
3.1  The Middle Server handles DB Server unavailability gracefully
     (if DB Server is down at startup, does Middle crash or retry?)

3.2  Dump failures are handled without crashing the game
     (one retry, then log and continue — not a process crash)

3.3  Redis unavailability is handled
     (if Redis is down, does the auth middleware crash or degrade gracefully?)

3.4  MinIO unavailability is handled
     (avatar upload fails cleanly — does not corrupt user state)

3.5  Game state corruption is detected
     (what happens if a deserialized GameState from the DB is malformed?
      is there a validation step before loading it into GameStore?)

3.6  The Time Wheel handles exceptions per-event
     (one broken event handler must not stop the entire wheel for all games)

3.7  Player disconnection mid-combat is handled
     (game continues, troop deployment continues — tested?)

3.8  Process crashes are recoverable without data loss beyond the dump window
     (the ~15 min window between dumps is acceptable and documented)

3.9  There are no unhandled promise rejections in Node.js
     (process.on('unhandledRejection') handler exists)

3.10 There are no uncaught exceptions that could silently corrupt state
     (process.on('uncaughtException') handler exists with clean shutdown)

SCORE THIS DIMENSION: X/10
```

---

### DIMENSION 4 — Security Posture (0–10)

Evaluate security holistically — beyond the rules checklist, assess the overall posture.

```
4.1  Attack surface is minimal
     (only two ports publicly exposed: frontend and middle)

4.2  JWT implementation is complete: jti, blacklist, short expiry
     (not just "JWT is used" — the full lifecycle is correct)

4.3  There are no obvious privilege escalation paths
     (a regular user cannot perform admin actions by manipulating any request)

4.4  Input validation is defence-in-depth
     (validated at the HTTP level AND at the business logic level — not just one)

4.5  Secrets management is sound
     (no secrets in code, in logs, in git history, in docker-compose hardcoded)

4.6  The game logic cannot be manipulated by a malicious client
     (all outcomes computed server-side, client only sends intentions)

4.7  Rate limiting covers all abuse vectors
     (not just login — also game creation, avatar upload)

4.8  There are no IDOR vulnerabilities
     (user A cannot read or modify user B's characters, games, or state
      by guessing or enumerating UUIDs)

4.9  File upload is safe
     (magic bytes, size limit, UUID rename, EXIF strip via sharp)

4.10 Logging does not leak sensitive data

SCORE THIS DIMENSION: X/10
```

---

### DIMENSION 5 — Observability (0–10)

Evaluate how easy it is to understand what the system is doing in production.

```
5.1  Structured logging is used (pino in Node.js, SLF4J/Logback in Java)
     — logs are machine-parseable

5.2  Log levels are used correctly
     (DEBUG for dev noise, INFO for significant events, WARN for degraded states,
      ERROR for failures requiring attention)

5.3  Key game events are logged with enough context to reconstruct what happened
     (combat resolution, phase transitions, player eliminations, dump failures)

5.4  Request/response logging exists on the Middle Server for HTTP endpoints
     (at least: method, path, status, duration — no request body on auth endpoints)

5.5  The Time Wheel logs when it processes an event that takes unusually long
     (a single slow event handler can delay the entire tick)

5.6  Dump failures are logged with gameId, timestamp, and error details
     (enough to know which game state was not persisted)

5.7  Failed auth attempts are logged with IP and timestamp
     (prerequisite for detecting brute force — not just rate limiting)

5.8  There is a health check endpoint on the Middle Server
     (GET /health — returns 200 with { status: 'ok', uptime, gamesActive }
      or equivalent — useful for Docker healthcheck and load balancer)

5.9  There is a health check endpoint on the DB Server
     (Spring Boot Actuator /actuator/health is acceptable)

5.10 Log output is consistent — same fields across similar events
     (gameId always in the same field, userId always labelled the same way)

SCORE THIS DIMENSION: X/10
```

---

### DIMENSION 6 — Performance & Scalability (0–10)

Evaluate performance decisions and whether the system would hold under realistic load.

```
6.1  The Time Wheel tick interval is appropriate
     (500ms default — is the per-tick processing time well below 500ms?)

6.2  Game state serialization is efficient
     (serializing a full GameState for a 6-player game — is it fast enough for
      the 15-min dump cadence? Any blocking JSON.stringify on large objects?)

6.3  Database queries have appropriate indexes
     (game_state_dumps has index on game_id — are there other hot query paths
      that need indexes in PostgreSQL?)

6.4  MongoDB writes are async and do not block the request path
     (the 2h analytics dump should never slow down a game action)

6.5  The Socket.IO room model is used correctly
     (players in a game are in the same room — broadcasts go to the room,
      not looped over all connected sockets)

6.6  There are no N+1 query patterns in the Java service
     (loading a game with all participants should not fire N queries for N participants)

6.7  Large list endpoints have limits
     (GET /internal/games/active without a LIMIT could be slow with many games)

6.8  The Angular frontend is not polling
     (all real-time updates via Socket.IO push — no setInterval fetching state)

6.9  Heavy Angular components use @defer
     (tech tree, statistics panels loaded lazily)

6.10 The system's single-node constraint is acknowledged
     (no Redis pub/sub for horizontal scaling — this is acceptable for TFG scope
      but the limitation should be documented)

SCORE THIS DIMENSION: X/10
```

---

### DIMENSION 7 — Code Quality & Maintainability (0–10)

Evaluate whether the code is clean, readable, and easy to change.

```
7.1  Functions and methods are small and single-responsibility
     (< 40 lines in JS, < 50 lines in Java methods — exceptions noted)

7.2  Naming is clear and consistent across the codebase
     (no abbreviations like 'usr', 'mgr', 'svc' — full names)

7.3  There is no duplicated logic
     (same validation, same mapping, same calculation appearing in multiple places)

7.4  Business logic is not scattered across layers
     (combat resolution is in one place, not split between socket handler and game state)

7.5  Magic numbers and strings are named constants
     (no if (phase === 'war') scattered everywhere — use GamePhase.WAR)

7.6  DTOs and domain models are cleanly separated
     (no JPA annotations on classes also used as API response bodies)

7.7  The codebase is consistent in style
     (same patterns used for similar problems throughout — not a different approach
      in every file)

7.8  Comments explain WHY, not WHAT
     (// resolve casualties starting from weakest — good
      // loop over troops — not useful)

7.9  Dead code is absent
     (no commented-out blocks, no unused imports, no unreachable branches)

7.10 The code reads as if written by one person
     (two developers, but consistent style — suggests code review is happening)

SCORE THIS DIMENSION: X/10
```

---

### DIMENSION 8 — Testing (0–10)

Evaluate the quality and coverage of the test suite.

```
8.1  The most critical paths have unit tests:
     - Combat resolution (resolveCombat) — pure function, fully testable
     - Handshake JWT generation and validation
     - bcrypt password hashing and verification
     - Time Wheel event dispatch

8.2  Edge cases are tested, not just happy paths
     (tie in combat, 0 troops attacking, troop with 1 currentPoint, player already eliminated)

8.3  Integration tests cover the full HTTP lifecycle
     (request in → DB write → response out — with real PostgreSQL via Testcontainers)

8.4  Tests are fast
     (unit tests finish in seconds — integration tests in under 2 minutes)

8.5  Test coverage is meaningful
     (not 100% line coverage chased blindly — the critical game logic modules
      have thorough tests, boilerplate has minimal tests)

8.6  Tests do not test implementation details
     (tests assert observable behaviour — not that a private method was called)

8.7  Failing tests are never committed
     (CI or pre-commit hook runs tests — or discipline is evident)

8.8  Angular component tests cover signal behaviour
     (input changes produce correct computed signal values)

8.9  Socket.IO event handlers have tests
     (event received → correct GameState mutation verified)

8.10 Test naming makes failure messages self-explanatory
     (resolveBattle_givenAttackerOverpowers_shouldReturnAttackerVictory
      is immediately clear when it fails)

SCORE THIS DIMENSION: X/10
```

---

### DIMENSION 9 — Developer Experience & Operations (0–10)

Evaluate how easy it is to work on and operate this project.

```
9.1  The project can be started from zero with one command
     (docker-compose up — or equivalent — with a documented setup step)

9.2  A README exists with: purpose, architecture summary, setup steps, env vars required
     (not just the .agents files — a human-readable README)

9.3  .env.example exists with all required variables and example values
     (a new developer can copy it and run immediately in local mode)

9.4  The Flyway migration history is clean and linear
     (no gaps in version numbers, no duplicate versions)

9.5  The collaboration rules (collaboration.md) are evidently being followed
     (no signs of overwritten work, merge conflicts in history, or files touched
      outside their sprint scope)

9.6  The .agents folder is complete and up-to-date
     (architecture doc reflects what is actually built — no major drift)

9.7  Git commit messages are descriptive
     (not "fix", "update", "wip" — enough context to understand what changed)

9.8  The docker-compose file is well-organised
     (services have health checks, depends_on with condition: service_healthy,
      volumes named and documented)

9.9  There is a documented process to run the audits
     (/audit-db-server, /audit-middle, /audit-front, /security-audit — are they
      being run and their findings addressed?)

9.10 Local development does not require manual steps after setup
     (Flyway runs automatically, MinIO bucket creation is scripted, no manual DB init)

SCORE THIS DIMENSION: X/10
```

---

### DIMENSION 10 — Production Readiness (0–10)

Evaluate the final gap between "it works on my machine" and "it runs in production safely".

```
10.1  All containers have Docker health checks defined
      (postgres, mongodb, redis, minio, db-server, middle — not just the front)

10.2  depends_on uses condition: service_healthy
      (middle does not start until db-server is healthy,
       db-server does not start until postgres is healthy)

10.3  Graceful shutdown is implemented in the Middle Server
      (SIGTERM handler: stop accepting new connections, flush in-flight Time Wheel tick,
       trigger a final DB dump, then exit)

10.4  The ~15 minute dump window is acceptable and explicitly acknowledged
      (the team knows that a crash could lose up to 15 minutes of game state,
       and this is documented as a known limitation)

10.5  There is a documented backup strategy for PostgreSQL
      (even a simple pg_dump cron on the Ubuntu server counts)

10.6  The MinIO data volume is persistent
      (avatars survive a container restart — volume mounted in docker-compose)

10.7  PostgreSQL and MongoDB data volumes are persistent and named
      (not anonymous volumes that disappear on docker-compose down)

10.8  There is a documented update/deployment process
      (how do you deploy a new version without losing active game state?)

10.9  The Dockerfile uses a specific image tag, not :latest
      (eclipse-temurin:25.0.1-jre not eclipse-temurin:latest)

10.10 There is at least a basic monitoring plan
      (even just: "check /health endpoint every 5 minutes and alert if it returns non-200")

SCORE THIS DIMENSION: X/10
```

---

## Step 3 — Produce the report

```
╔══════════════════════════════════════════════════════════════╗
║        FULLSTACK EXPERT REVIEW — Viking Clan Wars            ║
║                      [DATE]                                  ║
╚══════════════════════════════════════════════════════════════╝

OVERALL SCORE: [X / 100]

┌─────────────────────────────────────────────────────────────┐
│  D1  Architecture & Design        [X/10]  ██████████░░      │
│  D2  API Design                   [X/10]  ████████░░░░      │
│  D3  Resilience & Error Handling  [X/10]  ███████░░░░░      │
│  D4  Security Posture             [X/10]  █████████░░       │
│  D5  Observability                [X/10]  ██████░░░░░░      │
│  D6  Performance & Scalability    [X/10]  ████████░░░░      │
│  D7  Code Quality                 [X/10]  █████████░░       │
│  D8  Testing                      [X/10]  ███████░░░░░      │
│  D9  Developer Experience         [X/10]  ████████░░░░      │
│  D10 Production Readiness         [X/10]  ██████░░░░░░      │
└─────────────────────────────────────────────────────────────┘

SCORE INTERPRETATION:
  90–100  Production-ready. Ship it.
  75–89   Solid project. Address HIGH findings before production.
  60–74   Working but fragile. Significant gaps to close.
  45–59   Functional prototype. Major work needed before production.
  < 45    Proof of concept only. Redesign required in flagged areas.

──────────────────────────────────────────────────────────────

STRENGTHS  (what this project does well)
─────────────────────────────────────────
List 3–5 specific things that are genuinely well-designed or well-implemented.
Be specific — not "good security" but "JWT blacklist with Redis TTL is correctly
implemented and prevents token reuse after logout".

──────────────────────────────────────────────────────────────

CRITICAL GAPS  (must fix before production)
────────────────────────────────────────────
List findings that would cause data loss, security breaches, or service
unavailability in a real production environment.

[CG-01] <Title>
  Dimension:  D<N> — <name>
  Check:      <check number, e.g. 3.6>
  Finding:    <what is wrong>
  Risk:       <what could go wrong in production>
  Fix:        <concrete action>

──────────────────────────────────────────────────────────────

SIGNIFICANT IMPROVEMENTS  (should fix before production)
──────────────────────────────────────────────────────────
Findings that would cause operational pain, performance issues, or
make the system hard to maintain in production.

[SI-01] ...

──────────────────────────────────────────────────────────────

NICE TO HAVE  (polish and long-term health)
────────────────────────────────────────────
Improvements that would elevate the project but are not urgent.

[NTH-01] ...

──────────────────────────────────────────────────────────────

DIMENSION BREAKDOWNS
──────────────────────
For each dimension: the score, the 2–3 specific items that most influenced it
(both positive and negative), and the single most impactful improvement.

D1 — Architecture & Design: X/10
  + <what drove the score up>
  - <what drove the score down>
  → To improve: <single best action>

[repeat for all 10 dimensions]

──────────────────────────────────────────────────────────────

HONEST OVERALL ASSESSMENT
───────────────────────────
2–3 paragraphs written as a senior engineer would write a code review summary.
Direct, specific, constructive. Not a list — prose.
Acknowledge what is genuinely good. Be honest about the gaps.
Give a clear recommendation: is this project on track for its goals?
```

---

## Step 4 — Rules for this workflow

- **Read-only.** Never modifies any file.
- **Be honest.** The purpose of this review is to find real problems, not to validate.
  A score of 60 with specific, actionable findings is more useful than a flattering 85.
- **Be specific.** Every finding must point to actual code or a real gap.
  No generic "you should add monitoring" — say what monitoring, where, and why.
- **Separate what exists from what is planned.** If a feature is in the sprint plan
  but not yet implemented, it is ⚪ NOT YET BUILT — not a failure, but not a pass either.
- **Context matters.** This is a TFG (university final project), not a bank.
  Score accordingly — a missing disaster recovery plan is worth noting but not a
  critical blocker. A missing JWT blacklist IS a critical blocker.
- **Does not count as a file modification** per collaboration.md.
- After the report, ask:
  > "¿Quieres que prioricemos los gaps críticos en el plan de sprints actual?"
