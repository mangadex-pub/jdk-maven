#!/usr/bin/env bash

set -euo pipefail

export MAVEN_VERSION="3.9.9"
export MAVEN_TARBALL_SHA="a555254d6b53d267965a3404ecb14e53c3827c09c3b94b5678835887ab404556bfaf78dcfe03ba76fa2508649dca8531c74bca4d5846513522404d48e8c4ac8b"
export MAVEN_TARBALL_BASEURL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries"

MAVEN_INSTALL_DIR="${1:-"/usr/share/maven"}"
echo "Installing maven $MAVEN_VERSION at $MAVEN_INSTALL_DIR"

mkdir -pv "$MAVEN_INSTALL_DIR" "$MAVEN_INSTALL_DIR/ref"
curl -sfSL -o /tmp/apache-maven.tar.gz ${MAVEN_TARBALL_BASEURL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz
echo "${MAVEN_TARBALL_SHA} /tmp/apache-maven.tar.gz" | sha512sum -c -
tar -xzf /tmp/apache-maven.tar.gz -C "$MAVEN_INSTALL_DIR" --strip-components=1
rm -fv /tmp/apache-maven.tar.gz
ln -s "$MAVEN_INSTALL_DIR/bin/mvn" /usr/bin/mvn
