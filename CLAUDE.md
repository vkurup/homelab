# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Docker Compose stack for an automated media download and playback setup. All services are run as containers using `compose.yml`.

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

Copy `.env.example` to `.env` and fill in values. The `.env` file is gitignored and never committed. Required variables:

| Variable | Description |
|---|---|
| `TZ` | Timezone string (e.g. `America/New_York`) |
| `PUID` / `PGID` | User/group IDs (`id $USER`) |
| `MEDIA_ROOT` | Where media data is stored (e.g. `/mnt/storage/data`) |
| `CONFIG_ROOT` | Where service configs are persisted (e.g. `/mnt/storage/config`) |
| `OPENVPN_USER` / `OPENVPN_PASSWORD` | PureVPN credentials for gluetun |
| `UPDATER_PERIOD` | How often gluetun updates server list (e.g. `24h`) |

## Architecture

All services are defined in `compose.yml`. The stack has two networking modes:

**Behind VPN (gluetun network):** `deluge` and `sabnzbd` run with `network_mode: service:gluetun`. Their ports are exposed on the gluetun container (8112 for Deluge web UI, 8080 for SABnzbd).

**Host network:** `sonarr`, `radarr`, `bazarr`, `prowlarr`, `jellyfin` use `network_mode: host` and are accessible directly.

### Services and Ports

| Service | Port | Purpose |
|---|---|---|
| gluetun | — | VPN gateway (PureVPN via OpenVPN) |
| deluge | 8112 | Torrent downloader (via VPN) |
| sabnzbd | 8080 | Usenet downloader (via VPN) |
| prowlarr | 9696 | Unified indexer manager for Sonarr/Radarr |
| sonarr | 8989 | TV show monitoring and download orchestration |
| radarr | 7878 | Movie monitoring and download orchestration |
| bazarr | 6767 | Automatic subtitle downloader |
| jellyfin | 8096 | Media server (replaces Plex in this setup) |
| grampsweb | 5000 | Genealogy web app (unrelated to media stack) |

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

Some service settings live in `$CONFIG_ROOT/<service>/` (persisted volumes, **not** version-controlled) and must be set by hand after a fresh deploy:

- **Deluge download location must be `/data/torrents`.** The linuxserver image defaults `download_location` (and `move_completed_path`) to `/downloads`, which is **not** mounted — torrents will connect to peers but stall at 0% because libtorrent can't write the files. Set both to `/data/torrents` (the mount of `$MEDIA_ROOT/torrents`) via the web UI (Preferences → Downloads) or `deluge-console`. This path also matches what Sonarr/Radarr see (`/data/torrents`), so no remote-path mapping is needed. Don't "fix" this by mounting `/downloads` — that would break the path consistency Sonarr/Radarr rely on.

### Key Differences from README

The `compose.yml` in this repo diverges from the README in several ways:
- **gluetun** replaces the old `dperson/openvpn-client` VPN container
- **SABnzbd** replaces NZBGet as the usenet downloader
- **Prowlarr** replaces Jackett as the indexer aggregator
- **Jellyfin** replaces Plex as the media server
- Sonarr/Radarr mount all of `MEDIA_ROOT` as `/data` (rather than separate tv/movies mounts)
