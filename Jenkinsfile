pipeline {

    agent {
        label 'ubuntu-agent'
    }

    environment {
        DOCKER_IMAGE = 'viflash/devops-lab'
        CONTAINER_NAME = 'addressbook'
        HOST_PORT = '8080'
        CONTAINER_PORT = '8080'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                sh '''
                    echo "===== CHECKOUT ====="
                    hostname
                    git log -1 --oneline
                '''
            }
        }

        stage('Compile') {
            steps {
                sh '''
                    echo "===== COMPILE ====="
                    mvn -B clean compile
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    echo "===== TEST ====="
                    mvn -B test
                '''
            }

        }

        stage('Package') {
            steps {
                sh '''
                    echo "===== PACKAGE ====="
                    mvn -B package -DskipTests
                    ls -lh target/addressbook.war
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    echo "===== DOCKER BUILD ====="

                    docker build \
                      -t ${DOCKER_IMAGE}:${BUILD_NUMBER} \
                      -t ${DOCKER_IMAGE}:latest \
                      .
                '''
            }
        }

        stage('Docker Login and Push') {
            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {

                    sh '''
                        echo "===== DOCKER LOGIN ====="

                        echo "$DOCKER_PASSWORD" | docker login \
                          -u "$DOCKER_USERNAME" \
                          --password-stdin

                        echo "===== DOCKER PUSH ====="

                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE}:latest

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy Container') {
            steps {
                sh '''
                    echo "===== DEPLOY CONTAINER ====="

                    docker rm -f ${CONTAINER_NAME} || true

                    docker pull ${DOCKER_IMAGE}:${BUILD_NUMBER}

                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      -p ${HOST_PORT}:${CONTAINER_PORT} \
                      ${DOCKER_IMAGE}:${BUILD_NUMBER}

                    echo "===== CONTAINER ====="

                    docker ps
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "===== VERIFY ====="

                    for i in $(seq 1 30); do

                        code=$(curl -s -o /dev/null \
                          -w '%{http_code}' \
                          http://localhost:8080/addressbook/ || true)

                        echo "Attempt $i: HTTP $code"

                        if [ "$code" = "200" ]; then
                            echo "DEPLOYMENT VERIFIED"
                            exit 0
                        fi

                        sleep 2

                    done

                    echo "DEPLOYMENT FAILED"
                    docker logs ${CONTAINER_NAME} || true
                    exit 1
                '''
            }
        }
    }
}
