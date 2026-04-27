#!/bin/bash
set -euo pipefail

ASSETS_DIR="${1:-src/assets/images}"
QUALITY="${QUALITY:-65}"

echo "Scanning: $ASSETS_DIR"

# 1. Delete exact duplicate files by content
find "$ASSETS_DIR" -type f ! -name "*.svg" -print0 |
  xargs -0 sha256sum |
  sort |
  awk '
    seen[$1] {
      print $2
      next
    }
    {
      seen[$1] = $2
    }
  ' |
  while read -r duplicate; do
    echo "Deleting duplicate: $duplicate"
    rm "$duplicate"
  done

# ---------------------------------------------------
# 2. Convert images recursively to WebP using FFmpeg
# ---------------------------------------------------
find "$ASSETS_DIR" -type f \
  \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.gif" \) \
  -print0 |
while IFS= read -r -d '' file; do
  if [[ ! -f "$file" ]]; then
    echo "Skipping missing file: $file"
    continue
  fi

  output="${file%.*}.webp"

  echo "Converting:"
  echo "  $file"
  echo "  -> $output"

  ffmpeg -y -loglevel error \
    -i "$file" \
    -vcodec libwebp \
    -compression_level 6 \
    -q:v "$QUALITY" \
    -preset picture \
    "$output"

  if [[ -f "$output" ]]; then
    rm -f "$file"
    echo "Deleted original: $file"
  fi
done

echo "Done."
