---
description: crear test unitarios
---

# Workflow: /create_unit_test

## Trigger

This workflow is invoked with `/create_unit_test` from the Antigravity chat.

## Purpose

Generate comprehensive unit tests for the file currently open or explicitly referenced by the user. The tests must cover the real logic of the code, not just verify that methods exist.

---

## Step 1 — Identify the Target File and Technology

1. Determine which file needs tests (the open file, or the one named by the user).
2. Identify the technology layer from the file's extension and location:
   - `.component.ts` → **Angular component test** (Jasmine / Jest + Angular Testing Utilities)
   - `.service.ts` → **Angular service test** (Jasmine / Jest, with `TestBed` only if DI is required)
   - `.ts` (shared utility / domain logic) → **Pure TypeScript unit test** (Jest, no framework)
   - `.java` (service or domain class) → **JUnit 5 + Mockito test**
   - `.js` (Node.js service, engine, or utility) → **Jest or Vitest test**
3. If the layer is ambiguous, ask the user before proceeding.

---

## Step 2 — Read and Understand the Code

Before writing a single test:

1. Read the **entire target file**.
2. Identify every **public method or exported function**.
3. For each method, identify:
   - Its inputs and their types / constraints.
   - Its outputs or side effects.
   - **Edge cases**: empty collections, zero values, null/undefined inputs, boundary values.
   - **Error paths**: what should throw or return an error value.
4. Identify any **dependencies** (services, repositories, external clients) that must be mocked.

---

## Step 3 — Write the Tests

### General Rules for All Layers

- Each test must have a single, clear assertion focus.
- Test names must follow the pattern:
  `methodName_givenContext_shouldExpectedBehavior`
  Example: `resolveBattle_givenAttackerOverpowers_shouldReturnAttackerVictory`
- Do **not** test implementation details (private methods, internal state). Test observable behaviour.
- Do **not** write tests that always pass (trivial assertions like `expect(true).toBe(true)`).
- Cover at minimum:
  - ✅ Happy path
  - ✅ Boundary / edge cases
  - ✅ Error / failure path

---

### Angular — Component Tests

- Use `TestBed.configureTestingModule` only when component behaviour depends on Angular's DI or template rendering.
- For logic-only components, instantiate the class directly and test signal values.
- Mock all injected services using `jasmine.createSpyObj` or Jest `jest.fn()`.
- Test signal outputs by reading `.()` after triggering input changes.

```typescript
// Ejemplo de test de componente con signals
it('troops_givenDeployedTroop_shouldExcludeFromDefenseList', () => {
  const fixture = TestBed.createComponent(TroopListComponent);
  fixture.componentRef.setInput('troops', [mockDeployedTroop]);
  fixture.detectChanges();
  expect(fixture.componentInstance.defenseTroops()).toHaveLength(0);
});
```

---

### Angular — Service Tests

- Use `TestBed` only if the service has Angular-specific dependencies (e.g. `HttpClient`).
- Use `HttpTestingController` to intercept and assert HTTP calls.
- For pure logic services, instantiate directly with mocked constructor arguments.

---

### Java — JUnit 5 + Mockito

- Annotate the test class with `@ExtendWith(MockitoExtension.class)`.
- Mock dependencies with `@Mock`. Inject them with `@InjectMocks`.
- Use `@BeforeEach` for shared setup. Keep each test method self-contained.
- Use **`assertThrows`** to verify exception paths.
- Use **`verify`** to assert that collaborators were called correctly when side effects matter.

```java
@Test
void resolveBattle_givenDefenderHasMorePoints_shouldReturnDefenderVictory() {
    // Preparar — configurar datos del combate
    var attackers = List.of(new Troop("t1", TroopType.RAIDER, 10));
    var defenders = List.of(new Troop("t2", TroopType.SHIELD_WALL, 30));

    // Ejecutar
    var result = combatService.resolve(attackers, defenders, ClanAdvantage.NONE);

    // Verificar
    assertThat(result.winner()).isEqualTo(CombatResult.Winner.DEFENDER);
}
```

---

### Node.js — Jest

- Mock external dependencies (DB server HTTP client, Socket.IO) using `jest.mock()` or manual mocks.
- Test the time wheel event processing by injecting a fake clock (`jest.useFakeTimers()`).
- Test in-memory game state mutations by creating a fresh `GameStore` instance per test.
- Restore all mocks after each test using `afterEach(() => jest.restoreAllMocks())`.

```js
// Ejemplo: test del motor de resolución de batalla
test('resolveBattle_givenEqualPoints_shouldReturnDraw', () => {
  // Preparar — puntos iguales entre atacantes y defensores
  const attackers = [{ id: 't1', actionPoints: 20, currentPoints: 20 }];
  const defenders = [{ id: 't2', actionPoints: 20, currentPoints: 20 }];

  const result = resolveBattle(attackers, defenders, { advantage: null });

  expect(result.outcome).toBe('draw');
});
```

---

## Step 4 — Place the Test File

| Source file location | Test file location |
|---|---|
| `src/app/features/game/service.ts` | `src/app/features/game/service.spec.ts` |
| `src/main/java/com/.../CombatService.java` | `src/test/java/com/.../CombatServiceTest.java` |
| `src/game/engine/combat.js` | `src/game/engine/combat.test.js` |

---

## Step 5 — Final Checklist

Before presenting the tests, verify:

- [ ] Every public method has at least one test.
- [ ] At least one error / edge case is covered per method.
- [ ] No test depends on execution order (tests are fully isolated).
- [ ] All mocks are correctly typed and scoped.
- [ ] Test names are descriptive and follow the naming convention.
- [ ] Comments explaining the test intent are written in **Spanish**.
