# Coolify GPU Configuration for ComfyUI

## Prerequisites
1. NVIDIA GPU on the host server
2. NVIDIA drivers installed on the host
3. NVIDIA Container Toolkit installed on the host

## Coolify Configuration

### In Coolify Dashboard:

1. **Environment Variables**
   Add these to your service configuration:
   ```
   NVIDIA_VISIBLE_DEVICES=all
   NVIDIA_DRIVER_CAPABILITIES=compute,utility
   ```

2. **Docker Compose Override**
   In your Coolify service settings, add this to the Docker Compose configuration:
   ```yaml
   deploy:
     resources:
       reservations:
         devices:
           - driver: nvidia
             count: all
             capabilities: [gpu]
   ```

3. **Runtime Configuration**
   Add to your service's advanced settings:
   ```
   runtime: nvidia
   ```

## Alternative: Using Docker Run Command

If Coolify allows custom Docker run commands, use:
```bash
docker run --gpus all \
  -p 8188:8188 \
  -v ./models:/app/ComfyUI-Easy-Install/ComfyUI/models \
  -v ./output:/app/ComfyUI-Easy-Install/ComfyUI/output \
  comfyui-easy-install:latest
```

## Verifying GPU Access

After deployment, check if GPU is accessible:
1. Access the container shell through Coolify
2. Run: `nvidia-smi`
3. Or check ComfyUI logs for GPU detection

## Troubleshooting

If GPU is not detected:
1. Verify NVIDIA Container Toolkit is installed on host:
   ```bash
   docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
   ```

2. Check Docker daemon configuration (`/etc/docker/daemon.json`):
   ```json
   {
     "default-runtime": "nvidia",
     "runtimes": {
       "nvidia": {
         "path": "nvidia-container-runtime",
         "runtimeArgs": []
       }
     }
   }
   ```

3. Restart Docker service after configuration changes:
   ```bash
   sudo systemctl restart docker
   ```
