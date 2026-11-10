# PROJECT FUL454
**Find. Discover. Connect.**

FUL454 is a Tanzania-first property and business discovery/listing platform owned by EAM VENTURES LTD.

## Application stack
- Frontend: HTML, CSS and JavaScript in `public/index.html`
- Hosting: Cloudflare Workers Static Assets
- Authentication, database and photo storage: Supabase
- Source control: GitHub

## Deploy through the existing Cloudflare Worker
This repository is configured for a Cloudflare Worker named `ful454`, intended to serve:

`https://ful454.eckson.workers.dev`

1. In Cloudflare Dashboard open **Workers & Pages** and select the existing `ful454` Worker.
2. Open its **Builds / Git integration** settings and confirm it is connected to `Eckson2621/PROJECT-FUL454`, production branch `main`.
3. Set the build/deploy command to `npx wrangler@4 deploy`.
4. Set the root directory to `/` (repository root). No separate build output directory is needed.
5. Save and trigger a new deployment. Do not create or edit the AMWEMARI Worker.
6. After deployment, test `https://ful454.eckson.workers.dev/health`. It should return JSON with `"ok": true`, then open the homepage.

The Worker configuration is in `wrangler.jsonc`; its entry point is `src/index.js`; public site assets are in `public/`.

## Supabase project
Project ref: `bpavcqtttadzenuvvkkv`
Region: EU West (Paris)

The database contains the core profiles, property listings, listing photos, contacts, agent access requests, listing payments and audit logs tables.

## Current application capabilities
- Public browsing of approved listings
- Search by keyword, region, property type, purpose and price
- Email/password sign-up and login
- Buyer, owner and agent account selection
- Owner listing submission with contact details and up to eight JPG/PNG/WEBP photos (5 MB each)
- Owner listing status view
- Agent requests permission to view listing contact details
- Owner reviews agent requests; platform admin verifies owner-approved requests
- Basic platform-admin listing review interface (requires an authorized admin profile)

## Important work still required before public launch
- Verify the Cloudflare Worker deployment and Supabase Auth redirect URLs.
- Test signup, email confirmation, login, owner listing submission, photo uploads and admin approval end-to-end.
- End-to-end test the agent request → owner decision → administrator verification flow.
- Complete payment plans, payment verification, listing expiry and admin user management.
- Review all database RLS and Storage policies and run production security checks.
- Add full listing detail pages, report/fraud workflow, pagination and mobile QA.

Never put a Supabase service-role key or secret key in this repository or browser code. The frontend uses only the publishable key.
