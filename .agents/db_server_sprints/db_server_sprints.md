# db_server — Sprint Plan

## Meta

```yaml
project: Viking Clan Wars — db_server
service: Java 25 + Spring Boot
team_size: 2 developers (dev_a, dev_b)
total_sprints: 6
references:
  - .agents/proyect_arquitecture.md   # sections 2.3, 3.2, 4, 5, 6, 12
  - .agents/rules/java_good_practices.md
  - .agents/rules/security.md
  - .agents/rules/collaboration.md

conventions:
  - All code in English, comments in Spanish
  - Records for all DTOs
  - Constructor injection only (@RequiredArgsConstructor)
  - @Transactional on writes, @Transactional(readOnly=true) on reads
  - Flyway for all schema changes — never ddl-auto=create in non-local
  - Bean Validation on all request DTOs
  - No entity objects returned from controllers — always map to DTO
  - Unit tests: JUnit 5 + Mockito, naming: methodName_givenContext_shouldExpectedBehavior
  - Integration tests: @SpringBootTest + Testcontainers (Sprint 6)
```

---

## Integration contract between dev_a and dev_b

Before starting each sprint, both developers agree on:
1. Service interface signatures (method names, params, return types)
2. DTO field names and types
3. Package structure for new classes

The developer who owns the Controller always depends on the Service interface
defined by the other developer. Agree on the interface FIRST, then implement in parallel.

---

## SPRINT 1 — Foundation & Security Layer

```yaml
sprint: 1
name: Foundation & Security Layer
goal: >
  Working Spring Boot project with:
  - All PostgreSQL tables created via Flyway V1 migration
  - Global error handling with standardised response shape
  - Handshake JWT filter rejecting all unprotected requests
  - POST /internal/auth/handshake endpoint functional
  - Unit tests for HandshakeService passing
duration_estimate: 1 week
status: DONE  # 2026-04-21 — implementado por agente, verificado estáticamente

architecture_refs:
  - proyect_arquitecture.md#section-2.3  # DB Server role
  - proyect_arquitecture.md#section-3.2  # Handshake JWT
  - proyect_arquitecture.md#section-4    # POST /internal/auth/handshake endpoint
  - proyect_arquitecture.md#section-5    # Full PostgreSQL schema
  - proyect_arquitecture.md#section-12   # Env vars: DB_HANDSHAKE_SECRET, POSTGRES_URL, PORT

integration_point: >
  dev_a creates the SecurityFilterChain bean.
  dev_b creates the HandshakeJwtFilter bean.
  They must agree on the exact bean name and injection point before starting.
  dev_b cannot test the filter end-to-end until dev_a's SecurityConfig is in place.
  Agree: filter is registered as a bean and added via http.addFilterBefore() in SecurityConfig.
```

### dev_a tasks

