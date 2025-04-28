pipeline {
    
    agent any
    
    tools {
        jdk 'jdk21'
        nodejs 'nodejs23'
    }
    
    environment {
        SONAR_HOME = tool 'sonar-scanner'
    }
    
    stages {
    
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
    
        stage('Git Checkout') {
            steps {
                git branch: 'master', credentialsId: 'git-credential', url: 'https://github.com/Routparesh/Amazon-prime-video-clone-deploy'
            }
        }
        
        stage('Sonarqube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '$SONAR_HOME/bin/sonar-scanner -Dsonar.projectKey=amazonprime -Dsonar.projectName=amazonprime'
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }
        
        stage('Installing Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        
        stage('Trivy Scan on Filesystem') {
            steps {
                sh 'trivy fs . > trivy-fs-output.txt'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh 'docker build -t routparesh/amazon-prime:$BUILD_NUMBER .'
                    }
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh 'docker push routparesh/amazon-prime:$BUILD_NUMBER'
                    }
                }
            }
        }
        
        stage('Trivy Scan on Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh 'trivy image routparesh/amazon-prime:$BUILD_NUMBER > trivy-image-output.txt'
                    }
                }
            }
        }
        
        stage('Testing Deploy to Docker Container') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh 'docker rm -f prime-video || true'
                        sh 'docker run -d --name prime-video -p 3001:3000 routparesh/amazon-prime:$BUILD_NUMBER'
                    }
                }
            }
        }
        
        stage('Deployment to Production') {
            environment {
                GIT_REPO_NAME = "Amazon-prime-video-clone-deploy"
                GIT_USER_NAME = "Routparesh"
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'git-cred', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                        git config user.email "routpareshkumar737@gmail.com"
                        git config user.name "Paresh Kumar Rout"
                        BUILD_NUMBER=${BUILD_NUMBER}
                        cp Kubernetes-development/* K8S-Production/
                        sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" K8S-Production/Deployment.yaml
                        git add K8S-Production/
                        git commit -m "Update Deployment Manifest for Production"
                        git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME}.git HEAD:master
                    '''
                }
            }
        }
    }
    
    post {
        always {
            emailext(
                attachLog: true,
                subject: "'${currentBuild.result}'",
                body: """
                    <html>
                    <body>
                        <div style="background-color: #FFA07A; padding: 10px; margin-bottom: 10px;">
                            <p style="color: white; font-weight: bold;">Project: ${env.JOB_NAME}</p>
                        </div>
                        <div style="background-color: #90EE90; padding: 10px; margin-bottom: 10px;">
                            <p style="color: white; font-weight: bold;">Build Number: ${env.BUILD_NUMBER}</p>
                        </div>
                        <div style="background-color: #87CEEB; padding: 10px; margin-bottom: 10px;">
                            <p style="color: white; font-weight: bold;">URL: ${env.BUILD_URL}</p>
                        </div>
                    </body>
                    </html>
                """,
                to: 'routpareshkumar737@gmail.com',
                mimeType: 'text/html',
                attachmentsPattern: 'trivy-fs-output.txt, trivy-image-output.txt'
            )
        }
    }
}

