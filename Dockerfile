###
# Information and Instructions
###
# Dockerfile for the creating the jenkins agent inside Docker with maven
# Extends: docker:17.06
# and https://github.com/vfarcic/docker-jenkins-slave-dind/blob/master/Dockerfile
# and https://github.com/frol/docker-alpine-glibc/blob/master/Dockerfile
# Installs the following software:
# openjdk8-jre python py-pip git maven openssh ca-certificates openssl docker-compose swarm-client (jenkins)
# sonar-runner aws
###
## To build:
# docker build -t jenkins-swarm-agent-docker:1.0.1 .
## To run, with login:
# docker run -it --name jenkins-agent jenkins-swarm-agent-docker
# To run as a service
# docker service create --network ci-network --with-registry-auth --secret jenkins-user --secret jenkins-pass --name jenkins-agent 667203200330.dkr.ecr.ap-northeast-1.amazonaws.com/jenkins-swarm-agent-docker:1.0.3
## To run in background:
# docker run -d --name jenkins-agent jenkins-swarm-agent-docker:1.0.0
## To login when running
# docker exec -i -t (containerId) bash # obtain the containerId from docker ps
## to tag for pushing to aws, e.g.
# docker tag jenkins-swarm-agent-docker:1.0.1 667203200330.dkr.ecr.ap-northeast-1.amazonaws.com/jenkins-swarm-agent-docker:1.0.1
## to push to aws
# docker push 667203200330.dkr.ecr.ap-northeast-1.amazonaws.com/jenkins-swarm-agent-docker:1.0.1
## to pull from aws
# docker pull 667203200330.dkr.ecr.ap-northeast-1.amazonaws.com/jenkins-swarm-agent-docker:1.0.1
################################################
# Some useful Docker commands
# To list running docker containers: "docker ps"
# When running in the background, the container needs to be stopped.
#  - type "docker ps" to get the container id
#  - type "docker stop {containerid}"
#  - type "docker rm {id}
# To log in to the container: "docker exec -it {containerid} bash"
# login to ecr aws ecr get-login --no-include-email --region ap-northeast-1 | sh
# docker service update --with-registry-auth  --image 667203200330.dkr.ecr.ap-northeast-1.amazonaws.com/jenkins-swarm-agent-docker:1.0.0 jenkins-agent
###############################################

FROM docker:17.06

MAINTAINER Fergus MacDermot <fergusmacdermot@gmail.com>

ARG "version=0.2.0"
ARG "build_date=unknown"
ARG "commit_hash=unknown"
ARG "vcs_url=unknown"
ARG "vcs_branch=unknown"

LABEL org.label-schema.vendor="fmacdermot" \
    org.label-schema.name="jenkins-swarm-agent" \
    org.label-schema.description="Jenkins agent based on the Swarm plugin" \
    org.label-schema.vcs-url=$vcs_url \
    org.label-schema.vcs-branch=$vcs_branch \
    org.label-schema.vcs-ref=$commit_hash \
    org.label-schema.version=$version \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$build_date

ENV SWARM_CLIENT_VERSION="3.3" \
    DOCKER_COMPOSE_VERSION="1.14.0" \
    COMMAND_OPTIONS="" \
    USER_NAME_SECRET="" \
    PASSWORD_SECRET=""

RUN adduser -G root -D jenkins && \
    apk --update --no-cache add python py-pip git openssh ca-certificates openssl && \
    wget -q https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VERSION}/swarm-client-${SWARM_CLIENT_VERSION}.jar -P /home/jenkins/ && \
   pip install docker-compose



# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.

RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.25-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

# Here we install the Oracle JDK
ENV JAVA_VERSION=8 \
    JAVA_UPDATE=141 \
    JAVA_BUILD=15 \
    JAVA_PATH=336fa29ff2bb4ef291e347e091f7f4a7 \
    JAVA_HOME="/usr/lib/jvm/default-jvm"