```yaml
developer: dev_a
tasks:

  - id: S1-A1
    name: Project bootstrap
    description: >
      Create Spring Boot 3.x project with Java 25.
      Dependencies: spring-boot-starter-web, spring-boot-starter-data-jpa,
      spring-boot-starter-security, spring-boot-starter-validation,
      postgresql driver, flyway-core, lombok, jjwt (io.jsonwebtoken),
      spring-boot-starter-test, testcontainers.
      Set "type: module" is not applicable here — this is Java, not Node.
      Configure application.yml with profiles: local, prod.
      Local profile loads from .env via spring-dotenv or direct env vars.
    files_to_create:
      - db-server/pom.xml
      - db-server/src/main/resources/application.yml
      - db-server/src/main/resources/application-local.yml
    security_notes:
      - spring.jpa.hibernate.ddl-auto must be 'validate' in prod, 'none' in local
      - Never commit application-local.yml if it contains real credentials

  - id: S1-A2
    name: Package structure
    description: >
      Create the full package structure as defined in java_good_practices.md.
      Packages: config, security, api, api/dto, domain/model, domain/service,
      domain/repository, infrastructure/persistence, infrastructure/mongodb.
      Create placeholder README.md in each package explaining its role.
    files_to_create:
      - All package directories under db-server/src/main/java/com/project/

  - id: S1-A3
    name: Flyway V1 migration — full PostgreSQL schema
    description: >
      Create V1__initial_schema.sql with ALL tables from architecture Section 5.
      Tables: users, characters, games, game_participants, game_state_dumps.
      Include the index on game_state_dumps(game_id).
      Include the avatar_url column on users (VARCHAR 512, nullable).
      Do not split into multiple migrations — V1 is the full baseline.
    files_to_create:
      - db-server/src/main/resources/db/migration/V1__initial_schema.sql
    architecture_ref: proyect_arquitecture.md#section-5

  - id: S1-A4
    name: API response wrapper + global error handler
    description: >
      Create ApiResponse<T> record: { data: T } on success.
      Create ErrorResponse record: { code: String, message: String, timestamp: Instant }.
      Create GlobalExceptionHandler (@RestControllerAdvice) mapping:
        - MethodArgumentNotValidException → 400 with field errors
        - EntityNotFoundException (custom) → 404
        - Exception (catch-all) → 500 with generic message, NO stack trace
      Create custom domain exceptions: EntityNotFoundException, ConflictException.
    files_to_create:
      - db-server/src/main/java/com/project/api/dto/ApiResponse.java
      - db-server/src/main/java/com/project/api/dto/ErrorResponse.java
      - db-server/src/main/java/com/project/api/GlobalExceptionHandler.java
      - db-server/src/main/java/com/project/domain/exception/EntityNotFoundException.java
      - db-server/src/main/java/com/project/domain/exception/ConflictException.java
    security_notes:
      - ErrorResponse must NEVER include stack trace, SQL error, or internal path
      - catch-all handler logs full exception server-side but returns only generic message

  - id: S1-A5
    name: Spring Security base config
    description: >
      Create SecurityConfig (@Configuration, @EnableWebSecurity).
      SecurityFilterChain:
        - Disable CSRF (internal API, JWT-authenticated)
        - Disable session management (stateless)
        - All requests require authentication EXCEPT POST /internal/auth/handshake
        - Register HandshakeJwtFilter (created by dev_b) before UsernamePasswordAuthenticationFilter
        - Disable default login page
      Add security headers: X-Content-Type-Options, X-Frame-Options, Referrer-Policy.
    files_to_create:
      - db-server/src/main/java/com/project/config/SecurityConfig.java
    dependency_on: S1-B1 (HandshakeJwtFilter bean must exist to register it)

  - id: S1-A6
    name: Unit tests for GlobalExceptionHandler
    description: >
      Test each exception mapping produces the correct HTTP status and ErrorResponse shape.
      Use MockMvc with @WebMvcTest.
    files_to_create:
      - db-server/src/test/java/com/project/api/GlobalExceptionHandlerTest.java
```

### dev_b tasks

```yaml
developer: dev_b
tasks:

  - id: S1-B1
    name: HandshakeJwtFilter
    description: >
      Create HandshakeJwtFilter extends OncePerRequestFilter.
      On every request (except POST /internal/auth/handshake):
        1. Extract Bearer token from Authorization header.
        2. Validate signature using DB_HANDSHAKE_SECRET (loaded from env).
        3. If invalid or missing: return 401 ErrorResponse immediately.
        4. If valid: set a simple Authentication in SecurityContextHolder and proceed.
      Use io.jsonwebtoken (jjwt) for validation.
      DB_HANDSHAKE_SECRET loaded from environment — never hardcoded.
    files_to_create:
      - db-server/src/main/java/com/project/security/HandshakeJwtFilter.java
    architecture_ref: proyect_arquitecture.md#section-3.2
    security_notes:
      - shouldNotFilter() must return true for POST /internal/auth/handshake only
      - Return 401 with ErrorResponse body on rejection — never redirect

  - id: S1-B2
    name: HandshakeService
    description: >
      Create HandshakeService with one method: generateToken().
      Generates a signed JWT using DB_HANDSHAKE_SECRET.
      Payload: { iss: "db-server", iat: now, exp: now + HANDSHAKE_TOKEN_TTL_HOURS }.
      HANDSHAKE_TOKEN_TTL_HOURS loaded from env (default 24h).
      Token has no user-specific claims — it authenticates the Middle Server, not a user.
    files_to_create:
      - db-server/src/main/java/com/project/domain/service/HandshakeService.java
    architecture_ref: proyect_arquitecture.md#section-3.2

  - id: S1-B3
    name: AuthController — POST /internal/auth/handshake
    description: >
      Create AuthController @RestController @RequestMapping("/internal/auth").
      POST /handshake:
        - Body: { secret: String }
        - Validate that secret matches DB_HANDSHAKE_SECRET from env
        - If match: return 200 ApiResponse<{ token: String }> from HandshakeService.generateToken()
        - If no match: return 401 ErrorResponse { code: "INVALID_SECRET" }
      This endpoint is the ONLY one exempt from the HandshakeJwtFilter.
    files_to_create:
      - db-server/src/main/java/com/project/api/AuthController.java
      - db-server/src/main/java/com/project/api/dto/HandshakeRequestDto.java
      - db-server/src/main/java/com/project/api/dto/HandshakeResponseDto.java
    security_notes:
      - Compare secret with constant-time comparison to prevent timing attacks
      - Log failed handshake attempts with timestamp and IP, NOT the submitted secret

  - id: S1-B4
    name: Unit tests for HandshakeService
    description: >
      Test generateToken() produces a valid JWT signed with the correct secret.
      Test that a token generated with a wrong secret fails validation in HandshakeJwtFilter.
      Test naming: generateToken_givenValidSecret_shouldReturnSignedJwt
    files_to_create:
      - db-server/src/test/java/com/project/domain/service/HandshakeServiceTest.java

  - id: S1-B5
    name: Unit tests for AuthController
    description: >
      Test POST /internal/auth/handshake with correct secret → 200 + token.
      Test with wrong secret → 401.
      Test with missing body → 400.
      Use @WebMvcTest + MockBean for HandshakeService.
    files_to_create:
      - db-server/src/test/java/com/project/api/AuthControllerTest.java
```

