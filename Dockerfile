# ComfyUI2 image built on cu128 base; bakes startup scripts for reliability
FROM yanwk/comfyui-boot:cu128-slim

# Copy scripts into image
COPY Scripts /opt/comfy-scripts

# Normalize line endings and ensure executables
RUN set -eux; \
    if command -v sed >/dev/null 2>&1; then \
      for f in /opt/comfy-scripts/*.sh; do [ -f "$f" ] && sed -i 's/\r$//' "$f" || true; done; \
    fi; \
    chmod +x /opt/comfy-scripts/*.sh || true

# Default command: robust startup wrapper
CMD ["bash", "/opt/comfy-scripts/startup.sh"]
