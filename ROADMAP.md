# Roadmap

Home server stack on `cartman` (192.168.1.20). Finished workstreams move to
[ROADMAP-done.md](ROADMAP-done.md) (WS1-4, 8, 10, 11, 25); numbers are never reused.

**Order (decided 2026-11-08, a few hours a week):** first protection: WS23, WS17, WS5.
Then WS14. The rest after, one project at a time; the small ones (WS9, WS12, WS16) fit
between big ones. What matters most to keep: home video, then photos, then `~/Sync`.

---

## WS5: Backup

duplicacy (homebook) backs up cartman, brookfield and Home Assistant hourly to wdmybook4tb
and daily to B2. See homebook `docs/runbooks/duplicacy-backup.md`.

- [ ] **Fix the mpuri001 Gmail backup.** offlineimap fails with "Invalid credentials" and
      hasn't synced since 2021-12-14 (cron sends its output to `/dev/null`). Decided
      2026-11-19: keep the account. Generate a new Gmail app password for mpuri001, put it in
      the vault as `SECRET_IMAP_GMAIL_PASSWORD_MALA` (what `offlineimaprc` reads for this
      account), then add it to the offlineimap healthchecks.io ping (WS23)

---

## WS6: Claude Code Sandbox

Run Claude Code where it can't affect the host beyond intended limits.

- [ ] Decide what to isolate (files, network, commands) and where (cartman, brookfield)
- [ ] Pick one: Docker container, VM, bubblewrap/firejail, or Claude Code's own permissions

---

## WS7: Automated Book Acquisition

Replace Readarr for ebook downloads (currently uploaded by hand in Calibre-Web).

