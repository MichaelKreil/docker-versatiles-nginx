#!/usr/bin/env bash
set -euo pipefail

# Always run from repo root
cd "$(dirname "$0")/../docker"

# Build and load into the local Docker engine; remove --load if you’ll push instead
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --progress=plain \
    --tag versatiles-nginx:latest \
    --load \
    .
