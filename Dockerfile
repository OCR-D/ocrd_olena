# Patch and build Olena from Git, then
# Install OCR-D wrapper for binarization
FROM ocrd/core

MAINTAINER OCR-D

ENV PREFIX=/usr

WORKDIR /build-olena
COPY olena-configure-boost.patch .
COPY olena-configure-python3.patch .
COPY olena-disable-doc.patch .
COPY olena-fix-magick-load-catch-exceptions.patch .
COPY Makefile .
COPY ocrd-tool.json .
COPY ocrd-olena-binarize .
COPY README.md /

# ocrd/core is now based on ubuntu:19.10 ...
# ... Ubuntu 19 ships automake 1.16.2 (and does not package automake-1.15 correctly)
# ... Ubuntu 19 ships GCC 9 by default (but we need g++-7)
RUN apt-get update && \
    apt-get -y install --no-install-recommends build-essential automake-1.15 g++-7 git && \
    make deps-ubuntu && \
    update-alternatives --set automake /usr/bin/automake-1.15 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 -5 --slave /usr/bin/g++ g++ /usr/bin/g++-7 && \
    update-alternatives --set gcc /usr/bin/gcc-7 && \
    make build-olena install clean-olena && \
    apt-get -y remove build-essential git && \
    apt-get -y autoremove && apt-get clean && \
    rm -fr /build-olena

WORKDIR /data
VOLUME /data

#ENTRYPOINT ["/usr/bin/ocrd-olena-binarize"]
#CMD ["--help"]
CMD ["/usr/bin/ocrd-olena-binarize", "--help"]
