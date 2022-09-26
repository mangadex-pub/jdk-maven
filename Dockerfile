ARG JDK_VERSION="19"
FROM docker.io/library/amazoncorretto:${JDK_VERSION}

USER root
RUN yum install -y  \
      gzip \
      shadow-utils \
      tar \
      which \
  && rm -rf /var/cache/yum/* \
  && yum clean all

ARG MAVEN_VERSION="3.8.6"
ARG SHA="f790857f3b1f90ae8d16281f902c689e4f136ebe584aba45e4b1fa66c80cba826d3e0e52fdd04ed44b4c66f6d3fe3584a057c26dfcac544a60b301e6d0f91c26"
ARG BASE_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries"

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA} /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

RUN groupadd -r -g 999 mangadex && \
    useradd -m -u 999 -r -g 999 mangadex

USER mangadex
ENV MAVEN_CONFIG "/home/mangadex/.m2"
RUN mkdir -pv "$MAVEN_CONFIG"

WORKDIR /tmp
