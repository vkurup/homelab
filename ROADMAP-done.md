# Finished Workstreams

Moved here from `ROADMAP.md` when done. Numbers are never reused.

**WS1: Repo Hygiene.** README describes the actual stack; `.env.example` documents the
variables; Vagrantfile and upstream docs removed.

**WS2: Deploy Workflow.** `make deploy` (`bin/deploy.sh`) pulls on cartman and runs
`docker compose up -d`.

**WS3: Books.** Calibre-Web at `books.home.kurup.net`, serving the Calibre library. Readarr
was dropped (retired upstream, 2025). Leftovers moved to WS7 and WS13.

**WS4: Access & Service Portal.** Traefik + Homepage at `*.home.kurup.net`, Let's Encrypt
via Cloudflare DNS challenge. Split DNS: EdgeRouter on the LAN, Cloudflare for Tailscale.

**WS8: Monitoring.** Uptime Kuma → ntfy (`homelab` topic, priority 4, no auth) and Scrutiny.
cartman's own death is caught by a healthchecks.io dead man's switch pinged from a host cron,
not a container. See homebook `docs/runbooks/dead-mans-switch.md`.

**WS10: Container Update Notifications.** diun replaced by Dependabot (weekly, grouped,
14-day cooldown) after pinning every image to a version tag. Exceptions: `scrutiny` and the
life103 stack are unpinned; `gluetun` and `grampsweb` are pinned by digest, because their
`latest` is ahead of their newest tag. See `openspec/changes/pin-images-and-dependabot/`.

**WS11: System Metrics.** Netdata at `netdata.home.kurup.net`, local only. Its data is under
`MEDIA_ROOT`, outside snapshots and backup, because a time-series DB would bloat both.