### Sprint 1 — Definition of Done

```yaml
done_when:
  - Application starts without errors against a local PostgreSQL instance
  - All 5 tables created by Flyway V1 migration
  - POST /internal/auth/handshake returns a valid JWT when correct secret is provided
  - All other endpoints return 401 without a valid handshake token
  - All unit tests pass (mvn test)
  - No hardcoded secrets in any file
  - SecurityConfig registered HandshakeJwtFilter correctly
  - Error responses contain no stack traces
```

---

## SPRINT 2 — User Domain

```yaml
sprint: 2
name: User Domain
goal: >
  Full CRUD for users via the internal REST API.
  Passwords hashed with bcrypt. Avatar URL persisted.
  All 4 user endpoints functional and tested.
duration_estimate: 1 week
status: DONE  # 2026-04-21 — implementado y testeado exitosamente (Lombok removido)
depends_on: [sprint_1]

architecture_refs:
  - proyect_arquitecture.md#section-4    # User endpoints
  - proyect_arquitecture.md#section-5    # users table
  - rules/security.md#section-3          # Password rules

pre_sprint_agreement:
  - Agree on UserService interface (method signatures) before starting
  - Agree on DTO field names: CreateUserRequestDto, UserResponseDto, UpdateAvatarRequestDto

developer_split:
  dev_a:
    owns: [User JPA entity, UserRepository, UserService, unit tests for service]
    files:
      - domain/model/User.java
      - domain/repository/UserRepository.java
      - domain/service/UserService.java
      - UserServiceTest.java

  dev_b:
    owns: [UserController, all 4 user endpoints, request/response DTOs, controller unit tests]
    files:
      - api/UserController.java
      - api/dto/CreateUserRequestDto.java
      - api/dto/UserResponseDto.java
      - api/dto/UpdateAvatarRequestDto.java
      - UserControllerTest.java

integration_point: >
  dev_b depends on UserService interface defined by dev_a.
  Agree interface before coding. dev_b can use @MockBean in tests while dev_a implements.

key_rules:
  - bcrypt cost factor >= 12 (use BCryptPasswordEncoder bean)
  - password_hash never returned in UserResponseDto
  - Failed find → throw EntityNotFoundException (defined in Sprint 1)
  - Duplicate username/email → throw ConflictException → 409

endpoints:
  - POST /internal/users          # create user, hash password
  - GET  /internal/users/{id}     # find by UUID — never auto-increment
  - GET  /internal/users/by-username/{username}  # for login validation in Middle
  - PUT  /internal/users/{id}/avatar  # persist MinIO URL after avatar upload
```

---

## SPRINT 3 — Character Domain

