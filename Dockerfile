# Stage 1: Use a standard image to fix line endings
FROM debian:stable-slim as fixer

# Install dos2unix
RUN apt-get update && apt-get install -y dos2unix

# Copy scripts and fix them
COPY Scripts /scripts
RUN find /scripts -type f -print0 | xargs -0 dos2unix

# Stage 2: Use the comfyui base image
FROM yanwk/comfyui-boot:cu128-slim

# Copy the corrected scripts from the fixer stage
COPY --from=fixer /scripts /opt/comfy-scripts

# Ensure scripts are executable
RUN chmod +x /opt/comfy-scripts/*.sh

# Default command: robust startup wrapper
CMD ["bash", "/opt/comfy-scripts/startup.sh"]
