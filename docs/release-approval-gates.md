# Release approval gates — EAM VENTURES systems

## Non-negotiable release path

Changes must pass through these separate gates:

1. **Development branch:** code changes are prepared away from the production branch.
2. **Verification:** static checks, automated tests, compatibility review, security review, and data-preservation checks are completed. A failed or unperformed test must be reported honestly.
3. **Center review:** the candidate release and its notes are presented to the Super Admin in Center. A candidate is not customer-visible merely because code exists in GitHub.
4. **Super Admin publication approval:** only an explicit publish action in Center may mark a release as available to customers. No implicit publication on merge, build, or deployment.
5. **Customer device approval:** after publication, each device sees at most one pending New version. The device remains on its Current version until its user explicitly chooses Update.

## Two slots only

For each device, the customer-facing UI shows exactly:
- **Current:** the immutable artifact currently selected by this device.
- **New:** the newest published candidate that is newer than Current, if one exists.

If another release is published before the device updates, New is replaced by the latest release. No queue or customer-facing archive is shown.

## Safety and rollback

- A normal code merge or deployment must not silently switch customer devices.
- Customer data and database records are independent of front-end artifact selection.
- Rollback is an explicit Super Admin operation and must select a retained immutable artifact; it must not restore or overwrite customer data.
- Keep an artifact while at least one device is pinned to it, and retain the configured rollback copy.
- Emergency security handling is a separate, documented approval path; do not disguise it as an ordinary update.

## What Center must enforce

- Draft/candidate releases are visible only to authorized administrators.
- Only the designated Super Admin can publish or withdraw a release.
- The customer release-check endpoint returns only the single latest published candidate relevant to the device's selected version.
- A customer-facing endpoint must never return an unpublished draft.
- Publishing a release does not change any device's selected version.
- Device Update confirmation changes only that device's selected version.
- Audit log records who prepared, approved, published, withdrew, or rolled back a release, with timestamps and release identifiers.

## Current implementation boundary

The current Center release form and release metadata endpoint are not yet a complete artifact-delivery or per-device pinning system. The current FUL454 Update/Later prompt is not durable across browser restarts. These features must be implemented and tested before calling the policy operational.

No production deployment, merge to the default branch, customer data mutation, or destructive database migration is authorized by this design document.