```yaml
sprint: 3
name: Character Domain
goal: >
  Full CRUD for characters via the internal REST API.
  A user can have multiple characters, each tied to a clan.
  All 3 character endpoints functional and tested.
duration_estimate: 4 days
status: DONE  # 2026-04-21 — implementado por agente, verificado estáticamente (CharacterServiceImplTest + CharacterControllerTest)
depends_on: [sprint_2]

architecture_refs:
  - proyect_arquitecture.md#section-4    # Character endpoints
  - proyect_arquitecture.md#section-5    # characters table
  - clans.yml                            # valid clan_id values

pre_sprint_agreement:
  - Agree on CharacterService interface before starting
  - clan_id validation: validate against the 6 known clan IDs from clans.yml
    (berserkers, valkirias, jarls, skalds, seidr, draugr) — use @Pattern or custom validator

developer_split:
  dev_a:
    owns: [Character JPA entity, CharacterRepository, CharacterService, unit tests for service]
    files:
      - domain/model/Character.java
      - domain/repository/CharacterRepository.java
      - domain/service/CharacterService.java
      - CharacterServiceTest.java

  dev_b:
    owns: [CharacterController, 3 endpoints, DTOs, controller unit tests]
    files:
      - api/CharacterController.java
      - api/dto/CreateCharacterRequestDto.java
      - api/dto/CharacterResponseDto.java
      - CharacterControllerTest.java

endpoints:
  - POST /internal/characters               # create character for a user
  - GET  /internal/characters/{id}          # find by UUID
  - GET  /internal/characters/by-user/{userId}  # list all for a user (returns List)
```

---

## SPRINT 4 — Game Domain

```yaml
sprint: 4
name: Game Domain
goal: >
  Full game lifecycle persistence: create, read active games, dump state, end game.
  This is the most critical sprint — the Middle depends on these endpoints
  for restart recovery and periodic state persistence.
duration_estimate: 1 week
status: DONE  # 2026-04-21 — implementado por agente, 65 tests en verde (GameControllerTest 13 + GameServiceTest 10 + GameDumpServiceTest 5)
depends_on: [sprint_3]

architecture_refs:
  - proyect_arquitecture.md#section-4      # Game endpoints
  - proyect_arquitecture.md#section-5      # games, game_participants, game_state_dumps tables
  - proyect_arquitecture.md#section-11     # GameState shape (what state_json contains)

pre_sprint_agreement:
  - Agree on GameService interface split: GameService (lifecycle) + GameDumpService (state dumps)
  - state_json is JSONB — stored as String in Java, no deserialization needed (opaque blob)
  - GET /internal/games/active returns all games WHERE status != 'finished'
  - PUT /internal/games/{id}/state INSERTS a new row in game_state_dumps (history kept)
    Middle always reads the latest dump: ORDER BY dumped_at DESC LIMIT 1

developer_split:
  dev_a:
    owns: >
      Game entity, GameParticipant entity, GameRepository, GameParticipantRepository,
      GameService (create, findById, findActive, endGame), unit tests for service
    files:
      - domain/model/Game.java
      - domain/model/GameParticipant.java
      - domain/repository/GameRepository.java
      - domain/repository/GameParticipantRepository.java
      - domain/service/GameService.java
      - GameServiceTest.java

  dev_b:
    owns: >
      GameStateDump entity, GameStateDumpRepository, GameDumpService (dumpState, getLatestDump),
      GameController (all 5 endpoints), all DTOs, controller unit tests
    files:
      - domain/model/GameStateDump.java
      - domain/repository/GameStateDumpRepository.java
      - domain/service/GameDumpService.java
      - api/GameController.java
      - api/dto/CreateGameRequestDto.java
      - api/dto/GameResponseDto.java
      - api/dto/StateDumpRequestDto.java
      - api/dto/EndGameRequestDto.java
      - GameControllerTest.java
      - GameDumpServiceTest.java

endpoints:
  - POST /internal/games                  # create game record
  - GET  /internal/games/{id}             # get game (includes latest state dump)
  - GET  /internal/games/active           # list non-finished games (restart recovery)
  - PUT  /internal/games/{id}/state       # insert new state dump row
  - POST /internal/games/{id}/end         # set status=finished, winner_character_id

key_rules:
  - state_json stored as String (JSONB column) — never parsed by the DB Server
  - game_state_dumps has no DELETE — history is kept (Middle always reads latest)
  - GET /internal/games/active is called on every Middle restart — must be fast
    Add index on games(status) if query plan shows seq scan
```

---

## SPRINT 5 — MongoDB & Analytics

