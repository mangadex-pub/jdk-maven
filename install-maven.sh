#!/usr/bin/env bash

set -euo pipefail

export MAVEN_VERSION="3.8.7"
export MAVEN_TARBALL_SHA="21c2be0a180a326353e8f6d12289f74bc7cd53080305f05358936f3a1b6dd4d91203f4cc799e81761cf5c53c5bbe9dcc13bdb27ec8f57ecf21b2f9ceec3c8d27"
export MAVEN_TARBALL_BASEURL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries"

MAVEN_INSTALL_DIR="${1:-"/usr/share/maven"}"
echo "Installing maven $MAVEN_VERSION at $MAVEN_INSTALL_DIR"

mkdir -pv "$MAVEN_INSTALL_DIR" "$MAVEN_INSTALL_DIR/ref"
curl -sfSL -o /tmp/apache-maven.tar.gz ${MAVEN_TARBALL_BASEURL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz
echo "${MAVEN_TARBALL_SHA} /tmp/apache-maven.tar.gz" | sha512sum -c -
tar -xzf /tmp/apache-maven.tar.gz -C "$MAVEN_INSTALL_DIR" --strip-components=1
rm -fv /tmp/apache-maven.tar.gz
ln -s "$MAVEN_INSTALL_DIR/bin/mvn" /usr/bin/mvn
