pipeline {
    agent any

    options {
        // Evita que dos ejecuciones simultaneas se eliminen el contenedor entre si
        disableConcurrentBuilds()
    }

    environment {
        IMAGEN     = 'jenkins-docker-tzib'
        TAG        = "${env.BUILD_NUMBER}"
        CONTENEDOR = 'web-tzib'
        PUERTO     = '8090'
    }

    stages {

        stage('Clonacion') {
            steps {
                echo "Clonando repositorio desde GitHub..."
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Verificacion') {
            steps {
                echo "Verificando archivos requeridos..."
                sh '''
                    if [ ! -f index.html ]; then
                        echo "ERROR: no se encontro index.html"
                        exit 1
                    fi
                    if [ ! -f Dockerfile ]; then
                        echo "ERROR: no se encontro Dockerfile"
                        exit 1
                    fi
                    echo "OK: index.html y Dockerfile existen"
                '''
            }
        }

        stage('Construccion') {
            steps {
                echo "Construyendo imagen ${IMAGEN}:${TAG}..."
                sh '''
                    docker build -t ${IMAGEN}:${TAG} -t ${IMAGEN}:latest .
                    docker images | grep ${IMAGEN}
                '''
            }
        }

        stage('Despliegue') {
            steps {
                echo "Desplegando contenedor ${CONTENEDOR}..."
                sh '''
                    # Reemplazar el contenedor de una ejecucion anterior si existe
                    if [ "$(docker ps -aq -f name=^${CONTENEDOR}$)" ]; then
                        echo "Eliminando contenedor anterior: ${CONTENEDOR}"
                        docker rm -f ${CONTENEDOR}
                    fi

                    docker run -d --name ${CONTENEDOR} -p ${PUERTO}:80 ${IMAGEN}:${TAG}
                    docker ps -f name=${CONTENEDOR}
                '''
            }
        }

        stage('Confirmacion') {
            steps {
                echo "Comprobando que la aplicacion responde..."
                sh '''
                    sleep 3

                    # El contenedor debe seguir en ejecucion
                    if [ "$(docker inspect -f '{{.State.Running}}' ${CONTENEDOR} 2>/dev/null)" != "true" ]; then
                        echo "ERROR: el contenedor ${CONTENEDOR} no esta en ejecucion"
                        docker ps -a -f name=${CONTENEDOR}
                        exit 1
                    fi

                    # La pagina debe responder y contener el mensaje esperado
                    docker exec ${CONTENEDOR} wget -q -O /tmp/salida.html http://localhost/
                    docker exec ${CONTENEDOR} grep -q "Aplicacion desplegada con Jenkins y Docker" /tmp/salida.html \\
                        || docker exec ${CONTENEDOR} grep -q "Aplicaci" /tmp/salida.html

                    echo "OK: la aplicacion responde correctamente en el puerto ${PUERTO}"
                '''
            }
        }
    }

    post {
        success {
            echo "=================================================="
            echo " PROCESO EXITOSO"
            echo " Imagen desplegada: ${IMAGEN}:${TAG}"
            echo " Aplicacion disponible en: http://localhost:${PUERTO}"
            echo "=================================================="
        }
        failure {
            echo "=================================================="
            echo " EL PROCESO FALLO - Revise la salida de consola"
            echo "=================================================="
        }
    }
}
