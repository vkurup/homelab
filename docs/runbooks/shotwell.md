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

## Processing new photos

The regular sweep of the camera folders into the library. The phones' Syncthing folders
are **send-only**, so deleting files on cartman never deletes them on the phones (only on
other receivers), which is what we want. Vinod's photos are already in Google Photos;
everyone else's go to a "Miscellaneous YYYY" album there.

`ssh cartman` triggers a Tailscale SSH browser check; from home, `192.168.1.20` skips it.

### 1. Move videos out (cartman)

```bash
~/Sync/Vinod/bin/video-mv -n   # dry run
~/Sync/Vinod/bin/video-mv      # to /mnt/storage/archive/movies/new
```

Then record the batch, so photos that sync in mid-session wait for next time:

```bash
find ~/Sync/Cameras/*/Camera -maxdepth 1 -type f -name '*.jpg' > ~/photo-batch.txt
```

### 2. Import each camera (brookfield)

`waypipe ssh 192.168.1.20 shotwell`, then **File → Import From Folder…** →
`~/Sync/Cameras/<Person>/Camera` → **Copy Photos** (never "import in place": step 4 deletes
the originals). One camera at a time. The import is recursive, so clear out junk
subfolders first (Avik's phone has `Camera/thumbnails/`).

### 3. Tag and cull

Delete bad photos to Shotwell's Trash, then **empty the Trash and delete the files**, so
they are gone from `~/Pictures` and not uploaded in step 5.

### 4. Delete the batch from Sync (cartman)

```bash
xargs -d '\n' rm -v < ~/photo-batch.txt
```

### 5. Upload everyone but Vinod to "Miscellaneous YYYY"

Gather the kept photos into `~/upload` on cartman, one of two ways:

- **No edits in Shotwell (the usual case):** copy the originals, found by name.

  ```bash
  mkdir -p ~/upload && grep -v '/Cameras/Vinod/' ~/photo-batch.txt | while read -r f; do
    m=$(find ~/Pictures/$(date +%Y) -name "$(basename "$f")" -print -quit)
    [ -n "$m" ] && cp -p "$m" ~/upload/
  done
  ```

  Adjust the year if the batch spans a new year.

- **Rotated, cropped or adjusted photos:** Shotwell keeps edits in `photo.db`, not in the
  file, so originals would upload unedited. Select those people's photos in Shotwell and
  use **File → Export…**, format **Current**, to `~/upload` (the dialog browses cartman).

Then on brookfield:

```bash
scp -r 192.168.1.20:upload ~/
```

Drag `~/upload` into the album on photos.google.com. When the upload finishes, remove
`~/upload` on both machines and `~/photo-batch.txt` on cartman.

The separate "pick the best for Shutterfly" flow isn't written up yet.

## Fallback

If waypipe over WiFi is too slow for reviewing photos: install a minimal desktop on
cartman, connect it to the TV's second HDMI input, and share the gaming PC's keyboard and
mouse with a 2-port HDMI KVM switch. It is the same Shotwell and library, used locally.
