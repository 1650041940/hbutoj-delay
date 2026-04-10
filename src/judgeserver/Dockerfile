FROM eclipse-temurin:8-jdk-focal

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       bash \
       curl \
       ca-certificates \
       gcc \
       g++ \
       python2 \
       python3 \
       pypy \
       pypy3 \
       golang-go \
       mono-devel \
       php-cli \
       nodejs \
       ruby \
       rustc \
    && mkdir -p /usr/bin/jsv8 \
    && ln -sf /usr/bin/python2 /usr/bin/python \
    && ln -sf /usr/bin/python3 /usr/bin/python3.7 \
    && ln -sf /usr/bin/node /usr/bin/jsv8/d8 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /judge

# The build script copies hoj-judgeServer-*.jar into this directory.
COPY hoj-judgeServer-*.jar /judge/hoj-judgeServer.jar
COPY Sandbox-amd64-v1.8.0 /judge/Sandbox-amd64-v1.8.0
COPY Sandbox-arm64-v1.8.0 /judge/Sandbox-arm64-v1.8.0
COPY entrypoint.sh /entrypoint.sh

ENV JAVA_OPTS=""

EXPOSE 8088

RUN chmod +x /entrypoint.sh /judge/Sandbox-amd64-v1.8.0 /judge/Sandbox-arm64-v1.8.0

ENTRYPOINT ["/entrypoint.sh"]
