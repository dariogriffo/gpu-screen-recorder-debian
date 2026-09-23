ARG BASE_IMAGE=debian:trixie
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

# Toolchain first so the build-deps layer below is the only one that changes
# with debian/control.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        debhelper \
        devscripts \
        equivs \
        dpkg-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build/src
COPY src/debian/control /build/src/debian/control
RUN apt-get update \
    && mk-build-deps --install --remove --tool 'apt-get -y --no-install-recommends' debian/control \
    && rm -rf /var/lib/apt/lists/*

COPY src/ /build/src/
COPY *.orig.tar.gz /build/
RUN dpkg-buildpackage -b -us -uc

RUN mkdir -p /out && cp /build/*.deb /out/
