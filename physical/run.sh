#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
variant=${1:-baseline}
case "$variant" in baseline|area) ;; *) echo 'Expected baseline or area' >&2; exit 2;; esac
mkdir -p build/physical
image=$(cat physical/image.txt)
docker run --rm --platform linux/amd64 --entrypoint bash \
  -v "$PWD:/workspace" "$image" /workspace/physical/in-container.sh "$variant"
