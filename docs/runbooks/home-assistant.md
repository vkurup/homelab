# Home Assistant runbook

How Home Assistant is tracked, accessed, backed up, and recovered.

## Overview

- **What:** Home Assistant OS (HAOS) on a Raspberry Pi 4, `192.168.1.248`, web UI at
  `http://192.168.1.248:8123` (and `https://ha.home.kurup.net` via Traefik — see [Access / TLS](#access--tls)).
- **Style:** 100% UI-driven. The only hand-editable config that lives as plain YAML is
  `configuration.yaml` and the UI-editor outputs `automations.yaml` / `scripts.yaml` /
  `scenes.yaml`. Everything else (integrations, helpers, dashboards, registries) lives in
  `/config/.storage/` and is **not** version-controlled (it holds auth tokens) — it is only
  protected by HA Backups.
- **Goal:** LLM-assisted integration/automation work via `ha-mcp`, change-history via git,
  disaster recovery via HA Backups → duplicacy → B2.

## Repos

- **This repo:** the integration glue —  Traefik route + Homepage tile + this runbook.
- **`/config` on the Pi:** a standalone git repo (history/rollback). Browse history with
  `git log` / `git diff` in the SSH add-on terminal; edits flow through `ha-mcp`. (No
  workstation clone — `ha-mcp` + git-on-the-Pi cover editing and history.)

## LLM access (ha-mcp)

The unofficial [`ha-mcp`](https://github.com/homeassistant-ai/ha-mcp) add-on plus its
`ha_mcp_tools` companion component (auto-installed on HAOS) give an MCP client read/write
access to `/config` and to logs/traces. The official `mcp_server` integration was rejected —
it only exposes the Assist API (entity control), not config editing.

- **Install:** Settings → Apps → Store → ⋮ → Repositories → add
  `https://github.com/homeassistant-ai/ha-mcp` → install **"Home Assistant MCP Server"**.
- **Config:** defaults are correct
- **Endpoint:** the add-on **Logs** tab prints a secret URL, e.g.
  `http://192.168.1.248:9583/private_<secret>`. **That URL is the credential — treat it like a
  password.** LAN-only; no internet/Traefik route.
- **Claude Code wiring:**
  ```sh
  claude mcp add-json -s user home-assistant '{"url":"http://192.168.1.248:9583/private_<secret>","type":"http"}'
  ```
  Restart Claude Code, then `/mcp` should show `home-assistant` connected.

Safety nets: `ha-mcp` auto-backs-up before edits, and `/config` is under git — commit after
changes so edits are diffable/revertable.

## /config git (history)

`git` is initialized inside `/config` on the Pi (run from the Advanced SSH & Web Terminal
add-on). `.gitignore` excludes `secrets.yaml`, `.storage/`, databases, logs, `custom_components/`
(HACS-managed), `.cache/`, and `.ha_run.lock`. Tracked: the YAML config + stock blueprints.

## Backups (disaster recovery)

HAOS can't run the duplicacy client, so cartman **pulls** HA's native backups over SSH, then
snapshots them with duplicacy. Pipeline:

1. **HA automatic backups** → Pi `/backup` (daily ~04:45, keep 3; includes HA settings + small
   add-ons; **excludes Plex**). **Encrypted** — the key is in **1Password** (HA's new backup
   system forces encryption; without the key a restore is impossible).
2. **cartman cron 20:30** — `rsync` over SSH from `vinod@192.168.1.248:/backup/` →
   `/home/vkbackup/ha-backups/`, using the dedicated key `/root/.ssh/ha_backup`.
3. **cartman cron 20:45** — `duplicacy backup` of that dir under the `homeassistant` snapshot-id
   into the local storage.
4. **cartman cron 21:01** — the existing `duplicacy copy -from default -to b2` carries it to
   Backblaze B2. The existing `prune -a` crons cover the new snapshot-id's retention
   automatically.

This is codified in `homebook` → `roles/desktop/tasks/main.yml` (tag `ha_backup`). The dedicated
pull key's **public** half must be added to the Pi's Advanced SSH & Web Terminal add-on
`authorized_keys` (manual — HAOS isn't Ansible-managed).

Apply: `ansible-playbook -i cartman, playbook.yml --tags ha_backup`

Verify B2: `cd /home/vkbackup/dummy && duplicacy list -storage b2 -id homeassistant`

### Restore

1. Flash Home Assistant OS with the Raspberry Pi Imager.
2. Boot, complete onboarding, then restore the latest HA backup
   (Settings → System → Backups → upload the `.tar` from `/home/vkbackup/ha-backups/` or pulled
   from B2). **You need the encryption key from 1Password.**
3. Reinstall any add-ons not in the backup: Advanced SSH & Web Terminal, ha-mcp.
4. In `/config`, `git pull` to reconcile the hand-written YAML.
5. Re-add the cartman pull key to the Advanced SSH add-on `authorized_keys`.

## Access / TLS

`https://ha.home.kurup.net` is served by the Traefik reverse proxy in this repo
(`config/traefik/dynamic/services.yml`): a router for `ha.home.kurup.net` and a service
pointing at `http://192.168.1.248:8123`. The wildcard `*.home.kurup.net` cert (Let's Encrypt +
Cloudflare DNS challenge) already covers it — no new cert. **LAN + Tailscale only; not
internet-facing.**

For HA to trust the proxy, `/config/configuration.yaml` on the Pi needs (cartman = where
Traefik runs):

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.1.20
```

A Homepage tile is in `config/homepage/services.yaml` (group "Smart Home"). Its widget needs a
**long-lived access token**: HA → profile → Long-lived access tokens → create → set
`HOMEPAGE_VAR_HOMEASSISTANT_API_KEY` in Homepage's env.

## Known gaps

- **cartman has no at-rest disk encryption.** All service creds (this repo's `.env`, etc.) and
  the pulled HA backups sit in plaintext on its disk. HA-side backup encryption is on (forced),
  but cartman remains a single plaintext crown-jewels host. LUKS full-disk encryption would fix
  this uniformly — a separate future project.

## Pending manual steps

- [x] Add the `http: trusted_proxies` block above to the Pi's `configuration.yaml` and restart HA.
- [x] Deploy the Traefik + Homepage changes to cartman (restart/redeploy the stack).
- [x] Confirm `ha.home.kurup.net` resolves (wildcard `*.home.kurup.net` DNS likely already covers it).
- [x] Create the HA long-lived token and set `HOMEPAGE_VAR_HOMEASSISTANT_API_KEY`.
- [x] Restart Claude Code and confirm `/mcp` shows `home-assistant`.
- [x] Rename this repo `htpc-download-box` → `homelab` (touches the live stack — do deliberately).
