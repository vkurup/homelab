# Roadmap

Personal home server stack based on a fork of [htpc-download-box](https://github.com/sebgl/htpc-download-box). Running on `cartman` (192.168.1.20).

---

## WS1: Repo Hygiene ✓

Clean up the repo so it reflects what's actually running, not upstream docs.

- [x] Remove or replace upstream README (references Jackett, NZBGet, Plex — none of which are in use)
- [x] Delete Vagrantfile (not used)
- [x] Stage the `docker-compose.yml → compose.yml` rename
- [x] Restore `.env.example` with placeholder values (was deleted; documents required vars)
- [x] Decide: commit `.claude/` and `openspec/` or gitignore them
- [x] Verify `.gitignore` covers all secrets (`.env` is already there)
- [x] Write a short README that describes the actual stack

---

## WS2: Deploy Workflow ✓

`make deploy` SSHs to cartman, pulls latest commits, and runs `docker compose up -d`. Script lives at `bin/deploy.sh`.

---

## WS3: Books ✓ (partially complete)

**Calibre-Web** is running at `cartman:8083` serving the existing Calibre library from `$MEDIA_ROOT/media/books/library`. OPDS confirmed working at `/opds`.

**Readarr removed** — official project retired June 2025, community fork had SQLite permission issues. Book acquisition is manual for now (upload via Calibre-Web UI).

**Remaining TODOs:**
- Configure Send-to-Kindle email (`Admin → Email settings` in Calibre-Web)
- Verify OPDS with a reader app
- If automated book downloading becomes a priority, evaluate alternatives (e.g. LazyLibrarian)
- Metadata on upload: Google Books requires API key, Goodreads API is shut down. Evaluate alternatives (e.g. enable Calibre binaries + `fetch-ebook-metadata`, or a self-hosted metadata proxy)

---

## WS4: Access & Service Portal ✓

Traefik + Homepage running at `*.home.kurup.net`. TLS via Let's Encrypt + Cloudflare DNS challenge. Split DNS: EdgeRouter for LAN, Cloudflare for Tailscale. Traefik dashboard protected with basicAuth.

**Possible future simplification:** Move Traefik to `network_mode: host` (consistent with all other services) so backend URLs in `config/traefik/dynamic/services.yml` can use `localhost` instead of the hardcoded `192.168.1.20` IP.

**Future:** Consider Pi-hole for network-wide ad blocking + local DNS resolver (replaces EdgeRouter dnsmasq config)

---

## WS5: Backup

Service configs live in `$CONFIG_ROOT` (`/mnt/storage/config`) on cartman. If the server dies without a backup, all UI configuration (indexers, download clients, quality profiles, users, etc.) is lost. Media in `$MEDIA_ROOT` has the same risk.

**Strategy: periodic offsite backup of `$CONFIG_ROOT`**

Config is small (MBs) and changes infrequently — easy to back up. Media is large and replaceable (re-downloadable), so backing it up is optional.

**Options:**
- **rclone to cloud** (Backblaze B2, S3, Google Drive) — good for offsite, cheap for small config dirs
- **rsync to NAS or another machine** — good if you have local storage elsewhere
- **`make backup` target** — rsync `$CONFIG_ROOT` from cartman to laptop on demand

**Suggested tasks:**
- [x] Determine where `/mnt/storage` lives on cartman — local ZFS pool
- [ ] Set up automatic ZFS snapshots via cron (first line of defense, free — protects against accidental deletion/corruption)
- [ ] Decide on offsite backup destination (cloud vs. local — still needed for hardware failure/theft)
- [ ] Add `bin/backup.sh` + `make backup` target (mirrors `$CONFIG_ROOT` off cartman)
- [ ] Schedule backup via cron on cartman or as a periodic manual step

---

## WS6: Claude Code Sandbox

Run Claude Code in an isolated environment so it can't affect the host system outside of intended boundaries (filesystem, network, process access). Useful for running Claude on cartman directly or from the laptop with controlled blast radius.

**Open questions:**
- What should be sandboxed? (filesystem writes, network access, shell commands, all of the above)
- Should the sandbox run on cartman, the laptop, or both?
- Acceptable performance/complexity tradeoff?

**Options to evaluate:**
- **Docker container** — easy to set up, good filesystem/network isolation, Claude Code runs inside
- **VM** (e.g. lima, multipass, UTM) — stronger isolation, more overhead
- **bubblewrap / firejail** — lightweight Linux sandboxing, no VM overhead, Linux-only
- **Claude Code's built-in permission system** — already provides some guardrails (tool approval, path restrictions)

---

## WS7: Automated Book Acquisition

Evaluate a Readarr replacement for automated ebook downloading. Book acquisition is currently manual (upload via Calibre-Web UI).

**Candidates:**
- **[Shelfmark](https://github.com/calibrain/shelfmark)** — newer project, Calibre-aware
- **[LazyLibrarian](https://gitlab.com/LazyLibrarian/LazyLibrarian)** — established, integrates with SABnzbd/NZB indexers and torrent clients

**Suggested tasks:**
- [ ] Evaluate Shelfmark: activity level, amd64 support, Calibre-Web integration
- [ ] Evaluate LazyLibrarian: feature set, usenet support, last release date
- [ ] Pick one and add to compose.yml, wiring to SABnzbd + Calibre library
- [ ] Verify downloaded books appear in Calibre-Web automatically

---

## WS8: Monitoring ✓

Health and performance visibility for the stack.

- [x] Add Uptime Kuma to compose.yml (`uptime.home.kurup.net`) and Homepage dashboard
- [x] Add Scrutiny to compose.yml (`scrutiny.home.kurup.net`) with S.M.A.R.T. disk monitoring

**Post-deploy setup:**
- Uptime Kuma: create monitors for each service via the web UI, then grab the status page slug for the Homepage widget (`slug: default`)
- Scrutiny: verify it detects cartman's drives; if more than `/dev/sda`, add additional `devices:` entries in compose.yml

System metrics (CPU, memory, disk I/O) deferred to WS11.

---

## WS9: Media Requests (Jellyseerr)

Let family request movies and TV shows without needing access to Radarr/Sonarr directly.

**Jellyseerr** sits in front of Radarr/Sonarr and provides a Netflix-style request UI. Family browses available media, submits requests, and Radarr/Sonarr handle the download automatically.

**Suggested tasks:**
- [ ] Add `jellyseerr` service to compose.yml
- [ ] Connect Jellyseerr to Jellyfin (for user auth), Radarr, and Sonarr
- [ ] Add Traefik route (`requests.home.kurup.net` or similar)
- [ ] Add tile to Homepage
- [ ] Invite family members and verify request flow end-to-end

---

## WS11: System Metrics

CPU, memory, disk I/O, and network visibility for cartman.

**Options:**
- **Netdata** — simple, self-contained, minimal config; built-in dashboards
- **Grafana + Prometheus** — more powerful, more complex; better for long-term retention and custom dashboards

**Suggested tasks:**
- [ ] Decide: Netdata vs Grafana stack
- [ ] Add chosen service(s) to compose.yml and Homepage dashboard

---

## WS10: Automatic Container Updates (Watchtower)

Keep containers up to date with security patches without manual intervention.

**Watchtower** monitors running containers and pulls updated images automatically. Can be configured to notify-only (recommended to start) rather than auto-update, so you control when updates are applied.

**Suggested tasks:**
- [ ] Decide: notify-only vs auto-update (notify-only recommended — review updates before applying)
- [ ] Add `watchtower` service to compose.yml scoped to specific containers (exclude grampsweb, calibre-web to avoid breaking changes)
- [ ] Configure notification channel (email or other)

---

## WS12: Swap Deluge → qBittorrent

Replace Deluge with qBittorrent as the torrent client. **Low-stakes** — Usenet (SABnzbd) is the primary downloader, so torrents are a fallback and there's little state worth preserving. Do a clean swap, not a fussy migration.

**Why switch:** native Sonarr/Radarr seed-limit integration (Radarr manages/tracks seeding explicitly instead of inferring it from Deluge's paused state); built-in ratio **and** seed-time limits with no AutoRemovePlus plugin (fixes the "unpopular torrent never hits ratio, so it never gets cleaned up" gap); category→save-path management; a single Web UI password (no Deluge daemon-RPC `localclient` split); and active upstream development. qBittorrent is the de facto default for *arr stacks.

**Constraints / gotchas (read before starting):**
- **Reuse port 8112** for the qBittorrent Web UI (Deluge's old port) — avoids changing gluetun port mappings or Traefik. Do **not** use qBittorrent's default 8080; SABnzbd owns 8080 on gluetun.
- qBittorrent runs behind gluetun (`network_mode: service:gluetun`), same as Deluge. No port forwarding on PureVPN, so incoming connections stay disabled (expected).
- Mount `${MEDIA_ROOT}/torrents:/data/torrents` (same as Deluge) so imports **hardlink** with `/data/media` — keep the save path on the `/data` mount.
- The linuxserver qBittorrent image sets a **random temporary Web UI password on first start** — read it from `docker logs qbittorrent`, then set a real one. (Ships libtorrent 2.x; a `libtorrentv1` image tag exists if compatibility/memory is an issue.)

**Suggested tasks:**
- [ ] Note any private-tracker torrents still seeding in Deluge (e.g. `auctor.tv`) so they can be re-added and kept seeding
- [ ] compose.yml: remove the `deluge` service; add `qbittorrent` (`lscr.io/linuxserver/qbittorrent`, `network_mode: service:gluetun`, volumes `${CONFIG_ROOT}/qbittorrent:/config` + `${MEDIA_ROOT}/torrents:/data/torrents`, env `PUID`/`PGID`/`TZ` + `WEBUI_PORT=8112`); keep gluetun's `8112:8112` mapping
- [ ] Traefik: rename the `deluge` router/service → `qbittorrent` in `config/traefik/dynamic/services.yml`, pointing at `gluetun:8112`
- [ ] Homepage: swap the Deluge tile/widget for qBittorrent in `config/homepage/services.yaml`
- [ ] Deploy; read the temp password from `docker logs qbittorrent`; set a real Web UI password
- [ ] Configure qBittorrent: default save path `/data/torrents`; categories `radarr` and `sonarr`; Share Ratio Limiting = ratio `2.0` **or** seed time (e.g. 14 days) → action **Pause**
- [ ] Radarr & Sonarr: remove the Deluge download client, add qBittorrent (host `127.0.0.1`, port `8112`, matching category); set the now-available Seed Ratio/Time fields; keep **Remove Completed Downloads** on
- [ ] Re-add the noted private-tracker torrents to qBittorrent (add the .torrent/magnet, save to `/data/torrents`, **Force Recheck** → resumes seeding from the existing hardlinked files, no re-download)
- [ ] Verify end-to-end: grab a title → download → import (hardlink, link count 2) → seed → auto-cleanup, Jellyfin copy intact
- [ ] Update README "First-run service configuration" and CLAUDE.md to describe qBittorrent instead of Deluge
- [ ] After a few days of confidence, delete `${CONFIG_ROOT}/deluge` on cartman

**Rollback:** keep `${CONFIG_ROOT}/deluge` until qBittorrent is verified; revert the compose.yml change to bring Deluge back on 8112.
