## 1. Inventory (done 2026-09-12, read from 192.168.1.20)

Note: `ssh cartman` goes over Tailscale and hangs on a browser check. Use the LAN address.

| Service | Current tag | Running version | Pin to |
|---|---|---|---|
| sonarr | `:latest` | 4.0.19.2979-ls322 | `4.0.19` |
| radarr | `:latest` | 6.3.0.10514-ls314 | `6.3.0` |
| bazarr | (none) | v1.6.0-ls361 | `1.6.0` |
| prowlarr | `:nightly` | 2.6.2.5583-ls12 | see section 3 |
| deluge | `:latest` | 2.2.0-ls382 | `2.2.0` |
| sabnzbd | `:latest` | 5.1.2-ls270 | `5.1.2` |
| jellyfin | `:latest` | 10.11.11ubu2604-ls46 | `10.11.11` |
| calibre-web | `:latest` | 0.6.27-ls398 | `0.6.27` |
| homepage | `:latest` | v2.1.2 | `v2.1.2` |
| netdata | `:stable` | 2.11.0 | `v2.11.0` |
| ntfy | `:latest` | digest matches `v2.28.0` | `v2.28.0` |
| gluetun | (none) | unresolvable | `latest@sha256:e8be55ff` |
| grampsweb | `:latest` | unresolvable | `latest@sha256:496a97ad` |
| traefik | `:v3.3` | v3.3.7 | `v3.3.7` |
| uptime-kuma | `:1` | 1.23.17 | `1.23.17` |
| postgis | `:17-3.5` | PG 17.5 | leave, no patch tag published |
| scrutiny | `:master-omnibus` | no version published | leave, untracked |
| life103-backend | `:latest` | own image | leave, by choice |
| life103-apk | `nginx:alpine` | n/a | leave, by choice |

- [x] 1.1 Resolve `gluetun` and `grampsweb`. Both carry no usable version label, and their
      running `latest` digest matches **no** published version tag, so `latest` is built
      separately from the release tags. Decide per image: pin forward to the newest release
      (a real upgrade, verify after) or leave floating. Running digests: gluetun `e8be55ff`,
      grampsweb `496a97ad`.

## 2. Pin tags (mechanical, no behaviour change)

- [x] 2.1 Apply the pins in the table above
- [x] 2.2 Leave `scrutiny`, `postgis` and the whole life103 stack on their current tags
- [x] 2.2b Pin `traefik` and `uptime-kuma`, which named version tags but still floated on
      patch and minor respectively — `uptime-kuma:1` accepted any 1.x release without a PR
- [x] 2.3 Commit and push (must precede deploy: `bin/deploy.sh` pulls on cartman)
- [x] 2.4 `make deploy` and confirm every container comes back up
- [x] 2.5 Fix fallout: gluetun and grampsweb both broke, because for both images `latest`
      leads the newest version tag rather than aliasing it, so "pin forward to newest
      release" was a downgrade. Gluetun v3.41.3 (6 weeks older than the running build) could
      not reach any PureVPN server, taking deluge and sabnzbd down with it. Grampsweb v25.6.0
      (15 months older) crash-looped on `alembic upgrade head` because the running build had
      already stamped revision `6d8f3cb50b71`. Both repinned by digest and redeployed.
- [x] 2.6 Verify: all 22 containers up, zero restart counts, gluetun healthy with a VPN exit
      IP, gramps/sonarr/radarr/bazarr/jellyfin/deluge/sabnzbd all answering HTTP 200

## 3. Prowlarr: nightly to stable (separate, behaviour change)

**Caution: this is a downgrade.** Prowlarr is running nightly `2.6.2.5583`, while the newest
stable is `2.5.2`. Moving to stable moves the version backwards, which risks a config or
database schema that stable cannot read. Take a Prowlarr config backup first.

- [x] 3.0 Back up `$CONFIG_ROOT/prowlarr/` on cartman before touching the tag
- [x] 3.1 Change `linuxserver/prowlarr:nightly` to the current stable tag (`2.5.2` at writing)
- [x] 3.2 `make deploy`, then verify in the Prowlarr UI that indexers still sync and a test
      search returns results
- [x] 3.3 Verify Radarr still reports indexers as available (a Prowlarr fault surfaces there,
      see the DNS note in `CLAUDE.md`)
- [x] 3.4 Commit separately so it can be reverted without touching the pins

## 4. Dependabot

- [ ] 4.1 Create `.github/dependabot.yml`: `docker-compose` ecosystem, directory `/`,
      `schedule: weekly`, `open-pull-requests-limit: 5`
- [ ] 4.2 Add `cooldown`: 14 days default, 30 days for major
- [ ] 4.3 Add `groups`: arr apps (`sonarr`, `radarr`, `bazarr`, `prowlarr`), download clients
      (`deluge`, `sabnzbd`, `gluetun`), infrastructure (everything else)
- [ ] 4.4 Decide on `life103-db` (`postgis/postgis:17-3.5`). It is already pinned, so
      Dependabot will propose bumps for it unless ignored. Add an `ignore` entry to keep the
      life103 stack out of scope, or leave it in if Postgres patches are worth seeing.
- [ ] 4.5 Commit and push; confirm Dependabot runs (repo Insights, Dependency graph,
      Dependabot tab) and reports no parse errors on `compose.yml`
- [ ] 4.6 Confirm GitHub email notifications for this repo are on

## 5. Remove diun

- [ ] 5.1 Delete the `diun` service block from `compose.yml`
- [ ] 5.2 Remove the `diun.enable: "false"` labels from `prowlarr` and `scrutiny`
- [ ] 5.3 `make deploy`, then confirm the container is gone (`docker ps -a | grep diun`)
- [ ] 5.4 Remove `$CONFIG_ROOT/diun/` on cartman
- [ ] 5.5 Drop the diun row from the service table in `README.md`
- [ ] 5.6 Mark WS10 superseded in `ROADMAP.md`, pointing at this change; record `scrutiny` and
      `life103-backend` as knowingly untracked
- [ ] 5.7 Unsubscribe from the `homelab-updates` ntfy topic on the phone (the `homelab` topic
      stays — Uptime Kuma still uses it)

## 6. Verify the loop end to end

- [ ] 6.1 Wait for the first Dependabot PR (up to a week plus cooldown)
- [ ] 6.2 Confirm it names real versions and links a changelog, and that grouping worked
- [ ] 6.3 Merge one, run `make deploy`, confirm the service comes back on the new version
- [ ] 6.4 If Dependabot mis-parsed any LinuxServer tag, note which, and consider Renovate with
      regex versioning for that image only
