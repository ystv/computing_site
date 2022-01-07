pipeline {
    agent any

    environment {
        REGISTRY_ENDPOINT = credentials('docker-registry-endpoint')
    }

    stages {
        stage('Update Components') {
            steps {
                sh "docker pull golang:1.17-alpine" // Update with current Go image
            }
        }
        stage('Build') {
            steps {
                sh 'docker build -t $REGISTRY_ENDPOINT/ystv/computing:$BUILD_ID .'
            }
        }
        stage('Registry Upload') {
            steps {
                sh 'docker push $REGISTRY_ENDPOINT/ystv/computing:$BUILD_ID' // Uploaded to registry
            }
        }
        stage('Deploy') {
            stages {
                stage('Staging') {
                    when {
                        branch 'master'
                        not {
                            expression { return env.TAG_NAME ==~ /v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)/ }
                        }
                    }
                    environment {
                        APP_ENV = credentials('computing-env')
                        TARGET_SERVER = credentials('staging-server-address')
                        TARGET_PATH = credentials('staging-server-path')
                    }
                    steps {
                        sshagent(credentials : ['staging-server-key']) {
                            script {
                                sh 'rsync -av $APP_ENV deploy@$TARGET_SERVER:$TARGET_PATH/computing/.env'
                                sh '''ssh -tt deploy@$TARGET_SERVER << EOF
                                    docker pull $REGISTRY_ENDPOINT/ystv/computing:$BUILD_ID
                                    docker rm -f ystv-computing
                                    docker run -d -p 1336:8081 --env-file $TARGET_PATH/computing/.env --name ystv-computing $REGISTRY_ENDPOINT/ystv/computing:$BUILD_ID
                                    docker image prune -a -f --filter "label=site=computing"
                                    exit 0
                                EOF'''
                            }
                        }
                    }
                }
                stage('Production') {
                    when {
                        expression { return env.TAG_NAME ==~ /v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)/ } // Checking if it is main semantic version release
                    }
                    environment {
                        APP_ENV = credentials('')
                        TARGET_SERVER = credentials('prod-server-address')
                        TARGET_PATH = credentials('prod-server-path')
                    }
                    steps {
                        sshagent(credentials : ['prod-server-key']) {
                            script {
                                sh 'rsync -av $APP_ENV deploy@$TARGET_SERVER:$TARGET_PATH/computing/.env'
                                sh '''ssh -tt deploy@$TARGET_SERVER << EOF
                                    docker pull $REGISTRY_ENDPOINT/ystv/computing:$BUILD_ID
                                    docker rm -f ystv-computing
                                    docker run -d -p 1336:8081 --env-file $TARGET_PATH/computing/.env --name ystv-computing $REGISTRY_ENDPOINT/ystv/computing:$BUILD_ID
                                    docker image prune -a -f --filter "label=site=computing"
                                    exit 0
                                EOF'''
                            }
                        }
                    }
                }
            }
        }
    }
    post {
        success {
            echo 'Very cash-money'
        }
        failure {
            echo 'That is not ideal, cheeky bugger'
        }
        always {
            sh "docker image prune -f --filter label=site=computing --filter label=stage=builder" // Removing the local builder image
            sh 'docker image prune -a -f --filter "label=site=computing"' // remove old image
        }
    }
}