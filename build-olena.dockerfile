# Patch and build Olena from Git
FROM ubuntu:18.04

MAINTAINER OCR-D

ENV PREFIX=/usr

WORKDIR /build-olena
COPY olena-configure-boost.patch .
COPY olena-configure-python3.patch .
COPY olena-disable-doc.patch .
COPY olena-fix-magick-load-catch-exceptions.patch .
COPY Makefile .

RUN apt-get update && \
    apt-get -y install --no-install-recommends build-essential automake git && \
    make deps-ubuntu && \
    make build-olena clean-olena && \
    apt-get -y remove build-essential git && \
    apt-get -y autoremove && apt-get clean && \
    rm -fr /build-olena

WORKDIR /data
VOLUME /data

#ENTRYPOINT ["/usr/bin/scribo-cli"]
#CMD ["--help"]
CMD ["/usr/bin/scribo-cli", "--help"]
