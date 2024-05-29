FROM ghcr.io/mangadex-pub/containers-base/rockylinux:9 as base

ARG JDK_VERSION="22"
ENV JDK_VERSION=${JDK_VERSION}

USER root
RUN rpm --import https://yum.corretto.aws/corretto.key && \
    dnf config-manager --add-repo https://yum.corretto.aws/corretto.repo && \
    dnf update -y && \
    dnf install -y \
      brotli \
      expat \
      java-${JDK_VERSION}-amazon-corretto-devel && \
    dnf clean all && \
    rm -rf \
      /tmp/* \
      /var/cache \
      /var/lib/apt/lists/* \
      /var/log/* \
      /var/tmp/*

COPY install-maven.sh /tmp/install-maven.sh
RUN chmod -v +x /tmp/install-maven.sh && \
    /tmp/install-maven.sh && \
    rm -v /tmp/install-maven.sh

USER mangadex
RUN java -version
RUN mkdir "$HOME/.m2" && mvn -v

FROM base as mozjpeg

USER root
WORKDIR /tmp

RUN dnf groupinstall -y 'Development Tools' && \
    dnf install -y \
      cmake \
      yasm

ARG MOZJPEG_VERSION="v4.1.1"
RUN curl -sfS -o mozjpeg.tar.gz https://codeload.github.com/mozilla/mozjpeg/tar.gz/${MOZJPEG_VERSION} && \
    mkdir -v mozjpeg && \
    tar -C mozjpeg --strip-components=1 -xf mozjpeg.tar.gz && \
    rm mozjpeg.tar.gz

WORKDIR /tmp/mozjpeg
RUN mkdir build && \
    pushd build && \
    cmake -G 'Unix Makefiles' ../ -D CMAKE_BUILD_TYPE=Release -D ENABLE_SHARED=OFF -D ENABLE_STATIC=ON -D PNG_SUPPORTED=OFF -D REQUIRE_SIMD=ON && \
    make -j$(nproc) && \
    ./jpegtran-static -version && \
    ldd ./jpegtran-static

FROM base as magick

USER root
RUN dnf install -y  \
      exiv2 \
      gifsicle \
      ImageMagick \
      oxipng \
      perl-Image-ExifTool && \
    dnf clean all && \
    rm -rf \
      /tmp/* \
      /var/cache \
      /var/lib/apt/lists/* \
      /var/log/* \
      /var/tmp/*

COPY --from=mozjpeg /tmp/mozjpeg/build/jpegtran-static /usr/local/bin/jpegtran

USER mangadex
WORKDIR /tmp

RUN convert --version
RUN exiftool -ver
RUN exiv2 --version
RUN identify --version
RUN gifsicle --version
RUN jpegtran -version
RUN oxipng --version
RUN fc-cache -rf

FROM base as playwright

ARG PLAYWRIGHT_VERSION="1.44"
ENV PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION}"
ENV PLAYWRIGHT_BROWSERS_PATH /ms-playwright

USER root
RUN curl -fsSL -o setup_node.sh https://rpm.nodesource.com/setup_20.x && \
    chmod +x setup_node.sh && \
    ./setup_node.sh && \
    rm -v setup_node.sh && \
    dnf install -y \
      at-spi2-atk \
      at-spi2-core \
      atk \
      cups-client \
      libXcomposite \
      libXdamage \
      libXfixes \
      mesa-libgbm \
      nodejs \
      nss \
      pango && \
    npm install -g npm && \
    mkdir -pv "$PLAYWRIGHT_BROWSERS_PATH" && \
    npx --yes playwright@^${PLAYWRIGHT_VERSION} install chromium && \
    rm -rf $PLAYWRIGHT_BROWSERS_PATH/ffmpeg* && \
    rm -rf $PLAYWRIGHT_BROWSERS_PATH/firefox* && \
    rm -rf $PLAYWRIGHT_BROWSERS_PATH/webkit* && \
    dnf autoremove -y nodejs && \
    rm -rf "$HOME/.npm" && \
    dnf clean all && \
    rm -rf \
      /tmp/* \
      /var/cache \
      /var/lib/apt/lists/* \
      /var/log/* \
      /var/tmp/* && \
    fc-cache -rf

USER mangadex
WORKDIR /tmp
