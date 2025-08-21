# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is **ComfyUI-Easy-Install**, a comprehensive containerized deployment solution for ComfyUI (an advanced AI image generation interface) that includes:

- **Portable ComfyUI** with pre-configured custom nodes from the Pixaroma community
- **Multi-platform support**: Windows, Linux, macOS, and Docker deployments
- **Cloud deployment** integrations with Coolify, Proxmox, and SwarmUI backend support
- **Extensive custom node ecosystem** with 25+ pre-installed community extensions

## Key Architecture Components

### Deployment Methods
The repository supports multiple deployment patterns:

1. **Docker Containerized**: Primary deployment method using `docker-compose.yaml` and `Dockerfile`
2. **Native Linux Installation**: Shell script-based installation with `ComfyUI-Easy-Install-Linux.sh`
3. **macOS Installation**: Optimized for Apple Silicon (M1/M2) with MPS acceleration
4. **Cloud Platform Integration**: Coolify and Proxmox LXC container support

### Directory Structure
```
.
├── docker-compose.yaml          # Main container orchestration
├── Dockerfile                   # Container build definition
├── ComfyUI-Easy-Install-Linux.sh # Native Linux installer
├── deploy.sh                    # Coolify deployment automation
├── Update/                      # Version management system
│   └── update.py               # Git-based updater with conflict resolution
├── Scripts/                     # Utility scripts collection
│   ├── Extra_Model_Paths_Maker.sh # Model directory YAML generator
│   ├── sync_models.sh          # Model synchronization with progress
│   └── [various system utilities]
└── Documentation/
    ├── SWARMUI_*.md            # SwarmUI backend integration guides
    ├── COOLIFY_DEPLOYMENT.md   # Cloud deployment instructions
    └── README.md               # Multi-platform setup guide
```

## Common Development Commands

### Docker Operations
```bash
# Build and start ComfyUI container
docker-compose up -d --build

# View real-time logs
docker-compose logs -f comfyui-easy-install

# Stop and remove containers
docker-compose down

# Rebuild without cache (after updates)
docker-compose build --no-cache
```

### Quick Deployment
```bash
# Automated deployment with Coolify integration
./deploy.sh

# Linux native installation 
chmod +x ComfyUI-Easy-Install-Linux.sh
./ComfyUI-Easy-Install-Linux.sh

# Proxmox LXC container installation
./ComfyUI-Easy-Install-Linux.sh --proxmox
```

### Model Management
```bash
# Generate extra_model_paths.yaml for existing models
cd /path/to/your/models && ./Scripts/Extra_Model_Paths_Maker.sh

# Sync models from network storage (with progress monitoring)
./Scripts/sync_models.sh -s /source/models/ -d /destination/models/

# Test sync without copying (dry run)
./Scripts/sync_models.sh -n -s /source/ -d /dest/

# S3 Centralized Storage Management
# Models and custom nodes are automatically shared via S3/MinIO
# Downloads through ComfyUI Manager go directly to shared S3 bucket
# Initialize S3 storage structure
bash init-s3-storage.sh
```

### Update Operations
```bash
# Update ComfyUI core and all custom nodes (Linux)
./LinuxUpdate_all_and_run.sh

# Update ComfyUI only (Linux)
./LinuxUpdate_comfy_and_run.sh

# Manual update using Python updater
cd Update && python update.py ../ComfyUI-Easy-Install/ComfyUI

# Update to stable release only
cd Update && python update.py ../ComfyUI-Easy-Install/ComfyUI --stable
```

## Integration Capabilities

### Centralized S3 Model Storage
This deployment uses MinIO S3 for centralized model management:
- **Shared Models**: All AI instances share the same model library via S3
- **ComfyUI Manager Downloads**: Models downloaded through Manager go directly to S3
- **Custom Nodes**: Shared custom node installations across all instances
- **Automatic Sync**: New models appear instantly in all ComfyUI instances
- **Storage Path**: S3 bucket mounted to `/app/ComfyUI-Easy-Install/ComfyUI/models`

### SwarmUI Backend Integration
This ComfyUI instance can serve as a backend for SwarmUI:
- **API Endpoint**: `http://localhost:8188` 
- **Backend Type**: "ComfyUI API By URL" (not self-starting)
- **CORS Support**: Pre-configured with `--enable-cors-header "*"`
- **Model Sharing**: Automatic through shared S3 storage

### Pre-installed Custom Nodes
The installation includes 25+ community nodes:
- ComfyUI-Manager (node package manager)
- WAS Node Suite (extensive utility nodes)
- Easy-Use (workflow simplification)
- ControlNet Aux (advanced control systems)
- VideoHelperSuite (video processing)
- Florence2, OmniGen (multimodal AI)
- Ollama, Searge LLM (local language models)

### GPU and Performance Optimization
- **CUDA Support**: PyTorch 2.1.0+cu118 with GPU memory management
- **Memory Configuration**: `PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512`
- **Apple Silicon**: MPS optimization with watermark ratio controls
- **Container Limits**: 8GB memory limit with 4GB reservation

## Development Environment Setup

### Prerequisites
- **Docker & Docker Compose**: Required for containerized deployment
- **Python 3.10+**: For native installations
- **CUDA Drivers**: For GPU acceleration (Linux/Windows)
- **Minimum Hardware**: 8GB RAM, 50GB storage for models

### Environment Variables
```bash
# Core runtime settings
PYTHONUNBUFFERED=1
PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=compute,utility

# S3 Storage indicator
COMFYUI_S3_READY=true

# macOS Apple Silicon optimization
PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
PYTORCH_MPS_LOW_WATERMARK_RATIO=0.0
```

### Port Configuration
- **ComfyUI Web Interface**: `8188`
- **Docker Health Check**: HTTP GET `/` every 30s
- **Network**: External `ai-network` for multi-container setups

## Troubleshooting Reference

### Common Issues
1. **GPU Not Detected**: Verify `nvidia-smi` works, check Docker GPU runtime
2. **Out of Memory**: Reduce `max_split_size_mb`, use smaller models/batches
3. **Custom Node Import Failures**: Check console for dependency conflicts
4. **CORS Errors**: Already configured, try `http://127.0.0.1:8188` vs `localhost`

### Performance Tuning
- **Model Loading**: Models cached in memory after first load
- **Batch Processing**: Sequential by default, run multiple instances for parallel
- **Storage**: Use SSD for model directories, regular cleanup of output folder
- **Apple Silicon**: Use GGUF models, avoid CPU-intensive nodes

## Platform-Specific Notes

### Linux/Proxmox
- Supports LXC containers with GPU passthrough
- Automatic system dependency installation
- Virtual environment isolation with `venv`

### macOS (Apple Silicon)
- MPS acceleration with Metal Performance Shaders
- Memory management optimizations
- FP32 accumulation for precision

### Docker/Cloud
- Health checks with automatic restart policies
- Volume mounts for persistent model storage
- Resource limits and GPU device mapping

## Update and Maintenance Workflow

The update system uses a sophisticated Git-based approach:
1. **Conflict Resolution**: Automatic stashing and backup branch creation
2. **Self-Updating**: Update script updates itself when repository changes
3. **Dependency Tracking**: Compares `requirements.txt` and installs changes
4. **Stable Releases**: Optional `--stable` flag for tagged versions only

Access ComfyUI at `http://localhost:8188` after any deployment method.
