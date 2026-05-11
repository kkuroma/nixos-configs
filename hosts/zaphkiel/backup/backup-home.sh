#!/bin/bash
SOURCE="/home/kuroma/"
DEST="/mnt/NAS/backup-home/"
MOUNT_POINT="/mnt/NAS"

EXCLUDES=(
  ".cache/"
  ".local/share/Trash/"
  ".Trash-*"
  "Downloads/"
  "node_modules/"
  "*.tmp"
  ".gvfs/"
)

EXCLUDE_FLAGS=()
for item in "${EXCLUDES[@]}"; do
  EXCLUDE_FLAGS+=("--exclude=$item")
done

if ! mountpoint -q "$MOUNT_POINT"; then
  echo "Error: $MOUNT_POINT is not mounted. Aborting." >&2
  exit 1
fi

rsync -av --delete "${EXCLUDE_FLAGS[@]}" "$SOURCE" "$DEST" &&
  echo "Backup completed at $(date)" ||
  {
    echo "Backup failed." >&2
    exit 1
  }
