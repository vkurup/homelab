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

**WS25: Post-Migration Cleanup on cartman** (2026-11-21, homebook). Drift: the swappiness
setting is now laptop only (gone from cartman's `sysctl.conf`), and the HA backups dir is
`root:root`, which the nightly pull keeps setting it to anyway. Packages: cartman lost what
nothing there used: the GUI bits, preload, default-jre, dkms, openvpn, emacs, hugo, cmake,
mplayer, ffmpeg, mpg123, mediainfo, unrar, hdhomerun-config, ledger and Finance::Quote.
Brookfield keeps its copies. The Brother printer install is laptop only (it had failed on
cartman and installed nothing). Mail: root's mail on cartman had been going to an unread
`/var/mail/root` through postfix, including 35 smartd warnings. Now `msmtp-mta` forwards it
through SES, so smartd and failed root cron jobs reach the inbox. The duplicacy
prune/check/B2 jobs run under `cron-quiet`, so a successful run mails nothing.
