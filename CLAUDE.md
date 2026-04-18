# CLAUDE.md — Project Rules (High Precedence)

This file is loaded with maximum priority by Antigravity. All rules defined here override any conflicting instruction from other sources.

---

## 🔴 CRITICAL — AFTER DO ANITHING

put in the Agents_changelog.md, all that you do

## 🔴 CRITICAL — Two-Person Team: Always Ask Before Acting

**This project is developed by two people working simultaneously on the same repository.**
A wrong move by the agent can cause Git conflicts that block both developers.

### The agent MUST stop and ask the user before:

1. **Modifying any file outside the explicit scope of the current request.**
   - If the task says "edit file X", only file X (and its direct test file, if tests were requested) may be touched.
   - Any other file — no matter how obvious the improvement seems — requires explicit confirmation first.

2. **Performing any destructive operation**, regardless of scope:
   - ❌ Deleting a file or directory
   - ❌ Renaming a file or directory
   - ❌ Moving a file to a different path

   The agent must describe the intended action and wait for a clear **yes** before executing it.

### After every task, the agent must list:
- Which files were **modified**
- Which files were **created**
- Confirmation that everything else was **left untouched**

---

## Project Overview

**Viking Clan Wars** — A real-time multiplayer strategy game (2–6 players).

- Each player controls a Viking clan character with type-based advantages over other clans (similar to a type-advantage system).
- Core mechanics: train troops, deploy them, attack enemy capitals.
- Tech tree with 8 technologies that unlock stronger troop types.
- Two in-game currencies: economic credits (train troops) and research credits (earned from battle damage).
- Game phases: Preparation (5 min, no attacks) → War (resource ticks every 30–60 s) → End (2 players remaining).
- Games run on the server continuously, even when players are offline.

## Architecture

| Layer | Technology | Responsibility |
|---|---|---|
| **Frontend** | Angular 20 | UI, user interaction, Socket.IO client |
| **Middle Server** | Node.js + Express + Socket.IO | Game engine, in-memory state, time wheel, JWT issuance |
| **DB Server** | Java 25 + Spring Boot | REST API, PostgreSQL persistence, MongoDB analytics |
| **Main DB** | PostgreSQL | Persistent game and user data (dumped every ~15 min) |
| **Analytics DB** | MongoDB | Game snapshots for statistics (dumped every ~2 h) |

## Communication

- **Frontend ↔ Middle**: HTTPS for login and game join; Socket.IO (with JWT) for all game events.
- **Middle ↔ DB Server**: HTTP REST with a JWT handshake token issued by the DB server on startup.
- All tokens are JWT. Secrets are stored in environment variables only.

## Code Conventions

- Code: **English**
- Comments: **Spanish**
- Naming: `camelCase` (variables/functions), `PascalCase` (classes/types), `SCREAMING_SNAKE_CASE` (constants), `kebab-case` (files)
- Strict TypeScript (`strict: true`) on the frontend.
- No `any`. No `console.log` in production paths.

## Detailed Rules

See `.agents/rules/` for technology-specific rules:
- `angular_good_practices.md`
- `java_good_practices.md`
- `javascript_good_practices.md`
- `typescript_good_practices.md`
- `collaboration.md`
