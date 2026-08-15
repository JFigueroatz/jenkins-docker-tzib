# jenkins-docker-tzib

Proyecto del **Parcial 1 – III Serie** del curso *Aseguramiento de la Calidad de Software*.

Consiste en una página web estática servida con **Nginx**, empaquetada en una **imagen Docker** y desplegada
automáticamente como contenedor mediante un **pipeline de Jenkins** definido en este mismo repositorio.

| Dato | Valor |
|---|---|
| Nombre completo | Jefferson Alejandro Tzib Figueroa |
| Número de carné | 4090-21-14885 |
| Curso | Aseguramiento de la Calidad de Software |
| Fecha de realización | 14 de agosto de 2026 |

**Flujo implementado:** `GitHub` → `Jenkins` → `Imagen Docker` → `Contenedor web`

---

## 1. Contenido del repositorio

| Archivo | Descripción |
|---|---|
| `index.html` | Página web con los datos del estudiante y el mensaje requerido. Diseño propio en HTML + CSS. |
| `Dockerfile` | Empaqueta la página sobre una imagen ligera de Nginx. |
| `Jenkinsfile` | Pipeline declarativo con las 5 etapas obligatorias. |
| `README.md` | Este documento: procedimiento completo. |

---

## 2. Aplicación web

`index.html` es una página autocontenida (CSS embebido, sin dependencias externas) que muestra:

- Nombre completo
- Número de carné
- Curso
- Fecha de realización
- El mensaje **“Aplicación desplegada con Jenkins y Docker”**

El diseño usa un fondo con degradado, una tarjeta con efecto *glassmorphism*, tipografía del sistema y
reglas *responsive* mediante `@media` para pantallas menores a 520 px.

---

## 3. Dockerización

`Dockerfile`:

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Cumple con lo solicitado:

| Requisito | Cómo se cumple |
|---|---|
| Imagen ligera de Nginx | `nginx:alpine` (~50 MB) |
| Copiar la página al directorio público | `COPY index.html /usr/share/nginx/html/index.html` |
| Exponer el puerto del servidor web | `EXPOSE 80` |
| Ejecución automática al iniciar | `CMD ["nginx", "-g", "daemon off;"]` |

---

## 4. Verificación local (antes de Jenkins)

### 4.1 Construir la imagen con nombre y versión

```bash
docker build -t jenkins-docker-tzib:1.0 .
```

### 4.2 Crear el contenedor publicando el puerto 8081 de la computadora

```bash
docker run -d --name web-tzib-local -p 8081:80 jenkins-docker-tzib:1.0
```

### 4.3 Comprobar que el contenedor está en ejecución

```bash
docker ps -f name=web-tzib-local
```

Salida obtenida:

```
NAMES            IMAGE                     STATUS         PORTS
web-tzib-local   jenkins-docker-tzib:1.0   Up             0.0.0.0:8081->80/tcp
```

### 4.4 Verificar la página desde el navegador

Abrir <http://localhost:8081>. También puede comprobarse por consola:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8081
# 200
```

### 4.5 Detener y eliminar el contenedor de prueba

```bash
docker rm -f web-tzib-local
```

---

## 5. Pipeline de Jenkins

### 5.1 Requisito previo: Docker dentro de Jenkins

Jenkins se ejecuta en un contenedor, por lo que necesita acceso al *daemon* de Docker del anfitrión.
El contenedor se crea montando el socket de Docker y con el CLI de Docker instalado:

```bash
docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add $(stat -c '%g' /var/run/docker.sock) \
  jenkins-docker:lts
```

Comprobación:

```bash
docker exec jenkins docker ps
```

### 5.2 Configuración del job

1. Verificar en **Administrar Jenkins → Plugins** que estén instalados **Git** y **Pipeline**.
2. **Nueva Tarea** → nombre `primerpipeline` → tipo **Pipeline**.
3. En la sección *Pipeline*:
   - **Definition:** `Pipeline script from SCM`
   - **SCM:** `Git`
   - **Repository URL:** `https://github.com/JFigueroatz/jenkins-docker-tzib.git`
   - **Branch Specifier:** `*/main`
   - **Script Path:** `Jenkinsfile`
4. Guardar.

