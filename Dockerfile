FROM ghcr.io/mangadex-pub/containers-base/rockylinux:9 AS linux-base
ENV MD_OS_FLAVOUR="RockyLinux"
ENV MD_OS_VERSION="9"

ARG JDK_VERSION="23"
ENV JDK_VERSION=${JDK_VERSION}

FROM linux-base AS graal
USER root

ENV JDK_INSTALLDIR="/opt/graalvm-${JDK_VERSION}"
ENV PATH="${JDK_INSTALLDIR}/bin:$PATH"

WORKDIR /tmp
RUN curl -f "https://download.oracle.com/graalvm/${JDK_VERSION}/latest/graalvm-jdk-${JDK_VERSION}_linux-x64_bin.tar.gz" -o "jdk.tar.gz" && \
    mkdir -pv "${JDK_INSTALLDIR}" && \
    tar -C "${JDK_INSTALLDIR}" --strip-components=1 -xf "jdk.tar.gz" && \
    rm -v "jdk.tar.gz"

COPY install-maven.sh /tmp/install-maven.sh
RUN chmod -v +x /tmp/install-maven.sh && \
    /tmp/install-maven.sh && \
    rm -v /tmp/install-maven.sh

USER mangadex
RUN java -version
RUN mkdir "$HOME/.m2" && mvn -v

FROM linux-base AS corretto

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

FROM linux-base AS mozjpeg

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

FROM corretto AS magick

USER root
RUN dnf install -y  \
      exiv2 \
      fribidi \
      gifsicle \
      jpeginfo \
      libX11 \
      oxipng \
      perl-Image-ExifTool && \
    dnf clean all && \
    rm -rf \
      /tmp/* \
      /var/cache \
      /var/lib/apt/lists/* \
      /var/log/* \
      /var/tmp/*

RUN curl -sfSL -o magick.appimage https://github.com/ImageMagick/ImageMagick/releases/download/7.1.1-41/ImageMagick-bbdcbf7-gcc-x86_64.AppImage && \
    chmod +x -v ./magick.appimage && \
    ./magick.appimage --appimage-extract && \
    rm -v magick.appimage && \
    cp -rv squashfs-root/usr/bin/* /usr/bin/ && \
    cp -rv squashfs-root/usr/etc/ImageMagick-7 /etc/ImageMagick-7 && \
    cp -rv squashfs-root/usr/lib /usr/lib/imagemagick-7 && \
    rm -rv squashfs-root && \
    echo '/usr/lib/imagemagick-7' > /etc/ld.so.conf.d/99-imagemagick.conf && \
    ldconfig && \
    magick --version

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

FROM corretto AS playwright

ARG PLAYWRIGHT_VERSION="1.44"
ENV PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION}"
ENV PLAYWRIGHT_BROWSERS_PATH="/ms-playwright"

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
