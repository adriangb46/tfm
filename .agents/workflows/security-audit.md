---
description: revision de seguridad
---

# Workflow: /security-audit

## Trigger

Invoked with `/security-audit` from the Antigravity chat.

## Purpose

Perform a structured security audit of the entire project codebase, acting as a security expert.
Produces a scored report divided by severity, with specific file references and actionable fixes.
Does NOT modify any file — this workflow is read-only. All findings are reported, never auto-fixed.

---

## Step 1 — Scope definition

Before scanning, confirm with the user:

1. **Full audit** (default) — all layers: Angular, Node.js, Java, SQL schema, Docker config, environment files.
2. **Partial audit** — user specifies a layer or feature (e.g. "only the auth flow", "only the Middle Server").

If no scope is specified, run the full audit.

---

## Step 2 — Read the security baseline

Before scanning any code, read:
- `.agents/rules/security.md` — project security rules (source of truth for this audit)
- `.agents/proyect_arquitecture.md` — architecture decisions (JWT flow, Redis usage, MinIO, Docker)

These two files define what "correct" looks like for this project specifically.

---

## Step 3 — Scan each layer

Scan the following in order. For each finding, record:
- **File path and line number** (or block, if line is not applicable)
- **Severity** (see classification below)
- **Description** of the issue
- **Recommended fix** — concrete, specific to this codebase

### 3.1 Authentication & JWT (Middle Server)
- [ ] Is `jti` present in every issued JWT?
- [ ] Is logout writing `jti` to Redis blacklist?
- [ ] Is the Socket.IO middleware rejecting unauthenticated connections before any event handler runs?
- [ ] Is `MIDDLE_JWT_SECRET` loaded from env, never hardcoded?
- [ ] Is token expiry defined and short?
- [ ] Are JWT contents ever logged?

### 3.2 Passwords (Middle + DB Server)
- [ ] Is bcrypt used with cost factor ≥ 12?
- [ ] Is `password_hash` excluded from every API response?
- [ ] Does failed login return a generic message (not field-specific)?
- [ ] Is password validation enforced server-side?

### 3.3 Input Validation
- [ ] Are all Java DTOs annotated with Bean Validation?
- [ ] Are all Socket.IO payloads validated before processing?
- [ ] Are all HTTP request bodies in Node.js validated before processing?
- [ ] Is there any raw SQL string concatenation anywhere?
- [ ] Is `innerHTML` / `[innerHTML]` used in Angular templates on user-provided content?
- [ ] Is `eval()` or `new Function()` used anywhere in Node.js or Angular?

### 3.4 Authorization
- [ ] Does every protected endpoint verify `userId` from the JWT, not from the request body?
- [ ] Does every Socket.IO game event verify the user is a participant of that game?
- [ ] Are admin routes verified against the database, not the JWT payload?
- [ ] Can a user access or modify another user's data by changing a UUID in the request?

