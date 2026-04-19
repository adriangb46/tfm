# Agents Activity Changelog

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
| Archivo | Acción |
|---|---|
| `front/src/app/pages/game/game.component.ts` | Reescrito (tipos, signals, handlers) |
| `front/src/app/pages/game/game.component.html` | Reescrito (layout completo final) |
| `front/src/app/pages/game/game.component.scss` | Reescrito (estilos SCSS completos) |
| `.agents/previews/gamePage-preview.html` | Modificado (iteraciones de diseño) |
| `.agents/AGENTS_CHANGELOG.md` | Modificado |

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
| Archivo | Acción |
|---|---|
| `front/src/app/pages/game/game.component.ts` | **CREADO** |
| `front/src/app/pages/game/game.component.html` | **CREADO** |
| `front/src/app/pages/game/game.component.scss` | **CREADO** |
| `.agents/previews/gamePage-preview.html` | **CREADO** |
| `front/src/app/app.ts` | Modificado |
| `front/src/app/app.html` | Modificado |
| `front/src/app/app.routes.ts` | Modificado |
| `.agents/AGENTS_CHANGELOG.md` | Modificado |

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
| Archivo | Acción |
|---|---|
| `README.md` | **CREADO** |
| `LICENSE` | **CREADO** |
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
| Archivo | Acción |
|---|---|
| `docker-compose.yml` | Modificado |
| `docker-compose.dev.yml` | Modificado |
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
| Archivo | Acción |
|---|---|
| `docker-compose.yml` | Modificado |
| `docker-compose.dev.yml` | Modificado |
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
| Archivo | Acción |
|---|---|
| `docker-compose.yml` | Modificado |
| `docker-compose.dev.yml` | Modificado |

---
2: 
3: ## [2026-04-18] Actualización de Reglas: Sync Obligatorio (Git Pull + Changelog)
4: **Agente**: Antigravity (Google DeepMind)
5: **Objetivo**: Implementar una salvaguarda para evitar conflictos en un entorno de dos desarrolladores, obligando al agente a sincronizar y revisar el historial previo a cambios importantes.
6: 
7: ### 📝 Resumen de Tareas Realizadas:
8: 1. **Modificación de rules/collaboration.md**:
9:    - Añadida "RULE 0" que obliga a realizar `git pull` y leer `AGENTS_CHANGELOG.md` antes de cambios significativos.
10: 2. **Modificación de GEMINI.md**:
11:    - Añadida sección crítica "BEFORE ANY BIG CHANGE" con los pasos de sincronización, revisión de changelog y análisis de impacto.
12: 
13: ### 🗂️ Archivos Modificados:
14: | Archivo | Cambio |
15: |---|---|
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
| Archivo | Acción |
|---|---|
| `front/src/app/shared/components/navbar/navbar.component.ts` | Modificado (Lógica `toggleDropdown`) |
| `front/src/app/shared/components/navbar/navbar.component.html` | Modificado (Estructura condicional y logout) |
| `.agents/previews/navbar-preview.html` | Modificado (Preview interactivo con testeo) |

---

## [2026-04-18] Creación de la Página de Estadísticas de Usuario
**Agente**: Antigravity (Google DeepMind)
**Objetivo**: Implementar la vista de estadísticas de usuario siguiendo el mockup y el sistema de diseño "Mythic Viking".

### 📝 Resumen de Tareas Realizadas:

1. **Ruta de Navegación**:
   - Añadida ruta `/stats/user` con carga perezosa (*Lazy Loading*) en `app.routes.ts`.

2. **Componente de Estadísticas (`StatisticsComponent`)**:
   - **Ubicación**: `front/src/app/pages/statistics-view/` (renombrado de `stats` para evitar conflictos y refrescar el tracking del compilador).
   - **Lógica (`statistics.component.ts`)**: Componente *standalone* con `ChangeDetectionStrategy.OnPush`. Uso de `signals` para los 6 indicadores requeridos (tiempo, dinero, tropas, ataques, victorias).
   - **Template (`statistics.component.html`)**: Diseño fiel al mockup con cabecera de panel ("Barra"), iconos SVG integrados y lista de métricas.
   - **Estilos (`statistics.component.scss`)**: Aplicación del sistema de diseño (fuentes `Cinzel`/`Lato`, colores oro y fondos oscuros). Incluye micro-animaciones de entrada para los elementos.

3. **Corrección de Error de Compilación**:
   - Se resolvió el error `Could not resolve "./pages/stats/stats.component"` realizando un renombrado preventivo a `statistics-view` y sanitizando los archivos para asegurar que el compilador de Angular/Vite los indexe correctamente.

### 🗂️ Archivos:
| Archivo | Acción |
|---|---|
| `front/src/app/app.routes.ts` | Modificado |
| `front/src/app/pages/statistics-view/statistics.component.ts` | **CREADO** |
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
| Archivo | Acción |
|---|---|
| `core/auth/auth.service.ts` | **CREADO** |
| `navbar.component.ts` | Modificado |
| `navbar.component.html` | Modificado |
| `navbar.component.scss` | Modificado |

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
| Archivo | Cambio |
|---|---|
| `front/src/styles.scss` | Reset global de `body` y `app-root` |
| `front/src/app/app.html` | `<main>` usa `flex: 1` en lugar de `calc()` |
| `front/src/app/pages/admin/admin.component.ts` | Signals, computed, métodos ban/unban |
| `front/src/app/pages/admin/admin.component.html` | Layout completo, tabla con scroll wrapper, buscador al pie |
| `front/src/app/pages/admin/admin.component.scss` | Estilos completos + correcciones de overflow + scroll interno |
| `.agents/previews/adminPage-preview.html` | Preview estático de la pantalla |

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
**Objetivo**: Generar la pantalla del panel de administrador basada en los "mockups" y el diseño *Mythic Viking* (`tokens.scss`).

### 📝 Resumen de Tareas Realizadas:
1. **Frontend Base (`app.html`, `app.routes.ts`, `app.ts`)**:
   - Reemplazo del *boilerplate* nativo de Angular en `app.html` para dejar un layout limpio con `<app-navbar>` persistente en el nivel superior y un `<router-outlet>` abajo.
   - Definimos la ruta perezosa (*Lazy Loading*) en `app.routes.ts` que delega el path `/admin` a la carga del componente.
   - Importación de la *Navbar* al archivo de punto de entrada (`app.ts`).
2. **Implementación de Componente `NavbarComponent` (`shared`)**:
   - Estructuración de la "Barra Superior" integrando el icono/logo, estilo *glassmorphism* aplicando colores `tokens.scss` (ej. `--color-bg-card` para la superficie).
3. **Implementación de Componente `AdminComponent` (`pages/admin`)**:
   - Compuesto por un menú lateral estructurado (Grid de 240px de ancho) y un área principal fluida (`1fr`).
   - Recreación estricta al *mockup* de **Gráficos**, codificado en puro CSS (`[style.height.%]`) con asignaciones a colores correspondientes de los Clanes Vikingos.
   - Construcción de una subpestaña o tarjeta llamada **Baneos**, reflejando información falsa en formato tabla respetando los `--color-text-primary` e inputs decorativos.

### 🛠️ Correcciones y Refactorización:
- **SASS Deprecations**: Solucionado el error de compilación reordenando el mixin `@light-theme-vars` antes de su invocación según la arquitectura pre-compiladora de estilos en SCSS, y reemplazando `@import` por `@use` en `styles.scss` para prevenir _warnings_ de Dart Sass 3.0.0.
