# Add these lines to your Dockerfile to fix the dependency issues permanently

# After the base image and before the CMD/ENTRYPOINT
RUN cd /app/ComfyUI-Easy-Install && \
    . venv/bin/activate && \
    pip install --upgrade "numpy<2.0" && \
    pip install gitpython && \
    pip install uv && \
    echo "Dependencies fixed"

# Optional: Upgrade PyTorch (uncomment if needed)
# RUN cd /app/ComfyUI-Easy-Install && \
#     . venv/bin/activate && \
#     pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
