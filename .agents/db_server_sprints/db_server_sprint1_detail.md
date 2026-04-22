# Sprint 1 — Foundation & Security Layer
# DB Server · Viking Clan Wars · Java 25 + Spring Boot 4.0.5
# Fuente de verdad: db_server_sprints.md (sprint 1)
# Refs: proyect_arquitecture.md §2.3, §3.2, §4, §5, §12 | rules/java_good_practices.md | rules/security.md

---

## Objetivo

Al final de este sprint el servidor debe:
- Arrancar limpiamente contra PostgreSQL local
- Crear las **5 tablas** del schema vía Flyway automáticamente (sin ddl-auto=create)
- Rechazar **toda petición** sin JWT de handshake válido → 401
- Resolver `POST /internal/auth/handshake` correctamente
- Responder errores con shape consistente `{ code, message, timestamp }`
- Pasar todos los tests: `./mvnw clean test` → BUILD SUCCESS

---

## Punto de integración entre devs (ACORDAR ANTES DE EMPEZAR)

```
dev_a crea SecurityConfig → registra HandshakeJwtFilter via http.addFilterBefore()
dev_b crea HandshakeJwtFilter → bean @Component

Acuerdo previo obligatorio:
  - nombre del bean: HandshakeJwtFilter (un @Component en security/)
  - se registra BEFORE UsernamePasswordAuthenticationFilter
  - dev_b puede implementar y testear el filtro en aislamiento con MockMvc
  - dev_a no puede completar S1-A5 hasta que el bean de dev_b exista
```

---

## DEV_A — Infraestructura & Security Config

### S1-A1 · application.yml

archivo: src/main/resources/application.yml

```yaml
# Configuración principal — todos los valores vienen de variables de entorno
spring:
  application:
    name: db-server
  datasource:
    url: ${POSTGRES_URL}
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: validate        # Flyway gestiona el schema, JPA solo valida
    show-sql: false
    open-in-view: false
  data:
    mongodb:
      uri: ${MONGODB_URL}
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  port: ${PORT:8080}

app:
  handshake-secret: ${DB_HANDSHAKE_SECRET}
  handshake-token-ttl-hours: ${HANDSHAKE_TOKEN_TTL_HOURS:24}
```

reglas:
- NUNCA ddl-auto=create fuera de entorno local (security.md §7)
- NUNCA credenciales reales en este archivo (solo ${ENV_VAR})
- open-in-view=false evita LazyInitializationException silenciosas

### S1-A2 · Estructura de paquetes

Crear bajo src/main/java/com/tfm/db_back/:

```
config/                    → @Configuration beans (AsyncConfig, etc.)
security/                  → OncePerRequestFilter, SecurityConfig
api/                       → @RestController (sin lógica de negocio)
  dto/                     → Records de Request/Response
domain/
  model/                   → @Entity JPA
  service/                 → lógica de negocio (@Transactional)
  repository/              → JpaRepository interfaces
  exception/               → excepciones de dominio tipadas
infrastructure/
  mongodb/                 → @Document + MongoRepository
```

### S1-A3 · Flyway V1 — Schema completo

archivo: src/main/resources/db/migration/V1__initial_schema.sql

```sql
-- Habilitar extensión para gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Usuarios del sistema
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username      VARCHAR(50)  UNIQUE NOT NULL,
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  avatar_url    VARCHAR(512),
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  modify_at     TIMESTAMPTZ
);

-- Personajes (un usuario puede tener varios)
CREATE TABLE characters (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES users(id),
  clan_id    VARCHAR(50) NOT NULL,
  name       VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Registro de partidas
CREATE TABLE games (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status               VARCHAR(20) NOT NULL DEFAULT 'waiting',
  max_players          SMALLINT    NOT NULL CHECK (max_players BETWEEN 2 AND 6),
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at           TIMESTAMPTZ,
  ended_at             TIMESTAMPTZ,
  winner_character_id  UUID REFERENCES characters(id)
);

-- Participantes de cada partida
CREATE TABLE game_participants (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id          UUID     NOT NULL REFERENCES games(id),
  character_id     UUID     NOT NULL REFERENCES characters(id),
  join_order       SMALLINT NOT NULL,
  eliminated       BOOLEAN  NOT NULL DEFAULT false,
  eliminated_at    TIMESTAMPTZ,
  UNIQUE (game_id, character_id)
);

-- Volcados periódicos del estado (cada ~15 min desde el Middle)
CREATE TABLE game_state_dumps (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id     UUID  NOT NULL REFERENCES games(id),
  state_json  JSONB NOT NULL,
  dumped_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_game_state_dumps_game_id ON game_state_dumps(game_id);
```

