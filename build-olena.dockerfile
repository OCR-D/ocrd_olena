# Patch and build Olena from Git
FROM ubuntu:18.04
ARG VCS_REF
ARG BUILD_DATE
LABEL \
    maintainer="https://github.com/OCR-D/ocrd_olena/issues" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/OCR-D/ocrd_olena" \
    org.label-schema.build-date=$BUILD_DATE

MAINTAINER OCR-D

ENV PREFIX=/usr/local

WORKDIR /build-olena
COPY .gitmodules .
COPY Makefile .

ENV DEPS="g++ make automake git libtool"
RUN apt-get update && \
    apt-get -y install --no-install-recommends $DEPS && \
    make deps-ubuntu && \
    git init && \
    git submodule add https://github.com/OCR-D/olena.git repo/olena && \
    git submodule add https://github.com/OCR-D/assets.git repo/assets && \
    make build-olena clean-olena && \
    apt-get -y remove $DEPS && \
    apt-get -y autoremove && apt-get clean && \
    rm -fr /build-olena

WORKDIR /data
VOLUME /data

#ENTRYPOINT ["/usr/bin/scribo-cli"]
#CMD ["--help"]
CMD ["/usr/bin/scribo-cli", "--help"]
