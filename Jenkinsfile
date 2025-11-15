pipeline {
    agent any
    
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
                        
                        // Get the latest snapshot version from maven-metadata.xml
                        sh """
                            curl -u ${NEXUS_USERNAME}:${NEXUS_PASSWORD} \
                            -s -o maven-metadata.xml \
                            "${NEXUS_URL}/repository/maven-snapshots/com/example/sample-webapp/${pomVersion}/maven-metadata.xml"
                        """
                        
                        def metadata = readFile('maven-metadata.xml')
                        def timestamp = (metadata =~ /<timestamp>(.+)<\/timestamp>/)[0][1]
                        def buildNumber = (metadata =~ /<buildNumber>(.+)<\/buildNumber>/)[0][1]
                        def snapshotVersion = pomVersion.replace('-SNAPSHOT', "-${timestamp}-${buildNumber}")
                        
                        echo "Downloading snapshot version: ${snapshotVersion}"
                        
                        // Download WAR from Nexus using snapshot version
                        sh """
                            curl -u ${NEXUS_USERNAME}:${NEXUS_PASSWORD} \
                            -L -o sample-webapp.war \
                            "${NEXUS_URL}/repository/maven-snapshots/com/example/sample-webapp/${pomVersion}/sample-webapp-${snapshotVersion}.war"
                        """
                        
                        // Build Docker image
                        docker.build("${DOCKER_IMAGE}:${VERSION}")
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh "docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                    sh "docker push ${DOCKER_IMAGE}:${VERSION}"
                    sh "docker tag ${DOCKER_IMAGE}:${VERSION} ${DOCKER_IMAGE}:latest"
                    sh "docker push ${DOCKER_IMAGE}:latest"
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
