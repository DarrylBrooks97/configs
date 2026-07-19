#!/usr/bin/env bash
set -euo pipefail

if ! command -v herdr >/dev/null 2>&1; then
  echo "herdr is required before installing plugins" >&2
  exit 1
fi

herdr plugin install cloudmanic/herdr-plus \
  --ref f32b0825f12543c1d03e54fb10d1741c40d66cdc --yes
herdr plugin install smarzban/herdr-file-viewer \
  --ref 81d798aadd5b006dcb7dd9a98734f505f0d4b3a6 --yes
herdr plugin install dcolinmorgan/herdr-push \
  --ref f4fdb06d5413ac2d96ca225ea33f288f41bfc001 --yes
