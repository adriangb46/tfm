# Guía: Configuración de Secretos en GitHub

Para que los tests de integración del `db_server` pasen correctamente en el sistema de Integración Continua (CI), es necesario configurar el secreto de handshake en GitHub.

## Pasos para configurar `DB_HANDSHAKE_SECRET`

Siga estos pasos en la interfaz web de GitHub:

1.  **Navegue a su repositorio**: Entre en la página principal del repositorio `db_back` en GitHub.
2.  **Acceda a Settings**: Haga clic en la pestaña **Settings** (Configuración) en la barra superior.
3.  **Sección de Secretos**: En el menú lateral izquierdo, busque la sección **Security** (Seguridad).
4.  **Actions Secrets**: Despliegue **Secrets and variables** y haga clic en **Actions**.
5.  **Nuevo Secreto**: Haga clic en el botón verde **New repository secret**.
6.  **Nombre**: Ingrese `DB_HANDSHAKE_SECRET` (debe ser exacto).
7.  **Valor**: Pegue el valor del secreto que está utilizando en su entorno de desarrollo local (el que se corresponde con la variable `${DB_HANDSHAKE_SECRET}`).
8.  **Guardar**: Haga clic en **Add secret**.

> [!IMPORTANT]
> Sin este secreto, los tests de integración que requieren handshake (como `CharacterControllerIntegrationTest`) fallarán con un error `401 Unauthorized` durante la ejecución del CI.

> [!NOTE]
> Una vez añadido el secreto, el siguiente **Push** a la rama `main` o cualquier **Pull Request** disparará automáticamente el workflow y utilizará este valor de forma segura.
