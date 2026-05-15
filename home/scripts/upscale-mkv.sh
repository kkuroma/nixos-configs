#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
TARGET_HEIGHT=1080
INPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true ;;
    --target)     shift; TARGET_HEIGHT="$1" ;;
    --target=*)   TARGET_HEIGHT="${1#--target=}" ;;
    --help|-h)
      cat << 'EOF'
Usage: upscale-mkv [--dry-run] [--target HEIGHT] <input_dir>

Upscales all .mkv files under <input_dir> whose height is below TARGET to
TARGET height using video2x (libplacebo / anime4k-v4-a+a). Aspect ratio is
preserved — width is computed automatically. Already-upscaled files are
detected by reading the container height with ffprobe; no cache or marker
files are used.

  --target HEIGHT  Target height in pixels (default: 1080)
  --dry-run        Show what would be processed without modifying any files
  -h, --help       Show this help

Re-running on a directory that was already processed is safe — files at or
above TARGET height are skipped.
EOF
      exit 0 ;;
    -*) echo "Unknown flag: $1" >&2; exit 1 ;;
    *)
      [[ -n "$INPUT_DIR" ]] && { echo "Unexpected argument: $1" >&2; exit 1; }
      INPUT_DIR="$1" ;;
  esac
  shift
done

if [[ -z "$INPUT_DIR" ]]; then
  echo "Usage: upscale-mkv [--dry-run] [--target HEIGHT] <input_dir>" >&2
  exit 1
fi

LOG_FILE="$INPUT_DIR/upscale.log"

_bar() {
  local current=$1 total=$2 width=50
  local pct=$(( total > 0 ? current * 100 / total : 100 ))
  local filled=$(( total > 0 ? current * width / total : width ))
  local bar empty
  printf -v bar   '%*s' "$filled"              ''
  printf -v empty '%*s' "$((width - filled))"  ''
  printf "[%s%s] %3d%% %d/%d" "${bar// /█}" "${empty// /░}" "$pct" "$current" "$total"
}

# ── scan ─────────────────────────────────────────────────────────────────────

printf "Counting files...\r" >&2
total_files=$(find "$INPUT_DIR" -name "*.mkv" | wc -l)
printf "\033[KScanning %d file(s)...\n" "$total_files" >&2

to_process=()
to_skip=()
scanned=0

while IFS= read -r -d '' f; do
  scanned=$((scanned + 1))
  fname=$(basename "$f")
  (( ${#fname} > 45 )) && fname="${fname:0:42}..."
  printf "\r\033[K%s  %s" "$(_bar "$scanned" "$total_files")" "$fname" >&2

  # probesize+analyzeduration limits I/O to the first 128KB — MKV headers are always there
  height=$(ffprobe -v quiet \
    -probesize 131072 -analyzeduration 0 \
    -select_streams v:0 \
    -show_entries stream=height \
    -of default=noprint_wrappers=1:nokey=1 \
    "$f" 2>/dev/null || true)

  if [[ -z "$height" ]]; then
    printf "\n[WARN] could not read dimensions, skipping: %s\n" "$f" >&2
    continue
  fi

  THRESHOLD=$(( TARGET_HEIGHT * 95 / 100 )) # some files are 1070p in a 1080p, 1000 is acceptable
  if [[ "$height" -ge "$THRESHOLD" ]]; then
    to_skip+=("$f")
  else
    to_process+=("$f")
  fi
done < <(find "$INPUT_DIR" -name "*.mkv" -print0 | sort -z)

printf "\r\033[K%s  done\n\n" "$(_bar "$total_files" "$total_files")" >&2

total_proc=${#to_process[@]}

echo "=== Upscale Report: $INPUT_DIR ==="
echo "  To process      : $total_proc file(s)"
echo "  Already ${TARGET_HEIGHT}p+ (skip): ${#to_skip[@]} file(s)"
echo ""

# ── dry run ──────────────────────────────────────────────────────────────────

if [[ "$DRY_RUN" == true ]]; then
  echo "--- DRY RUN: files that would be upscaled ---"
  idx=1
  for f in "${to_process[@]}"; do
    printf "  %4d/%d  %s\n" "$idx" "$total_proc" "$f"
    idx=$((idx + 1))
  done
  echo ""
  echo "Total: $total_proc file(s) would be upscaled."
  exit 0
fi

# ── process ───────────────────────────────────────────────────────────────────

for i in "${!to_process[@]}"; do
  f="${to_process[$i]}"
  current=$((i + 1))
  filename=$(basename "$f")
  dir=$(dirname "$f")
  tmp="$dir/.tmp_${filename}"

  echo ""
  echo "$(_bar "$current" "$total_proc")  $filename"
  echo "[UPSCALE] $f" | tee -a "$LOG_FILE"

  # libplacebo requires explicit -w and -h; compute width from source AR so it's preserved.
  # Width must be even for codec compatibility.
  src_dims=$(ffprobe -v quiet -probesize 131072 -analyzeduration 0 \
    -select_streams v:0 -show_entries stream=width,height -of csv=p=0 \
    "$f" 2>/dev/null || true)
  src_dims="${src_dims%,}"
  src_w="${src_dims%%,*}"
  src_h="${src_dims##*,}"
  target_w=$(( src_w * TARGET_HEIGHT / src_h ))
  (( target_w % 2 != 0 )) && target_w=$(( target_w + 1 ))

  if video2x \
    -i "$f" \
    -o "$tmp" \
    -p libplacebo \
    --libplacebo-shader anime4k-v4-a+a \
    -w "$target_w" -h "$TARGET_HEIGHT" \
    -d 0; then
    mv "$tmp" "$f"
    echo "[DONE] $f" | tee -a "$LOG_FILE"
  else
    rm -f "$tmp"
    echo "[ERROR] $f failed" | tee -a "$LOG_FILE"
  fi
done

echo ""
echo "All done. Processed $total_proc file(s)." | tee -a "$LOG_FILE"
