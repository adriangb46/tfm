---
name: combat-resolution
description: Use this skill when the user wants to implement, modify, or debug the battle resolution logic. Triggers on phrases like "resolver combate", "lógica de batalla", "cálculo de daño", "tropas que mueren", "ventaja de clan", "combate entre jugadores", "resolución de ataque", or any request involving how attacks are calculated and troops are lost.
---

# Skill: Combat Resolution

## Context

The combat resolution algorithm lives entirely in the **Middle Server** (`middle/src/game/engine/combat.js`).
It is called synchronously when a `TROOP_ARRIVAL` Time Wheel event fires.
The algorithm is the heart of the game — changes here affect every active game immediately.

Read `proyect_arquitecture.md` Section 9 (Combat Resolution Algorithm) before making any change.

---

## Step 1 — Understand the current state of the code

Before modifying anything:

1. Read the full `combat.js` module.
2. Read its unit tests (`combat.test.js`).
3. Identify exactly which part of the algorithm the user wants to change or implement.
4. If the change affects troop data (power, type, etc.), also read `clans.yml`.

Do not modify a single line until you understand what the current code does and where the change fits.

---

## Step 2 — Clarify the change with the user

If any of the following is ambiguous, **ask before coding**:

- Does the change affect the **advantage multiplier**? (currently `[PROPOSED — TBD]`)
- Does the change affect **HEAL-type troops**? (their role in combat is `[TBD]` — see architecture doc)
- Does the change affect **ultimate troops** (`power: 0`, `ultimate: true`)? (special path)
- Does the change affect **casualty resolution order**? (damaged first, then weakest tier)
- Does the change affect the **post-battle state** of surviving troops?

---

## Step 3 — Algorithm reference (do not deviate without user confirmation)

```
INPUTS:
  attackerTroops[]    — deployed troops arriving at target (currentPoints may be < maxPoints)
  defenderTroops[]    — troops with deployed=false in the target capital
  attackerClanId      — used to look up clan advantage
  defenderClanId      — used to look up clan advantage

STEP A — Apply clan advantage multiplier
  advantageMultiplier = ADVANTAGE_MULTIPLIER (env var, default 1.25)
                        if attackerClan has advantage over defenderClan, else 1.0
  attackerTotal = sum(t.currentPoints) × advantageMultiplier
  defenderTotal = sum(t.currentPoints)   // no multiplier on defender [TBD — confirm]

STEP B — Determine winner
  diff = attackerTotal - defenderTotal
  winner = diff > 0 ? 'ATTACKER' : 'DEFENDER'   // tie → DEFENDER wins

STEP C — Resolve casualties on the LOSING side
  pointsToAbsorb = Math.abs(diff)
  sortedLosers = sort losing side troops by:
    1. damaged first: currentPoints < maxPoints, ascending by currentPoints
    2. then healthy: ascending by maxPoints (weakest base tier first)
  
  for (troop of sortedLosers):
    if troop.currentPoints <= pointsToAbsorb:
      mark troop as DEAD, remove from game state
      pointsToAbsorb -= troop.currentPoints
    else:
      troop.currentPoints -= pointsToAbsorb
      break  // remaining troops are intact

STEP D — Post-battle state update
  if ATTACKER_WIN:
    surviving attacker troops: deployed=false, travelTargetGameId=null (return home)
    target capital health: [TBD — reduction mechanism not yet defined]
  if DEFENDER_WIN:
    surviving defender troops: remain in capital (deployed=false)
    surviving attacker troops: [TBD — do they return home damaged?]

STEP E — Ultimate troop special path
  if an ultimate troop (ultimate: true) is present among attackers:
    damage dealt = Math.floor(defenderCapitalHealth / 3)
    this replaces the standard point-sum for that troop only
    resolve after the standard battle for the non-ultimate troops
    [TBD — exact interaction between ultimate and standard troops in the same attack wave]
```

---

## Step 4 — Implementation structure

Keep the module **pure** — it receives state objects and returns a result. No side effects, no GameStore access, no I/O.

```js
/**
 * Resuelve el combate entre tropas atacantes y defensoras
 * @param {Object} params
 * @param {TroopInstance[]} params.attackerTroops
 * @param {TroopInstance[]} params.defenderTroops
 * @param {string} params.attackerClanId
 * @param {string} params.defenderClanId
 * @param {number} params.defenderCapitalHealth
 * @param {number} params.advantageMultiplier
 * @returns {CombatResult}
 */
export function resolveCombat({
  attackerTroops,
  defenderTroops,
  attackerClanId,
  defenderClanId,
  defenderCapitalHealth,
  advantageMultiplier,
}) {
  // implementación del algoritmo
}

/**
 * @typedef {Object} CombatResult
 * @property {'ATTACKER' | 'DEFENDER'} winner
 * @property {TroopInstance[]} survivingAttackers  // con currentPoints actualizados
 * @property {TroopInstance[]} survivingDefenders  // con currentPoints actualizados
 * @property {TroopInstance[]} deadTroops
 * @property {boolean} ultimateTriggered
 * @property {number} capitalDamageDealt           // [TBD]
 */
```

The caller (`TROOP_ARRIVAL` event handler) is responsible for applying the `CombatResult` to the `GameState` in the `GameStore`.

---

## Step 5 — Advantage matrix helper

The clan advantage table must be defined as a constant, not computed inline:

```js
// Ciclo de ventajas: A tiene ventaja sobre B
// FURY → IRON → RUNE → DIVINE → DEATH → SONG → FURY
export const CLAN_ADVANTAGES = {
  FURY:   'IRON',
  IRON:   'RUNE',
  RUNE:   'DIVINE',
  DIVINE: 'DEATH',
  DEATH:  'SONG',
  SONG:   'FURY',
};

/**
 * Comprueba si el atacante tiene ventaja sobre el defensor
 * @param {string} attackerClanId
 * @param {string} defenderClanId
 * @returns {boolean}
 */
export function hasAdvantage(attackerClanId, defenderClanId) {
  const attackerArchetype = getClanArchetype(attackerClanId); // leer de clans.yml en memoria
  const defenderArchetype = getClanArchetype(defenderClanId);
  return CLAN_ADVANTAGES[attackerArchetype] === defenderArchetype;
}
```

---

## Step 6 — Update or create unit tests

Every change to combat resolution **requires** updating `combat.test.js`.

Minimum test cases to cover:

| Scenario | What to assert |
|----------|----------------|
| Attacker overpowers defender | `winner === 'ATTACKER'`, correct dead troops, survivors have correct `currentPoints` |
| Defender repels attack | `winner === 'DEFENDER'`, correct dead troops |
| Tie | `winner === 'DEFENDER'` |
| Clan advantage applied | `attackerTotal` reflects multiplier |
| Damaged troop dies first | Correct casualty order |
| Weakest troop dies before stronger | Correct casualty order |
| Ultimate troop present | Special path triggers |
| Single troop on losing side | That troop absorbs all damage (may be partially damaged) |

Use `jest.useFakeTimers()` is not needed here — `resolveCombat` is a pure function.

---

## Step 7 — Checklist before finishing

- [ ] `resolveCombat` is a pure function (no side effects, no I/O).
- [ ] Advantage matrix uses `CLAN_ADVANTAGES` constant — not a hardcoded condition.
- [ ] Ultimate troop path is handled separately and clearly commented.
- [ ] All `[TBD]` items in the algorithm were either implemented per user decision or left as explicit `// [TBD]` comments in code.
- [ ] Unit tests updated — all scenarios in the table above are covered.
- [ ] No existing test deleted without user confirmation.
- [ ] Files modified listed at the end of the response.
