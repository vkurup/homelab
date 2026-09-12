## Context

WS10 added diun (notify-only image update watching) pushing to the ntfy topic
`homelab-updates`. In use it proved noisy, and the notifications were not actionable. The root
cause is that the images it watches are on floating tags, so there is no version to report and
nothing to delay.

Today's stack: 21 images, 17 floating. Already pinned: `traefik:v3.3`,
`redis:7.2.4-alpine`, `postgis/postgis:17-3.5`, `louislam/uptime-kuma:1`.

## Goals / Non-Goals

**Goals:**
- The running version of every service is recorded in git
- Update notices name a version and link a changelog
- A new release waits before it is even proposed
- Reviewing updates is a pull activity on the developer's schedule, not a push interruption
- No new self-hosted service; ideally one fewer

**Non-Goals:**
- Auto-updating or auto-merging
- Zero blind spots (two images have no usable version tag; accepted and recorded)
- Changing how deploys work

## Decisions

**Pull request queue, not a push stream or a dashboard**
A stream demands attention on arrival, which is complaint #1. A dashboard (What's Up Docker
was considered) is silent but cannot say what changed between two digests, so complaint #2
survives. A PR carries the version diff, the changelog link, and merging is itself the action.
It also waits patiently, which is what a cooldown needs.

**Dependabot, not Renovate**
Renovate was the obvious choice until we checked the current state of Dependabot: as of 2026
it supports docker-compose as a SemVer-aware ecosystem with per-level cooldown, and applies a
3-day cooldown by default. It is native to GitHub, needs no self-hosting, and the config is
about eight lines. Renovate is more configurable — notably per-image regex versioning — but
that flexibility is only needed for tags Dependabot cannot parse, and we found almost none.
Renovate remains the documented fallback.

**Pin to what is running, not to latest**
Pinning to the newest release would bundle a mechanical change with fifteen simultaneous
upgrades, leaving fifteen suspects if something breaks and applying no cooldown to any of
them. Pinning to the running version makes the commit a no-op at runtime. Dependabot then
proposes the catch-up bumps one group at a time, each cooled down and each with a changelog.

**14-day cooldown, 30 for major**
Two weeks is long enough for a compromised or badly broken release to surface publicly, and
being two weeks behind costs nothing on homelab media services. Major bumps get 30 days since
they carry breaking-change risk on top. A genuine CVE is handled by bypassing manually, which
is a deliberate act rather than the default path.

**Weekly, grouped by role, PR limit 5**
Ungrouped PRs would be five to ten a week, which is the diun noise in a new place. One giant
group is all-or-nothing: a single image you want to hold back blocks every other bump. Groups
by role (arr apps / download clients / infrastructure) give roughly three readable PRs a week.
The accepted tradeoff is that a grouped PR mixes changelogs, so isolating a bad release takes
one extra step.

**Remove diun rather than narrow it**
Narrowing diun to only the unpinned stragglers was considered and rejected: it keeps a service
and a notification channel alive to watch two images. Removing it accepts a small blind spot
in exchange for one fewer moving part. The blind spot is recorded in ROADMAP.md.

**Prowlarr moves to stable**
Prowlarr ran on `nightly` from before it had stable releases. Stable exists now, so nightly is
a legacy choice rather than a necessary one, and it is exactly the unreviewed rolling tag the
cooldown is meant to guard against. The catch found during inventory: nightly `2.6.2.5583` is
*ahead* of stable `2.5.2`, so this is a version downgrade, not a channel swap at parity.
Separate commit, config backed up first, revert to nightly if stable will not read the config.

**Pin by digest where `latest` leads the version tags**
Discovered the hard way during the first deploy. For `gluetun` and `grampsweb`, `latest` is
not an alias for the newest release tag — it is built from a newer commit, so it runs *ahead*
of every published version. That is why their running digests matched no version tag. Pinning
them to the newest version tag was therefore a downgrade, and both broke: gluetun lost the VPN
entirely, and grampsweb could not run its own migrations backwards. For images like these the
correct pin is the digest, written as `tag@sha256:...`. It records exactly what runs without
depending on the publisher tagging sanely, and Dependabot can still bump a digest.

The general lesson: a running digest that matches no version tag is a signal that `latest`
leads the releases, not that the version is merely unknown. Do not resolve it by guessing
forward.

**Pin the application version, not the packaging build**
A plain semver tag like `linuxserver/sonarr:4.0.19` tracks the newest LinuxServer rebuild of
that version, so it still floats across `-lsNNN` build numbers. The first deploy moved six
images a build forward for this reason (sonarr ls322 to ls324, radarr ls314 to ls315, bazarr
ls361 to ls363, sabnzbd ls270 to ls271, jellyfin ls46 to ls47, calibre-web ls398 to ls400),
all healthy.

Pinning the full `4.0.19.2979-ls324` form would close that, and was considered. Rejected
because `-lsNNN` rebuilds are base-image security patches rather than application changes, so
taking them promptly is a benefit rather than a risk, and because that tag shape is the one
Dependabot is least likely to parse. The line is drawn at the upstream application version:
that never moves without a pull request. Packaging rebuilds do.

## Risks / Trade-offs

- **A security fix waits 14 days.** Mitigation: bypass the cooldown manually for a known CVE.
  These services are LAN and Tailscale only, never internet-facing, which lowers the stakes.
- **Grouped PRs mix changelogs.** Mitigation: the group is small and role-scoped; split a
  group temporarily if a bad release needs isolating.
- **scrutiny becomes untracked.** No version tag is published, so nothing can manage it.
  Accepted and recorded in ROADMAP.md rather than solved. The life103 stack is excluded by
  choice (internal, single user), which is a decision rather than a gap.
- **Moving Prowlarr to stable is a downgrade.** It runs nightly `2.6.2.5583`; newest stable is
  `2.5.2`. A downgrade can hit a config or database schema stable cannot read. Mitigation:
  back up `$CONFIG_ROOT/prowlarr/` first, and be willing to revert to nightly.
- **Base-image rebuilds arrive unreviewed.** A compromised LinuxServer rebuild of a version
  already in the repo would be pulled on the next deploy with no cooldown. Accepted: the
  alternative is a tag shape Dependabot likely cannot parse, and it would delay security
  patches. Revisit if a rebuild ever causes a problem.
- **Resolved: gluetun and grampsweb are pinned by digest.** Their `latest` leads the version
  tags, so they have no version tag that describes what runs. Trade-off: a digest pin carries
  no human-readable version, and Dependabot digest bumps say less than a version bump.
- **Dependabot parsing of LinuxServer tags is unverified in practice.** Mitigation: the first
  week's PRs are the test. If it mis-parses, migrate that image to Renovate.

**Version-looking tags can still float**
Found during implementation: `traefik:v3.3`, `louislam/uptime-kuma:1` and
`postgis/postgis:17-3.5` all name a version but still accept updates without a repo change.
`uptime-kuma:1` was the worst, accepting any 1.x release. Traefik and Uptime Kuma were pinned
to exact versions. Postgis publishes nothing more specific than `17-3.5`, so it stays there
and is recorded as partially tracked alongside scrutiny.

## Open Questions

- `make update` keeps its current behaviour, which after pinning means a no-op on most
  services and a silent bump on the two stragglers. Deliberately deferred.
