# Base image logic (12.1 for 1650S, 12.8 for 5060ti)
ARG CUDA_TAG=12.1.1-runtime-ubuntu22.04
FROM nvidia/cuda:${CUDA_TAG}

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

# Install system basics
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip python3-dev build-essential git ffmpeg libsndfile1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Install optimized Torch first
ARG TORCH_INDEX=cu121
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/${TORCH_INDEX}

# 2. Install NumPy and Cython
RUN pip3 install --no-cache-dir "numpy>=1.26.0,<2.0.0" "Cython<3.0.0" wheel setuptools

# 3. THE "GIVE UP ON PKUSEG" FIX
# We try to install it. If it fails (which it will), we create a dummy folder 
# so 'import pkuseg' doesn't crash the server.
RUN pip3 install --no-cache-dir pkuseg==0.0.25 --no-deps || \
    (mkdir -p /usr/local/lib/python3.10/dist-packages/pkuseg && \
     touch /usr/local/lib/python3.10/dist-packages/pkuseg/__init__.py && \
     echo "class pkuseg: def __init__(self, *args, **kwargs): pass\ndef pkuseg(*args, **kwargs): return pkuseg()" > /usr/local/lib/python3.10/dist-packages/pkuseg/__init__.py)

# 4. Install the rest of the requirements
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. Final TTS install
RUN pip3 install --no-cache-dir chatterbox-tts --no-deps

COPY . .

EXPOSE 8004
CMD ["python3", "server.py", "--host", "0.0.0.0", "--port", "8004"]
