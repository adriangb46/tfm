# 🛠️ Tareas: Desarrollador A (Infraestructura y Motor)

Este documento detalla las tareas asignadas al **Desarrollador A** para la implementación del Middle Server. El foco principal es la comunicación en tiempo real y el bucle de eventos del juego.

---

## Sprint 1: Infraestructura y Seguridad
*   [ ] **Configurar Servidor Socket.IO**:
    *   Implementar la base en `src/connectors/socket-handler.js`.
    *   Habilitar CORS restringido al origen del Frontend.
*   [ ] **Middleware de Autenticación**:
    *   Validar JWT en el handshake de Socket.IO.
    *   Extraer `userId`, `characterId` y `clanId` del token y asociarlos al socket.
*   [ ] **Gestión de Salas (Rooms)**:
    *   Unir automáticamente a los jugadores a una sala identificada por el `gameId` al conectar.

## Sprint 2: El Motor de Tiempo (Time Wheel)
*   [ ] **Bucle Principal**:
    *   Crear `src/game/engine/time-wheel.js`.
    *   Implementar un `setInterval` de 1 segundo que recorra las partidas activas en `gameStore`.
*   [ ] **Procesador de Eventos**:
    *   Implementar la lógica para disparar eventos de la `eventQueue` (ej: llegada de tropas, fin de investigación).
    *   Asegurar que los eventos sean idempotentes.

## Sprint 3: Combate y Movimiento
*   [ ] **Acción de Ataque**:
    *   Calcular tiempo de viaje entre el atacante y el objetivo.
    *   Añadir el evento `ATTACK_ARRIVAL` a la cola de la partida.
*   [ ] **Resolución de Batallas**:
    *   Crear `src/game/engine/combat-resolver.js`.
    *   Calcular daños basados en tropas, salud de capital y ventajas de clan (tipo piedra-papel-tijera).

## Sprint 4: Ciclo de Vida del Juego
*   [ ] **Fases de Partida**:
    *   Lógica para transiciones automáticas: `waiting` -> `preparation` (5 min) -> `war`.
*   [ ] **Condiciones de Victoria**:
    *   Detectar cuando solo quedan 2 jugadores con salud en la capital y disparar el fin de la partida.

---

## 🛡️ Notas de Seguridad
*   **Validación**: Nunca confíes en el `userId` enviado en el payload; usa siempre el extraído del JWT.
*   **Sanitización**: Escapa cualquier string que venga del cliente antes de procesarlo.
*   **Logs**: No loguear nunca el contenido completo de los JWT.
