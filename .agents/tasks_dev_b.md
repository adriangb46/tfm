# ⚔️ Tareas: Desarrollador B (Lógica y Estado)

Este documento detalla las tareas asignadas al **Desarrollador B** para la implementación del Middle Server. El foco principal es la lógica interna, la persistencia y el mantenimiento del estado.

---

## Sprint 1: Conectividad y Persistencia
*   [x] **Cliente REST (DB Connector)**:
    *   Implementar `src/connectors/db-connector.js` para comunicarse con el DB Server (Spring Boot).
*   [x] **Handshake de Seguridad**:
    *   Implementar la solicitud del token de handshake al arrancar el servidor.
    *   Almacenar y renovar el token automáticamente si expira.
*   [x] **Sincronización de Partidas**:
    *   Cargar el estado inicial de las partidas desde el DB Server al `gameStore`.
    *   Implementar el volcado periódico (cada 15 min) del estado de memoria a la DB.

## Sprint 2: Economía y Gestión de Unidades
*   [x] **Generación de Recursos**:
    *   Lógica de "ticks" económicos: sumar créditos a los jugadores según el tiempo transcurrido.
*   [x] **Entrenamiento de Tropas**:
    *   Implementar acción en `src/game/actions/game-actions.js` para reclutar unidades.
    *   Validar que el jugador tenga créditos suficientes y los requisitos tecnológicos.

## Sprint 3: Árbol Tecnológico (Investigación)
*   [x] **Sistema de Investigaciones**:
    *   Implementar la acción de iniciar investigación (consume créditos de investigación).
    *   Gestionar el estado `researchInProgress` en el modelo `Player`.
*   [x] **Aplicación de Mejoras (Buffs)**:
    *   Lógica para que las tecnologías desbloqueadas afecten a las estadísticas (ej: +10% daño, -5% coste).

## Sprint 4: Sincronización del Cliente (Frontend)
*   [ ] **Emisores de Estado**:
    *   Asegurar que cada acción (reclutar, atacar, investigar) dispare un evento de actualización al cliente.
*   [ ] **Filtrado de Datos (Fog of War)**:
    *   Antes de emitir el estado a un socket, filtrar información que el jugador no debería ver (ej: tropas enemigas que no están en su territorio).

---

## 🛡️ Notas de Seguridad
*   **UUIDs**: Usar siempre UUIDs para identificar partidas y jugadores en las comunicaciones.
*   **Validación de Negocio**: Verificar siempre en el servidor si un jugador puede permitirse una acción (nunca confiar en el estado del Front).
*   **Secretos**: Los tokens y claves del DB Server deben ir en variables de entorno, nunca en el código.
