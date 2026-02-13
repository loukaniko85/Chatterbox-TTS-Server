# Default to 12.1 for the 1650S, Matrix will override for 5060ti
ARG CUDA_TAG=12.1.1-devel-ubuntu22.04
FROM nvidia/cuda:${CUDA_TAG}

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    python3.11 python3-pip git ffmpeg libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Install optimized Torch based on your Matrix (cu121 or cu128)
ARG TORCH_INDEX=cu121
RUN pip3 install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/${TORCH_INDEX}

# 2. Install cleaned requirements (this won't conflict anymore)
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 3. THE FIX: Install Chatterbox-TTS WITHOUT its dependencies
# This prevents it from downgrading your 5060ti-ready Torch.
RUN pip3 install --no-cache-dir chatterbox-tts --no-deps

COPY . .

EXPOSE 8004
CMD ["python3", "server.py", "--host", "0.0.0.0", "--port", "8004"]