### S1-A4 · GlobalExceptionHandler + DTOs de error

archivos a crear:

```
api/dto/ErrorResponse.java          → record(String code, String message, Instant timestamp)
api/dto/ApiResponse.java            → record<T>(T data)  — wrapper de éxito
api/GlobalExceptionHandler.java     → @RestControllerAdvice
domain/exception/EntityNotFoundException.java  → extends RuntimeException
domain/exception/ConflictException.java        → extends RuntimeException
```

mapeo de excepciones en GlobalExceptionHandler:

```
EntityNotFoundException            → 404  code=NOT_FOUND
ConflictException                  → 409  code=CONFLICT
MethodArgumentNotValidException    → 400  code=VALIDATION_ERROR
Exception (catch-all)              → 500  code=INTERNAL_ERROR  mensaje genérico, sin stack trace
```

regla security.md §8: catch-all LOGUEA completo server-side, devuelve solo mensaje genérico al cliente

### S1-A5 · SecurityConfig

archivo: config/SecurityConfig.java

```java
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    // Filtro creado por dev_b — inyectado por Spring
    private final HandshakeJwtFilter handshakeJwtFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(s -> s.sessionCreationPolicy(STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(POST, "/internal/auth/handshake").permitAll()
                .anyRequest().authenticated()
            )
            .addFilterBefore(handshakeJwtFilter, UsernamePasswordAuthenticationFilter.class)
            .headers(h -> h
                .contentTypeOptions(withDefaults())
                .frameOptions(fo -> fo.deny())
            )
            .build();
    }
}
```

dependency_on: HandshakeJwtFilter bean (S1-B1 de dev_b)

### S1-A6 · Tests dev_a

archivo: test/.../GlobalExceptionHandlerTest.java  (@WebMvcTest)
casos:
- givenEntityNotFoundException_shouldReturn404WithCode_NOT_FOUND
- givenMethodArgumentNotValid_shouldReturn400WithCode_VALIDATION_ERROR
- givenUnhandledException_shouldReturn500_andResponseBodyHasNoStackTrace

---

## DEV_B — Handshake JWT & Auth Endpoint

### S1-B1 · HandshakeJwtFilter

archivo: security/HandshakeJwtFilter.java  (extends OncePerRequestFilter, @Component)

logica:
1. shouldNotFilter() → true si ruta es POST /internal/auth/handshake
2. Extraer "Authorization: Bearer <token>" del header
3. Si ausente → response 401 + body ErrorResponse
4. Validar firma con DB_HANDSHAKE_SECRET via JJWT (Jwts.parser().verifyWith(key))
5. Si inválido/expirado → 401 + ErrorResponse
6. Si válido → SecurityContextHolder.setAuthentication(new PreAuthenticatedToken(...)) + continuar

reglas:
- NUNCA loguear el token completo (security.md §11)
- Responder 401 con body ErrorResponse (mismo shape que GlobalExceptionHandler)
- DB_HANDSHAKE_SECRET se inyecta via @Value("${app.handshake-secret}")

### S1-B2 · HandshakeService

archivo: domain/service/HandshakeService.java

metodo principal: String generateToken()
- Construye JWT con JJWT: issuer="db-server", iat=now, exp=now+ttlHours*3600
- Firma con SecretKey derivada de DB_HANDSHAKE_SECRET (Keys.hmacShaKeyFor(secret.getBytes(UTF_8)))
- Sin claims de usuario — autentica al Middle Server como servicio, no como user
- TTL configurable via app.handshake-token-ttl-hours (default 24h)

