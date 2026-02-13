# Default to 12.1 for the 1650S
ARG CUDA_TAG=12.1.1-devel-ubuntu22.04
FROM nvidia/cuda:${CUDA_TAG}

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 python3-pip git ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Conditional Torch Install based on CUDA version
ARG TORCH_INDEX=cu121
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/${TORCH_INDEX}
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy the rest of the code
COPY . .

# Ensure the server listens on all interfaces inside the container
EXPOSE 8004
CMD ["python3", "server.py", "--host", "0.0.0.0", "--port", "8004"]
