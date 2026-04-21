# Sprint 4 — Game Domain
# DB Server · Viking Clan Wars · Java 25 + Spring Boot 3.x
# Fuente de verdad: db_server_sprints.md (sprint 4)
# Refs: proyect_arquitecture.md §4, §5, §11 | rules/java_good_practices.md | rules/security.md

---

## Objetivo

Al final de este sprint el servidor debe:
- Proveer el ciclo de vida completo de un juego: creación, consulta de juegos activos, persistencia de estado (dump) y finalización.
- Proveer la funcionalidad crítica para que el servidor Middle pueda recuperar el estado tras un reinicio y persistir el estado periódicamente.
- Asegurar que `state_json` se guarde como String puro (sin procesar por Jackson) para que PostgreSQL lo trate nativamente como columna `JSONB`.
- Guardar el historial de `game_state_dumps` (solo operaciones de creación, nunca `UPDATE` ni `DELETE`), recuperando siempre el último registro (ordenando por `dumped_at` DESC con límite 1).
- Estar altamente optimizado para las consultas a `GET /internal/games/active`, añadiendo índices en `games(status)` si fuere necesario.
- Evitar el uso de dependencias de Lombok debido a incompatibilidades con versiones recientes en entornos Java 25.

---

## Punto de integración entre devs

```java
// dev_a define la interfaz GameService
// dev_b la consume en GameController y expone GameDumpService

// Acuerdo previo obligatorio (Interface First):
GameResponseDto createGame(CreateGameRequestDto dto);
GameResponseDto getGame(UUID id); // Incluye el último state dump
List<GameResponseDto> getActiveGames();
void endGame(UUID id, EndGameRequestDto dto); // Fija status=finished y registra winner_character_id

// Interfaces para GameDumpService a consumir:
void dumpState(UUID gameId, StateDumpRequestDto dto); // Inserta un nuevo volcado en game_state_dumps
```

---

## DEV_A — Domain & Persistence (Juegos y Participantes)

### S4-A1 · Game & GameParticipant Entities
archivos: `domain/model/Game.java` y `domain/model/GameParticipant.java`
- `@Entity` + `@Table(name = "games")` y `@Table(name = "game_participants")`.
- `Game`: `id` (UUID), `status` (String), `winnerCharacterId` (UUID, nullable), `createdAt`, `endedAt`.
- `GameParticipant`: `id` (UUID), `gameId` (UUID), `characterId` (UUID).
- **NOTA**: Codificar de forma nativa los constructores, getters y setters pertinentes (No usar `@Data`, `@Builder`, `@Getter` ni `@Setter` de Lombok).

### S4-A2 · GameRepository & GameParticipantRepository
archivos: `domain/repository/GameRepository.java` y `domain/repository/GameParticipantRepository.java`
- Interfaces iterando `JpaRepository`.
- `List<Game> findByStatusNot(String status)` (para buscar todos aquellos juegos en progreso o activos).

### S4-A3 · GameService (Interface + Implementation)
archivos: `domain/service/GameService.java` y `GameServiceImpl.java`
- `createGame`: Crea un juego nuevo predeterminado en su estado inicial, junto con sus participantes indicados.
- `getGame`: Recupera un juego por `UUID`, lanzará `EntityNotFoundException` en caso de no existir.
- `getActiveGames`: Llama al repositorio para recuperar juegos con `status != 'finished'`.
- `endGame`: Finaliza el juego ubicando `status='finished'`, asignando `winner_character_id`, y registrando la hora de `endedAt`.

---

## DEV_B — API, DTOs & Game State Dumps

### S4-B1 · GameStateDump Entity & Repository
archivos: `domain/model/GameStateDump.java` y `domain/repository/GameStateDumpRepository.java`
- `@Entity` + `@Table(name = "game_state_dumps")`
- Atributos: `id` (UUID), `gameId` (UUID), `stateJson` (String), `dumpedAt` (Instant).
- Repositorio: `Optional<GameStateDump> findFirstByGameIdOrderByDumpedAtDesc(UUID gameId)`.

### S4-B2 · GameDumpService (Interface + Implementation)
archivos: `domain/service/GameDumpService.java` y `GameDumpServiceImpl.java`
- `dumpState`: Inserta un nuevo record con el string JSON del estado en la DB.
- `getLatestDump`: Retorna el string estado más reciente de un juego dado o nada si no existe un dump.

### S4-B3 · API DTOs (Records)
archivos: `api/dto/`
- `CreateGameRequestDto`: parámetros e info de inicialización provisto por Middle.
- `GameResponseDto`: datos generales combinados de la entidad `Game` y el string JSON puro proveniente de su último state.
- `StateDumpRequestDto`: encapsula estíritamente la propiedad `stateJson` (como String).
- `EndGameRequestDto`: `winnerCharacterId` (opcional/nullable dado que puede acabar en empate o sin ganadores).

### S4-B4 · GameController
archivo: `api/GameController.java`
- `@RestController` + `@RequestMapping("/internal/games")`
- Constructor explícito para inyección por autowiring (sin Lombok).
- `POST /` $\rightarrow$ Delegará a `GameService.createGame`
- `GET /{id}` $\rightarrow$ Entregará status consultado con info mergeada.
- `GET /active` $\rightarrow$ Devolverá lista a Middle Server
- `PUT /{id}/state` $\rightarrow$ Creará snapshot vía `GameDumpService.dumpState`
- `POST /{id}/end` $\rightarrow$ Modificará a fin y determinará ganador.

---

## Checklist de arquitectura y seguridad (security.md)

- [ ] ¿`state_json` se gestiona estrictamente como un `String` opaco desde Java para que PostgreSQL lo trate de forma directa en JSONB?
- [ ] ¿Se garantiza la retención del histórico completo de snapshots en `game_state_dumps` verificando que exista un `C` (Create) absoluto, sin rastros de updates o deletes?
- [ ] ¿Es eficiente la consulta en `GET /internal/games/active` limitando la tracción masiva en base de datos?
- [ ] ¿Los Controller evitan estrictamente la devolución de `@Entity` al exterior exponiendo en su lugar `Record` DTOs?
- [ ] ¿Se ha evitado el uso de utilidades generativas (Lombok) para garantizar cero bugs nativos al entorno de Java 25?

---

## Definition of Done

```bash
./mvnw clean test                    # → BUILD SUCCESS (Tanto tests de capa de dominio como controlador en verde).
POST /internal/games                 # → 201 Created + GameResponseDto
GET /internal/games/active           # → 200 OK + [Lista activa de juegos]
PUT /internal/games/{id}/state       # → 200/204 de acuerdo a definición
POST /internal/games/{id}/end        # → 200 OK con juego cerrado exitosamente
```
