#!/usr/bin/env bash

set -euo pipefail

export MAVEN_VERSION="3.9.1"
export MAVEN_TARBALL_SHA="d3be5956712d1c2cf7a6e4c3a2db1841aa971c6097c7a67f59493a5873ccf8c8b889cf988e4e9801390a2b1ae5a0669de07673acb090a083232dbd3faf82f3e3"
export MAVEN_TARBALL_BASEURL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries"

MAVEN_INSTALL_DIR="${1:-"/usr/share/maven"}"
echo "Installing maven $MAVEN_VERSION at $MAVEN_INSTALL_DIR"

mkdir -pv "$MAVEN_INSTALL_DIR" "$MAVEN_INSTALL_DIR/ref"
curl -sfSL -o /tmp/apache-maven.tar.gz ${MAVEN_TARBALL_BASEURL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz
echo "${MAVEN_TARBALL_SHA} /tmp/apache-maven.tar.gz" | sha512sum -c -
tar -xzf /tmp/apache-maven.tar.gz -C "$MAVEN_INSTALL_DIR" --strip-components=1
rm -fv /tmp/apache-maven.tar.gz
ln -s "$MAVEN_INSTALL_DIR/bin/mvn" /usr/bin/mvn
