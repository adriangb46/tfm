# 🪓 Viking Clan Wars

**Viking Clan Wars** es un juego de estrategia multijugador en tiempo real (2-6 jugadores) desarrollado como proyecto intermodular. Los jugadores lideran clanes vikingos, gestionan recursos, investigan tecnologías místicas y despliegan tropas para conquistar las capitales enemigas en un mundo persistente.

## 🏰 Características Principales

*   **Sistema de Clanes**: 6 clanes únicos (Berserkers, Valkirias, Jarls, Skalds, Seidr, Draugr) con ventajas de tipo circulares.
*   **Economía Dual**: Créditos económicos para entrenamiento y créditos de investigación obtenidos mediante el combate.
*   **Árbol Tecnológico**: 8 tecnologías por clan que desbloquean unidades de élite y hechizos.
*   **Mundo Persistente**: Las partidas se ejecutan en el servidor de forma continua, incluso si los jugadores están desconectados.
*   **Arquitectura Microservicios**: Separación clara de responsabilidades entre motor de juego, persistencia y almacenamiento.

## 🚀 Arquitectura del Sistema

El sistema se compone de cuatro pilares fundamentales comunicándose mediante HTTPS y WebSockets:

1.  **Frontend (Angular 21)**: Interfaz de usuario reactiva y visualmente inmersiva (Aesthetic "Mythic Viking").
2.  **Middle Server (Node.js + Socket.IO)**: El motor de juego autoritativo. Gestiona el estado en memoria y el bucle de tiempo (*Time Wheel*).
3.  **DB Server (Java 25 + Spring Boot)**: Capa de persistencia vinculada a PostgreSQL y MongoDB para analíticas.
4.  **Infraestructura**:
    *   **PostgreSQL**: Datos persistentes de usuarios y partidas.
    *   **MongoDB**: Instantáneas históricas para estadísticas.
    *   **Redis**: Gestión de sesiones (JWT Blacklist) y control de tráfico (*Rate Limiting*).
    *   **MinIO**: Almacenamiento de fotos de perfil y assets de usuario.

---

## 🛠️ Requisitos Previos

*   [Docker](https://www.docker.com/products/docker-desktop/) y [Docker Compose](https://docs.docker.com/compose/install/)
*   Node.js (v20+) y Java (v25+) para desarrollo local sin contenedores.

## 🏁 Inicio Rápido

Para desplegar el entorno completo de producción:

```bash
docker-compose up -d
```

Para el entorno de desarrollo (con hot-reload y puertos de depuración expuestos):

```bash
docker-compose -f docker-compose.dev.yml up -d
```

| Servicio | URL | Puerto |
|---|---|---|
| Frontend | `http://localhost:4200` | 4200 |
| API Middle | `http://localhost:3000` | 3000 |
| API DB Back | `http://localhost:8080` | 8080 |
| MinIO Console | `http://localhost:9001` | 9001 |

---

## 👥 Desarrolladores

*   **Adrián González Blando**
*   **Adriana Cabaleiro Álvarez**

## 📄 Licencia

Este proyecto está bajo la **Licencia MIT (Modificada para uso educativo)**. Consulta el archivo [LICENSE](./LICENSE) para más detalles.