El pipeline vive en GitHub (`Jenkinsfile`), no en la interfaz de Jenkins.

### 5.3 Etapas del pipeline

| Etapa | Resultado |
|---|---|
| `Clonacion` | Jenkins obtiene el repositorio desde GitHub (`checkout scm`). |
| `Verificacion` | Comprueba que existan `index.html` y `Dockerfile`; falla si alguno no está. |
| `Construccion` | Genera `jenkins-docker-tzib:${BUILD_NUMBER}` con el número de ejecución de Jenkins. |
| `Despliegue` | Elimina el contenedor de la ejecución anterior y crea uno nuevo en el puerto 8090. |
| `Confirmacion` | Consulta la página dentro del contenedor y muestra el resultado. |

El bloque `post` imprime un mensaje explícito de **proceso exitoso** o **proceso fallido**.

El reemplazo del contenedor anterior evita conflictos de nombre y de puerto:

```bash
if [ "$(docker ps -aq -f name=^web-tzib$)" ]; then
    docker rm -f web-tzib
fi
```

### 5.4 Ejecución

1. Entrar al job `primerpipeline` → **Construir ahora**.
2. Revisar que las cinco etapas terminen en verde en la vista *Stage View*.
3. Abrir <http://localhost:8090> para ver la aplicación desplegada por Jenkins.

---

## 6. Prueba de actualización

1. Modificar el contenido visual de `index.html`.
2. Publicar el cambio en GitHub:

   ```bash
   git add index.html
   git commit -m "feat: actualiza el diseño visual de la pagina"
   git push
   ```

3. Ejecutar nuevamente el pipeline (**Construir ahora**).
4. Recargar <http://localhost:8090> y confirmar que se muestra la modificación.

Cada ejecución genera una imagen con una etiqueta nueva (`:1`, `:2`, `:3`, …) correspondiente al
número de build de Jenkins, y el contenedor anterior es reemplazado automáticamente.

---

## 7. Resultados obtenidos

Registro de las ejecuciones realizadas en el job `primerpipeline`:

| Build | Imagen generada | Resultado | Observación |
|---|---|---|---|
| #3 | `jenkins-docker-tzib:3` | SUCCESS | Primer despliegue verificado en el puerto 8090 (versión 1.0 de la página). |
| #4 | `jenkins-docker-tzib:4` | SUCCESS | Despliegue tras modificar `index.html`; el contenedor anterior fue reemplazado (versión 2.0). |

Salida final de la consola de Jenkins en el build #4:

```
==================================================
 PROCESO EXITOSO
 Imagen desplegada: jenkins-docker-tzib:4
 Aplicacion disponible en: http://localhost:8090
==================================================
Finished: SUCCESS
```

Estado del contenedor desplegado por el pipeline:

```
NAMES      IMAGE                     STATUS   PORTS
web-tzib   jenkins-docker-tzib:4     Up       0.0.0.0:8090->80/tcp
```

### Cambio visual aplicado en la prueba de actualización

| Versión 1.0 (antes) | Versión 2.0 (después) |
|---|---|
| Fondo en degradado azul petróleo | Fondo en degradado morado, azul y magenta |
| Título en degradado azul y verde | Título en degradado amarillo y naranja |
| — | Aviso nuevo: “Actualización aplicada…” |
| Pie: *Versión 1.0* | Pie: *Versión 2.0* |

### Incidencia encontrada y corregida

En la primera ejecución el contenedor desplegado fue eliminado por una ejecución concurrente del
pipeline, y la etapa de confirmación no lo detectó porque el resultado del comando se perdía al
enviarse a través de una tubería (`| head`), lo que devolvía siempre un código de salida exitoso.

Se corrigió de dos formas:

1. Se agregó `options { disableConcurrentBuilds() }` para impedir ejecuciones simultáneas.
2. La etapa `Confirmacion` ahora valida con `docker inspect` que el contenedor esté en ejecución y
   que la página responda; si no es así, termina con `exit 1` y el build se marca como fallido.

---

## 8. Comandos útiles de verificación

```bash
docker images | grep jenkins-docker-tzib   # imágenes generadas por cada build
docker ps -f name=web-tzib                 # contenedor desplegado en ejecución
docker logs web-tzib                       # registros de Nginx
```
