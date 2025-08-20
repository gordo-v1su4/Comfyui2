# Connecting SwarmUI to Remote ComfyUI on Coolify

## Your Setup
- **SwarmUI**: Running locally on your Windows machine
- **ComfyUI Backend 1**: Local installation at `D:\ComfyUI_V45\`
- **ComfyUI Backend 2**: Deployed via Coolify at `comfyui.v1su4.com`

## Adding the Remote Coolify Backend to SwarmUI

### 1. In SwarmUI (from your screenshot):

Click the dropdown and select **"ComfyUI API By URL"**

### 2. Configure the Remote Backend:

```
Name: ComfyUI-Coolify (or any descriptive name)
API URL: https://comfyui.v1su4.com
```

Or if it's HTTP only:
```
API URL: http://comfyui.v1su4.com:8188
```

### 3. Test the Connection

Before adding in SwarmUI, verify the remote ComfyUI is accessible:

1. **Open in browser**: 
   - Try: `https://comfyui.v1su4.com`
   - Or: `http://comfyui.v1su4.com:8188`

2. **Test the API endpoint**:
   ```bash
   curl https://comfyui.v1su4.com/system_stats
   ```

## Coolify Configuration Requirements

Make sure your Coolify deployment has:

### 1. **Public Access Enabled**
In Coolify, ensure the service is:
- Set to public/exposed
- Has the correct domain configured
- SSL certificate is valid (if using HTTPS)

### 2. **Port Configuration**
- Default ComfyUI port: 8188
- Coolify might proxy this to port 80/443

### 3. **CORS Headers**
The Dockerfile already includes `--enable-cors-header "*"` which allows SwarmUI to connect.

## Network Configuration in Coolify

### If Connection Fails:

1. **Check Coolify Network Settings**:
   - Go to your Coolify dashboard
   - Navigate to your ComfyUI service
   - Check the "Domains" section
   - Ensure it shows: `comfyui.v1su4.com`

2. **Verify Exposed Ports**:
   - In Coolify service settings
   - Ensure port 8188 is exposed
   - Or that Coolify is proxying correctly

3. **Check Firewall Rules**:
   - The remote server needs to allow incoming connections
   - Port 8188 (or 80/443 if proxied) must be open

## SwarmUI Settings for Remote Backend

### Recommended Configuration:

```
Name: ComfyUI-Coolify
API URL: https://comfyui.v1su4.com  (or with port if needed)
GPU_ID: 0 (remote GPU will be used)
OverQueue: 2 (allow some queuing)
AutoRestart: ❌ (Coolify handles restarts)
```

### Advanced Settings:
- **Timeout**: Might need to increase for remote connection
- **Max Concurrent**: Set to 1 initially, increase if stable

## Model Management for Remote Backend

Since the Coolify backend is on a different server, models need to be managed separately:

### Option 1: Upload Models to Coolify Server
- SSH into the Coolify server
- Place models in the mounted volume directory
- Or use ComfyUI Manager to download models

### Option 2: Use Different Models
- Keep lightweight models on Coolify
- Use heavy models on local backend
- Distribute based on use case

## Testing the Dual Backend Setup

1. **In SwarmUI Generate Tab**:
   - You'll see a backend selector dropdown
   - Choose between "ComfyUI Self-Starting" (local) and "ComfyUI-Coolify" (remote)

2. **Test Both Backends**:
   - Generate with local backend
   - Switch to Coolify backend
   - Compare performance and results

## Performance Considerations

### Network Latency:
- Remote backend will have network latency
- Initial model loading might be slower
- Once loaded, generation speed depends on remote GPU

### Load Balancing:
- Use local for quick iterations
- Use remote for long-running or batch jobs
- Can run both simultaneously for parallel processing

## Monitoring

### Check Remote Backend Status:
```bash
# From your local machine
curl https://comfyui.v1su4.com/system_stats

# Should return JSON with system information
```

### In Coolify Dashboard:
- Monitor CPU/GPU usage
- Check container logs
- View resource consumption

## Troubleshooting

### "Backend Offline" in SwarmUI:

1. **Verify URL format**:
   - Try with/without HTTPS
   - Try with/without port number
   - Try with/without trailing slash

2. **Check Coolify logs**:
   ```
   In Coolify Dashboard > Your Service > Logs
   ```

3. **Test direct access**:
   - Open ComfyUI URL in browser
   - Should see ComfyUI interface

### CORS Errors:

If you see CORS errors in browser console:

1. **Verify Dockerfile has CORS enabled** (already done)
2. **Check if Coolify proxy is stripping headers**
3. **Try using the direct IP:port instead of domain**

### Connection Timeout:

1. **Increase timeout in SwarmUI backend settings**
2. **Check if Coolify has request size limits**
3. **Verify SSL certificate if using HTTPS**

## Security Notes

1. **Authentication**: 
   - ComfyUI doesn't have built-in auth
   - Consider adding basic auth in Coolify proxy
   - Or use VPN for secure access

2. **Rate Limiting**:
   - Consider adding rate limits in Coolify
   - Prevent abuse of public endpoint

3. **Monitoring**:
   - Set up alerts for high usage
   - Monitor for unauthorized access

## Benefits of This Setup

1. **Distributed Computing**: Leverage multiple GPUs across servers
2. **Redundancy**: If one backend fails, other continues
3. **Specialization**: Different models/workflows on each backend
4. **Scalability**: Easy to add more Coolify instances
5. **Cost Optimization**: Use remote GPU only when needed
