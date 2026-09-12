## Why

Seventeen of twenty-one images in `compose.yml` ride a floating tag (`:latest`, `:nightly`,
`stable`, `master-omnibus`), and `make update` pulls whatever is newest at that instant. Three
problems follow from that single fact:

- **Nothing records what is running.** The repo describes the stack but not its versions.
- **diun's notifications cannot be actionable.** With no version to name, the most it can say
  is that a digest moved — no version, no changelog, no decision attached. That is WS10's
  complaint #2, and the per-image daily firing is complaint #1.
- **A dependency cooldown is unimplementable.** Delaying a notification changes nothing when
  the pull still fetches the newest build. Cooldowns (see
  https://blog.yossarian.net/2025/11/21/We-should-all-be-using-dependency-cooldowns) require a
  pinned version you deliberately advance.

So the notification channel is the symptom and the floating tags are the cause. Fixing the
tags makes the notification problem mostly disappear on its own.

## What Changes

- **Pin image tags** in `compose.yml` to the versions currently running on cartman. Nearly
  every image has a clean semver tag available; this commit records reality rather than
  changing it.
- **Move Prowlarr from `nightly` to stable** (`2.5.2` at time of writing). This is a release
  channel change, not just a pin, so it is a separate commit with its own verification.
- **Add `.github/dependabot.yml`** — docker-compose ecosystem, weekly, grouped by role, open
  PR limit 5, 14-day cooldown (30 days for major). Update notices become pull requests with
  real version diffs and changelog links.
- **Remove diun entirely** — the service, the two `diun.enable=false` labels, the README row,
  and the WS10 roadmap entry is marked superseded.
- **Notification medium becomes GitHub email.** No new machinery. ntfy stays for Uptime Kuma
  alerts, unchanged.

## Capabilities

### New Capabilities
- `image-updates`: image versions are pinned in git, and updates arrive as cooled-down,
  grouped pull requests rather than push notifications

### Modified Capabilities
None. `deploy` is untouched.

## Impact

- `compose.yml`: ~15 tags pinned, `diun` service and its labels removed
- New file `.github/dependabot.yml`
- `README.md`: drop the diun row from the service table
- `ROADMAP.md`: mark WS10 superseded, record the untracked stragglers
- **Behaviour:** merging a Dependabot PR then running `make deploy` becomes the update path
- **Deliberately untracked:** `scrutiny` (`master-omnibus`, no semver tag published) is a
  genuine gap once diun is gone, and is recorded rather than solved. The life103 stack
  (`life103-backend`, `life103-apk`) is excluded by choice, not by limitation — it is an
  internal single-user app and does not warrant version management.

## Non-Goals

- Auto-merging update PRs. The supply-chain concern is the whole point; a human merges.
- Self-hosting Renovate. Dependabot's native cooldown covers this stack; Renovate stays the
  fallback if an image later needs custom regex versioning.
- Changing `make update`. It will no-op on pinned services and still bump the two stragglers.
  Left as-is deliberately; revisit separately.
- Replacing ntfy or adding an email bridge for Uptime Kuma alerts.
