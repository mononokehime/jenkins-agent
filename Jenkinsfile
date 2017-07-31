pipeline {
    agent any
    stages {
        stage ('Check out') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: 'any']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '3ebab8f6-e86d-4e5c-8d8e-6bdaf0d517de', url: 'https://github.com/mononokehime/jenkins-agent.git']]])
            }
        }
    }
}