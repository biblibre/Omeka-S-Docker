#!/bin/bash

# Load build arguments from file
if [ $# -ne 2 ]; then
  echo "Usage: $0 <config-file> <image-tag>"
  echo "Example: $0 .env.build omeka-s-docker:1.0.1"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "Error: Config file '$1' not found"
  exit 1
fi

CONFIG_FILE="$1"
IMAGE_TAG="$2"

# Load configuration
source "$CONFIG_FILE"

# Enable BuildKit
export DOCKER_BUILDKIT=1

# check if OMEKA_S_VERSION is set
if [ -z "$OMEKA_S_VERSION" ]; then
  echo "Error: OMEKA_S_VERSION is not set in the config file"
  exit 1
fi

# check if PHP_VERSION is set
if [ -z "$PHP_VERSION" ]; then
  echo "Error: PHP_VERSION is not set in the config file"
  exit 1
fi

# Build with SSH forwarding
docker build \
  --ssh default \
  --build-arg OMEKA_S_VERSION="${OMEKA_S_VERSION}" \
  --build-arg PHP_VERSION="${PHP_VERSION}" \
  --build-arg OMEKA_S_MODULES="${OMEKA_S_MODULES:-}" \
  --build-arg OMEKA_S_THEMES="${OMEKA_S_THEMES:-}" \
  --target prod \
  -t "$IMAGE_TAG" \
  .
