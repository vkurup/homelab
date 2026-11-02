# Shotwell runbook

How the photo library is curated on cartman until Immich replaces it (ROADMAP WS14).

## Overview

- **What:** Shotwell, the GTK photo manager, running on cartman next to the library. Its
  window is shown on brookfield over **waypipe**. Nothing in `compose.yml`, and cartman has
  no desktop installed.
- **Why this way:** cartman was rebuilt on 2026-11-01 as a headless TerraMaster F4-424 Pro.
  Before that, Shotwell ran on cartman's own desktop with a monitor attached. Running
  Shotwell remotely keeps the library, its database and the photo files on one machine,
  and needs no screen on the server.
- **Workflow it supports:** new photos arrive in `~/Sync` (syncthing from the phones),
  are reviewed and moved into `~/Pictures`, imported into Shotwell, and grouped into
  monthly albums that go to Shutterfly.
- **Interim.** WS14 replaces all of this with Immich.

## Where things live

| What                  | Path on cartman                                                   |
|-----------------------|-------------------------------------------------------------------|
| Photo files           | `/home/vinod/Pictures`: ZFS dataset `vkstoragepool/Pictures`      |
| Library database      | `~/.local/share/shotwell/data/photo.db` (on the NVMe, in `/home`) |
| Incoming, from phones | `~/Sync`                                                          |

**Shotwell stores each photo's absolute path in `photo.db`.** The library only opens
intact because the migration mounted the photo dataset at the *same* path,
`/home/vinod/Pictures`. Never move the library or remount it elsewhere without rewriting
those paths. Spot-check:

```bash
sqlite3 ~/.local/share/shotwell/data/photo.db 'select filename from PhotoTable limit 3'
```

**Backup: neither the photos nor the library is backed up.** homebook's
`files/duplicacy-filters` excludes `-home/*/Pictures/*` and `-home/*/.local/*`, so
duplicacy skips both the photo files and `photo.db` (albums, tags, edits). The ZFS mirror
protects against a dead disk, not against deletion or a lost machine. Until WS14's backup
step, Google Photos is the only off-site copy of the photos, and **nothing** holds a copy
of the Shotwell library.

## Setup

```bash
# cartman: Shotwell and its GTK libraries only, no desktop session
sudo apt install shotwell waypipe sqlite3

# brookfield
sudo apt install waypipe
```

`waypipe` has to be installed at both ends: it runs as the Wayland compositor's proxy on
brookfield and as a fake compositor on cartman. brookfield runs a Wayland session, which
it requires.

## Use

From brookfield:

```bash
waypipe ssh cartman shotwell
```

The window opens on brookfield's screen. Shotwell runs on cartman, so imports, thumbnail
generation and exports all happen next to the files, not over the network.

If browsing full-size photos is slow (brookfield is on WiFi), try stronger compression:
`waypipe --compress zstd ssh cartman shotwell`. Check `waypipe --help` for the exact
option names in the installed version.

Getting files back to brookfield, for example to upload an album to Shutterfly from the
browser: export the album to a folder under `~/Sync` (it syncs), or
`scp -r cartman:<export dir> .`.

## Fallback

If waypipe over WiFi is too slow for reviewing photos: install a minimal desktop on
cartman, connect it to the TV's second HDMI input, and share the gaming PC's keyboard and
mouse with a 2-port HDMI KVM switch. It is the same Shotwell and library, used locally.
