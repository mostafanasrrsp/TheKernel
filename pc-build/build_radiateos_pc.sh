#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "[RadiateOS][PC] Building Electron preview (Linux AppImage)"
docker build -t radiateos-pc:latest -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR"
echo "[RadiateOS][PC] Build complete. Artifacts in Docker image at /app/pc-preview/dist"
echo "[RadiateOS][PC] To extract artifacts:"
echo "  docker create --name rospc radiateos-pc:latest >/dev/null"
echo "  docker cp rospc:/app/pc-preview/dist ./dist && docker rm rospc >/dev/null"

