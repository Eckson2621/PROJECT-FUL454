# PROJECT FUL454
**Find. Discover. Connect.**

FUL454 is a Tanzania-first property and business discovery/listing platform owned by EAM VENTURES LTD.

## Application stack
- Frontend: HTML, CSS and JavaScript in `public/index.html`
- Hosting: Cloudflare Workers Static Assets
- Authentication and database: Supabase
- Listing photos: private Supabase Storage bucket with short-lived signed URLs
- Source control: GitHub

## Deploy through the existing Cloudflare Worker
This repository is configured for a Cloudflare Worker named `ful454`:

`https://ful454.eckson.workers.dev`

1. In Cloudflare Dashboard open **Workers & Pages** and select the existing `ful454` Worker.
2. Confirm it is connected to `Eckson2621/PROJECT-FUL454`, production branch `main`.
3. The deploy command is `npx wrangler@4 deploy`; root directory is `/`.
4. GitHub Actions runs the Node test suite and Wrangler dry-run before deployment.
5. After deployment, test `https://ful454.eckson.workers.dev/health`; it should return JSON with `"ok": true`.

The Worker configuration is in `wrangler.jsonc`; its entry point is `src/index.js`; public site assets are in `public/`.

## Supabase project
- Active destination project: `ieeyvhcluywkoymliswq` (EU West, Paris).
- Previous project ref: `bpavcqtttadzenuvvkkv` (backup; do not delete until cutover verification is complete).

## Implemented application capabilities
- Public browsing of approved listings, keyword/location/type/purpose/price search and sorting.
- Email/password signup and login; buyer, owner and agent account types.
- Owner listing submission with contact details and up to eight JPG/PNG/WEBP photos (5 MB each).
- Private listing-photo bucket; images are exposed through temporary signed URLs.
- Owner listing dashboard, saved listings, search history and basic owner analytics.
- Agent requests access to listing contacts; owner decides and administrator performs final verification.
- Super Admin account approval/suspension, listing moderation, brokerage company approval and business reports.
- Manual promotion payment requests with amount confirmation before a listing is featured.
- English/Kiswahili interface.
- Listing fraud/report workflow: signed-in users can report an approved listing; only platform admins can review, resolve or reject reports.
- RLS is enabled on all inspected public tables. Profile privilege triggers prevent users from changing their own role or approval state.
- The active Super Admin profile is assigned to the configured administrator account.

## Security and performance work completed (23 Nov 2026)
- Confirmed the active Supabase project is healthy and all 14 inspected public tables have RLS enabled.
- Confirmed the listing-photo bucket is private and restricts uploads to JPG, PNG and WEBP up to 5 MB.
- Added indexes for 11 previously unindexed foreign-key columns; the performance advisor no longer reports unindexed foreign keys.
- Added an RLS-protected `listing_reports` table, reporter/admin access rules and a dashboard moderation queue. SQL is documented in `database/manual/listing-reports.sql`.
- Added baseline security headers to both health and static-asset responses, including HSTS, anti-framing, MIME-sniffing protection, referrer policy and a restrictive permissions policy.
- Added automated Node tests for the Worker health endpoint, security headers, asset response preservation and 404 handling; the deployment workflow now runs these tests before deploying.

## Remaining before a public launch
- Enable leaked-password protection in Supabase Auth.
- Complete manual review of the two admin-only SECURITY DEFINER RPC functions and their guarded authorization paths; they currently enforce platform-admin checks.
- Run real signup, email confirmation, login, owner listing/photo upload, approval and agent-access tests with separate test accounts.
- Verify Supabase Auth redirect URLs and the deployed Worker health endpoint in a real browser.
- Complete full pagination, listing expiry/renewal rules and broader admin user-management QA.
- Exercise the listing-report workflow using separate reporter and administrator accounts.
- Test mobile layouts on real Android/iOS devices and verify all bilingual labels.
- Confirm Storage object policies and all RLS edge cases with unauthorised accounts.

## Local checks
- Run `npm test` to execute the Worker tests.
- Never put a Supabase service-role key or secret key in this repository or browser code. The frontend uses only the publishable key.
