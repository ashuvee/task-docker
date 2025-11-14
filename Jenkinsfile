pipeline {
    agent any
    
    environment {
        MAVEN_OPTS = '-Xmx1024m'
        SONARQUBE_URL = 'http://sonarqube:9000'
        SONAR_TOKEN = credentials('sonarqube-token')
        NEXUS_URL = 'http://nexus:8081'
        NEXUS_CREDENTIALS = credentials('nexus-credentials')
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = "yourusername/sample-webapp"
        VERSION = "${env.BUILD_NUMBER}"
        ARTIFACT_VERSION = "1.0.${env.BUILD_NUMBER}"
    }
    
    tools {
        maven 'Maven-3.8'
        jdk 'JDK-11'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "=== Stage 1: Git Checkout ==="
                checkout scm
                sh 'git rev-parse --short HEAD > .git/commit-id'
                script {
                    env.GIT_COMMIT_ID = readFile('.git/commit-id').trim()
                }
            }
        }
        
        stage('Build') {
            steps {
                echo "=== Stage 2: Maven Build ==="
                sh 'mvn clean compile -DskipTests'
            }
        }
        
        stage('Unit Tests') {
            steps {
                echo "=== Stage 3: Run Unit Tests ==="
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                echo "=== Stage 4: Code Quality Analysis ==="
                withSonarQubeEnv('SonarQube') {
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=sample-webapp \
                        -Dsonar.host.url=${SONARQUBE_URL} \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                echo "=== Stage 5: Quality Gate Check ==="
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Package') {
            steps {
                echo "=== Stage 6: Create WAR Package ==="
                sh 'mvn package -DskipTests'
            }
        }
        
        stage('Deploy to Nexus') {
            steps {
                echo "=== Stage 7: Upload Artifact to Nexus ==="
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    def isSnapshot = pom.version.contains('SNAPSHOT')
                    def repoId = isSnapshot ? 'nexus-snapshots' : 'nexus-releases'
                    def repoUrl = isSnapshot ? 
                        "${NEXUS_URL}/repository/maven-snapshots/" : 
                        "${NEXUS_URL}/repository/maven-releases/"
                    
                    sh """
                        mvn deploy:deploy-file \
                        -DgroupId=${pom.groupId} \
                        -DartifactId=${pom.artifactId} \
                        -Dversion=${pom.version} \
                        -Dpackaging=war \
                        -Dfile=target/sample-webapp.war \
                        -DrepositoryId=${repoId} \
                        -Durl=${repoUrl}
                    """
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "=== Stage 8: Build Docker Image ==="
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    dockerImage = docker.build(
                        "${DOCKER_IMAGE}:${VERSION}",
                        "--build-arg NEXUS_URL=${NEXUS_URL} " +
                        "--build-arg VERSION=${pom.version} " +
                        "--build-arg NEXUS_REPO=maven-snapshots " +
                        "."
                    )
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo "=== Stage 9: Push to Docker Hub ==="
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub-credentials') {
                        dockerImage.push("${VERSION}")
                        dockerImage.push("latest")
                        dockerImage.push("${GIT_COMMIT_ID}")
                    }
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                echo "=== Stage 10: Cleanup ==="
                sh """
                    docker rmi ${DOCKER_IMAGE}:${VERSION} || true
                    docker rmi ${DOCKER_IMAGE}:latest || true
                    docker system prune -f
                """
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline completed successfully!"
            echo "🐳 Docker Image: ${DOCKER_IMAGE}:${VERSION}"
            echo "📦 Artifact in Nexus: sample-webapp-${ARTIFACT_VERSION}.war"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
        always {
            cleanWs()
        }
    }
}
