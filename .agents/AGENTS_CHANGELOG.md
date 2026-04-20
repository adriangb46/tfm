# Agents Activity Changelog

---

## [2026-04-21] Corrección y Centralización de Workflows de GitHub Actions

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Resolver los fallos en los workflows de CI/CD del servidor de base de datos (`db_back`) y poblar los flujos inexistentes del `middle_server` y `frontend`.

### 📝 Resumen de Tareas Realizadas:

1. **Reparación de DB Server (`db_back`)**:
   - **Fix de Case Sensitivity**: Se ha implementado un paso de shell en `build-docker.yml` para transformar el nombre de la imagen a minúsculas. Esto soluciona el error de "invalid reference format" que impedía el push a GHCR.
   - **Estandarización de Dockerfile**: Renombrado `dockerfile` a `Dockerfile` y actualizado el workflow.
   - **Fix de .dockerignore**: Eliminada la exclusión de `Dockerfile` que impedía que Docker leyera el archivo de configuración durante la construcción.
   - **Estabilización de CI**: Verificada la compatibilidad con Java 25 y las versiones de acciones `v6/v5`.

2. **Implementación de Middle Server**:
   - **Pipeline de CI**: Creado `middle_server_compile.yml` con Node.js 20, instalación de dependencias y validación sintáctica del entrypoint.
   - **Pipeline de Docker**: Creado `middle-server-docker.yml` para automatizar la construcción y publicación de la imagen.

3. **Implementación de Frontend**:
   - **Pipeline de CI**: Creado `front_ci.yml` para validar la compilación de Angular en cada push.
   - **Pipeline de Docker**: Creado `front_docker.yml` para empaquetar la app en una imagen Nginx.

4. **Workflow de Raíz (`tfm`) - Orquestador Agregador**:
   - **Estrategia de Agregación**: Rediseñado `main-ci.yml` para actuar como un "hub" de imágenes.
   - **Simplificación de Seguridad**: Tras hacer los repositorios públicos, se ha eliminado la dependencia de `GH_PAT`.
   - **Control Manual de Ejecución**: Se han desactivado los disparadores automáticos (`push`, `pull_request`) en todos los workflows (`root`, `db_back`, `middle_server`, `front`). Ahora todos usan `workflow_dispatch`, permitiendo la ejecución manual bajo demanda desde la pestaña Actions de GitHub para optimizar el control y el consumo de recursos.
   - **Pull & Re-tag**: El workflow descarga las imágenes ya compiladas, las re-etiqueta bajo el namespace del proyecto raíz y las publica.
   - **Bundle de Infraestructura**: Incluye Postgres, Redis, MongoDB y MinIO en el mismo namespace para un despliegue unificado.

### 🗂️ Archivos Creados/Modificados:

| Archivo | Acción |
|---------|--------|
| `docker-compose.yml` | Modificado (Nombres Dockerfile) |
| `.github/workflows/main-ci.yml` | **REDISEÑADO** (Orquestador Full Stack) |
| `db_back/.github/workflows/build-docker.yml` | Modificado (Fix lowercase) |
| `middle_server/.github/workflows/middle_server_compile.yml` | Poblado (Node CI) |
| `middle_server/.github/workflows/middle-server-docker.yml` | **CREADO** |
| `front/.github/workflows/front_ci.yml` | Poblado (Angular CI) |
| `front/.github/workflows/front_docker.yml` | **CREADO** |

---

## [2026-04-20] Refinamiento de Navbar: Layout Centrado y Logo Mythic

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Transformar la navegación global a un diseño de 3 columnas con el logo a la izquierda y el menú centrado para una estética más simétrica y premium.

### 📝 Resumen de Tareas Realizadas:

1. **Reestructuración de Layout**:
   - Implementación de `display: grid` con `grid-template-columns: 1fr auto 1fr`.
   - **Corrección de Overflow**: Se ha forzado `grid-template-rows: 72px` y se ha restringido el `logo-section` para evitar que las dimensiones del logo desplacen los enlaces. Se ha mantenido el `overflow` visible en la Navbar para permitir ver el desplegable de usuario.
   - Centrado matemático de los enlaces de navegación (`Home`, `Lobby`, etc.) independientemente del contenido lateral.
   - Incremento de la altura de la navbar a `72px` para mejorar la jerarquía visual.

2. **Integración de Marca**:
   - Inserción del componente oficial `app-logo` (Cabeza de lobo y hachas) en el extremo izquierdo.
   - **Mejora de Layout**: Se ha actualizado `LogoComponent` para soportar una disposición horizontal (`direction="horizontal"`), permitiendo que el texto aparezca a la derecha del icono en la Navbar, optimizando el espacio vertical.
   - Sincronización de estilos rúnicos y tipografía `Outfit`.

3. **Mejoras Estéticas y UX**:
   - **Animaciones Glow**: Nuevo efecto de subrayado expansivo con brillo dorado al hacer hover/active.
   - **Dropdown Refinado**: Ajuste de posicionamiento y animación de entrada para el menú de usuario.
   - **Responsividad**: Ocultamiento del texto del logo y ajuste de gaps en pantallas menores a 900px.

### 🗂️ Archivos Modificados:

| Archivo | Acción |
|---------|--------|
| `front/src/app/shared/components/navbar/navbar.component.ts` | Import de `LogoComponent` |
| `front/src/app/shared/components/navbar/navbar.component.html` | Nueva estructura de grid |
| `front/src/app/shared/components/navbar/navbar.component.scss` | Rediseño completo de estilos |

---

## [2026-04-20] Resolución de Desbordamientos y Responsividad Global

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Corregir errores de overflow vertical y horizontal reportados por el usuario, eliminando el scroll fantasma en el juego y el desborde en Configuración.

### 📝 Resumen de Tareas Realizadas:

1. **Refactorización de Layout Global (`styles.scss`)**:
   - Sincronización de `height` entre `html`, `body` y `app-root` usando `min-height: 100%` y `height: 100dvh`.
   - Implementación de `overflow-x: hidden` en el body para prevenir scrolls horizontales accidentales.

2. **Corrección de Configuración (`ConfigComponent`)**:
   - **Eliminación de Altura Fija**: Cambiado `height: 100%` por `flex: 1` para que respete el espacio de la Navbar.
   - **Layout Adaptativo**: Las secciones de la tarjeta ahora se envuelven (`flex-wrap`) y el grid pasa de `320px 1fr` a `1fr` en pantallas móviles.
   - **Gaps y Paddings**: Sustitución de valores fistas (`5rem`, `160px`) por `clamp()` y unidades responsivas.

3. **Eliminación de Scroll en Juego (`GamePageComponent`)**:
   - Cambio de `:host` de `100vh/100vw` a `100%` para integrarse perfectamente en el contenedor `main`.

4. **Ajustes de Responsividad en Home y Estadísticas**:
   - **Home**: Corregido el grid de clanes que desbordaba por un `min-width` excesivo.
   - **Estadísticas**: Títulos y contenedores ahora usan `clamp()` para escalas tipográficas fluidas.

### 🗂️ Archivos Modificados:

| Archivo | Cambio |
|---------|--------|
| `front/src/styles.scss` | Refactor de layout base |
| `front/src/app/pages/config/config.component.scss` | Rediseño responsivo |
| `front/src/app/pages/game/game.component.scss` | Corrección de scroll (100%) |
| `front/src/app/pages/home/home.component.scss` | Fix de grid de clanes |
| `front/src/app/pages/statistics-view/statistics.component.scss` | Tipografía fluida |

---


## [2026-04-20] Restauración de Layout y Corrección Técnica (ConfigComponent)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Corregir errores de compilación y restaurar el diseño original de dos columnas (barra lateral + formulario) por petición del usuario.

### 📝 Resumen de Tareas Realizadas:

1. **Corrección de Errores Técnicos (Manteniendo Estabilidad)**:
   - **TypeScript**: Asegurada la definición de `onChangeLanguage` y métodos de guardado/cancelación.
   - **SASS Imports**: Corregida la ruta a `variables.scss` (`../../../styles/variables`).
   - **SASS Deprecations**: Cambiado `lighten()` por `color.adjust()` para compatibilidad con Sass 3.0.
   - **Ajuste de Layout**: Corregido el desborde (overflow) causado por la navbar cambiando `100vh` por `100%` y configurando el host flex.

2. **Restauración de Diseño Original**:
   - **Estructura de Grid**: Se ha recuperado el layout de dos columnas (`280px 1fr`).
   - **Sidebar de Perfil**: Re-introducida la barra lateral izquierda para el Avatar y el Nombre de Usuario, siguiendo el diseño aprobado en `config-preview.html`.
   - **Formulario Centrado**: Las preferencias y ajustes se han re-ubicado en la columna principal derecha.

3. **Optimización Estética**:
   - Se ha mantenido el look "premium" con hero banner atmosférico y tarjetas con glassmorphism.

### 🗂️ Archivos Modificados:

| Archivo | Acción |
|---------|--------|
| `front/src/app/pages/config/config.component.ts` | Corrección técnica |
| `front/src/app/pages/config/config.component.html` | Restauración de layout |
| `front/src/app/pages/config/config.component.scss` | Restauración de estilos |

---

## [2026-04-20] Configuración de CI/CD: Workflow de Docker para db_back

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Automatizar la construcción y publicación de la imagen Docker del servidor de base de datos (`db_back`).

### 📝 Resumen de Tareas:

1. **Creación de Workflow**:
   - Definición de `build-docker.yml` para GitHub Actions.
   - Configuración de disparadores en `push` a `main` y etiquetas de versión.
   - Integración con **GitHub Container Registry (GHCR)** para el almacenamiento de imágenes.
   - Implementación de caché nativa de GitHub Actions (`gha`) para optimizar tiempos de construcción.
   - Uso de metadatos automáticos para el etiquetado de imágenes (`latest`, rama, SHA corto).

