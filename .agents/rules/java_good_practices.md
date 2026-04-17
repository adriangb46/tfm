# Java 25 + Spring Boot Good Practices

## Project Structure

Follow a **layered architecture** within each bounded context:

```
src/main/java/com/project/
  config/           # Spring configuration beans
  security/         # JWT filters, security config
  api/              # REST controllers (thin layer, no business logic)
    dto/            # Request/Response DTOs
  domain/           # Business logic, domain models
    model/          # Entities / domain objects
    service/        # Domain services
    repository/     # Repository interfaces
  infrastructure/
    persistence/    # JPA repository implementations, PostgreSQL adapters
    mongodb/        # MongoDB repositories and document models
    http/           # Outbound HTTP clients (if any)
```

## Modern Java 25 Features

- Use **records** for DTOs and value objects. Never use mutable classes for data transfer.
  ```java
  // ✅ Correcto
  public record TroopResponseDto(String id, String type, int actionPoints, boolean deployed) {}
  ```
- Use **sealed classes** to model closed domain hierarchies (e.g. game phases, clan types, combat results).
  ```java
  public sealed interface GamePhase permits PreparationPhase, WarPhase, EndPhase {}
  ```
- Use **pattern matching** for `instanceof` and `switch` expressions. Never cast manually.
  ```java
  // ✅ Correcto
  String describe(GamePhase phase) {
      return switch (phase) {
          case PreparationPhase p -> "Preparation: " + p.durationSeconds() + "s";
          case WarPhase w        -> "War";
          case EndPhase e        -> "End";
      };
  }
  ```
- Use **text blocks** for SQL, JSON, or multi-line strings.
- Prefer **`var`** for local variables when the type is obvious from the right-hand side.

## REST Controllers

- Controllers must be **thin**: delegate all logic to the service layer immediately.
- Annotate controllers with `@RestController` and `@RequestMapping("/api/v1/...")`.
- Always specify the HTTP method explicitly (`@GetMapping`, `@PostMapping`, etc.).
- Return `ResponseEntity<T>` from all endpoints to allow explicit HTTP status control.
- Validate all incoming DTOs with Bean Validation (`@Valid`, `@NotNull`, `@Size`, etc.).
- Code in **English**. Comments in **Spanish**.

## Security — JWT

- The DB server issues a **startup handshake token** to the middle server. Validate this token on every inbound request from the middle server using a dedicated `OncePerRequestFilter`.
- Store the handshake token secret in environment variables. Never hardcode it.
- Use `spring-security-oauth2-resource-server` for JWT validation.
- All endpoints must be protected by default. Whitelist only what is explicitly public.

## Service Layer

- Services contain all business logic. Keep them framework-agnostic where possible.
- Use `@Transactional` on service methods that write to the database. Read-only methods use `@Transactional(readOnly = true)`.
- Never call a repository directly from a controller.
- Throw domain-specific exceptions (not generic `RuntimeException`) that are caught by the global exception handler.

## Exception Handling

- Use a single `@RestControllerAdvice` class to handle all exceptions globally.
- Map domain exceptions to appropriate HTTP status codes.
- Return a consistent error body structure:
  ```java
  public record ErrorResponse(String code, String message, Instant timestamp) {}
  ```
- Never expose stack traces or internal details in API responses.

## Persistence — PostgreSQL / JPA

- Use **Spring Data JPA** repositories. Extend `JpaRepository<Entity, Id>`.
- Define entities with `@Entity`. Use `UUID` as the primary key type.
- Use `@CreatedDate` and `@LastModifiedDate` from Spring Data Auditing.
- Write JPQL or native queries only when necessary. Prefer derived query methods for simple cases.
- Never use `FetchType.EAGER` on collections. Always use `LAZY` and fetch explicitly when needed.
- Use **Flyway** for database migrations. Never use `spring.jpa.hibernate.ddl-auto=create` in non-local environments.

## Persistence — MongoDB

- Use **Spring Data MongoDB** repositories for the analytics dump (every ~2 hours).
- Define MongoDB documents with `@Document`. Use a separate model from JPA entities.
- MongoDB models represent **snapshots** of game state for analytics, not live game data.
- Keep MongoDB writes asynchronous using `@Async` or reactive pipelines to avoid blocking the main flow.

## Testing

- Use **JUnit 5** and **Mockito** for unit tests.
- Use `@SpringBootTest` + `@AutoConfigureMockMvc` for integration tests. Use Testcontainers for PostgreSQL and MongoDB in integration tests.
- Unit tests must cover: service logic, combat resolution, resource calculation, phase transitions.
- Name tests using the pattern: `methodName_givenContext_shouldExpectedBehavior`.
  ```java
  @Test
  void resolveBattle_givenAttackerOverpowers_shouldReturnAttackerVictory() { ... }
  ```
- Do not test Spring wiring in unit tests. Test pure logic only.

## Naming Conventions

- Classes: `PascalCase`
- Methods and variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Packages: `lowercase`
- Code in **English**. Comments in **Spanish**.

## General Rules

- Never use field injection (`@Autowired` on fields). Use constructor injection.
- Use Lombok (`@RequiredArgsConstructor`) to reduce boilerplate on constructor injection.
- Do not suppress warnings without a comment explaining why.
- Enable and respect all compiler warnings.
- Keep dependencies minimal. Add a library only when it provides clear value.
