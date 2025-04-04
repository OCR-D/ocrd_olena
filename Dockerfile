ARG DOCKER_BASE_IMAGE=ocrd/core

# Patch and build Olena from Git
FROM ubuntu:20.04 AS olena
ARG VCS_REF
ARG BUILD_DATE
LABEL \
    maintainer="https://ocr-d.de/en/contact" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/OCR-D/ocrd_olena" \
    org.label-schema.build-date=$BUILD_DATE \
    org.opencontainers.image.vendor="DFG-Funded Initiative for Optical Character Recognition Development" \
    org.opencontainers.image.title="ocrd_olena" \
    org.opencontainers.image.description="Binarize with Olena/scribo" \
    org.opencontainers.image.source="https://github.com/OCR-D/ocrd_olena" \
    org.opencontainers.image.documentation="https://github.com/OCR-D/ocrd_olena/blob/${VCS_REF}/README.md" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.base.name=ubuntu:20.04

ENV PREFIX=/usr/local

# set frontend non-interactive to silence interactive tzdata config
ENV DEBIAN_FRONTEND noninteractive
# set proper locales
ENV PYTHONIOENCODING utf8
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /build-olena
COPY . .

ENV DEPS="g++ make automake git libtool pkgconf"
RUN apt-get update && \
    apt-get -y install --no-install-recommends $DEPS && \
    make deps-ubuntu && \
    make build-olena clean-olena GIT_SUBMODULE=: && \
    apt-get -y remove $DEPS && \
    apt-get clean && \
    rm -fr /build-olena

# smoke test
RUN scribo-cli sauvola --help

WORKDIR /data
VOLUME /data

CMD ["/usr/local/bin/scribo-cli", "--help"]

# Install OCR-D wrapper for binarization
FROM $DOCKER_BASE_IMAGE AS ocrd
ARG VCS_REF
ARG BUILD_DATE
LABEL \
    maintainer="https://ocr-d.de/en/contact" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/OCR-D/ocrd_olena" \
    org.label-schema.build-date=$BUILD_DATE \
    org.opencontainers.image.vendor="DFG-Funded Initiative for Optical Character Recognition Development" \
    org.opencontainers.image.title="ocrd_olena" \
    org.opencontainers.image.description="Binarize with Olena/scribo" \
    org.opencontainers.image.source="https://github.com/OCR-D/ocrd_olena" \
    org.opencontainers.image.documentation="https://github.com/OCR-D/ocrd_olena/blob/${VCS_REF}/README.md" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.base.name=$DOCKER_BASE_IMAGE

# set frontend non-interactive to silence interactive tzdata config
ENV DEBIAN_FRONTEND noninteractive
# set proper locales
ENV PYTHONIOENCODING utf8
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# avoid HOME/.local/share (hard to predict USER here)
# so let XDG_DATA_HOME coincide with fixed system location
# (can still be overridden by derived stages)
ENV XDG_DATA_HOME /usr/local/share
# avoid the need for an extra volume for persistent resource user db
# (i.e. XDG_CONFIG_HOME/ocrd/resources.yml)
ENV XDG_CONFIG_HOME /usr/local/share/ocrd-resources

WORKDIR /build/ocrd_olena
COPY --from=olena /usr/local/bin/scribo-cli /usr/local/bin/
COPY --from=olena /usr/local/libexec/scribo /usr/local/libexec/scribo
COPY . .
COPY ocrd-tool.json .
# prepackage ocrd-tool.json as ocrd-all-tool.json
RUN ocrd ocrd-tool ocrd-tool.json dump-tools > $(dirname $(ocrd bashlib filename))/ocrd-all-tool.json
# install everything and reduce image size
RUN make deps-ubuntu
RUN scribo-cli sauvola --help
RUN make install && \
    rm -fr /build/ocrd_olena

# smoke test
RUN scribo-cli sauvola --help
RUN ocrd-olena-binarize -h

WORKDIR /data
VOLUME /data


