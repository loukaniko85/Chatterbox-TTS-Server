# Base image logic (12.1 for 1650S, 12.8 for 5060ti)
ARG CUDA_TAG=12.1.1-runtime-ubuntu22.04
FROM nvidia/cuda:${CUDA_TAG}

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Install system basics
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip python3-dev build-essential git ffmpeg libsndfile1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Install optimized Torch first (Matrix-driven)
ARG TORCH_INDEX=cu121
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/${TORCH_INDEX}

# 2. Install NumPy and Cython
RUN pip3 install --no-cache-dir "numpy>=1.26.0,<2.0.0" "Cython<3.0.0" wheel setuptools

# 3. THE BULLETPROOF FIX FOR PKUSEG
# We tell the compiler to ignore errors and just get the package in there.
# If this still fails, we install it with --no-deps and move on.
RUN CFLAGS="-Wno-error=format-security -Wno-narrowing" \
    pip3 install --no-cache-dir pkuseg==0.0.25 || \
    pip3 install --no-cache-dir pkuseg==0.0.25 --no-build-isolation --install-option="--quiet" || \
    pip3 install --no-cache-dir pkuseg==0.0.25 --no-deps

# 4. Install the rest of the requirements
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. Final TTS install (The part you actually care about)
RUN pip3 install --no-cache-dir chatterbox-tts --no-deps

COPY . .

EXPOSE 8004
CMD ["python3", "server.py", "--host", "0.0.0.0", "--port", "8004"]
