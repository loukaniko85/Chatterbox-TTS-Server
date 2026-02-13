#!/bin/bash
# run.sh - Auto-detects GPU and runs the correct Chatterbox container

# Get the GPU name
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1)

if [[ $GPU_NAME == *"1650"* ]]; then
    echo "Detected GTX 1650S. Pulling 1650s optimized image..."
    IMAGE_TAG="1650s"
elif [[ $GPU_NAME == *"5060"* ]]; then
    echo "Detected RTX 5060 Ti. Pulling Blackwell optimized image..."
    IMAGE_TAG="5060ti"
else
    echo "Unknown GPU: $GPU_NAME. Defaulting to 1650s (safe mode)."
    IMAGE_TAG="1650s"
fi

docker pull ghcr.io/loukaniko85/chatterbox-tts-server:$IMAGE_TAG
docker run --gpus all -p 8004:8004 ghcr.io/loukaniko85/chatterbox-tts-server:$IMAGE_TAG
