#!/usr/bin/env bash

set -euo pipefail

export MAVEN_VERSION="3.9.2"
export MAVEN_TARBALL_SHA="900bdeeeae550d2d2b3920fe0e00e41b0069f32c019d566465015bdd1b3866395cbe016e22d95d25d51d3a5e614af2c83ec9b282d73309f644859bbad08b63db"
export MAVEN_TARBALL_BASEURL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries"

MAVEN_INSTALL_DIR="${1:-"/usr/share/maven"}"
echo "Installing maven $MAVEN_VERSION at $MAVEN_INSTALL_DIR"

mkdir -pv "$MAVEN_INSTALL_DIR" "$MAVEN_INSTALL_DIR/ref"
curl -sfSL -o /tmp/apache-maven.tar.gz ${MAVEN_TARBALL_BASEURL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz
echo "${MAVEN_TARBALL_SHA} /tmp/apache-maven.tar.gz" | sha512sum -c -
tar -xzf /tmp/apache-maven.tar.gz -C "$MAVEN_INSTALL_DIR" --strip-components=1
rm -fv /tmp/apache-maven.tar.gz
ln -s "$MAVEN_INSTALL_DIR/bin/mvn" /usr/bin/mvn
