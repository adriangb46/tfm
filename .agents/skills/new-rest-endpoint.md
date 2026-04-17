---
name: new-rest-endpoint
description: Use this skill when the user wants to create a new internal REST endpoint between the Node.js middle server and the Java Spring Boot DB server. Triggers on phrases like "nuevo endpoint interno", "llamada del middle al db server", "persistir dato nuevo", "guardar en base de datos", or any request that involves the middle-to-dbserver HTTP communication.
---

# Skill: New Internal REST Endpoint (Middle ↔ DB Server)

## Context

- **Caller:** Node.js middle server (HTTP client using `fetch` or an `HttpClient` wrapper).
- **Server:** Java 25 + Spring Boot DB server.
- All endpoints are prefixed `/internal/`. They are not exposed to the internet.
- Every request from the middle must carry the handshake JWT: `Authorization: Bearer <token>`.
- The DB Server validates the token via `OncePerRequestFilter` on every request.
- Responses follow: `{ data: T }` on success, `{ code, message, timestamp }` on error.
- Code in **English**. Comments in **Spanish**.

---

## Step 1 — Clarify the endpoint

Before writing any code, confirm with the user:

1. **Purpose** — what data is being read or written?
2. **HTTP method and path** — propose one following the patterns in `proyect_arquitecture.md`. Ask for confirmation.
3. **Request body shape** (for POST/PUT) — define fields and types explicitly.
4. **Response body shape** — what does the DB Server return?
5. **Which database?** — PostgreSQL (operational data) or MongoDB (analytics only)?

Do not proceed until these are confirmed.

---

## Step 2 — DB Server: create the Request/Response DTOs

Location: `db-server/src/main/java/com/project/api/dto/`

```java
// DTO de petición — inmutable, validado con Bean Validation
public record <Entity>RequestDto(
    @NotBlank String fieldOne,
    @NotNull UUID fieldTwo
) {}

// DTO de respuesta — inmutable
public record <Entity>ResponseDto(
    UUID id,
    String fieldOne,
    // ...
) {}
```

Rules:
- Always use **records** for DTOs.
- Validate all request fields with Bean Validation annotations (`@NotNull`, `@NotBlank`, `@Size`, etc.).
- Never expose JPA entity objects directly from a controller. Always map to a DTO.

---

## Step 3 — DB Server: create or update the Controller

Location: `db-server/src/main/java/com/project/api/<domain>Controller.java`

```java
@RestController
@RequestMapping("/internal/<domain>")
@RequiredArgsConstructor
public class <Domain>Controller {

    private final <Domain>Service <domain>Service;

    @PostMapping                          // ajustar método y path según el caso
    public ResponseEntity<<Entity>ResponseDto> create(
            @Valid @RequestBody <Entity>RequestDto request) {
        // Delegar inmediatamente al servicio — cero lógica aquí
        var result = <domain>Service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }
}
```

---

## Step 4 — DB Server: create or update the Service

Location: `db-server/src/main/java/com/project/domain/service/<Domain>Service.java`

```java
@Service
@RequiredArgsConstructor
public class <Domain>Service {

    private final <Domain>Repository repository;

    @Transactional
    public <Entity>ResponseDto create(<Entity>RequestDto request) {
        // 1. Mapear DTO a entidad JPA
        var entity = new <Entity>();
        entity.setFieldOne(request.fieldOne());
        // ...

        // 2. Persistir
        var saved = repository.save(entity);

        // 3. Mapear entidad a DTO de respuesta
        return new <Entity>ResponseDto(saved.getId(), saved.getFieldOne());
    }
}
```

---

## Step 5 — DB Server: create or update the Repository

Location: `db-server/src/main/java/com/project/infrastructure/persistence/<Domain>Repository.java`

```java
public interface <Domain>Repository extends JpaRepository<<Entity>, UUID> {
    // Añadir métodos de consulta derivados si son necesarios
    // Optional<<Entity>> findByFieldOne(String fieldOne);
}
```

---

## Step 6 — Middle Server: create the HTTP client call

Location: `middle/src/db/<domain>.client.js`

```js
import { config } from '../config/index.js';
import { getHandshakeToken } from '../auth/handshake.js';

/**
 * Crea un nuevo <entity> en el DB server
 * @param {{ fieldOne: string, fieldTwo: string }} payload
 * @returns {Promise<{ id: string, fieldOne: string }>}
 */
export async function create<Entity>(payload) {
  const response = await fetch(`${config.dbServerUrl}/internal/<domain>`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${getHandshakeToken()}`,
    },
    body: JSON.stringify(payload),
  });

  if (response.status === 401) {
    // Token caducado — solicitar nuevo token y reintentar una vez
    await refreshHandshakeToken();
    return create<Entity>(payload);
  }

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`DB Server error [${error.code}]: ${error.message}`);
  }

  const { data } = await response.json();
  return data;
}
```

---

## Step 7 — DB Server: write the unit test

Location: `db-server/src/test/java/com/project/domain/service/<Domain>ServiceTest.java`

Apply the `create_unit_test` workflow logic:
- Use `@ExtendWith(MockitoExtension.class)`.
- Mock the repository with `@Mock`.
- Test: happy path, not-found case (if applicable), validation failure.

---

## Step 8 — Checklist before finishing

- [ ] DTO uses records with Bean Validation annotations.
- [ ] Controller is thin — zero business logic.
- [ ] Service is `@Transactional` on write methods.
- [ ] Middle client handles `401` with one automatic token refresh.
- [ ] Middle client throws a typed error (not a raw fetch failure) on non-OK responses.
- [ ] Unit test created for the service method.
- [ ] No entity objects leaked outside the service layer.
- [ ] Files modified listed at the end of the response.
