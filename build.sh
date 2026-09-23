#!/bin/bash
# Fetch the upstream source once, then build every distribution and the source
# packages from it.
#
# Usage: ./build.sh <version> <build_version>
set -euo pipefail

VERSION="${1:-}"
BUILD_VERSION="${2:-}"
if [ -z "$VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <version> <build_version>" >&2
    echo "Example: $0 6.1.3 1" >&2
    exit 1
fi

./fetch_source.sh "$VERSION"

# Jammy is left out: its ffmpeg 4.4 and Vulkan headers are too old for
# upstream's Vulkan encoder.
for dist in bookworm trixie forky sid noble questing resolute; do
    ./build_deb.sh "$VERSION" "$BUILD_VERSION" "$dist"
done

./build_src.sh "$VERSION" "$BUILD_VERSION"
