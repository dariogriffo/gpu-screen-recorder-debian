#!/bin/bash
# Build the source packages (.dsc + .debian.tar.xz) for every distribution,
# all sharing one .orig.tar.gz (see fetch_source.sh).
#
# Usage: ./build_src.sh <version> <build_version>
set -euo pipefail

VERSION="${1:-}"
BUILD_VERSION="${2:-}"
if [ -z "$VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <version> <build_version>" >&2
    echo "Example: $0 6.1.3 1" >&2
    exit 1
fi

PACKAGE_NAME="gpu-screen-recorder"
ORIG_TARBALL="${PACKAGE_NAME}_${VERSION}.orig.tar.gz"
BUILD_DIR="${PACKAGE_NAME}-${VERSION}"

if [ ! -f "$ORIG_TARBALL" ]; then
    echo "❌ ${ORIG_TARBALL} not found; run ./fetch_source.sh ${VERSION} first" >&2
    exit 1
fi

build_source_package() {
    local dist=$1
    local FULL_VERSION="${VERSION}-${BUILD_VERSION}~${dist}"

    echo "  Building source package for ${dist} (${FULL_VERSION})..."
    rm -rf "$BUILD_DIR"
    tar -xf "$ORIG_TARBALL"
    cp -r debian "$BUILD_DIR/"

    cat > "$BUILD_DIR/debian/changelog" << CHANGELOG
${PACKAGE_NAME} (${FULL_VERSION}) ${dist}; urgency=medium

  * New upstream release ${VERSION}.

 -- Dario Griffo <dariogriffo@gmail.com>  $(date -R)
CHANGELOG

    dpkg-source -b "$BUILD_DIR"
    rm -rf "$BUILD_DIR"
    echo "    ✅ ${FULL_VERSION}"
}

for dist in bookworm trixie forky sid noble questing resolute; do
    build_source_package "$dist"
done

echo ""
ls -la "${PACKAGE_NAME}_"*.dsc "${PACKAGE_NAME}_"*.orig.tar.gz "${PACKAGE_NAME}_"*.debian.tar.xz
