pipeline {
    agent any
    stages {
        stage ('Docker Build') {
            steps {
                script {
                    docker.build('jenkins-swarm-agent-docker')
                    }
                }

            post {
                success {

                    echo "Success"
                    }
                }
            }
        stage ('Docker Publish') {
            steps {
                script {
                    docker.withRegistry('https://667203200330.dkr.ecr.ap-northeast-1.amazonaws.com', 'ecr:ap-northeast-1:ecr-credentials') {
                    docker.image('jenkins-swarm-agent-docker').push('latest')
                    }
                }
            }
            post {
                success {

                    echo "Success"
                }
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