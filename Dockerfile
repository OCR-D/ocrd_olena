# Patch and build Olena from Git, then
# Install OCR-D wrapper for binarization
FROM ocrd/core:v2.62.0 AS base

MAINTAINER OCR-D

ENV PREFIX=/usr/local

WORKDIR /build-olena
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
    rm -fr /build-olena

WORKDIR /data
VOLUME /data

#ENTRYPOINT ["/usr/bin/ocrd-olena-binarize"]
#CMD ["--help"]
CMD ["/usr/bin/ocrd-olena-binarize", "--help"]