### 🗂️ Archivos Creados/Modificados:

| Archivo | Acción |
|---------|--------|
| `db_back/.github/workflows/build-docker.yml` | **CREADO** |

---

## [2026-04-20] Integración y Refinamiento Premium de Configuración (UserConfig)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Transformar la pantalla de configuración en una experiencia integrada, responsive y de alto impacto visual, eliminando la sensación de "modal" y optimizando el flujo de preferencias.

### 📝 Resumen de Mejoras:

1. **Diseño Integrado (Full Screen)**:
   - Eliminación de márgenes laterales para una integración total en la pantalla (`integrated look`).
   - Implementación de un layout de altura fija (`100vh`) con `overflow: hidden` para evitar scroll innecesario, optimizando para una estética de aplicación premium.
   - Banner heroico con tipografía **Cinzel** y fondo atmosférico vikingo.

2. **Refuerzo de UX y Layout**:
   - **Estructura de Dos Columnas**: Sidebar dedicado al avatar (con nuevo badge de edición tipo lápiz) y formulario principal de preferencias.
   - **Secciones de Acción**: Unificación de "Seguridad" y "Preferencias" en tarjetas visuales con botones de acción directa en lugar de inputs redundantes.
   - **Preferencias Agrupadas**: El selector de idioma y el toggle de modo oscuro ahora conviven en una misma tarjeta de preferencias para mayor claridad.

3. **Mejoras Técnicas y Estéticas**:
   - Uso estricto de variables SCSS del proyecto (`$color-gold`, `$color-bg-primary`, etc.).
   - Implementación de un `toggle-switch` personalizado con estética oro/navy.
   - Refactorización de la lógica del componente para soportar el nuevo flujo de cambio de idioma y tema.

### 🗂️ Archivos Modificados:

| Archivo | Acción |
|---------|--------|
| `front/src/app/pages/config/config.component.html` | Rediseño completo de la estructura |
| `front/src/app/pages/config/config.component.scss` | Implementación de estilos integrados y responsive |
| `front/src/app/pages/config/config.component.ts` | Actualización de lógica y señales |

---

---

## [2026-04-20] Rediseño Estético Premium de Personajes y Reglas (Códice MYTHIC)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Transformar las pantallas informativas de "feísimas" a una experiencia visual "WOW" de alta gama, utilizando tipografía épica, efectos atmosféricos y diseño inmersivo.

### 📝 Resumen de Mejoras Estéticas:

1. **Infraestructura Visual**:
   - **Tipografía**: Integración de **Cinzel** (para títulos y runas) y **Montserrat** (para lectura fluida) vía Google Fonts en `index.html`.
   - **Atmósfera**: Implementación de fondos radiales profundos, auroras boreales animadas y partículas de brasas (`embers`) flotantes.

2. **Rediseño de Personajes (Códice de Linajes)**:
   - **Tarjetas 3D**: Implementación de transformaciones en perspectiva al hacer hover.
   - **Detalles Forjados**: Bordes con acentos metálicos, runas que brillan intermitentemente y degradados específicos por clan.
   - **Iconografía**: Enormes iconos de fondo con baja opacidad y glow dinámico según el arquetipo del clan.

3. **Rediseño de Reglas (Leyes de la Guerra)**:
   - **Visualización Técnica**: La matriz de ventajas ahora utiliza un grid estilizado con degradados semánticos de "Victoria/Derrota".
   - **Timeline de Eras**: Línea de tiempo vertical con nodos brillantes y efectos de profundidad.
   - **Bloques de Leyes**: Uso de bordes laterales dorados y cajas de advertencia pulsantes para las reglas críticas.

4. **Experiencia de Usuario (UX)**:
   - Botones de navegación con efectos de cristal (glassmorphism) y feedback visual mejorado.
   - Animaciones de entrada escalonadas (`staggered entry`) para todos los elementos de la lista.

### 🗂️ Archivos Modificados:

| Archivo | Acción |
|---------|--------|
| `front/src/index.html` | Inyección de Google Fonts |
| `front/src/app/pages/personajes-page/*` | Rediseño completo (HTML/SCSS) |
| `front/src/app/pages/reglas-page/*` | Rediseño completo (HTML/SCSS) |

---

## [2026-04-20] Corrección de errores de navegación y limpieza de código (Front)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Resolver errores de navegación a rutas inexistentes, eliminar advertencias del compilador de Angular y cumplir con la regla de "No any" en el proyecto.

### 📝 Resumen de Tareas Realizadas:

1. **Corrección de Navegación**:
   - **`HomeComponent`**: Se ha cambiado la navegación de `/lobby` (ruta inexistente) a `/game` para permitir el acceso a la pantalla principal de juego desde el "Hero Section".

2. **Limpieza de Advertencias y Tipado**:
   - **`HomeComponent`**: Eliminado el import y la inclusión de `RouterLink` en el array de `imports` ya que no se estaba utilizando en el template.
   - **`GamePageComponent`**: Eliminados 6 usos de `any` en la definición de la señal `availableTroops`, sustituyéndolos por el enum `TroopType` correspondiente.

3. **Optimización SVG**:
   - **`GamePageComponent.html`**: Actualizada la sintaxis de `xlink:href` a `href` estándar en los elementos del camino de ataque animado.

### 🗂️ Archivos Modificados:

| Archivo | Cambio |
|---------|--------|
| `front/src/app/pages/home/home.component.ts` | Corregida navegación y eliminada advertencia |
| `front/src/app/pages/game/game.component.ts` | Eliminación de `any` (tipado estricto) |
| `front/src/app/pages/game/game.component.html` | Corrección de sintaxis SVG |

---

## [2026-04-20] Rediseño a Pantalla Completa de Configuración

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Aplicar el flujo `/refine-ui` para rediseñar la vista de configuración desde un formato modal/tarjeta a un formato de pantalla completa.

### 📝 Resumen de Tareas Realizadas:

1. **Iteraciones en el Preview**:
   - Cambiado el layout a un `grid` de pantalla completa con barra superior simulada.
   - Perfil de usuario movido a una barra lateral izquierda (`.profile-sidebar`).
   - Sección de Preferencias cambiada a ancho completo (`.full-width-section`).
   - Igualadas las alturas de las tarjetas de la cuadrícula mediante `display: flex` y `height: 100%`.
   - Ajustados márgenes, gaps y tamaños para asegurar que la pantalla sea responsive y encaje sin scroll vertical.
   - Eliminados los bordes de todas las tarjetas y aplicado el fondo `var(--color-bg-card)` en lugar de `var(--color-bg-secondary)` para seguir estrictamente la guía de estilos.

2. **Paso a Producción (Angular)**:
   - Sobrescrito `config.component.html` con la nueva estructura de grid.
   - Sobrescrito `config.component.scss` con los nuevos estilos de cuadrícula, secciones, barra lateral y layout responsive.

---
## [2026-04-20] Finalización del CI para db_back

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Establecer y configurar correctamente el flujo de Integración Continua (CI) para el servidor de base de datos (Java 25 + Spring Boot) utilizando GitHub Actions.

### 📝 Resumen de Tareas Realizadas:

1. **Configuración de GitHub Actions**:
   - **Reubicación**: Movido `db_back/ci.yml` a `.github/workflows/db-back-ci.yml` para cumplir con el estándar de GitHub.
   - **Optimización**: Añadidas reglas de filtrado por rutas (`paths: ['db_back/**']`) para ejecutar el CI solo ante cambios relevantes.
   - **Entorno**: Configurado JDK 25 (Temurin) con caché de Maven habilitado y ruta de dependencias explícita.
   - **Build**: Implementado comando `./mvnw clean package` con configuración de `working-directory` para el subproyecto.

### 🗂️ Archivos Modificados/Creados:

| Archivo | Acción |
|---------|--------|
| `.github/workflows/db-back-ci.yml` | **CREADO** |
| `db_back/ci.yml` | **ELIMINADO** |

---


## [2026-04-19] Implementación de Modo Debug Global

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Establecer un sistema de herramientas de desarrollo persistente en toda la aplicación para simular estados de autenticación (Login/Logout), roles (Admin/User) y alternancia de temas (Light/Dark).

### 📝 Resumen de Tareas Realizadas:

1. **Infraestructura de Debug**:
   - **`AuthService`**: Implementados métodos `mockLogin()` y `mockLogout()` para inyectar estados de sesión sin bypass real del servidor.
   - **`DebugService`**: Nuevo servicio centralizado para gestionar la visibilidad de la UI de herramientas.

2. **Componente `GlobalDebugComponent`**:
   - **Interfaz**: Botón flotante persistente con indicador de estado (punto rojo/verde según login).
   - **Funcionalidad**: Panel lateral (slide-out) con controles para:
     - Alternar entre Tema Claro y Oscuro.
     - Simular inicio/cierre de sesión.
     - Alternar privilegios de Administrador (activo solo si está logueado).
   - **Estética**: Diseño estilo "tech-debug" con glassmorphism y bordes dorados, coherente con el estilo "viking-moderno" del proyecto.

3. **Integración Global**:
   - Inyectado en `AppComponent` para disponibilidad en todas las rutas.
   - **Limpieza**: Refactorizado `GamePageComponent` para delegar la gestión del tema y auth al componente global, manteniendo solo los debugs específicos de la partida (Oro, Fases, Entrenamiento).

### 🗂️ Archivos Modificados/Creados:

| Archivo | Acción |
|---------|--------|
| `front/src/app/core/debug/debug.service.ts` | **CREADO** |
| `front/src/app/shared/components/debug/global-debug.component.*` | **CREADO** (3 archivos) |
| `front/src/app/core/auth/auth.service.ts` | Modificado |
| `front/src/app/app.*` | Modificado |
| `front/src/app/pages/game/game.component.*` | Modificado |

