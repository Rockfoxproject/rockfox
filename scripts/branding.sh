#!/usr/bin/env bash
# Regenerate the Linux branding images from one source logo (SVG, or a square PNG).
# usage: branding.sh [logo]   (default: branding/logo.png)
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
src=${1:-$root/branding/logo.png}
out=$root/overlay/configs/branding/release
mkdir -p "$out/content"

render() {
  if [[ $src == *.svg ]]; then
    rsvg-convert -w "$1" -h "$1" "$src" -o "$2"
  else
    convert "$src" -background none -resize "$1x$1" "$2"
  fi
}

for size in 16 22 24 32 48 64 128 256 512 1024; do
  render "$size" "$out/logo$size.png"
done
cp "$out/logo1024.png" "$out/logo.png"
cp "$out/logo1024.png" "$out/logo-mac.png"

render 512 "$out/content/about-logo.png"
render 1024 "$out/content/about-logo@2x.png"
render 192 "$out/content/about-logo-private.png"
render 384 "$out/content/about-logo-private@2x.png"

if [[ $src == *.svg ]]; then
  cp "$src" "$out/content/about-logo.svg"
  cp "$src" "$out/content/about-logo-private.svg"
else
  for name in about-logo about-logo-private; do
    printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><image width="512" height="512" href="data:image/png;base64,%s"/></svg>\n' \
      "$(base64 -w0 "$out/logo512.png")" > "$out/content/$name.svg"
  done
fi

for name in about-wordmark firefox-wordmark; do
  cat > "$out/content/$name.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="300" height="64" viewBox="0 0 300 64"><text x="0" y="50" font-family="sans-serif" font-size="54" font-weight="700" fill="context-fill #5b5b66">Rockfox</text></svg>
SVG
done