metodo auxiliar: boolean validateToken(String token) — usado internamente por el filtro

### S1-B3 · AuthController

archivo: api/AuthController.java
mapping: @RequestMapping("/internal/auth")

endpoint: POST /handshake
  body_in:  HandshakeRequestDto { @NotBlank String secret }
  body_out 200: ApiResponse<HandshakeResponseDto> { data: { token: "..." } }
  body_out 401: ErrorResponse { code: "INVALID_SECRET", message: "...", timestamp: "..." }

logica del handler:
  1. @Valid valida que secret no sea blank
  2. Comparar secret con DB_HANDSHAKE_SECRET en tiempo constante (MessageDigest.isEqual)
  3. Si coincide → return 200 con HandshakeService.generateToken()
  4. Si no coincide → throw nueva excepción que el handler mapee a 401
  5. Loguear intentos fallidos con IP y timestamp (NUNCA el secret enviado)

DTOs a crear:
  api/dto/HandshakeRequestDto.java   → record(@NotBlank String secret)
  api/dto/HandshakeResponseDto.java  → record(String token)

### S1-B4 · Tests dev_b

archivo: test/.../HandshakeServiceTest.java
casos:
- generateToken_givenValidConfig_shouldReturnNonNullJwt
- generateToken_givenGeneratedToken_shouldBeValidatableWithSameSecret
- validateToken_givenTokenSignedWithDifferentSecret_shouldReturnFalse

archivo: test/.../AuthControllerTest.java  (@WebMvcTest + @MockBean HandshakeService)
casos:
- handshake_givenCorrectSecret_shouldReturn200AndToken
- handshake_givenWrongSecret_shouldReturn401WithCodeInvalidSecret
- handshake_givenBlankSecret_shouldReturn400ValidationError
- handshake_givenNoBody_shouldReturn400

---

## Checklist de seguridad pre-PR (security.md §12)

- [ ] Sin secrets hardcodeados en ningún archivo (grep DB_HANDSHAKE_SECRET)
- [ ] ddl-auto=validate, no create
- [ ] ErrorResponse sin stack traces ni mensajes internos de JPA
- [ ] HandshakeJwtFilter rechaza con 401 cualquier request sin token válido
- [ ] POST /internal/auth/handshake whitelisted tanto en filtro como en SecurityConfig
- [ ] Tests cubren el rechazo con token inválido
- [ ] application.yml solo tiene ${ENV_VAR}, sin valores reales
- [ ] Comparación de secret en tiempo constante (no String.equals)

---

## Definition of Done

```
./mvnw clean test         → BUILD SUCCESS, 0 failures
Flyway                    → crea las 5 tablas al arrancar contra Postgres local
POST /internal/auth/handshake secret correcto    → 200 + JWT
POST /internal/auth/handshake secret incorrecto  → 401 ErrorResponse
GET  /internal/cualquier-ruta sin token          → 401 (HandshakeJwtFilter activo)
grep -r "DB_HANDSHAKE_SECRET" src/               → 0 matches con valor hardcodeado
PR revisado por el otro desarrollador            → aprobado antes de merge a main
```

---

## Resumen de archivos a crear

| Archivo (relativo a src/main/java/com/tfm/db_back/) | Dev |
|---|---|
| resources/application.yml | A |
| resources/db/migration/V1__initial_schema.sql | A |
| config/SecurityConfig.java | A |
| api/dto/ErrorResponse.java | A |
| api/dto/ApiResponse.java | A |
| api/GlobalExceptionHandler.java | A |
| domain/exception/EntityNotFoundException.java | A |
| domain/exception/ConflictException.java | A |
| test/.../GlobalExceptionHandlerTest.java | A |
| security/HandshakeJwtFilter.java | B |
| domain/service/HandshakeService.java | B |
| api/AuthController.java | B |
| api/dto/HandshakeRequestDto.java | B |
| api/dto/HandshakeResponseDto.java | B |
| test/.../HandshakeServiceTest.java | B |
| test/.../AuthControllerTest.java | B |

archivos NO tocados: DbBackApplication.java, pom.xml, Dockerfile, .github/workflows/**
