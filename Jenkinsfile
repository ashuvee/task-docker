pipeline {
    agent {
        dockerfile {
            dir 'jenkins'
        }
    }
    
    environment {
        SONARQUBE_URL          = 'http://sonarqube:9000'
        NEXUS_URL              = 'http://nexus:8081'
        DOCKER_IMAGE           = "ashuz/sample-webapp" // CHANGE THIS
        VERSION                = "${env.BUILD_NUMBER}"
    }
    
    tools {
        maven 'Maven-3.8'
        jdk 'JDK-21'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "Checking out code..."
                checkout scm
            }
        }
        
        stage('Build & Unit Tests') {
            steps {
                echo "Building and running unit tests..."
                sh 'mvn clean package'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis. NOTE: The explicit Quality Gate check is temporarily disabled for debugging."
                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                    sh "mvn sonar:sonar -Dsonar.host.url=${env.SONARQUBE_URL} -Dsonar.login=${SONAR_TOKEN}"
                }
            }
        }
        
        stage('Deploy to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials', passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                    sh """
                        mvn deploy -DskipTests \
                        -s settings.xml
                    """
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials', passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                    script {
                        def pomContent = readFile 'pom.xml'
                        def pomVersion = (pomContent =~ '<version>(.+)</version>')[0][1]
                        docker.build(
                            "${DOCKER_IMAGE}:${VERSION}",
                            "--build-arg VERSION=${pomVersion} " +
                            "--build-arg NEXUS_USERNAME=${NEXUS_USERNAME} " +
                            "--build-arg NEXUS_PASSWORD=${NEXUS_PASSWORD} ."
                        )
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                    docker.image("${DOCKER_IMAGE}:${VERSION}").push()
                    docker.image("${DOCKER_IMAGE}:${VERSION}").push('latest')
                }
            }
        }
    }
    
    post {
        always {
            echo "Cleaning up workspace..."
            cleanWs()
        }
    }
}
