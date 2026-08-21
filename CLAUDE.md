# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A homelab stack running on `cartman` (192.168.1.20): automated media download/playback plus supporting services (reverse proxy, dashboard, monitoring, genealogy). All services on cartman run as containers via `compose.yml`. The full service list with hostnames and ports lives in `README.md` — keep that table as the source of truth rather than duplicating it here.

Home Assistant is **not** part of this stack — it runs on a separate Raspberry Pi (HAOS). This repo only carries its Traefik route, Homepage tile, and `docs/runbooks/home-assistant.md`.

## Common Commands

```bash
# Start all services
docker compose up -d

# Start a specific service
docker compose up -d sonarr

# View logs for a service
docker compose logs -f <service>

# Restart a service
docker compose restart <service>

# Stop everything
docker compose down
```

## Environment Variables

Copy `.env.example` to `.env` and fill in values. The `.env` file is gitignored and never committed — `.env.example` is the authoritative list of required variables (paths, PUID/PGID, VPN credentials, `CF_DNS_API_TOKEN` for Traefik TLS, `HOMEPAGE_VAR_*` API keys).

## Architecture

All cartman services are defined in `compose.yml`. Networking:

**Behind VPN (gluetun network):** `deluge` and `sabnzbd` run with `network_mode: service:gluetun`. Their ports are exposed on the gluetun container (8112 for Deluge web UI, 8080 for SABnzbd).

**Host network:** most other services (`sonarr`, `radarr`, `bazarr`, `jellyfin`, `homepage`, `calibre-web`, `uptime-kuma`) use `network_mode: host`.

**DNS — bridge containers go stale after a host DNS change.** Docker writes a container's
`/etc/resolv.conf` when the container **starts**, from the host's resolver config at that
moment. Bridge-network containers therefore keep a stale resolver indefinitely after DNS
changes on cartman; host-network containers are unaffected because they use the host resolver
live. A plain `docker restart <name>` is enough to pick up the new config — recreation is not
required. `gluetun` is immune: it runs its own DoT resolver, so it and the containers sharing
its netns (`deluge`, `sabnzbd`) keep working regardless.

This is worth knowing because it does not look like a DNS problem. In Aug 2026 the host DNS
was fixed but long-running containers kept pointing at a resolver that had stopped answering:
Prowlarr lost DNS, so every indexer query failed, so **Radarr** reported "All indexers are
unavailable" — a fault in one container surfacing as an error in another, with `docker ps`
showing everything `Up`. Traefik was silently affected too, which would have broken the
Cloudflare DNS-01 cert renewal a month later.

To check: `docker exec <name> grep ExtServers /etc/resolv.conf` — compare against a freshly
started container. Host-side DNS is documented in the homebook repo
(`docs/runbooks/dns.md`).

**Traefik** (`config/traefik/`, version-controlled) fronts everything as `*.home.kurup.net` with a Let's Encrypt wildcard cert (Cloudflare DNS challenge). LAN + Tailscale only — nothing is internet-facing. Homepage config is in `config/homepage/` (version-controlled; secrets injected via `HOMEPAGE_VAR_*` env vars).

### Directory Layout (inside containers)

Media containers mount `MEDIA_ROOT` as `/data`, with the expected layout:
```
$MEDIA_ROOT/
  media/
    movies/
    tv/
  torrents/
  usenet/
  gramps/
$CONFIG_ROOT/
  <service-name>/   # per-service config persisted here
```

### Manual Configuration Not Captured in compose.yml

Some service settings live in `$CONFIG_ROOT/<service>/` (persisted volumes, **not** version-controlled) and must be set by hand after a fresh deploy. These are documented for humans under **"First-run service configuration"** in `README.md` — keep that section as the source of truth. Notably: Deluge's `download_location`/`move_completed_path` must be `/data/torrents` (not the image default `/downloads`, which isn't mounted), or torrents connect to peers but stall at 0%. Do not "fix" this by mounting `/downloads` — it breaks the path consistency Sonarr/Radarr rely on.