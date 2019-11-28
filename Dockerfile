# Patch and build Olena from Git, then
# Install OCR-D wrapper for binarization
FROM ocrd/core

MAINTAINER OCR-D

ENV PREFIX=/usr/local

WORKDIR /build-olena
COPY olena-configure-boost.patch .
COPY olena-configure-python3.patch .
COPY olena-disable-doc.patch .
COPY olena-fix-magick-load-catch-exceptions.patch .
COPY Makefile .
COPY ocrd-tool.json .
COPY ocrd-olena-binarize .
COPY README.md /

ENV DEPS="g++ make automake git"
RUN apt-get update && \
    apt-get -y install --no-install-recommends $DEPS && \
    make deps-ubuntu && \
    make build-olena install clean-olena && \
    apt-get -y remove $DEPS && \
    apt-get -y autoremove && apt-get clean && \
    rm -fr /build-olena

WORKDIR /data
VOLUME /data

#ENTRYPOINT ["/usr/bin/ocrd-olena-binarize"]
#CMD ["--help"]
CMD ["/usr/bin/ocrd-olena-binarize", "--help"]
