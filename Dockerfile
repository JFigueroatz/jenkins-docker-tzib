# Imagen ligera de Nginx basada en Alpine
FROM nginx:alpine

LABEL autor="Jefferson Alejandro Tzib Figueroa" \
      carne="4090-21-14885" \
      curso="Aseguramiento de la Calidad de Software"

# Copiar la página web al directorio público de Nginx
COPY index.html /usr/share/nginx/html/index.html

# Exponer el puerto utilizado por el servidor web
EXPOSE 80

# Ejecutar Nginx automáticamente al iniciar el contenedor
CMD ["nginx", "-g", "daemon off;"]
