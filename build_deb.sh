#!/bin/bash
# Build the binary .deb for one distribution inside a container of that
# distribution, so it links against (and depends on) that suite's libraries.
#
# Expects gpu-screen-recorder_<version>.orig.tar.gz (see fetch_source.sh).
# Ubuntu packages get a _ubu suffix, which the mirror's download script expects.
#
# Usage: ./build_deb.sh <version> <build_version> <dist>
set -euo pipefail

VERSION="${1:-}"
BUILD_VERSION="${2:-}"
DIST="${3:-}"
if [ -z "$VERSION" ] || [ -z "$BUILD_VERSION" ] || [ -z "$DIST" ]; then
    echo "Usage: $0 <version> <build_version> <dist>" >&2
    echo "Example: $0 6.1.3 1 trixie" >&2
    exit 1
fi

PACKAGE_NAME="gpu-screen-recorder"
ORIG_TARBALL="${PACKAGE_NAME}_${VERSION}.orig.tar.gz"
FULL_VERSION="${VERSION}-${BUILD_VERSION}~${DIST}"

case "$DIST" in
    bookworm|trixie|forky|sid)        BASE_IMAGE="debian:${DIST}"; SUFFIX="" ;;
    noble|questing|resolute)          BASE_IMAGE="ubuntu:${DIST}"; SUFFIX="_ubu" ;;
    *) echo "❌ Unsupported distribution: ${DIST}" >&2; exit 1 ;;
esac

if [ ! -f "$ORIG_TARBALL" ]; then
    echo "❌ ${ORIG_TARBALL} not found; run ./fetch_source.sh ${VERSION} first" >&2
    exit 1
fi

echo "==> Building ${PACKAGE_NAME} ${FULL_VERSION} on ${BASE_IMAGE}"

CTX=$(mktemp -d)
trap 'rm -rf "$CTX"' EXIT
cp Dockerfile "$ORIG_TARBALL" "$CTX/"
tar -xf "$ORIG_TARBALL" -C "$CTX"
mv "$CTX/${PACKAGE_NAME}-${VERSION}" "$CTX/src"
cp -r debian "$CTX/src/"

cat > "$CTX/src/debian/changelog" << CHANGELOG
${PACKAGE_NAME} (${FULL_VERSION}) ${DIST}; urgency=medium

  * New upstream release ${VERSION}.

 -- Dario Griffo <dariogriffo@gmail.com>  $(date -R)
CHANGELOG

IMAGE="${PACKAGE_NAME}-build-${DIST}"
docker build -t "$IMAGE" --build-arg "BASE_IMAGE=${BASE_IMAGE}" "$CTX"

mkdir -p out
cid=$(docker create "$IMAGE")
docker cp "${cid}:/out/." "$CTX/out/"
docker rm "$cid" > /dev/null

for f in "$CTX"/out/*.deb; do
    name=$(basename "$f" .deb)
    cp "$f" "out/${name}${SUFFIX}.deb"
    echo "  ✅ out/${name}${SUFFIX}.deb"
done
