#!/bin/bash

# Fix script for ComfyUI dependency issues
echo "🔧 Fixing ComfyUI dependencies..."

# Navigate to ComfyUI directory
cd /app/ComfyUI-Easy-Install

# Activate virtual environment
source venv/bin/activate

# Fix NumPy version conflict (downgrade to <2.0)
echo "📦 Downgrading NumPy to compatible version..."
pip install --upgrade "numpy<2.0"

# Install missing gitpython module for ComfyUI-Manager
echo "📦 Installing gitpython..."
pip install gitpython

# Install uv for ComfyUI-Manager
echo "📦 Installing uv..."
pip install uv

# Optional: Upgrade PyTorch to 2.4+ (commented out as it's large and may need specific CUDA version)
# echo "📦 Upgrading PyTorch (this may take a while)..."
# pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo "✅ Dependencies fixed! Please restart ComfyUI."
