# ComfyUI2 image built on cu128 base; bakes startup scripts for reliability
FROM yanwk/comfyui-boot:cu128-slim

# Copy scripts into image
COPY Scripts /opt/comfy-scripts

# Normalize line endings and ensure executables
RUN apt-get update && apt-get install -y findutils && \
    set -eux; \
    if command -v sed >/dev/null 2>&1; then \
      find /opt/comfy-scripts -type f -name "*.sh" -exec sed -i 's/\r$//' {} + ; \
    fi; \
    chmod +x /opt/comfy-scripts/*.sh || true

# Default command: robust startup wrapper
CMD ["bash", "/opt/comfy-scripts/startup.sh"]
