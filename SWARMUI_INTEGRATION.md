# SwarmUI Integration with ComfyUI Backend

## Overview
This guide explains how to use this ComfyUI deployment as a backend for SwarmUI.

## Prerequisites
1. ComfyUI running and accessible (default port: 8188)
2. SwarmUI installed and running
3. Both services on the same network or accessible to each other

## Configuration Steps

### 1. ComfyUI Setup (Already Done)
The Docker container is configured with:
- API enabled on port 8188
- CORS headers enabled for cross-origin requests
- GPU support enabled

### 2. SwarmUI Configuration

#### Option A: Using SwarmUI's Web Interface
1. Open SwarmUI in your browser
2. Go to **Server** → **Server Configuration**
3. Click **Add Backend**
4. Select **ComfyUI** as the backend type
5. Configure:
   - **Name**: ComfyUI-Docker
   - **API URL**: `http://<comfyui-host>:8188`
   - Replace `<comfyui-host>` with:
     - `localhost` if on same machine
     - Docker container name if in same Docker network
     - Actual IP address if on different machines

#### Option B: Using SwarmUI's backends.json
Add this to your SwarmUI's `Data/backends.json`:

```json
{
  "backends": [
    {
      "type": "comfyui",
      "name": "ComfyUI-Docker",
      "address": "http://comfyui-easy-install:8188",
      "enabled": true,
      "can_idle": true,
      "idle_timeout": 300
    }
  ]
}
```

### 3. Docker Network Configuration (If using Docker for both)

If both SwarmUI and ComfyUI are running in Docker, create a shared network:

```bash
# Create a shared network
docker network create ai-network

# Connect ComfyUI to the network
docker network connect ai-network comfyui-easy-install

# Connect SwarmUI to the network (replace with your SwarmUI container name)
docker network connect ai-network swarmui-container
```

Or update your docker-compose.yaml to use a shared network:

```yaml
networks:
  ai-network:
    external: true

services:
  comfyui-easy-install:
    networks:
      - ai-network
    # ... rest of configuration
```

### 4. Model Sharing Between SwarmUI and ComfyUI

To share models between SwarmUI and ComfyUI, mount the same model directories:

#### Update docker-compose.yaml:
```yaml
volumes:
  # Share models with SwarmUI
  - /path/to/shared/models/checkpoints:/app/ComfyUI-Easy-Install/ComfyUI/models/checkpoints
  - /path/to/shared/models/vae:/app/ComfyUI-Easy-Install/ComfyUI/models/vae
  - /path/to/shared/models/loras:/app/ComfyUI-Easy-Install/ComfyUI/models/loras
  - /path/to/shared/models/embeddings:/app/ComfyUI-Easy-Install/ComfyUI/models/embeddings
```

### 5. Environment Variables for SwarmUI Integration

Add these to your docker-compose.yaml if needed:

```yaml
environment:
  # Existing variables...
  - COMFYUI_API_ENABLE=true
  - COMFYUI_CORS_ENABLED=true
  - COMFYUI_CORS_ORIGIN=*
```

## Testing the Integration

1. **Verify ComfyUI is running:**
   ```bash
   curl http://localhost:8188/system_stats
   ```

2. **In SwarmUI:**
   - Go to the Generate tab
   - Select your ComfyUI backend from the dropdown
   - Try generating an image

3. **Check logs:**
   ```bash
   docker logs comfyui-easy-install
   ```

## Troubleshooting

### Connection Refused
- Ensure ComfyUI is listening on 0.0.0.0, not 127.0.0.1
- Check firewall rules
- Verify Docker network connectivity

### CORS Errors
- ComfyUI is already configured with `--enable-cors-header "*"`
- If issues persist, check browser console for specific CORS errors

### GPU Not Available in SwarmUI
- Verify GPU is working in ComfyUI first:
  ```bash
  docker exec comfyui-easy-install nvidia-smi
  ```
- Check SwarmUI backend settings for GPU configuration

### Models Not Showing
- Ensure model paths are correctly mounted
- Check file permissions
- Verify models are in the correct ComfyUI format/structure

## Performance Optimization

1. **Memory Settings:**
   - Adjust `PYTORCH_CUDA_ALLOC_CONF` in docker-compose.yaml
   - Current setting: `max_split_size_mb:512`

2. **Concurrent Requests:**
   - ComfyUI handles requests sequentially by default
   - For parallel processing, consider running multiple ComfyUI instances

3. **Model Caching:**
   - Models are cached in memory after first load
   - Ensure sufficient RAM for your model collection

## API Endpoints

ComfyUI exposes these endpoints for SwarmUI:

- `GET /system_stats` - System information
- `GET /object_info` - Available nodes and models
- `POST /prompt` - Submit generation request
- `GET /history` - Get generation history
- `WS /ws` - WebSocket for real-time updates

## Security Considerations

1. **Network Isolation:**
   - Use Docker networks to isolate services
   - Don't expose ComfyUI directly to the internet

2. **Authentication:**
   - ComfyUI doesn't have built-in authentication
   - Use a reverse proxy (nginx, traefik) if exposing externally

3. **Resource Limits:**
   - Set appropriate memory and CPU limits in docker-compose.yaml
   - Monitor GPU memory usage

## Advanced Configuration

### Custom Nodes for SwarmUI
Install SwarmUI-specific custom nodes:

```bash
docker exec -it comfyui-easy-install bash
cd /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes
git clone https://github.com/SwarmUI/ComfyUI-SwarmUI-Nodes.git
```

### Workflow Templates
Place SwarmUI-compatible workflows in:
```
./custom_nodes/workflows/
```

Mount in docker-compose.yaml:
```yaml
volumes:
  - ./workflows:/app/ComfyUI-Easy-Install/ComfyUI/workflows
```
