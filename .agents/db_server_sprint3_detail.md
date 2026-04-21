# Sprint 3 — Character Domain
# DB Server · Viking Clan Wars · Java 25 + Spring Boot 4.0.5
# Fuente de verdad: db_server_sprints.md (sprint 3)
# Refs: proyect_arquitecture.md §4, §5 | rules/java_good_practices.md | rules/security.md

---

## Objetivo

Al final de este sprint el servidor debe:
- Permitir la creación de personajes asociados a un `user_id` y a un `clan_id` válido.
- Recuperar un personaje específico por su UUID.
- Recuperar la lista completa de personajes pertenecientes a un usuario concreto.
- Validar rigurosamente que el `clan_id` pertenece a uno de los 6 clanes válidos (`berserkers`, `valkirias`, `jarls`, `skalds`, `seidr`, `draugr`).
- Evitar problemas de compilación en Java 25 no utilizando dependencias de Lombok.

---

## Punto de integración entre devs

```java
// dev_a define la interfaz CharacterService
// dev_b la consume en CharacterController

// Acuerdo previo obligatorio (Interface First):
CharacterResponseDto createCharacter(CreateCharacterRequestDto dto);
CharacterResponseDto getCharacter(UUID id);
List<CharacterResponseDto> getCharactersByUser(UUID userId);
```

---

## DEV_A — Domain & Persistence

### S3-A1 · Character Entity
archivo: `domain/model/Character.java`
- `@Entity` + `@Table(name = "characters")`
- Atributos: `id` (UUID), `userId` (UUID, mapeado manual o `@ManyToOne`), `clanId` (String), `name` (String), `createdAt` (Instant).
- NOTA: Codificar de forma nativa los constructores, getters y setters (No usar `@Data`, `@Builder`, `@Getter` ni `@Setter` de Lombok).
- Usar `@PrePersist` para inicializar `createdAt`.

### S3-A2 · CharacterRepository
archivo: `domain/repository/CharacterRepository.java`
- `JpaRepository<Character, UUID>`
- `List<Character> findByUserId(UUID userId)`
- `boolean existsByName(String name)` (Opcional, si decidimos que los nombres deben ser únicos globalmente).

### S3-A3 · CharacterService (Interface + Implementation)
archivo: `domain/service/CharacterService.java` y `UserServiceImpl.java`
- `createCharacter`: Crea el personaje validando que el user exista.
- `getCharacter`: Busca por UUID, lanza `EntityNotFoundException` si no existe.
- `getCharactersByUser`: Llama a `findByUserId` del repositorio.

---

## DEV_B — API & DTOs

### S3-B1 · Character DTOs (Records)
archivo: `api/dto/`
- `CreateCharacterRequestDto`: `userId` (UUID), `clanId` (String), `name` (String).
  - Validaciones: `@NotBlank` y `@Size(max=100)` para `name`.
  - Validación de clanes: Usar `@Pattern(regexp = "^(berserkers|valkirias|jarls|skalds|seidr|draugr)$", message="Clan inválido")` en `clanId`.
- `CharacterResponseDto`: `id`, `userId`, `clanId`, `name`, `createdAt`.

### S3-B2 · CharacterController
archivo: `api/CharacterController.java`
- `@RestController` + `@RequestMapping("/internal/characters")`
- Constructor explícito para la inyección (sin Lombok).
- `POST /` -> `createCharacter`
- `GET /{id}` -> `getCharacter`
- `GET /by-user/{userId}` -> `getCharactersByUser`

---

## Checklist de arquitectura y seguridad (security.md)

- [ ] ¿Se ha evitado el uso de Lombok para evadir bugs de compilación en Java 25?
- [ ] ¿Se valida el enum/string de `clan_id` mediante `@Pattern` en el RequestDto?
- [ ] ¿El Controller devuelve Records y NO la Entidad `Character` expuesta de hibernate?
- [ ] ¿Las recuperaciones usan el `EntityNotFoundException` implementado en S1?

---

## Definition of Done

```bash
./mvnw clean test         # → BUILD SUCCESS (sin errores de Annotation Processors)
POST /internal/characters               # → 201 Created + CharacterResponseDto
GET /internal/characters/{id}           # → 200 OK
GET /internal/characters/by-user/{id}   # → 200 OK + [CharacterResponseDto...]
```
