# FUL454 — Device identity and release-state architecture decision

Status: proposed for isolated implementation and testing on `feature/user-approved-updates`. Not deployed.

## Decision

Use the existing EAM Feedback Center Supabase project as the authoritative control plane for:
- approved release metadata;
- one device's selected/current release;
- audit events for bootstrap, update acceptance, and rollback;
- the list of devices still pinning each immutable artifact.

Use Cloudflare R2 as the immutable file store for versioned FUL454 build artifacts. Do not use the Worker's built-in `ASSETS` binding as the historical artifact store: it serves the assets attached to the currently deployed Worker version, not arbitrary old builds.

This avoids creating a second database (D1) just for release state while reusing the already-existing Center control plane. R2 is a separate prerequisite and must be created/configured by the account owner before any real artifact upload or Worker binding can work.

## Device identity

- On first visit, the Worker creates a cryptographically random opaque device identifier.
- The browser receives it in a `Secure; HttpOnly; SameSite=Lax` cookie with a bounded lifetime. The identifier is not an account password, Supabase token, or customer data.
- Center stores only a hash of the identifier, the app name, selected release ID, created/last-seen timestamps, and status.
- The Worker signs a compact version-selection token containing the opaque device ID, selected release ID, issue time, and expiry. The signing key is a Cloudflare Worker secret; it must never be put in source code or sent to the browser.
- Static asset requests validate the signed selection locally and read only from the matching immutable R2 prefix. This avoids a Center database round-trip for every image, script, stylesheet, and font.
- Bootstrap, update acceptance, and periodic renewal reconcile the signed token with Center's authoritative device record. The update endpoint must use an atomic server-side operation so two simultaneous requests cannot overwrite a newer selection incorrectly.

A normal browser restart preserves the cookie. Clearing site data, private browsing, changing browser profiles, or reinstalling the browser can erase browser identity; the system must then treat that browser profile as a new device. Do not promise identity persistence after a user deliberately clears browser storage.

## Release package layout

Each published build is stored under a unique immutable prefix, for example:

`apps/ful454/releases/<release-id>/<content-hash>/<asset-path>`

The manifest records every asset path, content type, byte length, and cryptographic digest. A release is eligible for publication only after every manifest entry is present and verified in R2. Never overwrite files under an existing release prefix.

The Worker resolves:
- HTML, JS, CSS, icons, fonts, manifest, and service-worker resources to the selected release prefix;
- `/api/*`, `/health*`, `/webhook*`, Supabase requests, and other configured data/auth/payment endpoints without rewriting them to R2.

Unknown paths must return a deliberate 404 or safe application fallback; they must not silently fall through to another release.

## Two-slot behavior

- Current is read from the device's selected release.
- New is the single latest published release newer than Current.
- Publishing another release replaces the pending New candidate; it does not change Current or create a customer-facing queue.
- Later changes no device state.
- Update requires an explicit user action, then Center records the accepted release for that device and the Worker issues a newly signed selection token.
- A device that has not accepted an update continues to resolve every application asset from its Current release.
- Center's administrator UI may show private operational retention data, but customer UI shows only Current and New.

## Retention and rollback

An artifact cannot be deleted while any active device record selects it. Also retain the configured rollback release for the agreed safety period. Cleanup must be a separate, audited process that first proves no device is pinned and no rollback hold remains.

Rollback is an explicit administrator action selecting a retained immutable artifact. It changes the selected release only for the intended device(s) or release policy; it never rewrites customer business records. A rollback policy must specify how long signed device tokens remain valid and how an emergency revocation invalidates them.

## Security requirements

- No service-role key, signing secret, or R2 credential in browser code or Git.
- Device endpoints accept only the minimum required fields and enforce strict request-size, method, origin/CORS, and rate limits.
- A browser-supplied release ID is never trusted as proof that a release is published.
- Center validates release status and app identity server-side.
- Device ID values are hashed at rest; raw identifiers are not logged.
- Admin publish/withdraw/rollback actions are restricted to the designated Super Admin and are audited.
- RLS is enabled on exposed device/release tables. Customer-facing access goes through a narrowly scoped Edge Function; no public table write policies.
- Cookie signing and verification use constant-time signature comparison and reject expired or malformed tokens.

## Failure behavior

- If Center is unavailable, an already-issued valid signed token can continue serving its selected immutable artifact until token expiry. It must not silently switch to the newest release.
- If R2 cannot serve a selected artifact, return an explicit service error and log the missing object; never serve files from a different version.
- If the signed token is missing/invalid, bootstrap through Center. If Center is unavailable and no valid token exists, show a safe unavailable page rather than guessing a version.
- Offline launch is served from a version-specific service-worker cache. Cache names include the immutable release ID. Activation of a new service worker must not delete caches still needed by the selected release.

## Implementation sequence

1. Add isolated unit tests for token signing/verification, path normalization, API-path bypass, manifest validation, and two-device selection.
2. Add Center schema/function changes as reviewed migrations and Edge Function source changes; do not apply them to the live database during this phase.
3. Add R2 manifest upload/verification tooling and a local mock bucket test.
4. Add Worker version routing behind a feature flag, with current `ASSETS` serving unchanged when the flag is off.
5. Test two browsers/devices, browser restart, Later, pending-release replacement, API bypass, offline launch, missing artifact, and rollback.
6. Only after all tests pass, submit a reviewable PR and present the candidate in Center. No merge or deployment without explicit Super Admin approval.

## Known limits

- Cookie/device identity survives ordinary browser restarts, not deliberate storage clearing or all browser-profile changes.
- Indefinite deferral requires indefinite private retention of the selected artifact. Storage cleanup cannot delete an artifact still in use.
- This architecture is a design decision only. No R2 bucket, database table, Edge Function action, cookie, version router, or production change has been created by this document.
