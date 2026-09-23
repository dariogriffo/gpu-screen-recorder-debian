#!/bin/bash
# Produce gpu-screen-recorder_<version>.orig.tar.gz from the upstream git tag.
#
# Upstream publishes no release tarballs, checksums or signed tags, and its
# cgit snapshots are regenerated on every request (so their bytes change).
# Instead we archive the tagged commit ourselves, reproducibly, and guard it:
#   - upstream-tags.lock pins every tag we've seen to its commit. A known tag
#     that now points elsewhere was moved or rewritten, and the build stops.
#     An unseen tag is trusted on first use and appended to the lock.
#   - LICENSE must still be the GPL-3.0 text we reviewed.
#
# Usage: ./fetch_source.sh <version>
set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>" >&2
    echo "Example: $0 6.1.3" >&2
    exit 1
fi

UPSTREAM_GIT="https://repo.dec05eba.com/gpu-screen-recorder"
PACKAGE_NAME="gpu-screen-recorder"
ORIG_TARBALL="${PACKAGE_NAME}_${VERSION}.orig.tar.gz"
LOCK_FILE="upstream-tags.lock"
# sha256 of upstream's LICENSE (GNU GPL v3, 29 June 2007).
EXPECTED_LICENSE_SHA256="3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986"

# Lightweight tags: ls-remote gives the commit directly.
SHA=$(git ls-remote --tags --refs "$UPSTREAM_GIT" "refs/tags/${VERSION}" | awk '{print $1}')
if [ -z "$SHA" ]; then
    echo "❌ Tag ${VERSION} not found in ${UPSTREAM_GIT}" >&2
    exit 1
fi

PINNED=$(awk -v t="$VERSION" '$1 == t {print $2}' "$LOCK_FILE")
if [ -z "$PINNED" ]; then
    echo "  Tag ${VERSION} not pinned yet; trusting ${SHA} on first use"
    echo "${VERSION} ${SHA}" >> "$LOCK_FILE"
    sort -V -o "$LOCK_FILE" "$LOCK_FILE"
elif [ "$PINNED" != "$SHA" ]; then
    echo "❌ Tag ${VERSION} moved: pinned ${PINNED}, upstream now ${SHA}. Refusing to build." >&2
    exit 1
else
    echo "  ✅ Tag ${VERSION} matches pinned commit ${SHA}"
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
git init -q "$WORK/src"
git -C "$WORK/src" fetch -q --depth 1 "$UPSTREAM_GIT" "$SHA"

LICENSE_SHA=$(git -C "$WORK/src" show "${SHA}:LICENSE" | sha256sum | awk '{print $1}')
if [ "$LICENSE_SHA" != "$EXPECTED_LICENSE_SHA256" ]; then
    echo "❌ Upstream LICENSE changed (sha256 ${LICENSE_SHA}); review it and update EXPECTED_LICENSE_SHA256" >&2
    exit 1
fi
echo "  ✅ LICENSE is the reviewed GPL-3.0 text"

MESON_VERSION=$(git -C "$WORK/src" show "${SHA}:meson.build" | sed -n "s/^project(.*version *: *'\([^']*\)'.*/\1/p")
if [ "$MESON_VERSION" != "$VERSION" ]; then
    echo "⚠️  meson.build says version ${MESON_VERSION:-<none>}, tag is ${VERSION}" >&2
fi

# git archive of a fixed commit is deterministic; gzip -n drops the timestamp.
git -C "$WORK/src" archive --format=tar --prefix="${PACKAGE_NAME}-${VERSION}/" "$SHA" | gzip -n -9 > "$ORIG_TARBALL"
echo "  ✅ ${ORIG_TARBALL} ($(sha256sum "$ORIG_TARBALL" | awk '{print $1}'))"