RUN apk add --no-cache --virtual=build-dependencies wget ca-certificates unzip && \
    cd "/tmp" && \
    wget --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
        "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}u${JAVA_UPDATE}-b${JAVA_BUILD}/${JAVA_PATH}/jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    tar -xzf "jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    mkdir -p "/usr/lib/jvm" && \
    mv "/tmp/jdk1.${JAVA_VERSION}.0_${JAVA_UPDATE}" "/usr/lib/jvm/java-${JAVA_VERSION}-oracle" && \
    ln -s "java-${JAVA_VERSION}-oracle" "$JAVA_HOME" && \
    ln -s "$JAVA_HOME/bin/"* "/usr/bin/" && \
    rm -rf "$JAVA_HOME/"*src.zip && \
    rm -rf "$JAVA_HOME/lib/missioncontrol" \
           "$JAVA_HOME/lib/visualvm" \
           "$JAVA_HOME/lib/"*javafx* \
           "$JAVA_HOME/jre/lib/plugin.jar" \
           "$JAVA_HOME/jre/lib/ext/jfxrt.jar" \
           "$JAVA_HOME/jre/bin/javaws" \
           "$JAVA_HOME/jre/lib/javaws.jar" \
           "$JAVA_HOME/jre/lib/desktop" \
           "$JAVA_HOME/jre/plugin" \
           "$JAVA_HOME/jre/lib/"deploy* \
           "$JAVA_HOME/jre/lib/"*javafx* \
           "$JAVA_HOME/jre/lib/"*jfx* \
           "$JAVA_HOME/jre/lib/amd64/libdecora_sse.so" \
           "$JAVA_HOME/jre/lib/amd64/"libprism_*.so \
           "$JAVA_HOME/jre/lib/amd64/libfxplugins.so" \
           "$JAVA_HOME/jre/lib/amd64/libglass.so" \
           "$JAVA_HOME/jre/lib/amd64/libgstreamer-lite.so" \
           "$JAVA_HOME/jre/lib/amd64/"libjavafx*.so \
           "$JAVA_HOME/jre/lib/amd64/"libjfx*.so && \
    rm -rf "$JAVA_HOME/jre/bin/jjs" \
           "$JAVA_HOME/jre/bin/keytool" \
           "$JAVA_HOME/jre/bin/orbd" \
           "$JAVA_HOME/jre/bin/pack200" \
           "$JAVA_HOME/jre/bin/policytool" \
           "$JAVA_HOME/jre/bin/rmid" \
           "$JAVA_HOME/jre/bin/rmiregistry" \
           "$JAVA_HOME/jre/bin/servertool" \
           "$JAVA_HOME/jre/bin/tnameserv" \
           "$JAVA_HOME/jre/bin/unpack200" \
           "$JAVA_HOME/jre/lib/ext/nashorn.jar" \
           "$JAVA_HOME/jre/lib/jfr.jar" \
           "$JAVA_HOME/jre/lib/jfr" \
           "$JAVA_HOME/jre/lib/oblique-fonts" && \
    wget --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
        "http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION}/jce_policy-${JAVA_VERSION}.zip" && \
    unzip -jo -d "${JAVA_HOME}/jre/lib/security" "jce_policy-${JAVA_VERSION}.zip" && \
    rm "${JAVA_HOME}/jre/lib/security/README.txt" && \
    apk del build-dependencies && \
    rm "/tmp/"*

# Install maven
RUN wget http://ftp.fau.de/apache/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz
RUN tar -zxvf apache-maven-3.5.0-bin.tar.gz
RUN rm apache-maven-3.5.0-bin.tar.gz
RUN mv apache-maven-3.5.0 /usr/lib/mvn

RUN java -version

#ENV JAVA_HOME /usr/lib/jvm/default-jvm
ENV JAVA=$JAVA_HOME/bin
ENV M2_HOME=/usr/lib/mvn
ENV M2=$M2_HOME/bin
ENV PATH $PATH:$JAVA_HOME:$JAVA:$M2_HOME:$M2

# Print out the maven version
RUN mvn --version

# We also need the sonarqube runner

RUN wget --output-document=sonar-runner.zip https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778.zip

RUN unzip sonar-runner.zip

RUN mkdir -p /apps/sonar-runner

RUN mv sonar-scanner-3.0.3.778/* /apps/sonar-runner

RUN chmod +x /apps/sonar-runner/bin/sonar-runner

COPY sonar-scanner.properties /apps/sonar-runner/conf/sonar-scanner.properties

COPY run-agent.sh /run-agent.sh
RUN chmod +x /run-agent.sh

### Install AWS
RUN wget "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install -b ~/bin/aws

ENV AWS_HOME=/root/bin

ENV PATH $PATH:$AWS_HOME

CMD ["/run-agent.sh"]
