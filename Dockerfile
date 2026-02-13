# Base image logic (12.1 for 1650S, 12.8 for 5060ti)
ARG CUDA_TAG=12.1.1-runtime-ubuntu22.04
FROM nvidia/cuda:${CUDA_TAG}

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip python3-dev build-essential git ffmpeg libsndfile1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Install optimized Torch based on your Matrix (cu121 or cu128)
ARG TORCH_INDEX=cu121
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/${TORCH_INDEX}

# 2. Install NumPy and Cython first
RUN pip3 install --no-cache-dir "numpy>=1.26.0,<2.0.0" "Cython<3.0.0" wheel setuptools

# 3. THE MOCK FIX: Satisfy the pkuseg requirement without compiling it
RUN mkdir -p /usr/local/lib/python3.10/dist-packages/pkuseg && \
    echo "class pkuseg: def __init__(self, *args, **kwargs): pass\ndef pkuseg(*args, **kwargs): return pkuseg()" > /usr/local/lib/python3.10/dist-packages/pkuseg/__init__.py

# 4. Install all requirements (Now including omegaconf and diffusers)
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. Final TTS engine install
RUN pip3 install --no-cache-dir chatterbox-tts --no-deps

COPY . .

EXPOSE 8004
CMD ["python3", "server.py", "--host", "0.0.0.0", "--port", "8004"]
