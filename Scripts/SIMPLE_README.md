# Simple Model Downloader

This is a simple script that downloads models from Hugging Face URLs and uploads them to your MinIO storage.

## 🚀 Quick Start

### 1. Add your Hugging Face token to Coolify environment variables:

### 2. Push to your repository:
```bash
git add Scripts/
git commit -m "Add simple model downloader"
git push origin main
```

### 3. Run the downloader inside the container:
```bash
# Access the container
docker exec -it comfyui2 bash

# Run the downloader
./Scripts/download_models_simple.sh
```

## 📁 Files

- **`simple_model_downloader.py`** - Main downloader script
- **`models_to_download.json`** - List of models to download
- **`download_models_simple.sh`** - Simple bash wrapper

## 📋 How it works

1. Reads models from `Scripts/models_to_download.json`
2. Downloads each model file
3. Automatically determines model type (vae, checkpoints, clip_vision)
4. Uploads to MinIO in the correct folder structure
5. Cleans up temporary files

## 🔧 Add more models

Edit `Scripts/models_to_download.json`:

```json
{
  "models": [
    {
      "url": "https://huggingface.co/.../model.safetensors",
      "filename": "model.safetensors",
      "type": "checkpoints"
    }
  ]
}
```

## 🎯 Model Types

- `vae` → goes to `models/vae/`
- `checkpoints` → goes to `models/checkpoints/`
- `clip_vision` → goes to `models/clip_vision/`

That's it! Simple and focused. 🎨
