#!/bin/bash
# MinIO Bucket Setup Script for AI Models
# Run this script once to set up the proper folder structure in your MinIO bucket

MINIO_ENDPOINT="https://minio-api.v1su4.com"
MINIO_ACCESS_KEY="zUN7kRPsXkV80cHE"
BUCKET_NAME="ai-models"

echo "🔧 Setting up MinIO bucket structure for AI models..."
echo "📡 Endpoint: $MINIO_ENDPOINT"
echo "🪣 Bucket: $BUCKET_NAME"

# Install MinIO client if not present
if ! command -v mc &> /dev/null; then
    echo "📥 Installing MinIO client..."
    curl https://dl.min.io/client/mc/release/linux-amd64/mc \
        --create-dirs \
        -o /usr/local/bin/mc
    chmod +x /usr/local/bin/mc
fi

# Configure MinIO client
echo "⚙️ Configuring MinIO client..."
mc alias set myminio $MINIO_ENDPOINT $MINIO_ACCESS_KEY {{MINIO_SECRET_KEY}}

# Create bucket if it doesn't exist
echo "🪣 Creating bucket '$BUCKET_NAME'..."
mc mb myminio/$BUCKET_NAME --ignore-existing

# Create folder structure
echo "📁 Creating folder structure..."

# Model directories
MODEL_FOLDERS=(
    "models/checkpoints"
    "models/vae"
    "models/loras"
    "models/controlnet"
    "models/embeddings"
    "models/upscale_models"
    "models/clip_vision"
    "models/diffusers"
    "models/photomaker"
    "models/insightface"
    "models/faceanalysis"
    "models/style_models"
    "models/ipadapter"
    "models/instantid"
    "models/pulid"
    "custom_nodes"
    "workflows"
)

for folder in "${MODEL_FOLDERS[@]}"; do
    # Create a .keep file to ensure the folder exists
    echo "# This file ensures the folder exists in MinIO" | mc pipe myminio/$BUCKET_NAME/$folder/.keep
    echo "   ✓ Created: $folder/"
done

# Set bucket policy for read access (optional)
echo "🔐 Setting bucket policy for public read access..."
mc anonymous set public myminio/$BUCKET_NAME

echo ""
echo "✅ MinIO bucket setup complete!"
echo "🌐 Bucket URL: $MINIO_ENDPOINT/$BUCKET_NAME"
echo "📊 Folder structure created for ComfyUI models and custom nodes"
echo ""
echo "Next steps:"
echo "1. Complete S3 storage setup in Coolify"
echo "2. Attach storage to your ComfyUI application"
echo "3. Deploy your ComfyUI instance"
echo "4. Models downloaded via ComfyUI Manager will be shared across all instances!"
