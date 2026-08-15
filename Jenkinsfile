pipeline {
    agent any

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
                    docker exec ${CONTENEDOR} wget -q -O - http://localhost/ | head -n 5
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
