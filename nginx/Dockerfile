FROM nginx:alpine

# Copiamos la plantilla de configuración.
# La imagen oficial de nginx:alpine extraerá las variables de entorno 
# (como DOMAIN_NAME) de los archivos en /etc/nginx/templates/ 
# y generará la configuración final en /etc/nginx/conf.d/
COPY templates/ /etc/nginx/templates/
