#!/bin/bash
set -euo pipefail

# Run init tasks in background if Scripts are available
if [ -d /opt/comfy-scripts ]; then
  (
    sed 's/\r$//' /opt/comfy-scripts/install_custom_nodes.sh | bash && \
    sed 's/\r$//' /opt/comfy-scripts/install_node_requirements.sh | bash && \
    python3 /opt/comfy-scripts/simple_model_downloader.py || true
  ) &
else
  echo "Scripts directory not found, skipping init."
fi

# Ensure user assets exist to avoid 404s
mkdir -p /root/ComfyUI/user
[ -f /root/ComfyUI/user/user.css ] || echo '/* user overrides */' > /root/ComfyUI/user/user.css
[ -f /root/ComfyUI/user/comfy.templates.json ] || echo '{"templates":[]}' > /root/ComfyUI/user/comfy.templates.json

# Start ComfyUI
if [ -x /runner-script ]; then
  exec bash /runner-script
elif [ -f /root/ComfyUI/main.py ]; then
  echo 'runner-script missing, starting ComfyUI directly via python'
  exec python3 -u /root/ComfyUI/main.py --listen 0.0.0.0 --port 8188 --enable-cors-header "*"
else
  echo 'ComfyUI entrypoint not found, sleeping for diagnostics'
  sleep infinity
fi
