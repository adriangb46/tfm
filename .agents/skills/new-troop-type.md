---
name: new-troop-type
description: Use this skill when the user wants to add a new troop or spell to the game, modify an existing one, or update the clans.yml game data file. Triggers on phrases like "añadir tropa", "nueva unidad", "modificar tropa", "cambiar stats", "nuevo hechizo", "editar clans.yml", or any request related to game entity data.
---

# Skill: New Troop Type (or Spell / Research Node)

## Context

- All game entity data (troops, spells, research nodes) lives in `clans.yml`.
- The Middle Server loads `clans.yml` at startup into memory. No live reload — a restart is needed to apply changes.
- `clans.yml` is the **single source of truth**. Never hardcode troop stats in application code.
- Code in **English**. Comments in **Spanish**.

---

## Step 1 — Clarify the new entity

Before touching any file, confirm with the user:

1. **Which clan** does the new entity belong to?
2. **Type:** troop (`ATTACK` or `HEAL`) or spell (`DAMAGE` or `HEAL`)?
3. **Tier:** base (no prerequisite), T2 (requires res_2), T3 (requires res_4), or ultimate?
4. **Stats to define:**
   - For troops: `apCost`, `trainingTimeSeconds`, `travelTimeSeconds`, `power`
   - For spells: `apCost`, `power`
   - Is it an ultimate? (`ultimate: true`, `power: 0`)
5. **Research prerequisite** — which `researchId` unlocks it? Does a new research node need to be created too?

Do not write anything until all stats are confirmed by the user.

---

## Step 2 — Add the entity to `clans.yml`

Follow the exact format of existing entries. Example for a new troop:

```yaml
- id: "<clan>_troop_<tier>"           # snake_case, único en todo el archivo
  name: "<Nombre en español>"
  type: ATTACK                        # ATTACK | HEAL
  apCost: 30
  trainingTimeSeconds: 60
  travelTimeSeconds: 70
  power: 120
  prerequisiteResearchId: "<clan>_res_<n>"   # omitir si es tropa base
```

Example for a new research node that unlocks the troop:

```yaml
- id: "<clan>_res_<n>"
  name: "<Nombre de la investigación>"
  description: "<Descripción corta>"
  rpCost: 40
  researchTimeSeconds: 45
  prerequisiteResearchId: "<clan>_res_<n-1>"   # omitir si es el primero
  unlocksId: "<clan>_troop_<tier>"
  unlocksType: "TROOP"                          # TROOP | SPELL
```

**Validation rules for `clans.yml`:**
- `id` must be globally unique across the entire file.
- `prerequisiteResearchId` must reference an existing research `id` within the same clan.
- `unlocksId` must reference an existing troop or spell `id` within the same clan.
- Power of `0` is only valid when `ultimate: true` is set.
- Do not modify any field of an existing entry without explicit user confirmation.

---

## Step 3 — Verify the Middle Server loader handles the new entity

Location: `middle/src/game/engine/clanLoader.js` (or equivalent loader module)

Check that the YAML loader correctly parses the new fields. If a new field is introduced (e.g. a new property not previously in any entry), update the loader's parsing logic and its JSDoc types.

If troops or spells are stored in a typed structure in memory, update the in-memory type definition:

```js
/**
 * @typedef {Object} TroopDefinition
 * @property {string} id
 * @property {string} name
 * @property {'ATTACK'|'HEAL'} type
 * @property {number} apCost
 * @property {number} trainingTimeSeconds
 * @property {number} travelTimeSeconds
 * @property {number} power
 * @property {boolean} [ultimate]
 * @property {string} [prerequisiteResearchId]
 */
```

---

## Step 4 — Verify combat resolution handles the new troop correctly

Open the combat resolution module (`middle/src/game/engine/combat.js` or equivalent) and check:

- [ ] Does the troop's `type` affect how it's counted in the battle sum? (`ATTACK` vs `HEAL`)
- [ ] If `ultimate: true`, does the special resolution path handle this troop? (deals 1/3 of target capital health — see `proyect_arquitecture.md` Section 9)
- [ ] Is the troop correctly sorted in the casualty resolution order? (weakest first, damaged first)

If any of these checks reveal a gap, flag it to the user before implementing a fix.

---

## Step 5 — Verify the Angular frontend reflects the new entity

If the frontend renders a list of available troops or the tech tree:

- Check that the component reads troop definitions from the data pushed by the Middle (via Socket.IO), not from a hardcoded list.
- If the frontend has a local type or enum that lists troop IDs, update it.

---

## Step 6 — Checklist before finishing

- [ ] New entity added to `clans.yml` with all required fields.
- [ ] No existing entry modified without user confirmation.
- [ ] `id` is globally unique in the file.
- [ ] All `prerequisiteResearchId` and `unlocksId` references are valid.
- [ ] Middle loader handles the new fields (no silent parsing failures).
- [ ] Combat resolution handles the new troop's type and ultimate flag.
- [ ] Frontend type definitions updated if applicable.
- [ ] Reminder to the user: **Middle Server restart required** to load the updated `clans.yml`.
- [ ] Files modified listed at the end of the response.
