ARG JDK_VERSION="22"
FROM docker.io/library/amazoncorretto:${JDK_VERSION}-al2023 as upstream

USER root

FROM upstream as base

RUN yum update && \
    yum install --allowerasing -y \
      brotli \
      curl \
      expat \
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

RUN yum install -y libX11-devel perl-CPAN perl-Tk

ENV PERL_MM_USE_DEFAULT "1"
RUN cpan install App::cpanminus
RUN cpanm install CPAN::DistnameInfo HTTP::Date
RUN cpanm install pp && pp --version
RUN cpanm install Image::ExifTool && exiftool -ver
RUN pp -S -c -o exiftool $(which exiftool) && ./exiftool -ver

FROM base as exiv2

WORKDIR /build

RUN yum groupinstall -y 'Development Tools'
RUN yum install -y \
      brotli-devel \
      cmake \
      expat-devel

ARG EXIV2_VERSION="0.28.2"
RUN git clone --depth=1 --branch="v${EXIV2_VERSION}" https://github.com/Exiv2/exiv2.git "exiv2"
WORKDIR /build/exiv2

RUN cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DEXIV2_ENABLE_INIH=OFF
RUN cmake --build build -j $(nproc)

RUN build/bin/exiv2 --version && ldd build/bin/exiv2

FROM base as magick

COPY --from=exiftool  /build/exiftool              /bin/exiftool
COPY --from=exiv2     /build/exiv2/build/bin/exiv2 /bin/exiv2
COPY --from=gifsicle  /opt/bin/gifsicle            /bin/gifsicle
COPY --from=oxipng    /usr/local/cargo/bin/oxipng  /bin/oxipng

RUN yum install -y  \
      ImageMagick \
      libjpeg-turbo-utils && \
    rm -rf /var/cache/yum/* && \
    yum clean all && \
    rm -rf /var/log/*.log

USER mangadex
RUN convert --version
RUN exiftool -ver
RUN exiv2 --version
RUN identify --version
RUN gifsicle --version
RUN jpegtran -version
RUN oxipng --version
RUN fc-cache -rf

USER mangadex
WORKDIR /tmp

FROM base as playwright

ENV PLAYWRIGHT_BROWSERS_PATH /ms-playwright

ARG PLAYWRIGHT_VERSION="1.42"
ENV PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION}"

USER root

RUN curl -fsSL -o setup_node.sh https://rpm.nodesource.com/setup_20.x && \
    chmod +x setup_node.sh && \
    ./setup_node.sh && \
    rm -v setup_node.sh && \
    yum install -y \
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
    yum autoremove -y nodejs && \
    rm -rf /var/cache/yum/* && \
    yum clean all && \
    rm -rf /var/log/*.log

RUN fc-cache -rf

USER mangadex
WORKDIR /tmp
