# Sprint 6 — Hardening, Integration Tests & Docker
# DB Server · Viking Clan Wars · Java 25 + Spring Boot 3.x
# Fuente de verdad: db_server_sprints.md (sprint 6)
# Refs: rules/security.md | rules/java_good_practices.md | proyect_arquitecture.md §10

---

## Objetivo

Al final de este sprint el servidor debe:
- Estar completamente cubierto por tests de integración utilizando **Testcontainers** (instancias reales de PostgreSQL y MongoDB, nada de H2 en memoria).
- Contar con un **Dockerfile** robusto, basado en `eclipse-temurin:25-jre` y utilizando un usuario no root (`appuser`).
- Superar con éxito los flujos `/arch-audit` y `/security-audit`, obteniendo una puntuación mínima de 80 y sin hallazgos de nivel CRITICAL o HIGH.

---

## Punto de integración entre devs

```java
// dev_a implementa la clase base de integración y la mitad de los perfiles
// dev_b implementa el resto de perfiles, el Dockerfile y pasa las auditorías

// Acuerdo previo obligatorio:
// Ambos desarrolladores deben acordar usar AbstractIntegrationTest para todos los tests,
// compartiendo la misma inicialización de los contenedores (PostgreSQL y MongoDB).
```

---

## DEV_A — Infraestructura de Tests e Integración Parte 1

### S6-A1 · AbstractIntegrationTest
archivo: `src/test/java/com/tfm/db_back/AbstractIntegrationTest.java` (o equivalente según estructura exacta)
- Clase base para todos los tests de integración.
- Anotada con `@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)`.
- Configurar `@Testcontainers` o arrancar los contenedores manualmente de forma estática para que se compartan entre todas las suites de test.
- Contenedores requeridos:
  - `PostgreSQLContainer("postgres:15-alpine")`
  - `MongoDBContainer("mongo:6.0")`
- Registrar las URLs dinámicas de los contenedores en las propiedades de Spring mediante `@DynamicPropertySource`.
- Flyway debe ejecutarse automáticamente sobre el contenedor de PostgreSQL.

### S6-A2 · Tests de Integración: AuthController
archivo: `src/test/java/com/tfm/db_back/api/AuthControllerIntegrationTest.java`
- Extender de `AbstractIntegrationTest`.
- Testear `POST /internal/auth/handshake` con el secret correcto (debe devolver 200 y el JWT válido) y con el secret incorrecto (debe devolver 401).

### S6-A3 · Tests de Integración: UserController
archivo: `src/test/java/com/tfm/db_back/api/UserControllerIntegrationTest.java`
- Extender de `AbstractIntegrationTest`.
- Múltiples tests (flujo de persistencia completa a testear en BD real):
  - Creación de usuario (comprobar que la clave se encriptó en base de datos real).
  - Búsqueda por ID y por username.
  - Actualización de avatar.
  - Casos de conflicto (username/email duplicado debe lanzar 409).

### S6-A4 · Tests de Integración: CharacterController
archivo: `src/test/java/com/tfm/db_back/api/CharacterControllerIntegrationTest.java`
- Extender de `AbstractIntegrationTest`.
- Testear creación de personajes para un usuario existente y aserciones sobre la base de datos real.

---

## DEV_B — Tests Parte 2, Docker y Auditorías

### S6-B1 · Tests de Integración: GameController
archivo: `src/test/java/com/tfm/db_back/api/GameControllerIntegrationTest.java`
- Extender de `AbstractIntegrationTest`.
- Flujo de test:
  1. Crear un juego.
  2. Obtener lista de juegos activos.
  3. Guardar snapshots usando testcontainers reales.
  4. Terminar juego.
- Validar aserciones directamente comprobando las filas insertadas en la base de datos si fuera necesario, o mediante el propio API.

### S6-B2 · Tests de Integración: AnalyticsController
archivo: `src/test/java/com/tfm/db_back/api/AnalyticsControllerIntegrationTest.java`
- Extender de `AbstractIntegrationTest`.
- Enviar payload de snapshot y comprobar que devuelve 202 Accepted.
- Opcionalmente (con Awaitility) comprobar que el documento se insertó asíncronamente en el MongoDBContainer en la colección `game_snapshots`.

### S6-B3 · Dockerfile
archivo: `Dockerfile` (en la raíz del servidor db_back)
- Imagen base: `eclipse-temurin:25-jre` (solo entorno de ejecución, la compilación de forma óptima usando un multi-stage build u opt-in asumiendo el JAR ya buildeado, según la política escogida).
- Usuario no privilegiado explícito:
  ```dockerfile
  RUN addgroup --system appgroup && adduser --system appuser --ingroup appgroup
  USER appuser
  ```
- Exposición correcta de puertos según el properties. Las variables de entorno en runtime sobreescribirán las variables de la base de datos y los secretos.

### S6-B4 · Resolución de Auditorías
- Ejecutar el workflow `/arch-audit` en la terminal de la Inteligencia Artificial.
- Ejecutar el workflow `/security-audit` en la terminal de la Inteligencia Artificial.
- **Corregir CUALQUIER error CRITICAL y HIGH** detectado en el proyecto.
- Ambas auditorías deben superar un score > 80.

---

## Checklist de arquitectura y seguridad

- [ ] ¿Se utilizan versiones reales de PostgreSQL y MongoDB en los tests de integración vía Testcontainers (cero uso de H2)?
- [ ] ¿El Dockerfile se ejecuta estrictamente como usuario no root?
- [ ] ¿Todas las dependencias y capas se encuentran testeadas bajo un entorno Spring real?
- [ ] ¿Se han subsanado las brechas de seguridad (HIGH/CRITICAL) de las auditorías?

---

## Definition of Done

```bash
./mvnw clean verify                        # Construcción y ejecución completa de tests de integración con Docker iniciado. Todos listados en Verde (SUCCESS).
docker build -t viking/db-server .         # Construye la imagen exitosamente y el usuario final de ejecución es verificado como distinto a root.
```
- Acreditar resultados superiores a >80 en `/arch-audit` y `/security-audit`.
