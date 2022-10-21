#!/usr/bin/env bash

set -euo pipefail

export MAVEN_VERSION="3.8.6"
export MAVEN_TARBALL_SHA="f790857f3b1f90ae8d16281f902c689e4f136ebe584aba45e4b1fa66c80cba826d3e0e52fdd04ed44b4c66f6d3fe3584a057c26dfcac544a60b301e6d0f91c26"
export MAVEN_TARBALL_BASEURL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries"

MAVEN_INSTALL_DIR="${1:-"/usr/share/maven"}"
echo "Installing maven $MAVEN_VERSION at $MAVEN_INSTALL_DIR"

mkdir -pv "$MAVEN_INSTALL_DIR" "$MAVEN_INSTALL_DIR/ref"
curl -sfSL -o /tmp/apache-maven.tar.gz ${MAVEN_TARBALL_BASEURL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz
echo "${MAVEN_TARBALL_SHA} /tmp/apache-maven.tar.gz" | sha512sum -c -
tar -xzf /tmp/apache-maven.tar.gz -C "$MAVEN_INSTALL_DIR" --strip-components=1
rm -fv /tmp/apache-maven.tar.gz
ln -s "$MAVEN_INSTALL_DIR/bin/mvn" /usr/bin/mvn
