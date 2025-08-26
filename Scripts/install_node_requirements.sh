#!/bin/bash

# Install Python dependencies for each custom node if a requirements file is present.
# Safe to run multiple times; pip will skip satisfied requirements.

set -euo pipefail

CUSTOM_DIR="/root/ComfyUI/custom_nodes"
PYTHON_BIN="python3"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "❌ $PYTHON_BIN not found in PATH"
  exit 1
fi

if [ ! -d "$CUSTOM_DIR" ]; then
  echo "ℹ️  Custom nodes directory not found: $CUSTOM_DIR (nothing to install)"
  exit 0
fi

cd "$CUSTOM_DIR"

shopt -s nullglob
for NODE in */ ; do
  # Strip trailing slash
  NODE=${NODE%/}
  echo "🔎 Checking requirements for: $NODE"
  for REQS in requirements.txt requirements.cuda.txt requirements-cuda.txt requirements-cu12.txt requirements-cu128.txt ; do
    if [ -f "$CUSTOM_DIR/$NODE/$REQS" ]; then
      echo "📦 Installing $REQS for $NODE"
      $PYTHON_BIN -m pip install --no-cache-dir -r "$CUSTOM_DIR/$NODE/$REQS" || true
    fi
  done
  # Some repos use pip install .
  if [ -f "$CUSTOM_DIR/$NODE/pyproject.toml" ] || [ -f "$CUSTOM_DIR/$NODE/setup.py" ]; then
    echo "📦 Installing editable package for $NODE (if applicable)"
    (cd "$CUSTOM_DIR/$NODE" && $PYTHON_BIN -m pip install --no-cache-dir -e .) || true
  fi
  echo "✅ Finished deps for: $NODE"
  echo ""
done
shopt -u nullglob

echo "🎉 Node requirements installation complete."
