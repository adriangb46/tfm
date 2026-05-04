# 🎨 Tareas: Frontend (Angular)

Este documento detalla las tareas asignadas para el desarrollo del Frontend Angular 20. El foco es la UI, UX y comunicación con el Middle Server.

---

## Sprint 1: Autenticación y Layout Base
*   [x] **Layout "Códice" (Global)**:
    *   Implementar `navbar` estable con posicionamiento fixed.
    *   Sistema de tokens SCSS y mixins responsivos.
*   [x] **Internacionalización (i18n)**:
    *   Sistema basado en Angular Signals (ES/EN).
    *   Traducción completa de Home, Lobby y Game.
*   [x] **Flujo de Acceso**:
    *   Integración de Login y Registro real con el Middle Server.

## Sprint 2: Lobby y Gestión de Partidas
*   [x] **Lobby Reestructurado**:
    *   Stack vertical de partidas activas/finalizadas.
    *   Modales de creación y unión de partidas.
*   [ ] **Visualización de Personajes**:
    *   Pantalla de selección de clanes con estadísticas reales desde `clans.yml`.

## Sprint 3: Refinamiento UI y Documentación
*   [x] **Refactorización de Reglas (Premium)**:
    *   Diseño editorial con glassmorphism.
    *   Actualización de ciclo de ventajas y mecánicas de combate.
*   [x] **Documentación Técnica**:
    *   Integración de Compodoc para el frontend.
    *   Actualización de `ui_screens.md`.

## Sprint 4: Experiencia de Juego (War)
*   [x] **Árbol Tecnológico (FOE Style)**:
    *   Diseño horizontal con tiers separados.
    *   Conexiones dinámicas con SVG (ángulos rectos).
    *   Navegación mediante arrastre (drag-to-scroll).
*   [ ] **Feedback de Combate**:

    *   Animaciones de llegada de tropas.
    *   Logs de batalla dinámicos con traducciones.
*   [ ] **Fog of War**:
    *   Ocultación de tropas enemigas lejanas (en coordinación con Middle Server).

---

## 🛡️ Notas de Diseño
*   **Premium Aesthetics**: Siempre usar glassmorphism, degradados suaves y tipografía moderna (Inter/Outfit).
*   **Responsividad**: Priorizar "Mobile First" usando los mixins `@include mobile` y `@include tablet`.
*   **Signals**: Usar Angular Signals para todo el estado reactivo.
