ARG JDK_VERSION="21"
FROM docker.io/library/amazoncorretto:${JDK_VERSION}-al2023 as upstream

USER root

FROM upstream as base

RUN yum update && \
    yum install --allowerasing -y \
      curl \
      fontconfig \
      gzip \
      shadow-utils \
      tar \
      util-linux \
      wget \
      which && \
    rm -rf /var/cache/yum/* && \
    yum clean all && \
    rm -rf /var/log/*.log

COPY install-maven.sh /tmp/install-maven.sh
RUN chmod -v +x /tmp/install-maven.sh && /tmp/install-maven.sh && rm -v /tmp/install-maven.sh

RUN groupadd -r -g 9999 mangadex && useradd -m -u 9999 -g 9999 mangadex
USER mangadex

RUN java -version
RUN mkdir "$HOME/.m2" && mvn -v

USER root

FROM base as gifsicle

RUN yum update && yum groupinstall -y "Development Tools"
COPY install-gifsicle.sh /tmp/install-gifsicle.sh

ARG GIFSICLE_VERSION="1.94"
RUN chmod -v +x /tmp/install-gifsicle.sh && /tmp/install-gifsicle.sh "${GIFSICLE_VERSION}"
RUN ldd /opt/bin/gifsicle && /opt/bin/gifsicle --version

FROM rust:1-alpine as oxipng

RUN rustup update && rustup install stable
RUN apk add --update alpine-sdk

ARG OXIPNG_VERSION="9.0.0"
RUN cargo install --features=binary oxipng@9.0.0
RUN oxipng --version

FROM base as exiftool

WORKDIR /build

RUN yum install -y libX11-devel perl-CPAN

ENV PERL_MM_USE_DEFAULT "1"
RUN cpan fforce install CPAN::DistnameInfo
RUN cpan fforce install pp && pp --version
RUN cpan install Image::ExifTool && exiftool -ver
RUN pp -S -o exiftool $(which exiftool) && ./exiftool -ver

FROM base as magick

COPY --from=exiftool  /build/exiftool             /bin/exiftool
COPY --from=gifsicle  /opt/bin/gifsicle           /bin/gifsicle
COPY --from=oxipng    /usr/local/cargo/bin/oxipng /bin/oxipng

RUN yum install -y  \
      ImageMagick \
      libjpeg-turbo-utils && \
    rm -rf /var/cache/yum/* && \
    yum clean all && \
    rm -rf /var/log/*.log

USER mangadex
RUN convert --version
RUN exiftool -ver
RUN identify --version
RUN gifsicle --version
RUN jpegtran -version
RUN oxipng --version
RUN fc-cache -rf

USER mangadex
WORKDIR /tmp

FROM base as playwright

ENV PLAYWRIGHT_BROWSERS_PATH /ms-playwright

ARG PLAYWRIGHT_VERSION="1.38"
ENV PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION}"

USER root

RUN yum update && \
    yum install -y https://rpm.nodesource.com/pub_18.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm && \
    yum install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1 && \
    npm install -g npm && \
    mkdir -pv "$PLAYWRIGHT_BROWSERS_PATH" && \
    npx --yes playwright@^${PLAYWRIGHT_VERSION} install chromium && \
    rm -rf $PLAYWRIGHT_BROWSERS_PATH/ffmpeg* && \
    rm -rf $PLAYWRIGHT_BROWSERS_PATH/firefox* && \
    rm -rf $PLAYWRIGHT_BROWSERS_PATH/webkit* && \
    yum install -y \
      at-spi2-atk \
      at-spi2-core \
      atk \
      cups-client \
      libXcomposite \
      libXdamage \
      libXfixes \
      mesa-libgbm \
      nss \
      pango && \
    yum autoremove -y nodejs && \
    rm -rf /var/cache/yum/* && \
    yum clean all && \
    rm -rf /var/log/*.log

RUN fc-cache -rf

USER mangadex
WORKDIR /tmp