- [ ] Evaluate [Shelfmark](https://github.com/calibrain/shelfmark) and
      [LazyLibrarian](https://gitlab.com/LazyLibrarian/LazyLibrarian)
- [ ] Add the winner to compose.yml, wired to SABnzbd and the Calibre library
- [ ] Verify new books appear in Calibre-Web
- [ ] Metadata on upload (Google Books needs an API key; Goodreads' API is gone)

---

## WS9: Media Requests (Jellyseerr)

Let the family request movies and shows without Radarr/Sonarr access.

- [ ] Add `jellyseerr` to compose.yml; connect Jellyfin (auth), Radarr, Sonarr
- [ ] Traefik route and Homepage tile
- [ ] Invite the family; test a request end to end

---

## WS12: Swap Deluge → qBittorrent

Torrents are only a fallback to SABnzbd, so do a clean swap, not a migration. qBittorrent
has native *arr seed limits and ratio **and** seed-time limits (no AutoRemovePlus).

Gotchas: Web UI on **8112** (Deluge's port; SABnzbd owns 8080 on gluetun). Runs as
`network_mode: service:gluetun`. Mount `${MEDIA_ROOT}/torrents:/data/torrents` so imports
hardlink. First start sets a random password: see `docker logs qbittorrent`.

- [ ] Note private-tracker torrents still seeding in Deluge (e.g. `auctor.tv`)
- [ ] compose.yml: replace `deluge` with `lscr.io/linuxserver/qbittorrent` (`WEBUI_PORT=8112`)
- [ ] Rename the Traefik router (`config/traefik/dynamic/services.yml`) and Homepage tile
- [ ] Set a real password; save path `/data/torrents`; categories `radarr`, `sonarr`; ratio
      2.0 or 14 days seeding → Pause
- [ ] Radarr/Sonarr: swap the download client (`127.0.0.1:8112`), set seed limits
- [ ] Re-add the private-tracker torrents and Force Recheck
- [ ] Test grab → import (hardlink) → seed → cleanup; update README and CLAUDE.md
- [ ] Delete `${CONFIG_ROOT}/deluge` after a few days (until then it's the rollback)

---

## WS13: Family Ebook Library

Make Calibre-Web usable by all five of us. Every device is a Kindle or the Kindle app, so
Send-to-Kindle email is the delivery path.

- [ ] Send-to-Kindle email in Calibre-Web (SMTP relay; sender approved in each Amazon account)
- [ ] An account per person, each with their Kindle address
- [ ] The college kid's devices on the tailnet; test from off the LAN
- [ ] A short "how to get a book" note for the family

---

## WS14: Photos — Replace Google Photos (Immich)

Make cartman the primary home for family photos, then leave Google Photos. **Before
starting, run `/grill-me` on this plan.**

The library is `~/Pictures` (413G, dataset `vkstoragepool/Pictures`, Shotwell, viewed over
waypipe: `docs/runbooks/shotwell.md`). Neither it nor the Shotwell library
(`~/.local/share/shotwell`) is backed up: Google Photos is the only other copy.

Decided: Immich, importing into Immich-managed storage on the pool with `immich-go`; the
Immich app replaces Syncthing for phone photos; shared links for people without accounts;
pin the version. **Google stays on until a B2 restore is verified.**

- [ ] Backup first: snapshots and duplicacy → B2 for the photo data (with WS17)
- [ ] Immich stack in compose.yml (server, ML, Postgres with vectors, Redis), `/dev/dri`
- [ ] Traefik route (`photos.home.kurup.net`) and Homepage tile
- [ ] Five accounts; partner sharing / family albums
- [ ] Import `~/Pictures` (optionally merge a Takeout for albums); check counts and dates
- [ ] Immich app with auto-backup on all five phones, over the tailnet
- [ ] Test-restore the photos from B2
- [ ] Retire the camera folders in Syncthing and the Shotwell workflow; then downgrade Google

---

## WS15: Home Assistant Buildout

Design and live state: [docs/runbooks/home-assistant.md](docs/runbooks/home-assistant.md).
Constraints: as local as possible, and everything still works physically if HA is down.

- [ ] **Foundation:** all five as Persons, Companion app on every phone (presence)
- [ ] **Security:** Reolink person/vehicle/package alerts to phones; Zigbee door and motion
      sensors, gated on away mode
- [ ] **Smart plugs** on lamps, keeping physical control
- [ ] **Local voice** last (Voice PE or Whisper/Piper)
- [ ] Check the hardware: Zigbee/Z-Wave stick model, the unboxed smart plugs; assign the
      kitchen devices

---

## WS16: Read-Later Archive (Readeck)

Save articles from phones, archived in full on cartman. Single binary on SQLite.

- [ ] Add `readeck` to compose.yml, data in `${CONFIG_ROOT}/readeck`
- [ ] Traefik route and Homepage tile
- [ ] Saving from phones over the tailnet; accounts for whoever wants one

---

## WS17: Storage Plan for the Rebuilt Pool

Make protection deliberate. Classes: **irreplaceable** (snapshots + duplicacy → B2),
**re-downloadable** (nothing), **scratch** (nothing). Decided: home video and photos go to B2
through duplicacy (about +$7/month). Google Takeout is itself the local copy: no backup. wdmybook4tb
(local duplicacy storage, ~7.5 years powered on) is replaced when it fails, not before.

| Dataset | What | Snapshots | duplicacy → B2 |
|---|---|---|---|
| `config` | service state | yes | yes |
| `data` | media | no | only `media/homevideos` |
| `Pictures` | photos, 413G | yes | **no** (WS14) |
| `Music` | 29G | yes | yes |
| `home-backup` | `~/backup`, 63G | yes | yes |
| `archive` | google-takeout (1.1T), vpkurup-recovery (36G), movies (694G) | after WS18 | **no** |
| `backup` | empty leftover | | |

- [x] Confirm the classes. `~/backup` goes to B2: `gmail` (58G) is the offlineimap mirror,
      `backup-acorn` (5.9G) is the only copy; ~$0.40/month
- [x] Snapshots for irreplaceable datasets (Pictures, Music, home-backup since 2026-11-21;
      `archive` after its cleanup, WS18)
- [ ] duplicacy for `archive/movies`, Pictures and the Shotwell library (about 1.2T more in B2).
      Runs are flock'd. Phase 1, Pictures + Shotwell (413G), deployed 2026-11-21; add
      `+mnt/storage/archive/` and `+mnt/storage/archive/movies/*` (703G) once it's in B2
- [ ] Check `duplicacy2` on wdmybook3tb holds nothing unique, then let it go
- [ ] Verify the rescue copies, then retire wdmybook3tb (2,164 pending sectors)
- [ ] Delete the empty `backup` dataset
- [ ] Sort through `archive/vpkurup-recovery`
- [ ] Renew the Takeout schedule by Nov 2027 (a quarterly reminder mail runs)

---

## WS18: Home Videos

Consolidate `media/homevideos` (88G, backed up) and `archive/movies` (694G, not backed up),
which probably overlap.

- [ ] Inventory both and find duplicates
- [ ] Decide the layout (own dataset, irreplaceable per WS17; raw vs edited) and processing
- [ ] Back up the consolidated library, then drop the duplicates
- [ ] Once `archive` cleanup is done (this and `vpkurup-recovery`), opt `archive` into ZFS
      snapshots in homebook (left off so deletes aren't pinned for 12 months)

---

## WS19: Review How Syncthing Is Used

Folders: Vinod's Dropbox (`~/Sync/Vinod`) and one camera folder per family member. Nothing in
`~/Sync` is backed up or versioned, yet cartman's cron jobs depend on `~/Sync/Vinod`.

- [ ] Decide what each folder is for and who should have it
- [ ] Camera folders: retire once Immich (WS14) replaces them
- [ ] Protect what stays: duplicacy for `~/Sync/Vinod` and/or file versioning on cartman
- [ ] Remove retired devices (giannis, kenny); decide about drkurup.com (do1); Kavi's
      phone hasn't connected for months
- [ ] Use `~/Sync/Shared` or drop it from the playbook

---

## WS20: Bring Back the 99-Day Signal

`~/dev/ninety-nine` mails a daily buy/sell signal from SPY's 99-day highs. It's Python 2 with
Alpha Vantage, and its cron job is disabled.

- [ ] Pick a free daily SPY price source (Stooq, Tiingo, yfinance)
- [ ] Port to Python 3 with uv; drop the pickle (or refetch ~200 days each run)
- [ ] Decide where it runs (cartman cron or a container here), then re-enable it
- [ ] Drop `alpha_vantage_api_key` from the vault and `~/.cron-secrets.env`

---

## WS21: Camera Video Sweep Without Ruby

`video-mv` (`~/Sync/Vinod/bin`) moves videos out of the camera folders before a Shotwell
import, renamed `YYYY-MM-DD-HH-MM-SS-<person>-<file>`. It replaced `video-mv.rb` (cartman
has no Ruby).

- [x] Remove the `~/movies` symlink (it points at the failing wdmybook3tb)
- [x] Rewrite in bash or stdlib Python: same naming, all folders, dry-run mode; destination
      `archive/movies/new` until WS18 decides. Now `video-mv` (stdlib Python, names by mtime)
- [ ] Retire it when Immich (WS14) replaces the camera folders

---

## WS22: Review the Python Tooling

pyenv + pyenv-virtualenv and direnv's `layout pyenv` (all 14 `.envrc` in `~/dev`) date from
years ago; asdf overlaps; the Mac moved to mise. It broke on 2026-11-08 when a Mac dotfiles
change dropped pyenv from `.bash_profile`.

- [ ] Choose: uv (versions, venvs, lockfiles, `uv tool install`) and/or mise (replaces pyenv
      and asdf, as on the Mac)
- [ ] Pick the matching direnv pattern; migrate the `.envrc` files, homebook first
- [ ] Update homebook's vinod role and the dotfiles to match on Linux and macOS
- [ ] Remove unused Python versions
- [ ] cartman needs neither pyenv nor asdf. It has no Python projects (just the old
      3.7.0/3.9.0 and virtualenvs copied from the Hitachi), and ansible runs from brookfield.
      So keep the pyenv install and its -dev build libraries to laptops, or replace them with
      uv on both (checked 2026-11-22: 13 of 14 `.envrc` still use `layout pyenv`; only
      my-servers uses uv)

---

## WS23: Catch Silent Failures

Most scheduled jobs fail silently: HA backups failed from June to Nov 2026, mpuri001 since
2021, and a stalled B2 copy went unnoticed. Alerts go by email.

- [x] A healthchecks.io check per scheduled job on cartman that nothing else watches; ping
      on success, so a failure, a missed run or a hang alerts. Free tier: 20 checks. Pattern
      and list: homebook `docs/runbooks/duplicacy-backup.md` ("healthchecks.io pings")
  - [x] duplicacy hourly backup, `duplicacy check`, B2 copy, HA pull (the staleness check
        can't see a failed pull: the backup after it succeeds on stale files)
  - [x] pinboard (now verifies the download; an API error used to overwrite the backup)
  - [x] offlineimap, vvkurup only; mpuri001 joins after WS5's new app password (drop
        `-a vvkurup` from the cron job)
  - Skipped on purpose: both prunes (no data lost when one fails) and the HA duplicacy
    backup (the staleness check covers it)
- [x] brookfield stays on the staleness check, with a grace period that survives a vacation.
      Done as: stale = online on the tailnet 24h+ after its last backup, plus a 14-day
      backstop (homebook `files/duplicacy-staleness-check`)
- [ ] Scrutiny alerts by email (SMART changes on the pool and USB disks)
- [x] Monthly `ansible-playbook --check` on cartman (no `--diff`), reporting to healthchecks,
      so playbook drift shows up within a month; brookfield gets a manual run after upgrades.
      Done as homebook `bin/drift-check`, run by hand from brookfield: a timer can't reach
      cartman without a passphrase-less sudo-capable key, so the check (30 days + 7 grace)
      is the reminder. Check mode now reports changed=0 when nothing has drifted

---

## WS24: Pick the Best Photos for Shutterfly

A separate pass after the regular sweep (`docs/runbooks/shotwell.md`, "Processing new
photos"): review the library, pick the best photos, and upload them to Shutterfly, today
from monthly albums in Shotwell exported over waypipe.

- [ ] Write down the current flow as it is (how picks are marked, album per month or per
      book, export settings, upload from brookfield's browser) in the Shotwell runbook
- [ ] Decide where it lives once WS14 lands: Shotwell albums now vs. Immich albums or
      favorites later, so the effort isn't spent twice
- [ ] Make the export-to-brookfield step one command (or an Immich download)
- [ ] Pick a cadence (monthly?) and add it to the processing runbook

---

## WS26: Backup Storage Trends

The daily duplicacy jobs went quiet in WS25 (`cron-quiet`; output only on failure). Their
reports were also how storage size got checked now and then. Today that means reading
`/var/log/duplicacy-check.log` on cartman, which holds only the latest run and no history.

- [ ] Decide what to track: per-client snapshot size and unique chunk bytes (from
      `duplicacy check -stats`), the storage's total size and free space on wdmybook4tb, and
      B2 bucket size (cost)
- [ ] Record it daily. Simplest: append one line per run to a CSV. Or push it to Netdata
      (already running, local only) or Uptime Kuma
- [ ] Look at it: a small page or chart, or a monthly summary mail (root's mail now reaches
      the inbox)
- [ ] Optional: alert on a jump (a sudden large backup, as in the May 2026 1.6TB incident) or
      on free space dropping below a threshold

---

## Someday / Maybe

- **Audiobookshelf:** audiobooks and podcasts, on the same `/data` layout (maybe with WS13)
- **Frigate:** local NVR for more cameras, feeding HA (with WS15)
- **Replace Alexa:** decide in WS15's local-voice step
- **Replace Amazon Music:** e.g. Navidrome, plus where the library comes from
- **Traefik on host networking:** backends could use `localhost` instead of `192.168.1.20`
- **Pi-hole:** ad blocking and local DNS in place of the EdgeRouter's dnsmasq
- **Netdata alarms to ntfy:** resource trends; its defaults are chatty
