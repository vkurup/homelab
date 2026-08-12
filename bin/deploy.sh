#!/usr/bin/env bash
set -euo pipefail

# "cartman" resolves over the tailnet, and Tailscale SSH periodically requires an
# interactive browser re-auth. It does not refuse the connection when it cannot get one --
# it waits, indefinitely, so a deploy appears to hang rather than fail. Set DEPLOY_HOST to
# the LAN address (vinod@192.168.1.20) to use ordinary sshd with your key instead.
HOST="${DEPLOY_HOST:-cartman}"
REPO_PATH="$HOME/dev/homelab"

# BatchMode turns "waiting forever for a login nobody will perform" into an immediate
# error naming the problem. ConnectTimeout covers the host simply being unreachable.
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10)

if ! ssh "${SSH_OPTS[@]}" "$HOST" true 2>/dev/null; then
  echo "Can't open a non-interactive SSH session to $HOST." >&2
  echo >&2
  echo "If this is Tailscale SSH asking for a browser check, either authenticate once:" >&2
  echo "    ssh $HOST true" >&2
  echo "or deploy over the LAN, which uses your key and needs no check:" >&2
  echo "    DEPLOY_HOST=vinod@192.168.1.20 make deploy" >&2
  exit 1
fi

# Pass REPO_PATH as a positional arg so the quoted heredoc has a clear
# expansion boundary: nothing inside <<'EOF' expands on the local machine.
ssh "${SSH_OPTS[@]}" "$HOST" bash -s -- "$REPO_PATH" <<'EOF'
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
