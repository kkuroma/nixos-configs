#!/usr/bin/env bash
set -euo pipefail

for arg in "$@"; do
  if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
    cat << 'EOF'
Usage: compress-mkv [--help]

Re-encodes all .mkv files in the current directory to HEVC using NVIDIA GPU
(hevc_nvenc), replacing each file in-place.

  Codec:    HEVC (H.265) via hevc_nvenc
  Quality:  VBR CQ 27, max 6000k / bufsize 12000k
  Audio:    AAC 128k
  -h, --help  Show this help

Run from the directory containing the .mkv files you want to compress.
EOF
    exit 0
  fi
done

files=(*.mkv)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No .mkv files found in current directory." >&2
  exit 0
fi

for INPUT in "${files[@]}"; do
  TEMP="${INPUT%.mkv}-processing.mkv"

  echo "$INPUT"

  ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i "$INPUT" \
    -c:v hevc_nvenc -preset p7 -tune hq -rc vbr -cq 27 \
    -maxrate:v 6000k -bufsize:v 12000k \
    -rc-lookahead 32 -spatial-aq 1 -temporal-aq 1 \
    -c:a aac -b:a 128k \
    "$TEMP"

  rm "$INPUT"
  mv "$TEMP" "$INPUT"

  echo "Done: $INPUT"
done

echo "All files compressed."
