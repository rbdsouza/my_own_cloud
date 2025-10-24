#!/usr/bin/env bash
set -euo pipefail

MODE=${1:-pull}
IMAGES_FILE=$(dirname "$0")/images.txt
CACHE_DIR=${CACHE_DIR:-$(pwd)/cache}
mkdir -p "$CACHE_DIR"

while read -r image; do
  [[ -z "$image" || "$image" == \#* ]] && continue
  if [[ "$MODE" == "pull" ]]; then
    docker pull "$image"
    docker save "$image" -o "$CACHE_DIR/$(echo "$image" | tr '/:' '__').tar"
  elif [[ "$MODE" == "load" ]]; then
    tarball="$CACHE_DIR/$(echo "$image" | tr '/:' '__').tar"
    [[ -f "$tarball" ]] || { echo "Missing $tarball" >&2; continue; }
    docker load -i "$tarball"
  else
    echo "Unknown mode: $MODE" >&2
    exit 1
  fi
done < "$IMAGES_FILE"
