#!/bin/bash
# This script generates the extra_model_paths.yaml to configure ComfyUI
# with a central models directory inside the container.

set -euo pipefail

YAML_FILE="/root/ComfyUI/extra_model_paths.yaml"
BASE_PATH="/root"

cat > "$YAML_FILE" << EOL
comfyui:
    base_path: $BASE_PATH
    is_default: true

    checkpoints: models/checkpoints/
    clip: models/clip/
    clip_vision: models/clip_vision/
    configs: models/configs/
    controlnet: models/controlnet/
    diffusers: models/diffusers/
    embeddings: models/embeddings/
    gligen: models/gligen/
    hypernetworks: models/hypernetworks/
    loras: models/loras/
    style_models: models/style_models/
    upscale_models: models/upscale_models/
    vae: models/vae/
EOL

echo "✅ Generated extra_model_paths.yaml"

# Ensure all model directories exist
mkdir -p \
    "$BASE_PATH/models/checkpoints" \
    "$BASE_PATH/models/clip" \
    "$BASE_PATH/models/clip_vision" \
    "$BASE_PATH/models/configs" \
    "$BASE_PATH/models/controlnet" \
    "$BASE_PATH/models/diffusers" \
    "$BASE_PATH/models/embeddings" \
    "$BASE_PATH/models/gligen" \
    "$BASE_PATH/models/hypernetworks" \
    "$BASE_PATH/models/loras" \
    "$BASE_PATH/models/style_models" \
    "$BASE_PATH/models/upscale_models" \
    "$BASE_PATH/models/vae"