### 3.5 IDs and Data Exposure in URLs / Responses
- [ ] Are all public-facing IDs UUIDs (never auto-increments)?
- [ ] Are any IDs, tokens, or emails in query parameters?
- [ ] Do API responses return only DTO fields, never raw entities?
- [ ] Do Socket.IO emissions sanitise the game state before sending (no internal queues, no other players' socket IDs)?
- [ ] Do error responses expose stack traces, SQL errors, or library versions?

### 3.6 File Uploads (Avatars)
- [ ] Is file type validated by magic bytes (not just Content-Type)?
- [ ] Is file size enforced before processing?
- [ ] Is the filename replaced with a UUID before storing in MinIO?
- [ ] Is `sharp` resizing applied (strips EXIF metadata)?
- [ ] Are MinIO credentials absent from any frontend code or public config?

### 3.7 Secrets & Environment
- [ ] Are `.env` files in `.gitignore`?
- [ ] Is there any hardcoded secret, password, or API key in any source file?
- [ ] Is any secret logged at startup or at any log level?
- [ ] Are `docker-compose.yml` or `Dockerfile` files free of hardcoded credentials?

### 3.8 HTTP Security (Middle Server)
- [ ] Is `X-Powered-By` header disabled?
- [ ] Are `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` headers set?
- [ ] Is CORS restricted to the known frontend origin only?
- [ ] Is rate limiting active on all public endpoints via Redis?

### 3.9 Infrastructure & Docker
- [ ] Do containers run as non-root users?
- [ ] Are internal ports (Redis 6379, MinIO 9001, DB Server, PostgreSQL, MongoDB) not exposed publicly?
- [ ] Is only the Middle Server and the frontend exposed to the public network?
- [ ] Is MinIO write access restricted to the Middle Server only?

### 3.10 Logging
- [ ] Are passwords, JWT tokens, or credentials absent from all log statements?
- [ ] Are failed login attempts logged with IP only (not the attempted password)?
- [ ] Is `console.log` absent from production paths in Node.js?

---

## Step 4 — Classify each finding

Every finding is assigned one of four severity levels:

### 🔴 CRITICAL
Exploitable immediately with no special skill. Direct data breach, authentication bypass, or full account takeover risk.
Examples: hardcoded secrets in source code, no authentication on protected endpoints, raw SQL concatenation, passwords stored in plain text.

### 🟠 HIGH
Significant risk that requires some context or effort to exploit, but directly impacts user security or data integrity.
Examples: JWT without `jti` (no logout invalidation), missing authorization checks on game actions, no bcrypt or cost factor < 10, stack traces in error responses, IDs in URLs enabling enumeration.

### 🟡 MEDIUM
Reduces the attack surface or hardens the system. Not immediately exploitable alone, but contributes to a chain of vulnerabilities.
Examples: missing security headers, CORS too permissive, no rate limiting, file type validated only by Content-Type, original filename kept on avatar upload.

### 🔵 LOW / BEST PRACTICE
Good hygiene issues. No direct exploit path, but deviates from the security rules defined in `security.md`.
Examples: `console.log` in production paths, verbose error messages without stack traces, non-root user not defined in Dockerfile.

---

## Step 5 — Produce the report

Output the report in the following format:

---

```
╔══════════════════════════════════════════════════════╗
║           SECURITY AUDIT — Viking Clan Wars          ║
║                    [DATE / SCOPE]                    ║
╚══════════════════════════════════════════════════════╝

GLOBAL SCORE: [X / 100]

  🔴 CRITICAL   [N findings]  ──────────────────  -25 pts each (capped at -60)
  🟠 HIGH        [N findings]  ──────────────────  -10 pts each (capped at -30)
  🟡 MEDIUM      [N findings]  ──────────────────  -3 pts each  (capped at -15)
  🔵 LOW         [N findings]  ──────────────────  -1 pt each   (capped at -5)

──────────────────────────────────────────────────────

🔴 CRITICAL FINDINGS
────────────────────

[C-01] <Short title>
  File:    <path/to/file.js> (line N)
  Issue:   <What is wrong and why it is dangerous>
  Fix:     <Specific, concrete action to resolve it in this codebase>

[C-02] ...

──────────────────────────────────────────────────────

🟠 HIGH FINDINGS
────────────────

[H-01] <Short title>
  File:    <path/to/file.java> (line N)
  Issue:   <Description>
  Fix:     <Concrete fix>

...

──────────────────────────────────────────────────────

🟡 MEDIUM FINDINGS
──────────────────

[M-01] ...

──────────────────────────────────────────────────────

🔵 LOW / BEST PRACTICE
───────────────────────

[L-01] ...

──────────────────────────────────────────────────────

✅ PASSING CHECKS
─────────────────
List all checklist items from Step 3 that passed with no issues found.

──────────────────────────────────────────────────────

RECOMMENDED FIX ORDER
──────────────────────
1. Fix all 🔴 CRITICAL first — these are blocking.
2. Then 🟠 HIGH — these should be resolved before any public exposure.
3. Then 🟡 MEDIUM — address before any production deployment.
4. 🔵 LOW — address in normal development flow, no urgency.
```

---

## Step 6 — Rules for this workflow

- **Read-only.** This workflow never modifies, creates, or deletes any file.
- **No auto-fix.** Even if a fix is trivial, the workflow only reports it. The user decides what to fix and when.
- **Specific references only.** Every finding must point to a real file and location found during the scan. No hypothetical or generic findings.
- **If a check cannot be evaluated** (e.g. a file does not exist yet or is not in scope), mark it as `⚪ NOT EVALUATED` in the passing checks section with a note explaining why.
- **Collaboration rule:** this workflow only reads files. It does not count as a modification for the purposes of `collaboration.md`.
- After delivering the report, ask: "¿Quieres que genere un plan de acción ordenado para resolver los findings críticos primero?"