---

## [2026-04-19] Creación del Modal de Reglas (Leyes de Midgard)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Implementar un modal informativo que detalle las reglas del juego, fases, recursos y sistemas de clanes para mejorar la experiencia del usuario y la comprensión de las mecánicas básicas.

### 📝 Resumen de Tareas Realizadas:

1. **Nuevo Componente `ReglasModalComponent`**:
   - **Visual**: Modal centrado con estética de pergamino digital, glassmorphism enriquecido (`$color-bg-glass-rich`) y detalles dorados.
   - **Contenido**: Secciones estructuradas para:
     - **Objetivo**: Explicación de la condición de victoria.
     - **Fases**: Detalle de Preparación (5 min), Guerra (ticks de 30-60s) y Final.
     - **Recursos**: Diferenciación entre Oro (entrenamiento) e Investigación (daño en batalla).
     - **Clanes**: Resumen del sistema de ventajas tácticas (tipos).
     - **Tecnología**: Mención al árbol de 8 niveles.

2. **Integración en `GamePageComponent`**:
   - **Signals**: Nueva señal `showReglasModal` para el control de visibilidad.
   - **Binding**: Vinculado el botón "Reglas" de la barra superior para abrir el modal.
   - **Lógica**: Implementados métodos `openRules()` y `closeReglasModal()`.

3. **Estilos y UX**:
   - Animación de entrada con escalado suave (`scale-up`).
   - Scrollbar personalizada para contenido extenso.
   - Diseño responsivo que adapta la grilla de recursos y clanes a dispositivos móviles.

### 🗂️ Archivos Modificados/Creados:

| Archivo | Acción |
|---------|--------|
| `front/src/app/pages/game/modals/reglas.modal.ts` | **CREADO** |
| `front/src/app/pages/game/modals/reglas.modal.html` | **CREADO** |
| `front/src/app/pages/game/modals/reglas.modal.scss` | **CREADO** |
| `front/src/app/pages/game/game.component.ts` | Modificado |
| `front/src/app/pages/game/game.component.html` | Modificado |

---

## [2026-04-19] Alineación con la Guía de Colores (Front Color Guide)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Eliminar la deuda técnica de estilos mediante la eliminación de todos los colores hexadecimales hardcodeados en los componentes Angular, asegurando el cumplimiento estricto de `front_color_guide.md`.

### 📝 Resumen de Tareas Realizadas:

1. **Unificación de Temas (Dark/Light)**:
   - **Adaptabilidad al Sistema**: Se ha configurado el proyecto para que los modales y componentes respeten la preferencia del sistema operativo (`prefers-color-scheme`) o la elección del usuario via `ThemeService`.
   - **Nuevos Tokens de Overlay**:
     - `$color-overlay-soft`: Reemplaza transparencias fijas de negro/blanco, adaptándose al fondo actual.
     - `$color-overlay-strong`: Reemplaza fondos de rejillas y capas de profundidad hardcodeadas.
   
2. **Eliminación de Colores Absolutos**:
   - Limpieza de `black`, `white`, `#000` y `#fff` en todos los archivos SCSS de `src/app`.
   - Sustitución por `var(--color-text-primary)` y `var(--color-text-inverse)` para garantizar contraste automático.

3. **Estandarización de Modales**:
   - El **Log de Batalla** ha sido migrado al sistema de degradados premium (`$color-bg-modal` + `$color-bg-primary`) para ser consistente con los modales de Ataque y Entrenamiento.
   - Refactorizados los 5 modales de juego para asegurar que no existan interfaces "oscuras" forzadas en temas claros.

4. **Herramientas de Desarrollo (Debug)**:
   - Se ha añadido un botón en el **Panel de Debug** para alternar entre Tema Claro y Oscuro en tiempo real, facilitando el QA visual.

5. **Calidad y Verificación**:
   - Corregido error de importación SCSS en `game.component.scss`.
   - Auditoría final con `grep` confirmando la ausencia de colores hardcodeados en la capa de aplicación.

2. **Refactorización de Componentes Principales**:
   - `game.component.scss`: Eliminación de `#hex` en barras de vida, paneles de debug y fondos de clanes (migrados a `color-mix`).
   - `admin.component.scss`: Corrección de colores en botones de acción de peligro.
   - `navbar.component.scss`: Ajuste de colores semantic en el menú desplegable.

