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
                sh 'aws ecr get-login --no-include-email --region ap-northeast-1 | sh'
                // ${env.BUILD_ID}
                sh 'docker tag jenkins-swarm-agent-docker 667203200330.dkr.ecr.ap-northeast-1.amazonaws.com/jenkins-swarm-agent-docker:latest'
                sh 'docker push 667203200330.dkr.ecr.ap-northeast-1.amazonaws.com/jenkins-swarm-agent-docker:latest'
              //  script {
              //      docker.withRegistry('https://667203200330.dkr.ecr.ap-northeast-1.amazonaws.com', 'ecr-credentials') {
              //      docker.image('jenkins-swarm-agent-docker').push('latest')
              //      }
                }
            }
            post {
                success {

                    echo "Success"
                }
            }
        }
    }
    post {
        always {
            // something to clean up images
        }
    }
    // The options directive is for configuration that applies to the whole job.
    options {
        // For example, we'd like to make sure we only keep 10 builds at a time, so
        // we don't fill up our storage!
        buildDiscarder(logRotator(numToKeepStr:'5'))

        // And we'd really like to be sure that this build doesn't hang forever, so
        // let's time it out after an hour.
        timeout(time: 60, unit: 'MINUTES')
    }
}