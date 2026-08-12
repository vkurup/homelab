#!/usr/bin/env bash
set -euo pipefail

# See bin/deploy.sh: "cartman" goes over Tailscale SSH, which periodically wants an
# interactive browser check and waits instead of failing when it cannot get one.
HOST="${DEPLOY_HOST:-cartman}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10)

if ! ssh "${SSH_OPTS[@]}" "$HOST" true 2>/dev/null; then
  echo "Can't open a non-interactive SSH session to $HOST." >&2
  echo "Authenticate once with 'ssh $HOST true', or use:" >&2
  echo "    DEPLOY_HOST=vinod@192.168.1.20 make update" >&2
  exit 1
fi

REPO_PATH="$HOME/dev/homelab"

ssh "${SSH_OPTS[@]}" "$HOST" bash -s -- "$REPO_PATH" <<'EOF'
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
