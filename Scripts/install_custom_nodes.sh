#!/bin/bash

# Install or update custom nodes from a curated list into ComfyUI/custom_nodes
# Idempotent: clones if missing, pulls if exists.

set -euo pipefail

CUSTOM_LIST_FILE="$(dirname "$0")/custom_nodes.txt"
TARGET_DIR="/root/ComfyUI/custom_nodes"

# Ensure ComfyUI repo exists to avoid runner clone conflicts
if [ ! -d "/root/ComfyUI/.git" ]; then
  echo "📥 Cloning ComfyUI core..."
  mkdir -p /root/ComfyUI
  git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git /root/ComfyUI || true
fi

echo "🧩 Installing custom nodes into: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

if [ ! -f "$CUSTOM_LIST_FILE" ]; then
  echo "ℹ️  No custom_nodes.txt found at $CUSTOM_LIST_FILE. Skipping."
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
