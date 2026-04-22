# Sprint 5 — MongoDB & Analytics
# DB Server · Viking Clan Wars · Java 25 + Spring Boot 3.x
# Fuente de verdad: db_server_sprints.md (sprint 5)
# Refs: proyect_arquitecture.md §4, §6 | rules/java_good_practices.md | rules/security.md

---

## Objetivo

Al final de este sprint el servidor debe:
- Conectar con MongoDB mediante Spring Data MongoDB y las variables de entorno `MONGODB_URL`.
- Persistir documentos `game_snapshots` y `battle_events` en MongoDB con los campos exactos definidos en §6 de la arquitectura.
- Exponer `POST /internal/analytics/snapshots` que el Middle llama cada ~2 horas.
- Escribir en MongoDB de forma **asíncrona** (`@Async`) — el endpoint responde `202 Accepted` inmediatamente y el write ocurre en segundo plano.
- Si MongoDB falla, **loguear el error** sin propagarlo al caller (fire-and-forget).
- Cumplir los nombres de campo exactos de la arquitectura: `gameId`, `snapshotAt`, `phase`, `players`, etc.
- Evitar el uso de Lombok para garantizar compatibilidad con Java 25.

---

## Punto de integración entre devs

```java
// dev_a crea los documentos de MongoDB y los repositorios
// dev_b implementa AnalyticsService (@Async) y AnalyticsController

// Acuerdo previo obligatorio (Interface First):
// AnalyticsService (dev_b define, dev_a puede mockear en tests):
CompletableFuture<Void> saveSnapshot(AnalyticsSnapshotRequestDto dto);
```

---

## DEV_A — Infraestructura MongoDB

### S5-A1 · MongoDB Config
archivo: `config/MongoConfig.java`
- `@Configuration` anotando la clase.
- La URI de conexión viene de `MONGODB_URL` (variable de entorno — nunca hardcodeada).
- El nombre de la base de datos se toma de la propiedad `spring.data.mongodb.database`.
- Añadir `@EnableAsync` aquí (o en una clase `AsyncConfig.java` separada).
- El `Executor` para `@Async` debe tener un número de threads configurable (default: `ASYNC_POOL_SIZE=4`).

### S5-A2 · GameSnapshotDocument
archivo: `infrastructure/mongodb/GameSnapshotDocument.java`
- `@Document(collection = "game_snapshots")`
- Campos **exactos** de la arquitectura §6 (no renombrar):
  - `_id` → gestionado por Spring Data (`@Id String id`)
  - `gameId` (String/UUID como String)
  - `snapshotAt` (Instant → se serializa como ISODate)
  - `phase` (String: "preparation" | "war" | "end")
  - `players` (List de objetos embebidos `PlayerSnapshotDto`)
- Sub-clase embebida `PlayerSnapshot`:
  - `characterId`, `clanId`, `economicCredits`, `researchCredits`, `capitalHealth`
  - `troops` (List de `TroopSnapshot`)
  - `unlockedResearches` (List<String>)
  - `eliminated` (boolean)
- Sub-clase `TroopSnapshot`: `troopId`, `typeId`, `currentPoints`, `deployed`
- NOTA: Usar clases internas estáticas o clases top-level. Sin Lombok.

### S5-A3 · BattleEventDocument
archivo: `infrastructure/mongodb/BattleEventDocument.java`
- `@Document(collection = "battle_events")`
- Campos **exactos** de la arquitectura §6:
  - `gameId`, `timestamp` (Instant), `attackerCharacterId`, `attackerClanId`
  - `defenderCharacterId`, `defenderClanId`
  - `attackerTotalPoints`, `defenderTotalPoints` (int)
  - `outcome` (String: "ATTACKER_WIN" | "DEFENDER_WIN")
  - `advantageApplied` (boolean), `advantageMultiplier` (double)
  - `attackerTroopsLost`, `defenderTroopsLost` (List<String> de UUIDs)
- Sin Lombok.

### S5-A4 · Repositorios MongoDB
archivos: `infrastructure/mongodb/GameSnapshotRepository.java` y `BattleEventRepository.java`
- Extienden `MongoRepository<T, String>` (Spring Data MongoDB).
- No necesitan métodos personalizados por ahora — solo los de `MongoRepository`.

---

## DEV_B — Service y Controller

### S5-B1 · AnalyticsSnapshotRequestDto
archivo: `api/dto/AnalyticsSnapshotRequestDto.java`
- Record Java con los campos del snapshot:
  - `gameId` (String, @NotBlank)
  - `snapshotAt` (String ISO8601, @NotBlank)
  - `phase` (String, @NotBlank: "preparation" | "war" | "end")
  - `players` (List, @NotNull @NotEmpty)
