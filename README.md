# htpc-download-box

Personal home server media stack running on `cartman` (192.168.1.20).

Forked from [sebgl/htpc-download-box](https://github.com/sebgl/htpc-download-box).

## Stack

| Service | Hostname | Port | Purpose |
|---|---|---|---|
| traefik | traefik.home.kurup.net | 80/443 | Reverse proxy + TLS |
| homepage | home.kurup.net | 3000 | Service dashboard |
| jellyfin | jellyfin.home.kurup.net | 8096 | Media server |
| sonarr | sonarr.home.kurup.net | 8989 | TV show monitoring and downloads |
| radarr | radarr.home.kurup.net | 7878 | Movie monitoring and downloads |
| prowlarr | prowlarr.home.kurup.net | 9696 | Indexer manager |
| bazarr | bazarr.home.kurup.net | 6767 | Subtitle downloader |
| deluge | deluge.home.kurup.net | 8112 | Torrent downloader (via VPN) |
| sabnzbd | sabnzbd.home.kurup.net | 8080 | Usenet downloader (via VPN) |
| calibre-web | books.home.kurup.net | 8083 | Ebook library UI + OPDS catalog |
| gluetun | — | — | VPN gateway (PureVPN via OpenVPN) |
| grampsweb | grampsweb.home.kurup.net | 5000 | Genealogy app |

## Setup

```bash
cp .env.example .env
# fill in .env values
docker compose up -d
```

## First-run service configuration

Some settings live inside each service's config volume (`$CONFIG_ROOT/<service>/`), which is **not** in this repo and survives across deploys. After a fresh setup you must set these by hand:

- **Deluge download location.** Set both *Download to* and *Move completed to* to `/data/torrents` in the web UI (Preferences → Downloads). The image defaults to `/downloads`, which isn't mounted — downloads will connect to peers but stall at 0% because Deluge can't write the files. `/data/torrents` matches what Sonarr/Radarr see, so completed imports work without remote-path mapping. (Don't work around this by mounting `/downloads` instead — it breaks that path consistency.)
- **VPN P2P location.** `SERVER_COUNTRIES` in `compose.yml` must be a location your VPN provider permits P2P on, or torrents announce fine but never connect to peers.

## Deploy (from laptop)

```bash
make deploy
```

Pushes the latest committed changes to cartman and restarts affected containers. Requires SSH access to `cartman` and the repo cloned at `~/dev/htpc-download-box` on the server.

> **Note:** `.env` is never touched by deploy — manage it manually on cartman.

## Environment Variables

See `.env.example` for all required variables, including:
- `CF_DNS_API_TOKEN` — Cloudflare API token for Traefik TLS certs (create at Cloudflare → My Profile → API Tokens → Edit zone DNS, scoped to `kurup.net`)
- `HOMEPAGE_VAR_*` — API keys for service dashboard widgets

## Ebook Library

Calibre-Web reads from `$MEDIA_ROOT/media/books/`. If you have an existing Calibre library, locate it first:

```bash
find /mnt /home -name "metadata.db" 2>/dev/null
```

Then move it to `$MEDIA_ROOT/media/books/` before starting the `calibre-web` container. On first run, point the setup wizard at `/books/library` (or whichever subdirectory your library is in).
