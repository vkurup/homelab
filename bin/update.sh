#!/usr/bin/env bash
set -euo pipefail

HOST="cartman"
REPO_PATH="$HOME/dev/homelab"

ssh "$HOST" bash -s -- "$REPO_PATH" <<'EOF'
set -euo pipefail
REPO_PATH="$1"
cd "$REPO_PATH"

echo "Pulling latest images..."
docker compose pull

echo ""
echo "Restarting updated containers..."
docker compose up -d
echo "Done."
EOF
