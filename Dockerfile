# ComfyUI Dockerfile for Coolify with S3 Support
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_DEFAULT_TIMEOUT=100

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3.10-venv \
    python3-pip \
    git \
    wget \
    curl \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.10 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

# Create app directory
WORKDIR /app

# Create virtual environment and upgrade pip
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    python -m pip install --upgrade pip wheel setuptools

# Install PyTorch without hash checking
RUN . venv/bin/activate && \
    pip config set global.trusted-host "pypi.org files.pythonhosted.org download.pytorch.org" && \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# Install ComfyUI requirements
RUN . venv/bin/activate && \
    cd ComfyUI && \
    pip install -r requirements.txt

# Install ComfyUI-Manager dependencies
RUN . venv/bin/activate && \
    pip install gitpython aiofiles

# Create startup script
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo 'cd /app' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Activate virtual environment' >> /app/start.sh && \
    echo 'source venv/bin/activate' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Install/Update ComfyUI-Manager if needed' >> /app/start.sh && \
    echo 'if [ ! -d "ComfyUI/custom_nodes/ComfyUI-Manager" ]; then' >> /app/start.sh && \
    echo '    echo "Installing ComfyUI-Manager..."' >> /app/start.sh && \
    echo '    cd ComfyUI/custom_nodes' >> /app/start.sh && \
    echo '    git clone https://github.com/ltdrdata/ComfyUI-Manager.git' >> /app/start.sh && \
    echo '    cd ../..' >> /app/start.sh && \
    echo 'fi' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Create model directories' >> /app/start.sh && \
    echo 'mkdir -p ComfyUI/models/{checkpoints,vae,loras,controlnet,embeddings,upscale_models,clip_vision}' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start ComfyUI' >> /app/start.sh && \
    echo 'cd ComfyUI' >> /app/start.sh && \
    echo 'echo "Starting ComfyUI on port 8188..."' >> /app/start.sh && \
    echo 'python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header "*"' >> /app/start.sh

RUN chmod +x /app/start.sh

# Create directories for volume mounts
RUN mkdir -p /app/ComfyUI/models \
    /app/ComfyUI/output \
    /app/ComfyUI/input \
    /app/ComfyUI/custom_nodes

WORKDIR /app/ComfyUI

# Expose port
EXPOSE 8188

# Start ComfyUI
CMD ["/app/start.sh"]
