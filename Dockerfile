# ComfyUI Easy Install Dockerfile for Coolify with GPU support
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

# Copy the Helper-CEI files
COPY Helper-CEI/ComfyUI-Easy-Install/ ./ComfyUI-Easy-Install/

# Copy S3 integration scripts
COPY init-s3-storage.sh /app/
COPY start-comfyui-with-s3.sh /app/start.sh

# Create virtual environment first
RUN cd ComfyUI-Easy-Install && \
    python3 -m venv venv

# Upgrade pip separately
RUN cd ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    pip install --upgrade pip wheel setuptools

# Install PyTorch components one by one to reduce memory usage
RUN cd ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    pip install torch==2.1.0+cu118 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

RUN cd ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    pip install torchvision==0.16.0+cu118 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

RUN cd ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    pip install torchaudio==2.1.0+cu118 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

# Clone ComfyUI
RUN cd ComfyUI-Easy-Install && \
    rm -rf ComfyUI && \
    git clone https://github.com/comfyanonymous/ComfyUI.git

# Install ComfyUI requirements
RUN cd ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    cd ComfyUI && \
    pip install -r requirements.txt --no-cache-dir

# Set working directory to ComfyUI installation
WORKDIR /app/ComfyUI-Easy-Install

# Set executable permissions for scripts
RUN chmod +x /app/start.sh && \
    chmod +x /app/init-s3-storage.sh

# Create directories for volume mounts
RUN mkdir -p /app/ComfyUI-Easy-Install/ComfyUI/models \
    /app/ComfyUI-Easy-Install/ComfyUI/output \
    /app/ComfyUI-Easy-Install/ComfyUI/input \
    /app/ComfyUI-Easy-Install/ComfyUI/temp \
    /app/ComfyUI-Easy-Install/ComfyUI/user \
    /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes

# Expose port
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# Start ComfyUI
CMD ["/app/start.sh"]