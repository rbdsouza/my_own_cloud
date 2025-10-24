#!/usr/bin/env bash
set -euo pipefail

PROVIDER="kreuzwerker/docker"
VERSION="3.0.2"
MIRROR_DIR=${MIRROR_DIR:-$HOME/.terraform.d/mirror}
mkdir -p "$MIRROR_DIR/$PROVIDER/$VERSION"

OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  armv7l) ARCH=arm ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

PROVIDER_SLUG=${PROVIDER//\//-}
ARCHIVE="${PROVIDER_SLUG}_${VERSION}_${OS}_${ARCH}.zip"
URL="https://releases.hashicorp.com/${PROVIDER_SLUG}/${VERSION}/${ARCHIVE}"
TARGET="$MIRROR_DIR/$PROVIDER/$VERSION/${ARCHIVE}"

if [[ ! -f "$TARGET" ]]; then
  echo "Downloading $URL"
  curl -fsSL "$URL" -o "$TARGET"
fi

echo "Provider mirror ready in $MIRROR_DIR"
