ARG JDK_VERSION="20"
FROM docker.io/library/amazoncorretto:${JDK_VERSION} as corretto

USER root
RUN yum install -y curl gzip shadow-utils tar which wget \
  && rm -rf /var/cache/yum/* \
  && yum clean all

COPY install-maven.sh /install-maven.sh
RUN /install-maven.sh

RUN groupadd -r -g 999 mangadex && useradd -m -u 999 -r -g 999 mangadex
USER mangadex

WORKDIR /tmp
RUN mkdir -pv "$HOME/.m2" && mvn -v

ARG JDK_VERSION="20"
FROM docker.io/library/eclipse-temurin:${JDK_VERSION}-jammy as temurin

ENV DEBIAN_FRONTEND "noninteractive"
ENV TZ "UTC"
RUN echo 'Dpkg::Progress-Fancy "0";' > /etc/apt/apt.conf.d/99progressbar

USER root
RUN apt -qq update && \
    apt -qq -y full-upgrade && \
    apt -qq -y install --no-install-recommends curl gzip tar wget && \
    apt -qq -y --purge autoremove && \
    apt -qq -y clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /var/log/*

COPY install-maven.sh /install-maven.sh
RUN /install-maven.sh

RUN groupadd -r -g 999 mangadex && useradd -m -u 999 -r -g 999 mangadex

ENTRYPOINT /bin/bash
USER mangadex

WORKDIR /tmp
RUN mkdir -pv "$HOME/.m2" && mvn -v

FROM corretto as magick

USER root
RUN yum install -y  \
      ImageMagick \
  && rm -rf /var/cache/yum/* \
  && yum clean all

ARG OXIPNG_VERSION="8.0.0-mangadex-1"
RUN curl -sfSL -o "oxipng.tar.gz" "https://github.com/mangadex-pub/oxipng/releases/download/v${OXIPNG_VERSION}/oxipng-${OXIPNG_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
    mkdir oxipng && tar -C oxipng --strip-components=1 -xf "oxipng.tar.gz" && \
    mv -fv oxipng/oxipng /bin/oxipng

USER mangadex
RUN identify --version | grep -Pz 'ImageMagick 6'
RUN convert --version | grep -Pz 'ImageMagick 6'
RUN oxipng --version

FROM temurin as playwright

ENV PLAYWRIGHT_BROWSERS_PATH /ms-playwright

USER root
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt -qq -y install --no-install-recommends nodejs && \
    mkdir -pv "$PLAYWRIGHT_BROWSERS_PATH" && \
    npx --yes playwright@^1.32 install chromium && \
    npx --yes playwright@^1.32 install-deps chromium && \
    apt -qq -y autoremove --purge nodejs lsb-release gnupg && \
    rm -rf /root/.npm && \
    apt -qq -y --purge autoremove && \
    apt -qq -y clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /var/log/* && \
    rm -rf $PLAYWRIGHT_BROWSERS_PATH/ffmpeg* && \
    rm -rf $PLAYWRIGHT_BROWSERS_PATH/firefox* && \
    rm -rf $PLAYWRIGHT_BROWSERS_PATH/webkit* && \
    true

USER mangadex
