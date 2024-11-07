# Patch and build Olena from Git, then
# Install OCR-D wrapper for binarization
ARG DOCKER_BASE_IMAGE
FROM $DOCKER_BASE_IMAGE
ARG VCS_REF
ARG BUILD_DATE
LABEL \
    maintainer="https://github.com/OCR-D/ocrd_olena/issues" \
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

MAINTAINER OCR-D

ENV PREFIX=/usr/local

WORKDIR /build/ocrd_olena
COPY .gitmodules .
COPY Makefile .
COPY ocrd-tool.json .
COPY ocrd-olena-binarize .

ENV DEPS="g++ make automake git libtool"
RUN apt-get update && \
    apt-get -y install --no-install-recommends $DEPS && \
    make deps-ubuntu && \
    git init && \
    git submodule add https://github.com/OCR-D/olena.git repo/olena && \
    git submodule add https://github.com/OCR-D/assets.git repo/assets && \
    make build-olena install clean-olena && \
    apt-get -y remove $DEPS && \
    apt-get clean && \
    rm -fr /build/ocrd_olena

WORKDIR /data
VOLUME /data