- Los sub-campos de `players` (troops, etc.) pueden ser `Object` o Maps — el DB Server NO los valida en profundidad, simplemente los persiste.
- Alternativa más robusta: usar registros anidados con los mismos campos de `GameSnapshotDocument`.

### S5-B2 · AnalyticsService (Interface + Implementation)
archivos: `domain/service/AnalyticsService.java` y `AnalyticsServiceImpl.java`
- `saveSnapshot(AnalyticsSnapshotRequestDto dto)`:
  - Anotado con `@Async` → se ejecuta en el pool de threads de `AsyncConfig`.
  - Devuelve `CompletableFuture<Void>` o `void` (ambos válidos con `@Async`).
  - Convierte el DTO a `GameSnapshotDocument` y llama a `GameSnapshotRepository.save()`.
  - Si falla: captura la excepción, loguea con nivel `ERROR` (usando SLF4J), y **NO propaga**.
  - NUNCA hace `throw` desde este método — el caller (controller) ya ha respondido 202.

### S5-B3 · AnalyticsController
archivo: `api/AnalyticsController.java`
- `@RestController` + `@RequestMapping("/internal/analytics")`
- Constructor explícito para inyección (sin Lombok).
- `POST /snapshots`:
  - Acepta `@Valid @RequestBody AnalyticsSnapshotRequestDto dto`
  - Llama a `analyticsService.saveSnapshot(dto)` (fire-and-forget — no espera el resultado)
  - Devuelve `ResponseEntity.accepted().build()` → **202 Accepted** inmediatamente
  - NO envuelve en `ApiResponse` — la respuesta es vacía (sin body de datos).

### S5-B4 · Tests

**AnalyticsServiceTest** (`domain/service/AnalyticsServiceTest.java`):
- Test `saveSnapshot_givenValidDto_shouldSaveDocumentToMongoDB`: mock del repositorio, verifica que `save()` se llama con los campos correctos.
- Test `saveSnapshot_givenMongoFailure_shouldLogErrorAndNotPropagate`: el repositorio lanza excepción, el método no la propaga (sin `assertThatThrownBy`).
- NOTA: Para testear `@Async` en unitario, invocar el método directamente en el impl (sin Spring context) para evitar que el executor asíncrono complique los asserts.

**AnalyticsControllerTest** (`api/AnalyticsControllerTest.java`):
- Test `saveSnapshot_givenValidDto_shouldReturn202`: verifica respuesta 202 con body vacío.
- Test `saveSnapshot_givenInvalidDto_shouldReturn400`: payload sin `gameId` → 400 con `VALIDATION_ERROR`.
- Test `saveSnapshot_givenAnyDto_shouldNotWaitForMongo`: verifica que el controller responde inmediatamente (mock del servicio no bloquea).

---

## Checklist de arquitectura y seguridad (security.md)

- [ ] ¿`MONGODB_URL` viene de variable de entorno — nunca hardcodeada?
- [ ] ¿`AnalyticsService.saveSnapshot()` tiene `@Async` y captura excepciones internamente?
- [ ] ¿El Controller devuelve **202 Accepted** (no 200 ni 201)?
- [ ] ¿Los nombres de campo en los documentos MongoDB coinciden **exactamente** con la arquitectura §6?
- [ ] ¿Se han evitado dependencias de Lombok para garantizar compatibilidad con Java 25?
- [ ] ¿El error de MongoDB se loguea con SLF4J y no se expone en la respuesta HTTP?

---

## application.properties — Añadir

```properties
# MongoDB Analytics (Sprint 5)
spring.data.mongodb.uri=${MONGODB_URL}
spring.data.mongodb.database=${MONGODB_DB_NAME:vikingclanwars}

# Pool de threads para @Async
ASYNC_POOL_SIZE=4
```

> ⚠️ `MONGODB_URL` ya estaba declarado en `application.properties` del Sprint 1.
> Solo añadir `spring.data.mongodb.database` si no existe.

---

## Definition of Done

```bash
./mvnw clean test                          # → BUILD SUCCESS (todos los tests en verde)
POST /internal/analytics/snapshots         # → 202 Accepted (body vacío)
# MongoDB recibe el documento en segundo plano
# Si MongoDB no está disponible → log ERROR, respuesta 202 igualmente
```

---

## Notas de integración con Sprint 6

En el Sprint 6 (Hardening), se añadirán tests de integración con Testcontainers para MongoDB.
Por ahora, los tests unitarios con Mockito son suficientes para el definition of done del Sprint 5.
