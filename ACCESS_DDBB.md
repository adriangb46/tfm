# Acceso Seguro a Bases de Datos (SSH Tunnel)

Para mantener la seguridad del sistema, los puertos de **PostgreSQL** (5432) y **MongoDB** (27017) no están expuestos públicamente en el servidor de despliegue.

Para acceder a ellos desde tu máquina local (usando herramientas como DBeaver, MongoDB Compass o pgAdmin), debes crear un **túnel SSH** a través del servicio `bastion`.

## 1. Configuración del Túnel

Ejecuta el siguiente comando en tu terminal local:

```bash
ssh -L 5432:db_sql:5432 -L 27017:mongodb:27017 -p 2222 viking@<IP_DEL_SERVIDOR>
```

- `-L 5432:db_sql:5432`: Mapea el puerto local 5432 al puerto 5432 del contenedor `db_sql`.
- `-L 27017:mongodb:27017`: Mapea el puerto local 27017 al puerto 27017 del contenedor `mongodb`.
- `-p 2222`: Especifica el puerto del servicio bastion.
- `viking`: El usuario configurado.

**Contraseña por defecto:** `viking_secret` (Se recomienda encarecidamente cambiarla en el `docker-compose.yml` o configurar claves SSH).

## 2. Conexión desde Herramientas

Una vez que el túnel esté abierto (mantén la terminal abierta), configura tus herramientas de la siguiente manera:

### PostgreSQL (DBeaver / pgAdmin)
- **Host:** `localhost`
- **Puerto:** `5432`
- **Usuario:** `postgres`
- **Contraseña:** `postgress` (definida en `docker-compose.yml`)
- **Base de Datos:** `tfm`

### MongoDB (Compass)
- **URI:** `mongodb://admin:password@localhost:27017/?authSource=admin`

---

> [!TIP]
> **Mejora de Seguridad: Claves SSH**
> Para no usar contraseñas, puedes montar tu clave pública en el contenedor bastion añadiendo un volumen en el `docker-compose.yml`:
> ```yaml
> volumes:
>   - ~/.ssh/id_rsa.pub:/pub_key:ro
> environment:
>   - PUBLIC_KEY_FILE=/pub_key
> ```
