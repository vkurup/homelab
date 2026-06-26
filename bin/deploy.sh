#!/usr/bin/env bash
set -euo pipefail

HOST="cartman"
REPO_PATH="$HOME/dev/homelab"

# Pass REPO_PATH as a positional arg so the quoted heredoc has a clear
# expansion boundary: nothing inside <<'EOF' expands on the local machine.
ssh "$HOST" bash -s -- "$REPO_PATH" <<'EOF'
set -euo pipefail
REPO_PATH="$1"
cd "$REPO_PATH"

if [ -n "$(git status --porcelain)" ]; then
  echo "WARNING: working tree has uncommitted changes:"
  git status --short
  echo ""
fi

git pull --ff-only

echo "Deployed: $(git log -1 --oneline)"
echo ""
echo "Starting containers..."
docker compose up -d
echo "Done."
EOF
