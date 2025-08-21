#!/bin/bash
# ComfyUI S3 Storage Initialization Script
# This ensures proper permissions and creates necessary directories for MinIO S3

echo "🚀 Initializing MinIO S3-backed ComfyUI storage..."
echo "📡 MinIO API: https://minio-api.v1su4.com"
echo "🌐 MinIO Console: https://minio-console.v1su4.com"

# Wait for S3 mounts to be available
echo "⏳ Waiting for S3 mounts to be ready..."
sleep 5

# Verify S3 directories are mounted
if [ ! -d "/app/ComfyUI-Easy-Install/ComfyUI/models" ]; then
    echo "⚠️  Warning: Models directory not mounted from S3"
    mkdir -p /app/ComfyUI-Easy-Install/ComfyUI/models
fi

if [ ! -d "/app/ComfyUI-Easy-Install/ComfyUI/custom_nodes" ]; then
    echo "⚠️  Warning: Custom nodes directory not mounted from S3"
    mkdir -p /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes
fi

# Set proper permissions for S3-mounted directories
chmod 755 /app/ComfyUI-Easy-Install/ComfyUI/models
chmod 755 /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes

# Create standard ComfyUI model subdirectories
MODEL_DIRS=(
    "checkpoints"        # Stable Diffusion models
    "vae"               # VAE models
    "loras"             # LoRA models
    "controlnet"        # ControlNet models
    "embeddings"        # Textual inversions
    "upscale_models"    # Upscaling models
    "clip_vision"       # CLIP vision models
    "diffusers"         # Diffusers format models
    "photomaker"        # PhotoMaker models
    "insightface"       # Face analysis models
    "faceanalysis"      # Face detection models
    "style_models"      # Style transfer models
    "ipadapter"         # IP-Adapter models
    "instantid"         # InstantID models
    "pulid"             # PuLID models
)

echo "📁 Creating/verifying model subdirectories..."
for dir in "${MODEL_DIRS[@]}"; do
    mkdir -p "/app/ComfyUI-Easy-Install/ComfyUI/models/$dir"
    chmod 755 "/app/ComfyUI-Easy-Install/ComfyUI/models/$dir"
    echo "   ✓ models/$dir"
done

# Prepare custom nodes directory for ComfyUI Manager
echo "📦 Setting up custom nodes directory for ComfyUI Manager..."
mkdir -p /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes
chmod 755 /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes

# Create a marker file to indicate S3 storage is properly initialized
touch /app/ComfyUI-Easy-Install/ComfyUI/.s3-initialized
echo "$(date): S3 storage initialized" > /app/ComfyUI-Easy-Install/ComfyUI/.s3-initialized

# Display storage information
echo ""
echo "📊 Storage Summary:"
echo "   🗂️  Models: $(ls -la /app/ComfyUI-Easy-Install/ComfyUI/models | wc -l) subdirectories"
echo "   🔌 Custom Nodes: Shared across all instances"
echo "   📦 Downloads: ComfyUI Manager → MinIO S3 → All instances"
echo ""
echo "✅ MinIO S3 storage initialization complete!"
echo "🌐 All model downloads will now be shared across AI instances"
