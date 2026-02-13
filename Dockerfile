# Use the runtime image to save space (devel is ~3GB larger)
# Matrix will pass: 12.1.1-runtime-ubuntu22.04 or 12.8.0-runtime-ubuntu24.04
ARG CUDA_TAG=12.1.1-runtime-ubuntu22.04
FROM nvidia/cuda:${CUDA_TAG}

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Install system dependencies and clean up in the same layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    git \
    ffmpeg \
    libsndfile1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Install optimized Torch based on Matrix (cu121 or cu128)
# Using --no-cache-dir is CRITICAL here to prevent disk space errors
ARG TORCH_INDEX=cu121
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/${TORCH_INDEX}

# 2. Install cleaned requirements
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 3. Install Chatterbox-TTS without dependencies to prevent driver overwrites
RUN pip3 install --no-cache-dir chatterbox-tts --no-deps

# Copy code last to maximize layer caching
COPY . .

# Ensure the server binds to 0.0.0.0 for external access
EXPOSE 8004
CMD ["python3", "server.py", "--host", "0.0.0.0", "--port", "8004"]