3. **Refactorización de Modales de Juego**:
   - `game-log.modal.scss`: Rediseño completo usando las nuevas variables de glassmorphism y eliminando fallbacks de `var()`.
   - `entrenar.modal.scss`, `visualizar-tropas.modal.scss`, `atacar.modal.scss`, `anadir-tropa-ataque.modal.scss`: Sustitución masiva de dorados hardcodeados (#d4af37) y rojos por los tokens oficiales `$color-gold` y `$color-error`.

4. **Calidad y Verificación**:
   - Ejecutada auditoría con `grep` para asegurar la ausencia total de `#` arbitrarios en la carpeta `src/app`.
   - Verificada la compatibilidad con los temas **Dark** y **Light**.

### 🗂️ Archivos Modificados:

| Archivo | Cambio |
|---------|--------|
| `.agents/front_color_guide.md` | Actualizado con nuevos tokens |
| `front/src/styles/tokens.scss` | Implementación de custom properties |
| `front/src/styles/variables.scss` | Implementación de variables SCSS |
| `front/src/app/pages/game/game.component.scss` | Refactorizado |
| `front/src/app/pages/admin/admin.component.scss` | Refactorizado |
| `front/src/app/shared/components/navbar/navbar.component.scss` | Refactorizado |
| `front/src/app/pages/game/modals/*.scss` | Refactorización de todos los modales (5 archivos) |

---

## [2026-04-19] Implementación de Log de Batalla Global

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Crear un sistema de registro de eventos global para la partida, permitiendo visualizarlos en un modal dedicado con estética vikinga y registro automático de acciones de juego.

### 📝 Resumen de Tareas Realizadas:

1. **Definición de Modelo (`attack.types.ts`)**:
   - Creada la interfaz `GameLogEntry` con campos para jugador, acción, timestamp y tipo (ataque, entrenamiento, investigación, sistema).

2. **Nuevo Componente `GameLogModalComponent`**:
   - **Visual**: Modal con glassmorphism, scrollbar personalizada y bordes dorados.
   - **Funcional**: Clasificación de mensajes por colores según el tipo (Rojo para ataques, Azul para entrenamiento, Dorado para sistema).
   - **Iconografía**: Uso de emojis/iconos dinámicos según el tipo de acción.

3. **Integración en `GamePageComponent`**:
   - **Signals**: Añadida señal `gameLogs` para gestionar la lista de eventos y `showLogModal` para la visibilidad.
   - **Logging Automático**:
     - `onTrainTroop`: Registra el entrenamiento de nuevas unidades.
     - `onLaunchAttack`: Registra el lanzamiento de ataques contra otros jugadores.
   - **Método `addLogEntry`**: Implementada lógica para generar timestamps automáticos y IDs únicos para las entradas.

4. **UI/UX**:
   - Vinculado el botón de pergamino (📜) de la barra lateral derecha para abrir el log.
   - Modal con animación de entrada y cierre por backdrop o botón.

### 🗂️ Archivos Modificados/Creados:

| Archivo | Acción |
|---------|--------|
| `front/src/app/pages/game/modals/game-log.modal.ts` | **CREADO** |
| `front/src/app/pages/game/modals/game-log.modal.html` | **CREADO** |
| `front/src/app/pages/game/modals/game-log.modal.scss` | **CREADO** |
| `front/src/app/pages/game/modals/attack.types.ts` | Modificado |
| `front/src/app/pages/game/game.component.ts` | Modificado |
| `front/src/app/pages/game/game.component.html` | Modificado |

---

## [2026-04-19] Creación del Panel de Debug (Desarrollo)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Implementar un panel de herramientas flotante para permitir al desarrollador manipular el estado del juego manualmente (Oro, Fases, Progreso) y verificar la UI sin depender del backend.

### 📝 Resumen de Tareas Realizadas:

1. **Interfaz de Debug (`GamePageComponent`)**:
   - Añadido un botón de engranaje (⚙️) en la esquina inferior izquierda.
   - Panel desplegable con controles de Economía, Fases y Entrenamiento.

2. **Funcionalidades de Simulación**:
   - **Economía**: Botones para añadir/quitar oro (`+50`, `+500`, `-100`).
   - **Fases**: Ciclo dinámico entre `PREPARACIÓN`, `GUERRA` y `FIN`.
   - **Entrenamiento Secuencial**:
     - Control manual del progreso (%) de la tropa activa.
     - Botón **Completar Entrenamiento**: Convierte instantáneamente la unidad activa en una tropa lista (visible en el modal de tropas).

3. **Estilos de Panel**:
   - Estética oscura translúcida (glassmorphism) coherente con el juego.
   - Posicionamiento fijo para no interferir con los botones de acción principales.

### 🗂️ Archivos Modificados:

| Archivo                                     | Cambio                                                       |
| ------------------------------------------- | ------------------------------------------------------------ |
| `front/src/app/pages/game/game.component.ts` | Añadidos signals de visibilidad y métodos de manipulación de estado. |
| `front/src/app/pages/game/game.component.html` | Inclusión del panel y controles de debug.                    |
| `front/src/app/pages/game/game.component.scss` | Estilos del panel de debug y botón disparador.               |

---

---

## [2026-04-19] Visualización de Progreso de Entrenamiento Secuencial

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Implementar la visualización del progreso de entrenamiento tanto en la pantalla principal (botón flotante) como en el modal de tropas, siguiendo el requisito de entrenamiento de una en una.

### 📝 Resumen de Tareas Realizadas:

1. **Lógica de Entrenamiento en `GamePageComponent`**:
   - Añadidas señales `computed` para detectar la tropa activa en entrenamiento y su progreso.
   - Actualizado el mock de entrenamiento para inicializar tropas con `trainingProgress: 0` y `isTraining: true`.

2. **Feedback Visual en Botones Flotantes (`GamePage`)**:
   - `game.component.scss`: Añadido un efecto de llenado vertical (`::before`) en los botones de acción (`.action-btn`) que responde a la variable CSS `--progress`.
   - `game.component.html`: Vinculado el progreso de la tropa activa al botón de "Ver Tropas".

3. **Refactor del Modal de Tropas (`VisualizarTropasModalComponent`)**:
   - **Lógica**: Implementado ordenamiento automático para mostrar primero las tropas listas, luego la activa en entrenamiento y finalmente las unidades en cola.
   - **Template**: Rediseñadas las tarjetas de tropas para soportar tres estados:
     - **READY**: Borde dorado y barra de vida verde.
     - **TRAINING**: Fondo animado con el progreso de entrenamiento (azul `--color-progress-training`).
     - **QUEUED**: Desaturado y con opacidad reducida (modo espera).
   - **Estilos**: Aplicado el efecto de "fondo progress bar" mediante gradientes dinámicos y pseudoelementos.

### 🗂️ Archivos Modificados:

| Archivo                                          | Cambio                                                       |
| ------------------------------------------------ | ------------------------------------------------------------ |
| `front/src/app/pages/game/game.component.ts`      | Lógica de cola y progreso computado                          |
| `front/src/app/pages/game/game.component.html`    | Binding de progreso al botón flotante                        |
| `front/src/app/pages/game/game.component.scss`    | Estilo de llenado de fondo para botones                      |
| `front/src/app/pages/game/modals/visualizar-tropas.modal.ts`   | Lógica de estados y ordenamiento                             |
| `front/src/app/pages/game/modals/visualizar-tropas.modal.html` | UI con badges y estados de entrenamiento                     |
| `front/src/app/pages/game/modals/visualizar-tropas.modal.scss` | Efectos visuales de progreso y unidades en espera (grayscale) |

---

---

## [2026-04-19] Creación del Modal de Entrenamiento de Tropas

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Implementar el modal "Entrenar" para que los jugadores puedan comprar nuevas unidades usando créditos económicos, con una lista de tropas dinámica controlada por el padre (anticipando integración con el middle server).

### 📝 Resumen de Tareas Realizadas:

1. **Definición de Tipos (`attack.types.ts`)**:
   - Añadida la interfaz `TrainableTroopOption` para manejar las opciones de compra (nombre, coste, icono, descripción).

2. **Creación del Componente `EntrenarModalComponent`**:
   - `entrenar.modal.ts`: Lógica con `signals` de Angular 20, validación de presupuesto (`canAfford`) y emisión de eventos de entrenamiento.
   - `entrenar.modal.html`: Layout basado en el mockup del usuario. Incluye cabecera con balance de "Ptos.", lista dinámica de tropas con estados visuales (asequible/no asequible).
   - `entrenar.modal.scss`: Estilo premium "Mythic Viking" con glassmorphism, gradientes dorados y animaciones de entrada (`fadeIn`, `slideIn`).

3. **Integración en `GamePageComponent`**:
   - `game.component.ts`: imports actualizados, señales para controlar la visibilidad del modal (`showEntrenarModal`) y mock data de las opciones de entrenamiento disponibles inicialmente (Infantería, Arquería, Caballería).
   - `game.component.html`: Inclusión del tag `<app-entrenar-modal>` con vinculación de datos y eventos.

4. **Lógica de Mock (Entrenamiento)**:
   - Implementado método `onTrainTroop` que descuenta el oro y añade la nueva tropa a la lista de `availableTroops` con estado `isTraining: true`.

### 🗂️ Archivos Modificados/Creados:

| Archivo                                          | Acción     |
| ------------------------------------------------ | ---------- |
| `front/src/app/pages/game/modals/entrenar.modal.ts`   | **CREADO** |
| `front/src/app/pages/game/modals/entrenar.modal.html` | **CREADO** |
| `front/src/app/pages/game/modals/entrenar.modal.scss` | **CREADO** |
| `front/src/app/pages/game/modals/attack.types.ts`     | Modificado |
| `front/src/app/pages/game/game.component.ts`          | Modificado |
| `front/src/app/pages/game/game.component.html`        | Modificado |

---


## [2026-04-19] Creación del Modal de Visualización de Tropas (Read-Only)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Implementar un modal informativo para visualizar las tropas de un territorio, siguiendo la estética del modal de ataque pero sin funcionalidades de edición o ataque.

### 📝 Cambios Realizados:

#### 1. **Componente `VisualizarTropasModalComponent`**
   - **Lógica (`visualizar-tropas.modal.ts`)**:
     - Componente independiente con `ChangeDetectionStrategy.OnPush`.
     - Inputs: `title` y `troops` (usando `Signal` de Angular).
     - Atributo computado `gridCols` para organizar la grilla dinámicamente.
   - **Template (`visualizar-tropas.modal.html`)**:
     - Estructura de modal con overlay y contenido centrado.
     - Grilla de tropas que muestra icono, barra de vida y texto detallado (actual/máxima).
     - Botón de cierre en el header y footer para facilitar la navegación.
   - **Estilos (`visualizar-tropas.modal.scss`)**:
     - Reutilización del diseño "vikingo": bordes dorados (#d4af37), fondos oscuros con degradados y glassmorphism.
     - Ajuste de interactividad: celdas de tropas en modo `read-only` (sin cursor de mano ni efectos de escala).
     - Barra de vida con gradiente verde (#2ecc71 → #27ae60).

#### 2. **Preview Estático**
   - **Archivo (`.agents/previews/visualizar-tropas-preview.html`)**:
     - Creado para validación visual inmediata.
     - Simula el estado del modal con 5 tropas de ejemplo con salud variable.

### ✨ Características Implementadas

| Requisito | Implementación |
|-----------|-----------------|
| **Consistencia Visual** | Mismo aspecto que el modal de ataque (grid 1x1, colores, fuentes). |
| **Informativo** | Muestra el estado actual de las tropas (salud) de forma clara. |
| **Read-Only** | Sin botones de añadir tropas o ejecutar ataque. |
| **Grilla Dinámica** | El número de columnas se ajusta según la cantidad de tropas. |

### 🗂️ Archivos Creados:

| Archivo | Tipo | Descripción |
|---------|------|------------|
| `front/src/app/pages/game/modals/visualizar-tropas.modal.ts` | Component | Lógica del modal informativo |
| `front/src/app/pages/game/modals/visualizar-tropas.modal.html` | Template | UI del modal de visualización |
| `front/src/app/pages/game/modals/visualizar-tropas.modal.scss` | Styles | Estilos vikingos y health bars |
| `.agents/previews/visualizar-tropas-preview.html` | HTML | Vista previa estática interactiva |

---


## [2026-04-19] Implementación de Caminos de Ataque Animados (SVG Attack Path Visualization)

**Agente**: GitHub Copilot (Claude Haiku 4.5)  
**Objetivo**: Añadir visualización de caminos de ataque animados utilizando SVG con curvas Bezier cúbicas, gradientes dinámicos y autoelimpiación automática tras 5 segundos.

### 📝 Cambios Realizados:

#### 1. **Estilos SVG en `game.component.scss`**
   - Nuevo contenedor `.attack-path-svg`:
     - Posicionamiento absoluto cubriendo todo el contenedor
     - `pointer-events: none` para que no interfiera con clicks
     - Z-index: 15 (por encima de nodos pero bajo modales)
   
   - Estilo del path `.attack-path`:
     - Stroke con gradiente lineal (6 colores rojo degradado: #e74c3c → #c0392b → #a93226)
     - `stroke-dasharray: 10, 5` para patrón de línea punteado
     - Animación `attackPathFlow` (3s, linear, infinito)
       - Offset de stroke viaja de 0 a -15px creando efecto de flujo
     - Filter `drop-shadow` con glow rojo (#c0392b, 8px, 60% de opacidad)
   
   - Animación de punta de flecha `.attack-arrow-head circle`:
     - `arrowPulse` (2s, ease-in-out, infinito)
     - Varía el radio de 4px → 6px → 4px
     - Varía opacidad del fill manteniendo glow

#### 2. **Template SVG en `game.component.html`**
   - Contenedor condicional: `@if (activeAttack())`
   - Elemento `<svg xmlns="http://www.w3.org/2000/svg">` con:
     - `<defs>`: Define gradiente lineal `attack-gradient`
       - 3 stops: #e74c3c (0%), #c0392b (50%), #a93226 (100%)
       - Dirección diagonal: x1=0% y1=0% x2=100% y2=100%
     - Elemento `<path>`:
       - Clase `attack-path` (aplica animación)
       - `[attr.d]="generateAttackPath()"` (curva Bezier dinámica)
       - `[attr.id]="activeAttack()!.pathId"` (ID único per ataque)
     - Grupo `<g class="attack-arrow-head">`:
       - Circle con clase `arrow-dot` animada (pulso)
       - Atributos cx/cy inicialmente en 0

#### 3. **Lógica de Auto-Limpieza en `game.component.ts`**
   - Método `onLaunchAttack()` modificado:
     - Establecer el signal `activeAttack` con el objeto de ataque
     - Añadir `setTimeout(() => { this.activeAttack.set(null); }, 5000)`
     - Limpia automáticamente la visualización después de 5 segundos
     - Comportamiento: "solo debe salir cuando se haya un ataque y durante el ataque"

### ✨ Características Implementadas

| Requisito | Implementación |
|-----------|-----------------|
| **Visualización SVG** | Overlay absoluto con path Bezier dinámico |
| **Gradiente lineal** | Definido en `<defs>` con 3 stops de color rojo |
| **Animación fluida** | `stroke-dasharray` offset (3s) crea efecto de flujo constante |
| **Punta animada** | Circle pulsa entre 4px-6px (efecto de movimiento) |
| **Auto-limpieza** | setTimeout 5s limpia activeAttack automáticamente |
| **Condicional** | Solo renderiza cuando `activeAttack() !== null` |
| **Z-indexing** | 15: visible sobre la mayoría, bajo modales |
| **Sin interferencia** | `pointer-events: none` no bloquea interacciones |

### 📋 Cambios Archivos:

| Archivo | Cambios |
|---------|---------|
| `front/src/app/pages/game/game.component.scss` | Nuevos estilos: `.attack-path-svg`, `.attack-path`, `.attack-arrow-head` con @keyframes |
| `front/src/app/pages/game/game.component.html` | @if condicional + SVG con defs, gradiente, path y arrow-head animado |
| `front/src/app/pages/game/game.component.ts` | setTimeout(5s) en `onLaunchAttack()` para limpiar activeAttack |

### 🎨 Efectos Visuales:

- **Animación de flujo**: patrón punteado que se mueve continuamente a lo largo del path
- **Glow rojo**: sombra difusa (#c0392b) de 8px alrededor del stroke
- **Pulso de punta**: circle que crece/encoge (4px → 6px → 4px) dando sensación de movimiento
- **Desvanecimiento automático**: 5s después de ejecutar el ataque

### ⏱️ Timeline:

1. Usuario hace clic en territorio enemigo → abre modal atacar
2. Selecciona tropas → click ATACAR → `onLaunchAttack(troopIds)`
3. SVG aparece instantáneamente con animación de flujo y pulso
4. Después de 5s, `activeAttack` se establece a `null`
5. Condicional `@if` elimina SVG del DOM

### ✅ Validación:

- ✓ TypeScript compilation: No errors
- ✓ HTML template: Sintaxis SVG correcta con bindings
- ✓ SCSS: @keyframes definidas correctamente
- ✓ Lógica: `onLaunchAttack()` incluye setTimeout

---

## [2026-04-19] Mejora: Selección Múltiple de Tropas en Modal Añadir (Multiple Troop Selection)

**Agente**: GitHub Copilot (Claude Haiku 4.5)  
**Objetivo**: Permitir seleccionar múltiples tropas en el modal de "Añadir Tropas" antes de confirmar con botones OK y Cancelar.

### 📝 Cambios Realizados:

#### 1. **Anademodalización en `AnadirTropaAtaqueModalComponent`**
   - Nuevo signal local: `localSelectedIds` para gestionar selección temporal
   - Constructor inicializa `localSelectedIds` con los valores del input `selectedTroopIds`
   - Cambio de salida: `troopSelected: string` → `troopsSelected: string[]` (emite array)
   - Métodos actualizados:
     - `onTroopClick()`: toggle en `localSelectedIds` (no emite directamente)
     - `onOkClick()`: emite array de IDs seleccionadas y cierra
     - `onCancelClick()`: descarta cambios y cierra

#### 2. **Template (`anadir-tropa-ataque.modal.html`)**
   - Cambio en binding de event: `(troopSelected)` → `(troopsSelected)`
   - Footer: añadido botón "OK" (verde) junto a "CANCELAR" (gris)
   - Justificación: `justify-content: flex-end` para alinear botones a la derecha

#### 3. **Estilos (`anadir-tropa-ataque.modal.scss`)**
   - Nuevo botón `.btn-ok`:
     - Gradiente verde (#27ae60 → #229954)
     - Glow effect al hover
     - Transición suave y shadow
   - Footer ahora con `justify-content: flex-end` y gap de 12px

#### 4. **Integración en `AtacarModalComponent`**
   - Actualización del método `onTroopSelected(newTroopIds: string[])`:
     - Recibe array de IDs en lugar de string único
     - Añade todas las nuevas tropas a `selectedTroopIds`
     - Evita duplicados mediante verificación
   - Template: `(troopSelected)` → `(troopsSelected)`

### ✨ Flujo de Uso

1. **Usuario abre modal Atacar** con tropas previas o vacío
2. **Click en "+"** → abre modal de selección
3. **Selecciona múltiples tropas** con click (checkmark)
4. **Click deselecciona** (toggle behavior)
5. **Click "OK"** → añade todas las seleccionadas y vuelve a atacar
6. **Click "CANCELAR"** → descarta cambios y cierra

### 📋 Cambios Archivos:

| Archivo | Cambios |
|---------|---------|
| `front/src/app/pages/game/modals/anadir-tropa-ataque.modal.ts` | Signal local, constructor, nuevo output array, métodos actualizados |
| `front/src/app/pages/game/modals/anadir-tropa-ataque.modal.html` | Binding event, botones dobles (OK + CANCELAR) |
| `front/src/app/pages/game/modals/anadir-tropa-ataque.modal.scss` | Nuevos estilos `.btn-ok` (verde), footer ajustado |
| `front/src/app/pages/game/modals/atacar.modal.ts` | Método `onTroopSelected()` actualizado (array) |
| `front/src/app/pages/game/modals/atacar.modal.html` | Binding event actualizado |

---

## [2026-04-19] Creación de Modales de Ataque: Atacar + Añadir Tropa (Attack Modal System)

**Agente**: GitHub Copilot (Claude Haiku 4.5)
**Objetivo**: Implementar el sistema de modales para el ataque de tropas en el GamePage siguiendo patrón Forge of Empires con UI grid de tropas y health bars por unidad.

### 📝 Cambios Realizados:

#### 1. **Creación de Sistema de Tipos (`attack.types.ts`)**
   - Tipo `ClanId`: unión de 6 clanes posibles
   - Interfaz `Troop`: datos completos de una tropa (id, name, type, clan, health actual/máxima, icon, costo, etc.)
   - Interfaz `EnemyTarget`: información del enemigo objetivo
   - Interfaz `TroopGridCell`: representación visual de celda en grid
   - Enum `TroopType`: tipos de tropas (infanteria, arqueria, caballeria)

#### 2. **Componente Principal: `AtacarModalComponent`**
   - **Entrada**: `target` (enemigo), `availableTroops` (tropas disponibles)
   - **Salida**: `closeModal`, `launchAttack` (IDs de tropas)
   - **UI**: 
     - Grid dinámico de tropas seleccionadas (Forge of Empires style)
     - Cada celda muestra: icono + barra de vida (con % de salud actual)
     - Botón "+" para añadir más tropas
     - Botón "ATACAR" (habilitado solo si hay tropas)
   - **Interacción**: Click en celda de tropa → la elimina de selección
   - **Mock data**: 6 tropas de prueba con diferentes tipos y salud variable

#### 3. **Componente Secundario: `AñadirTropaAtaqueModalComponent`**
   - **Entrada**: `availableTroops`, `selectedTroopIds` (IDs ya seleccionadas)
   - **Salida**: `troopSelected` (emite ID), `closeModal`
   - **UI**:
     - Grid 2 columnas de tropas disponibles
     - Cada tarjeta: icono + nombre + health bar + costo
     - Tropas seleccionadas previamente muestran checkmark (✓) y fondo/borde dorado
   - **Interacción**: 
     - Click en tropa no seleccionada → se añade a selección y muestra checkmark
     - Click en tropa seleccionada → se elimina (toggle comportamiento)
     - Click "CANCELAR" → cierra modal sin cambios
   - **Z-index**: modal 2 por encima del modal 1

#### 4. **Estilos (`atacar.modal.scss` + `añadir-tropa-ataque.modal.scss`)**
   - Tema vikingo: colores #d4af37 (dorado), #2a2a2a (gris oscuro), degradados
   - Bordes dorados con glow effects
   - Grid responsive con gap coherente
   - Transiciones suaves (hover, active)
   - Health bars con gradiente verde (#2ecc71 → #27ae60)
   - Botones:
     - "+" (dorado, grande, 48x48px)
     - "ATACAR" (rojo, solo habilitado con tropas)
     - "CANCELAR" (gris)

#### 5. **Integración en `GamePageComponent`**
   - Imports: `AtacarModalComponent`, `AñadirTropaAtaqueModalComponent`, tipos
   - Signals de control: `showAtacarModal`, `targetEnemy`, `selectedTroopsForAttack`
   - Signal de datos: `availableTroops` (mock con 6 tropas)
   - Método `onTerritoryClick(player)`:
     - ✅ Comprueba que no sea el jugador local (no abre si haces clic en ti)
     - ✅ Comprueba que fase !== PREPARACIÓN
     - ✅ Abre modal con enemigo objetivo
   - Métodos: `closeAtacarModal()`, `onLaunchAttack(troopIds)`
   - Template: `@if (showAtacarModal() && targetEnemy())` para renderizar modal anidado

#### 6. **Previews HTML Generados**
   - `.agents/previews/attack-modal-preview.html`: muestra modal vacío vs con 4 tropas
   - `.agents/previews/add-troops-modal-preview.html`: grid 2x3 de tropas, algunas seleccionadas

### ✨ Características Clave

| Requisito | Implementación |
|-----------|-----------------|
| **Grid visual** | CSS Grid dinámico, adapta columnas según raíz cuadrada de tropas |
| **Health bars** | Barra de progreso animada, muestra `currentHealth/maxHealth` |
| **Selección previa** | Al abrir modal añadir, tropas ya seleccionadas aparecen marcadas |
| **Toggle selection** | Click en tropa seleccionada → se deselecciona (inversa lógica) |
| **No ataque a ti mismo** | Comprobación en `onTerritoryClick()` del jugador local |
| **Fase PREPARACIÓN** | Bloquea apertura del modal en fase prep |
| **Botón ATACAR** | Deshabilitado si no hay tropas, emit con IDs al servidor |
| **Estilo Forge of Empires** | Grid de celdas cuadradas con iconos, degradados dorados |

### 🗂️ Archivos Creados:

| Archivo | Tipo | Descripción |
|---------|------|------------|
| `front/src/app/pages/game/modals/attack.types.ts` | TypeScript | Tipos e interfaces |
| `front/src/app/pages/game/modals/atacar.modal.ts` | Component | Lógica del modal principal |
| `front/src/app/pages/game/modals/atacar.modal.html` | Template | UI del modal atacar |
| `front/src/app/pages/game/modals/atacar.modal.scss` | Styles | Estilos grid + health bars |
| `front/src/app/pages/game/modals/añadir-tropa-ataque.modal.ts` | Component | Lógica de selección |
| `front/src/app/pages/game/modals/añadir-tropa-ataque.modal.html` | Template | UI grid de tropas |
| `front/src/app/pages/game/modals/añadir-tropa-ataque.modal.scss` | Styles | Estilos tarjetas + checkmark |
| `.agents/previews/attack-modal-preview.html` | HTML | Preview visual del modal atacar |
| `.agents/previews/add-troops-modal-preview.html` | HTML | Preview grid de añadir tropas |

### 🗂️ Archivos Modificados:

| Archivo | Acción |
|---------|--------|
| `front/src/app/pages/game/game.component.ts` | Imports, signals, mock data, métodos de control |
| `front/src/app/pages/game/game.component.html` | Añadido `@if` condicional para renderizar modal |
| `.agents/AGENTS_CHANGELOG.md` | Documentación de cambios |

### 📋 Pruebas Manuales Sugeridas

1. En game.component, cambiar `currentPhase()` a `'GUERRA'`
2. Hacer clic en otro jugador → debe abrir modal atacar
3. Hacer clic en ti mismo (username === 'Ragnar_Fury') → no debe abrir
4. Hacer clic en "+" → abre modal de selección
5. Seleccionar 3 tropas → checkmark visible, cierra y vuelve a atacar modal
6. Volver a abrir "+" → las 3 tropas siguen seleccionadas
7. Click en una seleccionada → se deselecciona
8. Botón "ATACAR" habilitado solo si hay tropas seleccionadas

---

## [2026-04-19] Refinamiento Visual Completo del GamePage (Workflow /refine-ui)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Iterar sobre el preview `gamePage-preview.html` hasta tener el diseño definitivo aprobado por el usuario y aplicarlo al componente Angular.

### 📝 Cambios Aplicados en el Preview (iteraciones):

1. **Mapa**: ocupa el 100% del ancho y alto del contenedor (`background-size: 100% 100%`), sin mantener relación de aspecto. Sin zoom al hacer hover.
2. **Botones laterales**: eliminada la barra (`<aside>`), reemplazada por botones flotantes semitransparentes con glassmorphism (`.actions-overlay`). Cambiados de texto a **iconos SVG** (espadas, tropas, rayo, pergamino).
3. **Jugadores en el mapa**: 6 círculos de colores (uno por clan) posicionados con `top/left` en porcentaje sobre los continentes del mapa. `transform: translate(-50%, -50%)` asegura que sigan su posición al redimensionar.
4. **Tarjeta de stats flotante**: centrada encima del mapa (`position: absolute`, `left: 50%`). Layout interno: Vida a la izquierda (grande, en verde), divisor dorado, Dinero + Ptos. de Investigación en columna a la derecha.
5. **Indicador de fase**: convertido en tarjeta con borde de color según la fase (`PREPARACIÓN` = azul, `GUERRA` = rojo, `FIN` = dorado) y efecto glow.
6. **Barra superior izquierda**: logo del juego (placeholder) + nombre de usuario + código de partida (solo `#XXXXXX` sin prefijo "Partida").
7. **Barra superior derecha**: añadido botón **Reglas** (icono + texto) con borde sutil, a la izquierda del botón Abandonar.

### 🗂️ Archivos Modificados:

| Archivo                                        | Acción                               |
| ---------------------------------------------- | ------------------------------------ |
| `front/src/app/pages/game/game.component.ts`   | Reescrito (tipos, signals, handlers) |
| `front/src/app/pages/game/game.component.html` | Reescrito (layout completo final)    |
| `front/src/app/pages/game/game.component.scss` | Reescrito (estilos SCSS completos)   |
| `.agents/previews/gamePage-preview.html`       | Modificado (iteraciones de diseño)   |
| `.agents/AGENTS_CHANGELOG.md`                  | Modificado                           |

---

## [2026-04-19] Creación de la Pantalla Principal de Juego (GamePage) y Ocultación Condicional del Navbar

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Implementar la vista del juego base (sin el componente Navbar global) de acuerdo con los mockups del mapa `viking-map-continents.png` y siguiendo el flujo preestablecido `/refine-ui`.

### 📝 Resumen de Tareas Realizadas:

1. **Flujo de Refinamiento (`/refine-ui`)**:
   - Generación de `.agents/previews/gamePage-preview.html` simulando la disposición completa del GamePage (mapa principal inmersivo y Acciones de Mando).
2. **Implementación de Componente `GamePageComponent` (`pages/game`)**:
   - Componente independiente `standalone: true` con `ChangeDetectionStrategy.OnPush`.
   - Uso de `signals` para los marcadores en tiempo real (Salud, Dinero, Puntos de Investigación y Fase actual).
   - Estilo configurado con `flex: 1` para ocupar toda la pantalla, imagen de fondo interactiva para el tablero / mapa y un panel interactivo derecho (`aside`) con las futuras acciones (ej. Entrenar tropas).
3. **Mecanismo Condicional para Localización Immersiva**:
   - Modificados `app.ts` y `app.html` inyectando dependencias del `Router` y `NavigationEnd` para verificar que la ruta actual pertenece a una partida. El `NavbarComponent` está envuelto interactuando con la señal generada `showNavbar()`.
4. **Enrutamiento Perezoso**:
   - Agregada la ruta `game` en `app.routes.ts` cargando `GamePageComponent`.

### 🗂️ Archivos Modificados:

| Archivo                                        | Acción     |
| ---------------------------------------------- | ---------- |
| `front/src/app/pages/game/game.component.ts`   | **CREADO** |
| `front/src/app/pages/game/game.component.html` | **CREADO** |
| `front/src/app/pages/game/game.component.scss` | **CREADO** |
| `.agents/previews/gamePage-preview.html`       | **CREADO** |
| `front/src/app/app.ts`                         | Modificado |
| `front/src/app/app.html`                       | Modificado |
| `front/src/app/app.routes.ts`                  | Modificado |
| `.agents/AGENTS_CHANGELOG.md`                  | Modificado |

---

## [2026-04-18] Documentación: Creación de README.md y LICENSE

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Establecer la documentación base del proyecto y definir los términos de uso educativo.

### 📝 Resumen de Tareas Realizadas:

1. **Creación de `README.md`**:
   - Redactada la presentación del proyecto "Viking Clan Wars".
   - Detallada la arquitectura de microservicios y el stack tecnológico.
   - Añadida guía de inicio rápido con comandos Docker Compose.
   - Listado de servicios y puertos correspondientes.

2. **Creación de `LICENSE`**:
   - Implementada una licencia MIT.
   - Añadida una cláusula de exclusividad para fines educativos y académicos en el marco de un proyecto intermodular/TFM.

### 🗂️ Archivos Modificados:

| Archivo                       | Acción     |
| ----------------------------- | ---------- |
| `README.md`                   | **CREADO** |
| `LICENSE`                     | **CREADO** |
| `.agents/AGENTS_CHANGELOG.md` | Modificado |

---

## [2026-04-18] Infraestructura: Adición de Contenedor Redis (Cache/Rate-Limiting)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Integrar Redis como sistema de almacenamiento efímero para la gestión de lista negra de JWT y control de tasa (rate limiting) en el Middle Server.

### 📝 Resumen de Tareas Realizadas:

1. **Configuración Docker (Producción)**:
   - Modificado `docker-compose.yml` para incluir el servicio `redis` (Imagen: `redis:7-alpine`).
   - Integrado en la red `tfm_net`.
   - Añadida variable de entorno `REDIS_URL=redis://redis:6379` al servicio `middle_server`.
   - Añadida dependencia de `redis` en `middle_server`.

2. **Configuración Docker (Desarrollo)**:
   - Modificado `docker-compose.dev.yml` para incluir `redis_dev`.
   - Expuesto el puerto `6379` para acceso local.
   - Integrado en la red `tfm_net_dev`.
   - Añadida variable de entorno `REDIS_URL=redis://redis:6379` al servicio `middle_server_dev`.
   - Añadida dependencia de `redis` en `middle_server_dev`.

### 🗂️ Archivos Modificados:

| Archivo                       | Acción     |
| ----------------------------- | ---------- |
| `docker-compose.yml`          | Modificado |
| `docker-compose.dev.yml`      | Modificado |
| `.agents/AGENTS_CHANGELOG.md` | Modificado |

---

## [2026-04-18] Infraestructura: Adición de Contenedor MinIO (Object Storage)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Integrar MinIO como sistema de almacenamiento de objetos (S3-compatible) para la gestión de avatares de usuario, siguiendo la arquitectura definida.

### 📝 Resumen de Tareas Realizadas:

1. **Configuración Docker (Producción)**:
   - Modificado `docker-compose.yml` para incluir el servicio `minio` (Imagen: `minio/minio`).
   - Añadido servicio `minio_init` (Imagen: `minio/mc`) para la creación automática del bucket `avatars` y configuración de política `public-read`.
   - Añadido volumen persistente `minio_data`.
   - Configurado con credenciales por defecto (`minioadmin`/`minioadmin`).

2. **Configuración Docker (Desarrollo)**:
   - Modificado `docker-compose.dev.yml` para incluir `minio` y `minio_init`.
   - Añadido volumen `minio_data_dev`.
   - Integrado en la red `tfm_net_dev`.

3. **Integración con Middle Server**:
   - Actualizados ambos archivos de compose para que `middle_server` dependa de `minio`.
   - Inyectadas las variables de entorno necesarias:
     - `MINIO_ENDPOINT`: `http://minio:9000`
     - `MINIO_ACCESS_KEY`: `minioadmin`
     - `MINIO_SECRET_KEY`: `minioadmin`
     - `MINIO_BUCKET_AVATARS`: `avatars`
     - `MINIO_PUBLIC_BASE_URL`: `http://localhost:9000/avatars`

### 🗂️ Archivos Modificados:

| Archivo                       | Acción     |
| ----------------------------- | ---------- |
| `docker-compose.yml`          | Modificado |
| `docker-compose.dev.yml`      | Modificado |
| `.agents/AGENTS_CHANGELOG.md` | Modificado |

---

## [2026-04-18] Infraestructura: Adición de Contenedor MongoDB

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Añadir un contenedor de MongoDB a la configuración de Docker para futuras analíticas del proyecto.

### 📝 Resumen de Tareas Realizadas:

1. **Configuración Docker (Producción/General)**:
   - Modificado `docker-compose.yml` para incluir el servicio `mongodb` (Imagen: `mongo:7.0`).
   - Añadido volumen persistente `mongodb_data`.
   - Configurado con credenciales por defecto (`admin`/`password`) y puerto `27017`.

2. **Configuración Docker (Desarrollo)**:
   - Modificado `docker-compose.dev.yml` para incluir `mongodb_dev`.
   - Añadido volumen `mongodb_data_dev`.
   - Integrado en la red `tfm_net_dev`.

### 🗂️ Archivos Modificados:

| Archivo                  | Acción     |
| ------------------------ | ---------- |
| `docker-compose.yml`     | Modificado |
| `docker-compose.dev.yml` | Modificado |

---

2:
3: ## [2026-04-18] Actualización de Reglas: Sync Obligatorio (Git Pull + Changelog)
16: | `GEMINI.md` | Nueva sección "BEFORE ANY BIG CHANGE" |
17: | `.agents/rules/collaboration.md` | Nueva "RULE 0" |
18:
19: ---

## [2026-04-18] NavBar: Lógica de Autenticación y Navegación Condicional

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Condicionar la visibilidad de elementos de la NavBar y el menú de usuario según el estado de la sesión, integrando con `AuthService`.

### 📝 Resumen de Tareas Realizadas:

1. **Visibilidad Condicional (Angular `@if`)**:
   - **Lobby**: Ahora solo visible si `authService.isLoggedIn()` es verdadero.
   - **Menú de Usuario**: Opciones "Configuración", "Estadísticas", "Administración" y "Salir" solo se renderizan si hay sesión.
   - **Desplegable**: Se impide la apertura del menú si no hay sesión (`toggleDropdown()` bloqueado).
   - **Avatar**: Se mantiene siempre visible (imagen genérica por ahora).

2. **Navegación y Funcionalidad**:
   - **Estadísticas**: Enlace corregido a `/stats/user`.
   - **Cierre de Sesión**: El botón "Salir de la cuenta" ahora invoca `authService.clearSession()` para limpiar el estado en memoria.

3. **Workflow `/refine-ui`**:
   - Iteración completa sobre `.agents/previews/navbar-preview.html` incluyendo controles de testeo (Login/Admin) aprobados por el usuario.

### 🗂️ Archivos Modificados:

| Archivo                                                        | Acción                                       |
| -------------------------------------------------------------- | -------------------------------------------- |
| `front/src/app/shared/components/navbar/navbar.component.ts`   | Modificado (Lógica `toggleDropdown`)         |
| `front/src/app/shared/components/navbar/navbar.component.html` | Modificado (Estructura condicional y logout) |
| `.agents/previews/navbar-preview.html`                         | Modificado (Preview interactivo con testeo)  |

---

## [2026-04-18] Creación de la Página de Estadísticas de Usuario

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Implementar la vista de estadísticas de usuario siguiendo el mockup y el sistema de diseño "Mythic Viking".

### 📝 Resumen de Tareas Realizadas:

1. **Ruta de Navegación**:
   - Añadida ruta `/stats/user` con carga perezosa (_Lazy Loading_) en `app.routes.ts`.

2. **Componente de Estadísticas (`StatisticsComponent`)**:
   - **Ubicación**: `front/src/app/pages/statistics-view/` (renombrado de `stats` para evitar conflictos y refrescar el tracking del compilador).
   - **Lógica (`statistics.component.ts`)**: Componente _standalone_ con `ChangeDetectionStrategy.OnPush`. Uso de `signals` para los 6 indicadores requeridos (tiempo, dinero, tropas, ataques, victorias).
   - **Template (`statistics.component.html`)**: Diseño fiel al mockup con cabecera de panel ("Barra"), iconos SVG integrados y lista de métricas.
   - **Estilos (`statistics.component.scss`)**: Aplicación del sistema de diseño (fuentes `Cinzel`/`Lato`, colores oro y fondos oscuros). Incluye micro-animaciones de entrada para los elementos.

3. **Corrección de Error de Compilación**:
   - Se resolvió el error `Could not resolve "./pages/stats/stats.component"` realizando un renombrado preventivo a `statistics-view` y sanitizando los archivos para asegurar que el compilador de Angular/Vite los indexe correctamente.

### 🗂️ Archivos:

| Archivo                                                         | Acción     |
| --------------------------------------------------------------- | ---------- |
| `front/src/app/app.routes.ts`                                   | Modificado |
| `front/src/app/pages/statistics-view/statistics.component.ts`   | **CREADO** |
| `front/src/app/pages/statistics-view/statistics.component.html` | **CREADO** |
| `front/src/app/pages/statistics-view/statistics.component.scss` | **CREADO** |

---

Registro de los cambios sustanciales realizados por agentes de asistencia para mantener el contexto persistente en el entorno de desarrollo. Este archivo ayuda a otros futuros agentes a entender qué fue lo último que se montó en el proyecto.

---

## [2026-04-18] AuthService + Navbar: dropdown por click y botón Admin condicional

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Corregir el comportamiento del dropdown del Navbar (hover → click) y hacer el botón de Administración condicional al rol del usuario.

### 📝 Resumen de Tareas Realizadas:

1. **Creación de `AuthService` (`core/auth/auth.service.ts`)**:
   - Servicio singleton (`providedIn: 'root'`) que gestiona la sesión en memoria (nunca en `localStorage`).
   - Parsea el payload del JWT (base64) para extraer `sub` y `role` sin verificar la firma.
   - Señales de solo lectura: `session`, `isLoggedIn`, `isAdmin`, `username`.
   - Métodos: `setSession(token)`, `clearSession()`, `getToken()`. Sin `any`.

2. **Refactor de `NavbarComponent`**:
   - `navbar.component.ts`: `inject(AuthService)`, signal `dropdownOpen`, `toggleDropdown()`, `closeDropdown()`, `@HostListener('document:click')` para cerrar al hacer click fuera.
   - `navbar.component.html`: dropdown controlado por `@if(dropdownOpen())`. Enlace Administración envuelto en `@if(authService.isAdmin())`.
   - `navbar.component.scss`: Eliminados `display:none`, `opacity:0`, `:hover`. Añadido `@keyframes dropdown-in`.

### 🗂️ Archivos:

| Archivo                     | Acción     |
| --------------------------- | ---------- |
| `core/auth/auth.service.ts` | **CREADO** |
| `navbar.component.ts`       | Modificado |
| `navbar.component.html`     | Modificado |
| `navbar.component.scss`     | Modificado |

---

## [2026-04-18] Refinamiento Completo de la Vista de Administración (`adminPage`)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Rediseñar el componente admin con el nuevo layout funcional (métricas, panel lateral, gestión de baneos) e iterar hasta corregir todos los problemas de layout, scroll y UX.

### 📝 Resumen de Tareas Realizadas:

1. **Workflow `/refine-ui` — Preview estático**:
   - Generado `.agents/previews/adminPage-preview.html` con la nueva propuesta de diseño.
   - Diseño aprobado: panel lateral con totales, sección de métricas en tiempo real y tabla de baneos activos con buscador de ban.

2. **Migración a Angular (`admin.component.ts / .html / .scss`)**:
   - `admin.component.ts`: estado migrado a `signals` (`globalStats`, `monitoringMetrics`, `bans`). Búsqueda de usuarios mediante `computed` con filtrado dinámico simulado. Acciones `banUser()` y `unban()`.
   - `admin.component.html`: layout con panel lateral (`<aside>`) + contenido principal (`<main>`). Sección de métricas (4 tarjetas). Tabla de baneos activos con `@for` / `@if` (Angular 20). Buscador con dropdown de resultados.
   - `admin.component.scss`: estilos completos alineados con `front_color_guide.md`. Sin hardcoded hex values. Uso de `var(--color-*)`.

3. **Reducción de tamaño de fuente** (petición del usuario):
   - `.stat-value`: `2.5rem → 2rem`
   - `.metric-value`: `3rem → 2.2rem`

4. **Corrección del desbordamiento de página (scroll externo)**:
   - `admin.component.scss`: cambiado `height: 100vh → height: 100%` en `.admin-dashboard`.
   - `admin.component.scss`: añadido bloque `:host { display: block; height: 100%; }` para que Angular resuelva el alto del elemento raíz del componente.
   - `admin.component.scss`: añadido `overflow-y: auto` y `flex-shrink: 0` al `.sidebar`.
   - `styles.scss`: añadido reset global: `* { box-sizing: border-box }`, `html, body { margin: 0; padding: 0; height: 100%; overflow: hidden; }`, `app-root { display: flex; flex-direction: column; height: 100%; }`.
   - `app.html`: simplificado de `height: calc(100vh - 64px)` a `flex: 1; overflow: hidden; display: flex; flex-direction: column;`, aprovechando que `app-root` es el flex parent.

5. **Ajuste de espaciado** (petición del usuario):
   - Eliminado `flex: 1` de `.bans-container` para que la tarjeta solo ocupe la altura de su contenido y no deje espacio vacío al fondo.

6. **Mejoras en la tabla de baneos**:
   - Quitada la línea inferior del último `<tr>` (`tbody tr:last-child td { border-bottom: none; }`).
   - Tabla envuelta en `div.table-scroll-wrapper` con `max-height: 300px` y `overflow-y: auto` para scroll interno.
   - `<thead>` con `position: sticky; top: 0` para que el encabezado quede fijo durante el scroll.
   - Scrollbar estilizada con los tokens `--color-scrollbar-thumb/track`.

7. **Reubicación del buscador de baneos** (petición del usuario):
   - Movido de la cabecera de la tarjeta al pie (`bans-footer`), separado por un divisor sutil.
   - Ahora ocupa el **ancho completo** (`width: 100%`).
   - Dropdown reconfigurado para abrirse hacia **arriba** (`bottom: 100%`, `border-radius: 4px 4px 0 0`).

### 🗂️ Archivos Modificados:

| Archivo                                          | Cambio                                                        |
| ------------------------------------------------ | ------------------------------------------------------------- |
| `front/src/styles.scss`                          | Reset global de `body` y `app-root`                           |
| `front/src/app/app.html`                         | `<main>` usa `flex: 1` en lugar de `calc()`                   |
| `front/src/app/pages/admin/admin.component.ts`   | Signals, computed, métodos ban/unban                          |
| `front/src/app/pages/admin/admin.component.html` | Layout completo, tabla con scroll wrapper, buscador al pie    |
| `front/src/app/pages/admin/admin.component.scss` | Estilos completos + correcciones de overflow + scroll interno |
| `.agents/previews/adminPage-preview.html`        | Preview estático de la pantalla                               |

---

## [2026-04-18] Refinamiento de Navbar (Componente Angular y menú desplegable)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Refinar el Navbar para adaptarlo al diseño (rutas y dropdown de usuario).

### 📝 Resumen de Tareas Realizadas:

1. **Paso a Angular (`navbar.component.ts/.html/.scss`)**:
   - Reemplazo del layout inicial por la nueva botonera (Home, Lobby, Personajes, Reglas) y el usuario.
   - Uso intensivo de `var(--color-bg-card)`, `var(--color-gold)`, etc., respetando `tokens.scss`.
   - Incorporación de `[routerLink]` para navegación interna.
2. **Despliegue del Workflow `/refine-ui` (Dropdown Menú)**:
   - Se crea y presenta nueva iteración en `.agents/previews/navbar-preview.html` implementando el dropdown del menú de usuario solicitado (Config., Estad., Admin., Salir).
3. **Integración Final del Dropdown en Angular**:
   - Se migra el diseño "Mythic Viking" (flecha dorada, hover effects y alineación derecha) a los archivos de producción `navbar.component.html` y `.scss`, conectando los correspondientes `[routerLink]`.

---

## [2026-04-18] Creación de Vista de Administración y NavBar (Angular 20)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Generar la pantalla del panel de administrador basada en los "mockups" y el diseño _Mythic Viking_ (`tokens.scss`).

### 📝 Resumen de Tareas Realizadas:

1. **Frontend Base (`app.html`, `app.routes.ts`, `app.ts`)**:
   - Reemplazo del _boilerplate_ nativo de Angular en `app.html` para dejar un layout limpio con `<app-navbar>` persistente en el nivel superior y un `<router-outlet>` abajo.
   - Definimos la ruta perezosa (_Lazy Loading_) en `app.routes.ts` que delega el path `/admin` a la carga del componente.
   - Importación de la _Navbar_ al archivo de punto de entrada (`app.ts`).
2. **Implementación de Componente `NavbarComponent` (`shared`)**:
   - Estructuración de la "Barra Superior" integrando el icono/logo, estilo _glassmorphism_ aplicando colores `tokens.scss` (ej. `--color-bg-card` para la superficie).
3. **Implementación de Componente `AdminComponent` (`pages/admin`)**:
   - Compuesto por un menú lateral estructurado (Grid de 240px de ancho) y un área principal fluida (`1fr`).
   - Recreación estricta al _mockup_ de **Gráficos**, codificado en puro CSS (`[style.height.%]`) con asignaciones a colores correspondientes de los Clanes Vikingos.
   - Construcción de una subpestaña o tarjeta llamada **Baneos**, reflejando información falsa en formato tabla respetando los `--color-text-primary` e inputs decorativos.

### 🛠️ Correcciones y Refactorización:

- **SASS Deprecations**: Solucionado el error de compilación reordenando el mixin `@light-theme-vars` antes de su invocación según la arquitectura pre-compiladora de estilos en SCSS, y reemplazando `@import` por `@use` en `styles.scss` para prevenir _warnings_ de Dart Sass 3.0.0.

## [2026-04-20] Implementación de Home Page Premium (Viking Clan Wars)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Crear una página de aterrizaje inmersiva y de alta calidad técnica para atraer a los usuarios y presentar las mecánicas del juego.

### 📝 Resumen de Tareas Realizadas:

1. **Diseño Visual de Alto Impacto**:
   - Generada imagen hero cinemática ("viking-home-hero.png") con estética de arte conceptual de videojuegos.
   - Implementado sistema de capas atmosféricas: Niebla animada por CSS y partículas (ascuas) flotantes.
   - Uso de tipografía moderna ('Outfit') combinada con pesos pesados para el título del juego.

2. **Componente `HomeComponent` (Angular 20)**:
   - **Hero Section**: Pantalla completa con parallax sutil (vía `background-attachment: fixed`) y un CTA "ENTRAR EN EL VALHALLA" con efectos de brillo y hover dinámico.
   - **Features Section**: Grid de 3 tarjetas con glassmorphism (blur de fondo) y bordes de oro reactivos.
   - **Clans Preview**: Vista previa interactiva de los 6 clanes (Furia, Divino, Hierro, Canción, Runa, Muerte) con filtros de escala de grises que se activan al hover.

3. **Arquitectura y Routing**:
   - Mapeada la ruta raíz (`path: ''`) al nuevo componente.
   - Integración con `AuthService` para redirigir al Lobby si el usuario ya está autenticado.

4. **Calidad Técnica**:
   - Uso estricto de variables SCSS y tokens del proyecto.
   - Diseño totalmente responsivo (móvil/desktop).
   - Componentes Standalone (Angular 20).

### 🗂️ Archivos Creados/Modificados:

| Archivo | Acción |
|---------|--------|
| `front/src/app/pages/home/home.component.ts` | **CREADO** |
| `front/src/app/pages/home/home.component.html` | **CREADO** |
| `front/src/app/pages/home/home.component.scss` | **CREADO** |
| `front/src/app/app.routes.ts` | Modificado |
| `front/public/viking-home-hero.png` | **CREADO** (Asset generado) |


## [2026-04-20] Refinamiento de Home Page (Inspiración Mythic VIKING)

**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Elevar la calidad visual y de contenido de la página de inicio basándose en la referencia de `prueba_ia`.

### 📝 Resumen de Cambios:

1. **Nuevo Componente `LogoComponent`**:
   - Implementado un logo SVG vectorial con una cabeza de lobo rúnica y hachas cruzadas.
   - Efectos de brillo (`filter: glow`) y pulsación rúnica (`animation`).
   - Soporte para escalado y visibilidad de texto mediante Signals (`input`).

2. **Rediseño Completo de `HomeComponent`**:
   - **Hero Section**: Integrado el nuevo logo y fondo cinemático corregido (`/viking_hero.png`). Añadidos botones con estilo "Mithic" (bordes forjados y clip-path nórdico).
   - **Sección de Eras**: Añadida una cronología detallada de la partida (Preparación, Guerra Total, Veredicto) con tarjetas de diseño premium.
   - **Códice Militar**: Nueva sección técnica explicando los puntos de acción (AP) y de investigación (RP), junto con un visual de radar de mapa táctico.
   - **Preview de Clanes**: Grid actualizado con los 6 clanes y sus arquetipos sagrados.
   - **Footer Premium**: Footer completo con créditos, logos y enlaces sociales temáticos.

3. **Mejoras Técnicas**:
   - Migración completa a Angular 20 (Signals, `inject()`, Control Flow `@for`/`@if`).
   - Uso estricto de variables SCSS del proyecto para coherencia de marca (Oro/Navy/Parchment).
   - Optimizaciones de accesibilidad y estructura semántica.

### 🗂️ Archivos Creados/Modificados:

| Archivo | Acción |
|---------|--------|
| `front/src/app/shared/components/logo/logo.component.ts` | **CREADO** |
| `front/src/app/pages/home/home.component.ts` | Modificado |
| `front/src/app/pages/home/home.component.html` | Modificado |
| `front/src/app/pages/home/home.component.scss` | Modificado |
| `front/public/viking_hero.png` | Vinculado (Copiado manualmente por usuario) |

