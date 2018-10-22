FROM  ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

#################################################################
# Install java
#################################################################

RUN apt-get update && \
    apt-get install -y software-properties-common  \
    git \
    curl \
    wget \
    zip \
    unzip \
    tzdata && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get update && \
    apt-get install -y oracle-java8-installer && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN  cp /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime \
    && echo "Europe/Copenhagen" > /etc/timezone

ENV TZ Europe/Copenhagen

#################################################################
# Install maven
#################################################################

ARG MAVEN_VERSION=3.5.4
ARG USER_HOME_DIR="/root"
ARG BASE_URL=https://www-eu.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/
ARG SHA=22cac91b3557586bb1eba326f2f7727543ff15e3

RUN curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz
RUN echo "${SHA}  /tmp/apache-maven.tar.gz" | sha1sum -c -
## Verified, let's install
RUN mkdir -p /usr/share/maven /usr/share/maven/ref
RUN tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1
RUN rm -f /tmp/apache-maven.tar.gz
RUN ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

#################################################################
# Install Nodejs
#################################################################
RUN  apt-get update \
  && apt-get install -y git \
  libpq-dev \
  apt-transport-https \
  make \
  python-pip \
  python2.7 \
  python2.7-dev \
  ssh \
  xz-utils  \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1006 node \
  && useradd --uid 1002 --gid node --shell /bin/bash --create-home node

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
  ; do \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NODE_VERSION 8.11.4

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz"
RUN curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc"
RUN gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc
RUN grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c -
RUN tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner
RUN rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs

RUN npm install npm@6.4.0 -g
RUN npm install --unsafe-perm -g @angular/cli findup-sync typescript


##################################################
# Headless chrome
##################################################

RUN  apt-get update \
  && apt-get install -y build-essential \
  ca-certificates \
  gcc \
  apt-transport-https \
  && rm -rf /var/lib/apt/lists/*

# Install deps + add Chrome Stable + purge all the things
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/chrome.list
RUN apt-get update -qqy
RUN apt-get -qqy install  google-chrome-stable
RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN npm install -g sonarqube-scanner
RUN mkdir /.sonar && chown -R node:node /.sonar && chmod -R 755 /.sonar
RUN mkdir -p /usr/local/lib/node_modules && chown -R node:node /usr/local/lib/node_modules && chmod -R 755 /usr/local/lib/node_modules

USER node
