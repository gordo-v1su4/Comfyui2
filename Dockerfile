# ComfyUI Easy Install Dockerfile for Coolify with S3 Support
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    wget \
    curl \
    bash \
    unzip \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

# Install NVIDIA Container Toolkit utilities (for GPU detection)
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    apt-get update && \
    apt-get install -y nvidia-utils-535 || true && \
    rm -rf /var/lib/apt/lists/* cuda-keyring_1.0-1_all.deb

# Create app directory
WORKDIR /app

# Clone the Linux-compatible ComfyUI-Easy-Install instead of copying Windows version
RUN git clone --single-branch --branch MAC-Linux https://github.com/Tavris1/ComfyUI-Easy-Install.git

# Make installation script executable and run it
RUN cd ComfyUI-Easy-Install && \
    chmod +x LinuxComfyUI-Easy-Install.sh && \
    ./LinuxComfyUI-Easy-Install.sh || true

# Ensure venv exists and upgrade pip
RUN cd ComfyUI-Easy-Install && \
    if [ ! -d "venv" ]; then python3 -m venv venv; fi && \
    . venv/bin/activate && \
    pip install --upgrade pip wheel setuptools

# Install PyTorch 2.1.0 with CUDA 11.8 - the stable version this repo was designed for
# Download with wget first to avoid hash mismatch issues
RUN cd /tmp && \
    wget --progress=bar:force:noscroll --tries=10 --timeout=120 \
    https://download.pytorch.org/whl/cu118/torch-2.1.0%2Bcu118-cp310-cp310-linux_x86_64.whl && \
    cd /app/ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    pip install /tmp/torch-2.1.0+cu118-cp310-cp310-linux_x86_64.whl --no-cache-dir && \
    rm /tmp/torch-2.1.0+cu118-cp310-cp310-linux_x86_64.whl

# Download and install torchvision
RUN cd /tmp && \
    wget --progress=bar:force:noscroll --tries=10 --timeout=120 \
    https://download.pytorch.org/whl/cu118/torchvision-0.16.0%2Bcu118-cp310-cp310-linux_x86_64.whl && \
    cd /app/ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    pip install /tmp/torchvision-0.16.0+cu118-cp310-cp310-linux_x86_64.whl --no-cache-dir && \
    rm /tmp/torchvision-0.16.0+cu118-cp310-cp310-linux_x86_64.whl

# Download and install torchaudio
RUN cd /tmp && \
    wget --progress=bar:force:noscroll --tries=10 --timeout=120 \
    https://download.pytorch.org/whl/cu118/torchaudio-2.1.0%2Bcu118-cp310-cp310-linux_x86_64.whl && \
    cd /app/ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    pip install /tmp/torchaudio-2.1.0+cu118-cp310-cp310-linux_x86_64.whl --no-cache-dir && \
    rm /tmp/torchaudio-2.1.0+cu118-cp310-cp310-linux_x86_64.whl

# Install torchsde for sampling methods
RUN cd ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    pip install torchsde==0.2.6 --no-cache-dir

# Clone ComfyUI - use the main branch for stability
RUN cd ComfyUI-Easy-Install && \
    rm -rf ComfyUI && \
    git clone https://github.com/comfyanonymous/ComfyUI.git

# Install ComfyUI requirements
RUN cd ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    cd ComfyUI && \
    pip install -r requirements.txt --no-cache-dir

# Fix dependency issues for ComfyUI-Manager
RUN cd ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    pip install --upgrade "numpy<2.0" && \
    pip install gitpython && \
    pip install uv && \
    pip install aiofiles && \
    echo "✅ Dependencies fixed for ComfyUI-Manager"

# Note: ComfyUI Manager will be installed at runtime to persist with volume mounts

# Set working directory to ComfyUI installation
WORKDIR /app/ComfyUI-Easy-Install

# Create startup script inline
RUN echo '#!/bin/bash\n\
set -e\n\
echo "🚀 Starting ComfyUI with S3 integration..."\n\
cd /app/ComfyUI-Easy-Install\n\
\n\
# Verify environment\n\
if [ ! -f "venv/bin/activate" ]; then\n\
    echo "❌ Error: Virtual environment not found!"\n\
    exit 1\n\
fi\n\
\n\
source venv/bin/activate\n\
\n\
if [ ! -f "ComfyUI/main.py" ]; then\n\
    echo "❌ Error: ComfyUI not found!"\n\
    exit 1\n\
fi\n\
\n\
# Wait for S3 mounts (Coolify) to be ready\n\
echo "⏳ Waiting for storage mounts..."\n\
sleep 5\n\
\n\
# Install ComfyUI Manager if not already present\n\
if [ ! -d "ComfyUI/custom_nodes/ComfyUI-Manager" ]; then\n\
    echo "📦 Installing ComfyUI Manager..."\n\
    cd ComfyUI/custom_nodes\n\
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git\n\
    if [ -f "ComfyUI-Manager/requirements.txt" ]; then\n\
        ../../venv/bin/pip install -r ComfyUI-Manager/requirements.txt --no-cache-dir || true\n\
    fi\n\
    # Ensure dependencies are correct\n\
    ../../venv/bin/pip install gitpython uv aiofiles av --no-cache-dir || true\n\
    cd ../..\n\
    echo "✅ ComfyUI Manager installed"\n\
else\n\
    echo "✅ ComfyUI Manager already installed"\n\
    # Still ensure dependencies are correct on restart\n\
    venv/bin/pip install gitpython uv aiofiles av --no-cache-dir || true\n\
fi\n\
\n\
# Create model subdirectories if they dont exist\n\
echo "📁 Setting up model directories..."\n\
mkdir -p ComfyUI/models/{checkpoints,vae,loras,controlnet,embeddings,upscale_models,clip_vision,diffusers,photomaker,insightface,faceanalysis,style_models,ipadapter,instantid,pulid}\n\
chmod -R 755 ComfyUI/models/\n\
\n\
# Create extra model paths config\n\
if [ ! -f "ComfyUI/extra_model_paths.yaml" ]; then\n\
cat > ComfyUI/extra_model_paths.yaml << EOF_CONFIG\n\
# ComfyUI Extra Model Paths - S3 Integration\n\
comfyui:\n\
    base_path: /app/ComfyUI-Easy-Install/ComfyUI/\n\
    is_default: true\n\
    checkpoints: models/checkpoints/\n\
    vae: models/vae/\n\
    loras: models/loras/\n\
    controlnet: models/controlnet/\n\
    embeddings: models/embeddings/\n\
    upscale_models: models/upscale_models/\n\
    clip_vision: models/clip_vision/\n\
EOF_CONFIG\n\
    echo "📝 Created extra_model_paths.yaml"\n\
fi\n\
\n\
# GPU Detection\n\
echo "🎮 Checking GPU availability..."\n\
if command -v nvidia-smi &> /dev/null; then\n\
    echo "🔥 NVIDIA GPU detected:"\n\
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits 2>/dev/null || echo "GPU info unavailable"\n\
else\n\
    echo "⚠️  Warning: nvidia-smi not found. Running in CPU mode."\n\
fi\n\
\n\
# Display storage info\n\
echo "📊 Storage Information:"\n\
echo "   📁 Models: $(ls -la ComfyUI/models 2>/dev/null | wc -l) subdirectories"\n\
echo "   🔌 Custom nodes: $(ls -la ComfyUI/custom_nodes 2>/dev/null | wc -l) items"\n\
\n\
echo "🌐 Starting ComfyUI server on port 8188..."\n\
echo "📦 ComfyUI Manager downloads will go to S3 storage (if mounted)"\n\
\n\
exec python ComfyUI/main.py \\\n\
    --listen 0.0.0.0 \\\n\
    --port 8188 \\\n\
    --enable-cors-header "*" \\\n\
    "$@"\n\
' > /app/start.sh && chmod +x /app/start.sh

# Create directories for volume mounts
RUN mkdir -p /app/ComfyUI-Easy-Install/ComfyUI/models \
    /app/ComfyUI-Easy-Install/ComfyUI/output \
    /app/ComfyUI-Easy-Install/ComfyUI/input \
    /app/ComfyUI-Easy-Install/ComfyUI/temp \
    /app/ComfyUI-Easy-Install/ComfyUI/user \
    /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes

# Expose port
EXPOSE 8188

# Health check with longer start period for initial model loading
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
    CMD curl -f http://localhost:8188/ || exit 1

# Start ComfyUI
CMD ["/app/start.sh"]
