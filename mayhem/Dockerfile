# syntax=docker/dockerfile:1.7
#
# Commit-image Dockerfile — JVM target (Maven + Jazzer).
#
# Build (from the repo root, on the `mayhem` branch):
#   DOCKER_BUILDKIT=1 docker build -f mayhem/Dockerfile \
#       --build-arg COMMIT=local \
#       [--build-arg SOURCE_DATE_EPOCH=$(date +%s)] -t cbor-java-commit:test .

FROM ghcr.io/mayhemheroes/base:20260621

ARG COMMIT
ARG REPO_URL
ARG SOURCE_DATE_EPOCH
ARG SANITIZER_FLAGS

ARG JAZZER_VERSION=0.26.0

ENV JAVA_HOME=/opt/toolchains/jdk17 \
    MAVEN_HOME=/opt/toolchains/maven \
    JAZZER_HOME=/opt/toolchains/jazzer \
    JAZZER_API_PATH=/opt/toolchains/jazzer/jazzer-api.jar \
    MAVEN_REPO=/opt/toolchains/maven-repo \
    JVM_LD_LIBRARY_PATH=/opt/toolchains/jdk17/lib/server \
    PATH=/opt/toolchains/jdk17/bin:/opt/toolchains/maven/bin:${PATH}

USER root
RUN install -d /opt/toolchains/jdk17 /opt/toolchains/maven /opt/toolchains/jazzer /opt/toolchains/maven-repo \
 && curl -fsSL "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.16%2B8/OpenJDK17U-jdk_x64_linux_hotspot_17.0.16_8.tar.gz" \
      -o /tmp/jdk17.tgz \
 && tar -xz --strip-components=1 -f /tmp/jdk17.tgz -C /opt/toolchains/jdk17 \
 && rm -f /tmp/jdk17.tgz \
 && rm -rf /opt/toolchains/jdk17/jmods /opt/toolchains/jdk17/lib/src.zip \
 && curl -fsSL "https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz" \
      -o /tmp/maven.tgz \
 && tar -xz --strip-components=1 -f /tmp/maven.tgz -C /opt/toolchains/maven \
 && rm -f /tmp/maven.tgz \
 && curl -fsSL "https://github.com/CodeIntelligenceTesting/jazzer/releases/download/v${JAZZER_VERSION}/jazzer-linux-x86-64.tar.gz" \
      -o /tmp/jazzer.tgz \
 && tar -xzf /tmp/jazzer.tgz -C /opt/toolchains/jazzer \
 && rm -f /tmp/jazzer.tgz \
 && curl -fsSL "https://repo1.maven.org/maven2/com/code-intelligence/jazzer-api/${JAZZER_VERSION}/jazzer-api-${JAZZER_VERSION}.jar" \
      -o /opt/toolchains/jazzer/jazzer-api.jar \
 && chown -R 2000:2000 /opt/toolchains

USER mayhem
WORKDIR /mayhem
COPY --chown=2000:2000 . /mayhem

RUN bash mayhem/build.sh

RUN bash mayhem/test.sh

LABEL org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.revision="${COMMIT}" \
      rlenv.tier="commit" \
      rlenv.source_date_epoch="${SOURCE_DATE_EPOCH}" \
      rlenv.user="mayhem"

USER mayhem
WORKDIR /mayhem
