#!/usr/bin/env python3
"""
Simple Model Downloader for ComfyUI with MinIO Support
Downloads models from Hugging Face and uploads them to MinIO storage
"""

import os
import json
import sys
import subprocess
from pathlib import Path
import urllib.request
import urllib.error
from typing import Dict, List, Optional

# Configuration
SCRIPT_DIR = Path(__file__).parent
MODELS_JSON = SCRIPT_DIR / "models_to_download.json"
TEMP_DIR = Path("/tmp/model_downloads")

# MinIO configuration from environment
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "http://minio:9000")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", os.getenv("SERVICE_USER_MINIO"))
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", os.getenv("SERVICE_PASSWORD_MINIO"))
MINIO_BUCKET = os.getenv("MINIO_BUCKET_MODELS", "ai-models")

# Hugging Face token (optional)
HF_TOKEN = os.getenv("HF_TOKEN", "")


def setup_minio_client():
    """Install and configure MinIO client if not available"""
    try:
        # Check if mc is installed
        result = subprocess.run(["which", "mc"], capture_output=True, text=True)
        if result.returncode != 0:
            print("📦 Installing MinIO client...")
            # Try wget, fall back to curl if wget is unavailable
            got_mc = False
            try:
                subprocess.run([
                    "wget", "-q",
                    "https://dl.min.io/client/mc/release/linux-amd64/mc",
                    "-O", "/tmp/mc"
                ], check=True)
                got_mc = True
            except Exception:
                # wget not present; try curl
                try:
                    subprocess.run([
                        "curl", "-fsSL",
                        "-o", "/tmp/mc",
                        "https://dl.min.io/client/mc/release/linux-amd64/mc"
                    ], check=True)
                    got_mc = True
                except Exception as e:
                    raise RuntimeError(f"Failed to download mc: {e}")
            if not got_mc:
                raise RuntimeError("Could not download mc")
            subprocess.run(["chmod", "+x", "/tmp/mc"], check=True)
            mc_path = "/tmp/mc"
        else:
            mc_path = "mc"
        
        # Configure MinIO client
        print("🔧 Configuring MinIO client...")
        subprocess.run([
            mc_path, "alias", "set", "myminio",
            MINIO_ENDPOINT, MINIO_ACCESS_KEY, MINIO_SECRET_KEY
        ], check=True)
        
        # Create bucket if it doesn't exist
        subprocess.run([mc_path, "mb", "-p", f"myminio/{MINIO_BUCKET}"], capture_output=True)
        
        return mc_path
    except Exception as e:
        print(f"❌ Failed to setup MinIO client: {e}")
        sys.exit(1)


def download_file(url: str, destination: Path, use_token: bool = True) -> bool:
    """Download a file from URL with progress indication"""
    try:
        print(f"📥 Downloading: {destination.name}")
        print(f"   From: {url[:80]}...")
        
        # Create headers with HF token if available
        headers = {}
        if use_token and HF_TOKEN:
            headers["Authorization"] = f"Bearer {HF_TOKEN}"
        
        # Create request
        req = urllib.request.Request(url, headers=headers)
        
        # Download with progress
        with urllib.request.urlopen(req) as response:
            total_size = int(response.headers.get('Content-Length', 0))
            downloaded = 0
            block_size = 8192
            
            with open(destination, 'wb') as f:
                while True:
                    chunk = response.read(block_size)
                    if not chunk:
                        break
                    f.write(chunk)
                    downloaded += len(chunk)
                    
                    # Show progress
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        mb_downloaded = downloaded / (1024 * 1024)
                        mb_total = total_size / (1024 * 1024)
                        print(f"   Progress: {percent:.1f}% ({mb_downloaded:.1f}/{mb_total:.1f} MB)", end='\r')
        
        print(f"\n✅ Downloaded: {destination.name}")
        return True
        
    except urllib.error.HTTPError as e:
        if e.code == 401 and use_token:
            print(f"⚠️  Auth failed, retrying without token...")
            return download_file(url, destination, use_token=False)
        print(f"❌ HTTP Error {e.code}: {e.reason}")
        return False
    except Exception as e:
        print(f"❌ Download failed: {e}")
        return False


def upload_to_minio(mc_path: str, local_file: Path, model_type: str, filename: str) -> bool:
    """Upload file to MinIO storage"""
    try:
        # Construct MinIO path
        minio_path = f"myminio/{MINIO_BUCKET}/models/{model_type}/{filename}"
        
        print(f"📤 Uploading to MinIO: models/{model_type}/{filename}")
        
        # Upload file
        result = subprocess.run(
            [mc_path, "cp", str(local_file), minio_path],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print(f"✅ Uploaded successfully!")
            return True
        else:
            print(f"❌ Upload failed: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Upload error: {e}")
        return False


def load_models_config() -> List[Dict]:
    """Load models configuration from JSON file"""
    try:
        with open(MODELS_JSON, 'r') as f:
            config = json.load(f)
            return config.get("models", [])
    except FileNotFoundError:
        print(f"❌ Models configuration not found: {MODELS_JSON}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in models configuration: {e}")
        sys.exit(1)


def main():
    """Main download and upload process"""
    print("🚀 ComfyUI Model Downloader with MinIO")
    print("=" * 50)
    
    # Setup
    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    mc_path = setup_minio_client()
    
    # Load models to download
    models = load_models_config()
    if not models:
        print("⚠️  No models configured in models_to_download.json")
        return
    
    print(f"\n📋 Found {len(models)} models to download")
    
    # Process each model
    success_count = 0
    for i, model in enumerate(models, 1):
        print(f"\n[{i}/{len(models)}] Processing: {model.get('filename', 'unknown')}")
        print("-" * 40)
        
        url = model.get("url")
        filename = model.get("filename")
        model_type = model.get("type", "checkpoints")
        
        if not url or not filename:
            print("❌ Missing URL or filename, skipping...")
            continue
        
        # Download file
        local_file = TEMP_DIR / filename
        if download_file(url, local_file):
            # Upload to MinIO
            if upload_to_minio(mc_path, local_file, model_type, filename):
                success_count += 1
                # Clean up local file
                local_file.unlink(missing_ok=True)
            else:
                print(f"⚠️  File saved locally at: {local_file}")
        
    # Summary
    print("\n" + "=" * 50)
    print(f"✨ Download complete! {success_count}/{len(models)} models uploaded to MinIO")
    
    if success_count < len(models):
        print(f"⚠️  {len(models) - success_count} models failed to upload")
        print(f"   Check {TEMP_DIR} for any local files")


if __name__ == "__main__":
    main()
