#!/bin/bash
# Enhanced ComfyUI Startup Script with MinIO S3 Integration
# This script handles both Coolify S3 mounts and Docker Compose MinIO integration

set -e

echo "🚀 Starting ComfyUI with MinIO S3 integration..."
echo "📡 MinIO Integration: ${COMFYUI_S3_ENABLED:-false}"

cd /app/ComfyUI-Easy-Install

# Verify virtual environment
if [ ! -f "venv/bin/activate" ]; then
    echo "❌ Error: Virtual environment not found!"
    exit 1
fi

source venv/bin/activate

# Verify ComfyUI installation
if [ ! -f "ComfyUI/main.py" ]; then
    echo "❌ Error: ComfyUI not found!"
    exit 1
fi

# S3/MinIO Storage Initialization
if [ "${COMFYUI_S3_ENABLED}" = "true" ]; then
    echo "🔧 Initializing S3 storage integration..."
    
    # Wait for MinIO to be ready (if using Docker Compose)
    if [ -n "${MINIO_ENDPOINT}" ]; then
        echo "⏳ Waiting for MinIO to be ready..."
        timeout=60
        while ! curl -s "${MINIO_ENDPOINT}/minio/health/ready" > /dev/null 2>&1; do
            sleep 2
            timeout=$((timeout - 2))
            if [ $timeout -le 0 ]; then
                echo "⚠️  Warning: MinIO not ready after 60s, continuing anyway..."
                break
            fi
        done
        echo "✅ MinIO is ready!"
    fi
    
    # Initialize S3 storage structure
    if [ -f "/app/init-s3-storage.sh" ]; then
        echo "📁 Running S3 storage initialization..."
        bash /app/init-s3-storage.sh
    fi
    
    # Install MinIO client for potential model management
    if ! command -v mc &> /dev/null && [ -n "${MINIO_ENDPOINT}" ]; then
        echo "📥 Installing MinIO client..."
        curl -s https://dl.min.io/client/mc/release/linux-amd64/mc \
            --create-dirs -o /tmp/mc
        chmod +x /tmp/mc
        
        # Configure MinIO client for this session
        if [ -n "${MINIO_ACCESS_KEY}" ] && [ -n "${MINIO_SECRET_KEY}" ]; then
            /tmp/mc alias set localminio "${MINIO_ENDPOINT}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}"
            echo "✅ MinIO client configured"
        fi
    fi
fi

# GPU Detection and Information
echo "🎮 Checking GPU availability..."
if command -v nvidia-smi &> /dev/null; then
    echo "🔥 NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits
    
    # Check CUDA availability in PyTorch
    python3 -c "
import torch
print('🔥 PyTorch CUDA available:', torch.cuda.is_available())
if torch.cuda.is_available():
    print('📊 CUDA devices:', torch.cuda.device_count())
    print('💾 GPU memory:', f'{torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB')
" 2>/dev/null || echo "⚠️  PyTorch CUDA check failed"
else
    echo "⚠️  Warning: nvidia-smi not found. Running in CPU mode."
fi

# ComfyUI Configuration
echo "⚙️  Configuring ComfyUI..."

# Create extra_model_paths.yaml if using S3 and it doesn't exist
if [ "${COMFYUI_S3_ENABLED}" = "true" ] && [ ! -f "ComfyUI/extra_model_paths.yaml" ]; then
    cat > ComfyUI/extra_model_paths.yaml << 'EOF'
# ComfyUI Extra Model Paths - S3 Integration
# Models are mounted from MinIO S3 at /app/ComfyUI-Easy-Install/ComfyUI/models

comfyui:
    base_path: /app/ComfyUI-Easy-Install/ComfyUI/
    is_default: true
    
    checkpoints: models/checkpoints/
    vae: models/vae/
    loras: models/loras/
    controlnet: models/controlnet/
    embeddings: models/embeddings/
    upscale_models: models/upscale_models/
    clip_vision: models/clip_vision/
    diffusers: models/diffusers/
    photomaker: models/photomaker/
    insightface: models/insightface/
    faceanalysis: models/faceanalysis/
    style_models: models/style_models/
    ipadapter: models/ipadapter/
    instantid: models/instantid/
    pulid: models/pulid/
EOF
    echo "📝 Created extra_model_paths.yaml for S3 integration"
fi

# Display storage information
echo ""
echo "📊 Storage Information:"
echo "   📁 Models directory: $(ls -la ComfyUI/models 2>/dev/null | wc -l) items"
echo "   🔌 Custom nodes: $(ls -la ComfyUI/custom_nodes 2>/dev/null | wc -l) items"
if [ "${COMFYUI_S3_ENABLED}" = "true" ]; then
    echo "   ☁️  S3 Storage: Enabled (${MINIO_ENDPOINT})"
    echo "   🪣 Model Bucket: ${MINIO_BUCKET_MODELS:-ai-models}"
fi

# Start ComfyUI with optimized arguments
echo ""
echo "🎯 Starting ComfyUI server..."
echo "🌐 Access ComfyUI at: http://localhost:8188"
echo "📊 ComfyUI Manager will download models to shared S3 storage"
echo ""

exec python ComfyUI/main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --enable-cors-header "*" \
    --extra-model-paths-config extra_model_paths.yaml \
    "$@"
