#!/bin/sh

echo "enter script $AWS_ACCESS_KEY"

if [ -f "${USER_NAME_SECRET}" ]; then
    read USR < ${USER_NAME_SECRET}
    COMMAND_OPTIONS="${COMMAND_OPTIONS} -username $USR"
fi

if [ -f "${PASSWORD_SECRET}" ]; then
    read PSS < ${PASSWORD_SECRET}
    COMMAND_OPTIONS="${COMMAND_OPTIONS} -password $PSS"
fi

if [ -n "${AWS_ACCESS_KEY}" ]; then
    echo "in here ${AWS_ACCESS_KEY}"
    AWS_ACCESS_KEY_ID=$(cat /run/secrets/${AWS_ACCESS_KEY})
fi

if [ -n "${AWS_SECRET_ACCESS_KEY}" ]; then
    AWS_SECRET_ACCESS_KEY=$(cat /run/secrets/${AWS_SECRET_ACCESS_KEY})
fi

echo $AWS_ACCESS_KEY_ID
echo "****************************************"

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY

java -jar /home/jenkins/swarm-client-${SWARM_CLIENT_VERSION}.jar ${COMMAND_OPTIONS}