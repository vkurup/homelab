## ADDED Requirements

### Requirement: Image versions are recorded in git
Every service in `compose.yml` SHALL name the upstream application version it runs, such that
no *application* upgrade can take effect without a change in this repository. A tag that
floats across upstream releases, such as a bare major or minor, does not satisfy this.

A tag MAY still float across packaging rebuilds of the same upstream version, such as
LinuxServer's `-lsNNN` build numbers, which carry base-image security patches rather than
application changes. These are accepted unreviewed and without cooldown.

Where a publisher's `latest` leads its version tags, so that no version tag describes the
running build, the reference SHALL be a digest (`tag@sha256:...`). Images where the publisher
offers nothing specific enough SHALL be listed as known gaps in `ROADMAP.md`.

#### Scenario: Reading the running version from the repo
- **WHEN** a developer reads `compose.yml`
- **THEN** the version of each service is stated, without needing to inspect cartman

#### Scenario: Publisher offers no version tag
- **WHEN** an image publishes only a rolling tag such as `master-omnibus`
- **THEN** it remains on that tag and is recorded in `ROADMAP.md` as untracked

#### Scenario: Publisher rebuilds the same upstream version
- **WHEN** LinuxServer rebuilds `4.0.19` as a new `-lsNNN` build to pick up a base-image patch
- **THEN** the rebuild is pulled on the next deploy without a pull request, because the
  application version named in the repo has not changed

#### Scenario: Publisher's latest leads its version tags
- **WHEN** the running image's digest matches no published version tag, because `latest` is
  built from a newer commit than the newest release
- **THEN** the image is pinned by digest, and is never resolved by guessing forward to the
  newest version tag, which would be a downgrade

#### Scenario: Publisher offers only a floating version tag
- **WHEN** an image publishes a version tag that still moves, such as `17-3.5` tracking
  Postgres patch releases
- **THEN** it uses the most specific tag available and is recorded in `ROADMAP.md` as
  partially tracked

### Requirement: Updates arrive as pull requests
Image updates SHALL be proposed as pull requests against this repository, naming the version
change and linking the upstream release notes. No update SHALL be applied automatically.

#### Scenario: A new release is published upstream
- **WHEN** a watched image publishes a newer version and the cooldown has elapsed
- **THEN** a pull request is opened that changes the tag in `compose.yml`

#### Scenario: Applying an update
- **WHEN** the developer merges an update pull request
- **THEN** the new version takes effect on the next `make deploy`, and not before

### Requirement: New releases are subject to a cooldown
A newly published release SHALL NOT be proposed until it has been available for at least 14
days, or 30 days for a major version bump.

#### Scenario: Release published today
- **WHEN** an image publishes a new minor version
- **THEN** no pull request is opened for it until 14 days have passed

#### Scenario: Urgent security fix
- **WHEN** the developer needs a fix before the cooldown elapses
- **THEN** they may bump the tag by hand, as a deliberate act outside the normal path

### Requirement: Update pull requests are grouped and rate-limited
Update pull requests SHALL be opened on a weekly schedule, grouped by service role, with no
more than 5 open at once.

#### Scenario: Several images update in the same week
- **WHEN** multiple images in the same role group have pending updates
- **THEN** they appear in a single pull request for that group

#### Scenario: Backlog exceeds the limit
- **WHEN** 5 update pull requests are already open
- **THEN** no further update pull requests are opened until some are merged or closed

### Requirement: No push notifications for image updates
The system SHALL NOT send push notifications for image updates. Notification of a pending
update SHALL be GitHub's own pull request email.

#### Scenario: An update becomes available
- **WHEN** an update pull request is opened
- **THEN** the developer is notified by GitHub email only, and nothing is published to ntfy

#### Scenario: Uptime alerting is unaffected
- **WHEN** a service goes down
- **THEN** Uptime Kuma still alerts via ntfy as before
