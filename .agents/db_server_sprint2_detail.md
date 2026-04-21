# Sprint 2 — User Domain
# DB Server · Viking Clan Wars · Java 25 + Spring Boot 4.0.5
# Fuente de verdad: db_server_sprints.md (sprint 2)
# Refs: proyect_arquitecture.md §4, §5 | rules/java_good_practices.md | rules/security.md §3

---

## Objetivo

Al final de este sprint el servidor debe:
- Permitir el registro de usuarios con contraseñas hasheadas (BCrypt).
- Recuperar usuarios por UUID y por nombre de usuario (para login en Middle).
- Permitir la actualización de la URL del avatar.
- Cumplir estrictamente con la seguridad: nunca devolver el hash de la contraseña.
- Pasar todos los tests unitarios de servicio y controlador.

---

## Punto de integración entre devs

```
dev_a define la interfaz UserService (métodos, parámetros, retornos)
dev_b consume UserService en UserController

Acuerdo previo obligatorio (Interface First):
  - UserResponseDto getUser(UUID id)
  - UserResponseDto getUserByUsername(String username)
  - UserResponseDto createUser(CreateUserRequestDto dto)
  - void updateAvatar(UUID id, String avatarUrl)
```

---

## DEV_A — Domain & Persistence

### S2-A1 · User Entity
archivo: `domain/model/User.java`
- `@Entity` + `@Table(name = "users")`
- `id` (UUID), `username`, `email`, `passwordHash`, `avatarUrl`, `createdAt`.
- Usar JPA Auditing si es posible o `PrePersist` para `createdAt`.

### S2-A2 · UserRepository
archivo: `domain/repository/UserRepository.java`
- `JpaRepository<User, UUID>`
- `Optional<User> findByUsername(String username)`
- `boolean existsByUsername(String username)`
- `boolean existsByEmail(String email)`

### S2-A3 · UserService (Interface + Implementation)
archivo: `domain/service/UserService.java`
- `createUser`: Valida duplicados (409 Conflict), hashea password (BCrypt), guarda.
- `getUser`: Busca por UUID, lanza `EntityNotFoundException` (S1) si no existe.
- `getByUsername`: Busca por username para validación de login.
- `updateAvatar`: Actualiza `avatar_url` de un usuario existente.

### S2-A4 · BCrypt Bean
archivo: `config/SecurityConfig.java` (Modificar)
- Añadir `@Bean public PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(12); }`

---

## DEV_B — API & DTOs

### S2-B1 · User DTOs (Records)
archivo: `api/dto/`
- `CreateUserRequestDto`: `username`, `email`, `password` (con validation `@Size`, `@NotBlank`).
- `UserResponseDto`: `id`, `username`, `email`, `avatarUrl`, `createdAt` (NUNCA el hash).
- `UpdateAvatarRequestDto`: `avatarUrl` (con validation `@URL` o similar).

### S2-B2 · UserController
archivo: `api/UserController.java`
- `@RequestMapping("/internal/users")`
- `POST /` -> `createUser`
- `GET /{id}` -> `getUser`
- `GET /by-username/{username}` -> `getByUsername`
- `PUT /{id}/avatar` -> `updateAvatar`

---

## Checklist de seguridad Sprint 2 (security.md)

- [ ] ¿Costo de BCrypt >= 12?
- [ ] ¿El hash de la contraseña sale en algún DTO de respuesta? (Debe ser NO)
- [ ] ¿Se validan duplicados de username/email antes de crear?
- [ ] ¿Se usa UUID en todos los paths de la API?
- [ ] ¿Se lanzan las excepciones adecuadas (404, 409)?

---

## Definition of Done

```
./mvnw clean test         → BUILD SUCCESS
POST /internal/users      → 201 Created + UserResponseDto
GET /internal/users/{id}  → 200 OK
GET /internal/users/by-username/xxx → 200 OK
PUT /internal/users/{id}/avatar → 200 OK (o 204 No Content)
```
