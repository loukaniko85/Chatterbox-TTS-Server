# Use runtime as base, matrix handles the version
ARG CUDA_TAG=12.1.1-runtime-ubuntu22.04
FROM nvidia/cuda:${CUDA_TAG}

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Install system dependencies + Build Tools for pkuseg
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    python3-dev \
    build-essential \
    g++ \
    git \
    ffmpeg \
    libsndfile1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Install optimized Torch first
ARG TORCH_INDEX=cu121
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/${TORCH_INDEX}

# 2. Install NumPy and Cython BEFORE other requirements
# This prevents pkuseg from failing with "ModuleNotFoundError: No module named 'numpy'"
RUN pip3 install --no-cache-dir "numpy>=1.26.0,<2.0.0" cython

# 3. Install the rest of the requirements
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. Final install of the TTS engine
RUN pip3 install --no-cache-dir chatterbox-tts --no-deps

COPY . .

EXPOSE 8004
CMD ["python3", "server.py", "--host", "0.0.0.0", "--port", "8004"]
