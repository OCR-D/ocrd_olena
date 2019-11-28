# Patch and build Olena from Git
FROM ubuntu:18.04

MAINTAINER OCR-D

ENV PREFIX=/usr/local

WORKDIR /build-olena
COPY olena-configure-boost.patch .
COPY olena-configure-python3.patch .
COPY olena-disable-doc.patch .
COPY olena-fix-magick-load-catch-exceptions.patch .
COPY Makefile .

ENV DEPS="g++ make automake git"
RUN apt-get update && \
    apt-get -y install --no-install-recommends $DEPS && \
    make deps-ubuntu && \
    make build-olena clean-olena && \
    apt-get -y remove $DEPS && \
    apt-get -y autoremove && apt-get clean && \
    rm -fr /build-olena

WORKDIR /data
VOLUME /data

#ENTRYPOINT ["/usr/bin/scribo-cli"]
#CMD ["--help"]
CMD ["/usr/bin/scribo-cli", "--help"]