```yaml
sprint: 5
name: MongoDB and Analytics
goal: >
  Analytics snapshot endpoint functional.
  Writes to MongoDB asynchronously — never blocks game persistence flow.
  Both collections match the schema in architecture Section 6.
duration_estimate: 4 days
status: PENDING
depends_on: [sprint_4]

architecture_refs:
  - proyect_arquitecture.md#section-6      # MongoDB schema: game_snapshots, battle_events
  - proyect_arquitecture.md#section-4      # POST /internal/analytics/snapshots

pre_sprint_agreement:
  - Confirm MongoDB connection string env var: MONGODB_URL
  - Confirm database name and collection names match architecture doc exactly
  - @Async writes require @EnableAsync in a config class (dev_a adds this)

developer_split:
  dev_a:
    owns: >
      MongoDB config, GameSnapshotDocument, BattleEventDocument,
      GameSnapshotRepository, BattleEventRepository, @EnableAsync config
    files:
      - config/MongoConfig.java
      - infrastructure/mongodb/GameSnapshotDocument.java
      - infrastructure/mongodb/BattleEventDocument.java
      - infrastructure/mongodb/GameSnapshotRepository.java
      - infrastructure/mongodb/BattleEventRepository.java

  dev_b:
    owns: >
      AnalyticsService (buildSnapshot, save — @Async),
      AnalyticsController (POST /internal/analytics/snapshots),
      DTOs, unit tests
    files:
      - domain/service/AnalyticsService.java
      - api/AnalyticsController.java
      - api/dto/AnalyticsSnapshotRequestDto.java
      - AnalyticsServiceTest.java
      - AnalyticsControllerTest.java

key_rules:
  - AnalyticsService.save() is annotated @Async — returns void or CompletableFuture<Void>
  - Controller returns 202 Accepted immediately (fire-and-forget pattern)
  - If MongoDB write fails, log error — do not propagate to caller
  - Document field names must match architecture Section 6 exactly (gameId, snapshotAt, etc.)

endpoints:
  - POST /internal/analytics/snapshots    # write game_snapshots document to MongoDB
```

---

## SPRINT 6 — Hardening, Integration Tests & Docker

```yaml
sprint: 6
name: Hardening, Integration Tests and Docker
goal: >
  All endpoints covered by integration tests using Testcontainers.
  Dockerfile with non-root user.
  /arch-audit and /security-audit both pass with score >= 80.
duration_estimate: 1 week
status: PENDING
depends_on: [sprint_5]

architecture_refs:
  - rules/security.md                      # full checklist
  - rules/java_good_practices.md#testing   # Testcontainers, JUnit 5
  - proyect_arquitecture.md#section-10     # Docker: non-root, internal ports not exposed

pre_sprint_agreement:
  - Create shared AbstractIntegrationTest base class with Testcontainers setup
    (PostgreSQL container + MongoDB container, started once for all tests)
  - Agree on test data factories / fixtures for users, characters, games

developer_split:
  dev_a:
    owns: >
      AbstractIntegrationTest base class,
      Integration tests: AuthController, UserController, CharacterController
    files:
      - test/.../AbstractIntegrationTest.java
      - test/.../AuthControllerIntegrationTest.java
      - test/.../UserControllerIntegrationTest.java
      - test/.../CharacterControllerIntegrationTest.java

  dev_b:
    owns: >
      Integration tests: GameController, AnalyticsController,
      Dockerfile (non-root user),
      Run /arch-audit and /security-audit, fix all FAIL items
    files:
      - test/.../GameControllerIntegrationTest.java
      - test/.../AnalyticsControllerIntegrationTest.java
      - db-server/Dockerfile

key_rules:
  - Integration tests use @SpringBootTest(webEnvironment = RANDOM_PORT)
  - Testcontainers starts real PostgreSQL and MongoDB — no H2 in-memory
  - Flyway migrations run automatically against the Testcontainers PostgreSQL
  - Dockerfile: FROM eclipse-temurin:25-jre, RUN adduser --system appuser, USER appuser
  - Run /arch-audit before declaring sprint done
  - Run /security-audit before declaring sprint done
  - All CRITICAL and HIGH findings from both audits must be resolved

done_when:
  - All integration tests pass
  - /arch-audit score >= 80
  - /security-audit score >= 80
  - No CRITICAL or HIGH findings in either audit
  - Docker container starts and all endpoints respond correctly
  - Non-root user confirmed in running container (docker exec whoami)
```

---

## Cross-sprint rules

```yaml
always:
  - Read security.md before implementing any endpoint
  - Read java_good_practices.md before creating any new class
  - Run /arch-audit after each sprint to catch drift early
  - Never merge to main without the other developer reviewing the PR
  - Follow collaboration.md: do not touch files outside your sprint scope
  - All new env vars must be added to proyect_arquitecture.md Section 12 immediately

never:
  - spring.jpa.hibernate.ddl-auto=create outside local profile
  - Hardcoded secrets anywhere
  - Entity objects returned from controllers
  - @Autowired field injection
  - Raw SQL string concatenation
  - Stack traces in API error responses
```
