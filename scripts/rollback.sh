#!/usr/bin/env bash
set -euo pipefail

: "${PREVIOUS_IMAGE_TAG:?PREVIOUS_IMAGE_TAG is required (e.g. commit SHA)}"

export IMAGE_TAG="${PREVIOUS_IMAGE_TAG}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Rolling back backend to image tag: ${IMAGE_TAG}"
"${SCRIPT_DIR}/deploy-backend.sh"
