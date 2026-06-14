#!/usr/bin/env bash
set -euo pipefail

# Pre-compress Flutter Web static assets for Nginx/OpenResty gzip_static and
# optional brotli_static serving.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_DIR="${1:-$PROJECT_ROOT/build/web}"

if [[ ! -d "$WEB_DIR" ]]; then
  echo "Web build directory not found: $WEB_DIR" >&2
  exit 1
fi

echo "==> 预压缩 Web 静态资源: $WEB_DIR"

find "$WEB_DIR" -type f \
  \( \
    -name '*.html' -o \
    -name '*.js' -o \
    -name '*.json' -o \
    -name '*.wasm' -o \
    -name '*.css' -o \
    -name '*.svg' -o \
    -name '*.ttf' -o \
    -name '*.otf' -o \
    -name '*.woff' -o \
    -name '*.woff2' \
  \) \
  ! -name '*.gz' \
  ! -name '*.br' \
  -size +1024c \
  -print0 |
while IFS= read -r -d '' file; do
  gzip -kf -9 "$file"
  if command -v brotli >/dev/null 2>&1; then
    brotli -f -q 11 "$file"
  fi
done

echo "==> 预压缩完成"
