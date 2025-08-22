#!/bin/bash

# Simple Model Downloader for ComfyUI
# Downloads models from Hugging Face and uploads to MinIO

set -e

echo "🚀 Starting Model Downloader for ComfyUI"
echo "========================================"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed!"
    exit 1
fi

# Check if we're in the container or have venv
if [ -f "/app/venv/bin/activate" ]; then
    echo "🐍 Activating virtual environment..."
    source /app/venv/bin/activate
elif [ -f "../venv/bin/activate" ]; then
    echo "🐍 Activating virtual environment..."
    source ../venv/bin/activate
fi

# Check if models config exists
if [ ! -f "$SCRIPT_DIR/models_to_download.json" ]; then
    echo "❌ models_to_download.json not found!"
    echo "   Please create it in: $SCRIPT_DIR/"
    exit 1
fi

# Check MinIO credentials
if [ -z "$SERVICE_USER_MINIO" ] || [ -z "$SERVICE_PASSWORD_MINIO" ]; then
    echo "⚠️  MinIO credentials not found in environment"
    echo "   Set SERVICE_USER_MINIO and SERVICE_PASSWORD_MINIO"
    echo "   Continuing anyway (may fail if MinIO requires auth)..."
fi

# Optional: Set Hugging Face token if available
if [ -n "$HF_TOKEN" ]; then
    echo "🔑 Hugging Face token found"
else
    echo "ℹ️  No Hugging Face token set (public models only)"
    echo "   Set HF_TOKEN environment variable for private models"
fi

# Run the Python downloader
echo ""
python3 "$SCRIPT_DIR/simple_model_downloader.py"

echo ""
echo "✅ Model download process complete!"
echo "   Check ComfyUI Manager to see downloaded models"
