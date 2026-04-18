# Team Collaboration Rules

## Context

This project is developed by **two people working simultaneously** on the same codebase. Git conflicts and accidental overwrites are a real risk. The agent must act conservatively at all times to protect the team's work.

---

## RULE 0 — Mandatory Sync for Significant Tasks

Before starting any task that qualifies as a **"Big Change"** (defined in `GEMINI.md`), the agent **MUST**:

1. **Synchronize**: Run `git pull` to avoid conflicts with the other developer's work.
2. **Context Check**: Read `.agents/AGENTS_CHANGELOG.md`. This file contains the most up-to-date information on what has been implemented recently, which may not yet be reflected in the code you are reading.
3. **Validate Scope**: Re-read the current task instructions in light of the newly pulled version.
4. **Ask if Unsure**: If the pulls create conflicts or clarify that the task is partially done, stop and ask the user for directions.

---

## RULE 1 — Never touch files outside the explicit scope

Before modifying, creating, or generating content in **any file**, verify that the file is within the scope of what was explicitly requested in the current task.

If the task is "add a method to `CombatService.java`", the agent:
- ✅ May edit `CombatService.java`
- ✅ May edit `CombatServiceTest.java` if tests were also requested
- ❌ Must NOT touch `GameStateService.java`, `TroopRepository.java`, or any other file — even if the agent detects something to improve

**When in doubt about whether a file is in scope: stop and ask.**

---

## RULE 2 — Always ask before any destructive action

The following actions are **always blocked** until the user explicitly confirms:

| Action | Examples |
|---|---|
| **Delete** a file or directory | `rm CombatService.java`, removing an Angular component |
| **Rename** a file or directory | Renaming `game.service.ts` to `game-state.service.ts` |
| **Move** a file to a different location | Moving a component to a different feature folder |

**The agent must describe exactly what it intends to do and wait for a yes/no confirmation before proceeding.**

Example of correct behaviour:
> "I need to rename `troopService.js` to `troop.service.js` to match the naming convention. This will affect the import in `gameEngine.js`. Do you want me to proceed?"

---

## RULE 3 — Propose, don't act, for out-of-scope improvements

If the agent notices a bug, a code smell, or an improvement opportunity in a file that is **outside the current scope**, it must:

1. Finish the requested task first.
2. At the end of the response, mention the finding as a **suggestion**, not a change.
3. Wait for the user to explicitly ask for that change in a new request.

**Never silently fix things outside the scope of the task.**

---

## RULE 4 — Summarise all file changes at the end of every response

After completing any task that involves file modifications, the agent must include a brief summary:

```
Files modified:
- src/game/engine/combat.js  →  added resolveBattle() function
Files created:
- src/game/engine/combat.test.js  →  unit tests for resolveBattle()
Files NOT touched: everything else
```

This gives both team members a clear audit trail of what changed in each interaction.
