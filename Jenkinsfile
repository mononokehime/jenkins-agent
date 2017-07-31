pipeline {
    agent any
    stages {
        stage ('Check out') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: 'any']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '3ebab8f6-e86d-4e5c-8d8e-6bdaf0d517de', url: 'https://github.com/mononokehime/jenkins-agent.git']]])
            }
        }
    }
    stage ('Docker Build') {
        steps {
            docker.build('jenkins-swarm-agent-docker')
        }

        post {
            success {

                echo "Success"
            }
        }
    }
    stage ('Docker Publish') {
        steps {
            docker.withRegistry('https://667203200330.dkr.ecr.ap-northeast-1.amazonaws.com', 'ecr:ap-northeast-1:ecr-credentials') {
            docker.image('jenkins-swarm-agent-docker').push('latest')
        }

        post {
            success {

                echo "Success"
            }
        }
    }
    // The options directive is for configuration that applies to the whole job.
    options {
        // For example, we'd like to make sure we only keep 10 builds at a time, so
        // we don't fill up our storage!
        buildDiscarder(logRotator(numToKeepStr:'10'))

        // And we'd really like to be sure that this build doesn't hang forever, so
        // let's time it out after an hour.
        timeout(time: 60, unit: 'MINUTES')
    }
}