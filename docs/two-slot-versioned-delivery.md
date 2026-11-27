# FUL454 — Two-slot, user-pinned release architecture

## Product rule

The customer-facing update experience exposes exactly two slots:
1. **Current version** — the version this device is actively using.
2. **New version** — the single newest approved release available to this device.

There is no customer-facing version catalogue or queue of old updates. If a newer release is published before the user accepts the pending update, the pending slot is replaced by the newest release. The current slot is never silently changed.

## Important retention distinction

The interface can show only two slots, but the delivery system may need to retain older immutable packages privately while devices still use them. If users may defer indefinitely, it is technically impossible to guarantee both (a) every device stays on its chosen version and (b) only two physical release packages exist globally. The implementation must therefore distinguish:
- two visible slots per device; and
- private, immutable package retention for versions still selected by at least one device, plus a rollback safety copy.

Old packages may be garbage-collected only after no registered device is pinned to them and the rollback retention window has expired.

## Required request flow

1. Every release is built as an immutable artifact with a unique version and content hash.
2. A device has a durable selected-version identifier. It must survive tab close, browser restart, and ordinary app refresh.
3. Requests for application HTML, JavaScript, CSS, images, fonts, manifest, and service-worker files must all resolve from that device's selected immutable artifact.
4. API, authentication, payment, webhook, and other data endpoints must not be rewritten to the static artifact path.
5. The update check returns at most one candidate: the latest approved release newer than the device's selected release.
6. Later keeps the selected release unchanged. A subsequently published release replaces the single pending candidate.
7. Update changes the device's selected release only after explicit confirmation, then reloads into that artifact.
8. Rollback changes the device's selected release to the retained prior artifact. It must not modify customer records.

## Cloudflare implementation constraints discovered

- FUL454 currently uses one Workers Static Assets binding (ASSETS) and run_worker_first: true.
- Cloudflare documents that an ASSETS binding serves assets belonging to the current Worker version; it does not search previous Worker versions' assets. Therefore simply keeping an old Worker deployment or rewriting a path through the current binding does not provide a durable multi-version asset store.
- Cloudflare allows only one static-assets collection per Worker configuration. A separate immutable artifact store or separate versioned asset origin is therefore required for reliable pinning.
- FUL454 uses root-relative URLs (for example /pwa-install.js, /icons/...) and a root-scoped /sw.js. A naive /releases/<version>/ URL prefix would break those references unless a request-routing layer consistently maps all static requests while preserving API paths and service-worker scope.

## Acceptance tests before any production release

- New device receives the currently approved release.
- Existing device remains on its selected release after a new release is published.
- The update UI shows only Current and New; never a list of many releases.
- Repeated releases replace the one pending candidate rather than queueing candidates.
- Later remains effective after tab close, browser restart, and device restart.
- Update switches only that device after explicit confirmation.
- Two devices can remain on different selected versions without affecting one another.
- Every asset requested by old HTML is served from the same immutable release.
- API/auth/payment/webhook requests continue to reach their original endpoints unchanged.
- Offline launch works on the selected release.
- Rollback restores the prior artifact without touching business data.
- An artifact is not deleted while any device is pinned to it.

## Current status

This is a design record, not an implementation or production deployment. The existing FUL454 Update/Later prompt is only a partial prototype: its Later choice is in-memory for the current page session, and standard Service Worker lifecycle behavior can activate a waiting worker after old controlled tabs close. Do not treat that prototype as satisfying durable per-device version pinning.