# Adding Dockerized ComfyUI as a Second Backend in SwarmUI

## Current Setup
You already have one ComfyUI backend running locally. Now let's add the Dockerized version as a second backend.

## Steps to Add the Docker Backend

### 1. In SwarmUI Interface (as shown in your screenshot):

Click **"Add new backend of type"** and select **"ComfyUI API By URL"** (not "ComfyUI Self-Starting")

### 2. Configure the New Backend:

Fill in these settings:

```
Name: ComfyUI-Docker (or any name you prefer)
API URL: http://localhost:8188
```

Or if your Docker is on a different machine:
```
API URL: http://<docker-host-ip>:8188
```

### 3. Advanced Settings (Optional):

- **GPU_ID**: Leave at 0 (Docker container will use the GPU you configured)
- **OverQueue**: Set to 1 or higher if you want to queue multiple requests
- **AutoRestart**: Can leave unchecked since Docker handles restarts

### 4. Important Differences from Self-Starting:

Your current backend uses **"ComfyUI Self-Starting"** which means SwarmUI launches ComfyUI.
The Docker backend should use **"ComfyUI API By URL"** since ComfyUI is already running in Docker.

## Verifying the Connection

1. **Check if Docker ComfyUI is accessible:**
   Open a browser and go to: `http://localhost:8188`
   You should see the ComfyUI interface.

2. **Test in SwarmUI:**
   - After adding the backend, click the refresh button
   - The status indicator should turn green
   - Try generating an image using the new backend

## Running Both Backends Simultaneously

You can now:
- Use the dropdown in the Generate tab to switch between backends
- Run different models on each backend
- Use one for testing and one for production
- Load balance between them

## Troubleshooting

### If the Docker backend shows as offline:

1. **Check if Docker container is running:**
   ```bash
   docker ps | grep comfyui
   ```

2. **Check Docker logs:**
   ```bash
   docker logs comfyui-easy-install
   ```

3. **Test API directly:**
   ```bash
   curl http://localhost:8188/system_stats
   ```

### If you get CORS errors:

The Docker container is already configured with CORS headers enabled. If issues persist:

1. Check browser console (F12) for specific errors
2. Try using `http://127.0.0.1:8188` instead of `localhost`
3. Ensure no firewall is blocking port 8188

## Model Sharing

To share models between your local ComfyUI and Docker ComfyUI:

1. **Find your local ComfyUI models folder:**
   Based on your path: `D:\ComfyUI_V45\ComfyUI\models\`

2. **Mount it in Docker** by updating docker-compose.yaml:
   ```yaml
   volumes:
     - D:/ComfyUI_V45/ComfyUI/models:/app/ComfyUI-Easy-Install/ComfyUI/models
   ```

3. **Restart the Docker container:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Performance Tips

1. **Sage Attention**: Your local backend uses `--use-sage-attention`. To add this to Docker backend, update the Dockerfile's start script to include this flag.

2. **Memory Management**: If running both backends causes memory issues, you can:
   - Limit Docker memory in docker-compose.yaml
   - Use different models on each backend
   - Stagger generation requests

## Benefits of Having Two Backends

1. **Isolation**: Docker backend is isolated from your system
2. **Testing**: Test new custom nodes or updates in Docker first
3. **Reliability**: If one crashes, the other continues working
4. **Different Configurations**: Run different PyTorch versions or settings
5. **Load Distribution**: Distribute work between backends
