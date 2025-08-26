#!/bin/bash

# Install or update custom nodes from a curated list into ComfyUI/custom_nodes
# Idempotent: clones if missing, pulls if exists.

set -euo pipefail

CUSTOM_LIST_FILE="/opt/comfy-scripts/custom_nodes.txt"
TARGET_DIR="/root/ComfyUI/custom_nodes"

# The base image is expected to contain the ComfyUI repository.
# This script only ensures the custom_nodes directory exists.
echo "🧩 Installing custom nodes into: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

if [ ! -f "$CUSTOM_LIST_FILE" ]; then
  echo "ℹ️  No custom_nodes.txt found at $CUSTOM_LIST_FILE. Skipping custom node installation."
  exit 0
fi

while IFS= read -r REPO || [ -n "$REPO" ]; do
  # skip comments/empty
  if [[ -z "$REPO" || "$REPO" =~ ^# ]]; then
    continue
  fi
  NAME=$(basename "$REPO" .git)
  DEST="$TARGET_DIR/$NAME"
  if [ -d "$DEST/.git" ]; then
    echo "↻ Updating $NAME"
    git -C "$DEST" pull --ff-only || true
  else
    echo "⬇️  Cloning $NAME from $REPO"
    git clone --depth=1 "$REPO" "$DEST" || true
  fi

done < "$CUSTOM_LIST_FILE"

echo "✅ Custom nodes install/update complete."
