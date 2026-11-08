# PROJECT FUL454
**Find. Discover. Connect.**

FUL454 is a Tanzania-first property and business discovery/listing platform owned by EAM VENTURES LTD.

## Stack
- Static frontend: HTML, CSS and JavaScript
- Hosting: Cloudflare Pages (Git integration)
- Authentication, database and image storage: Supabase
- Source control: GitHub

## Current frontend
The first web application is in `index.html`. It includes:
- Public browsing of approved listings
- Search by keyword, region, property type, purpose and price range
- Email/password sign-up and login
- Buyer, owner and agent account selection
- Owner listing submission and photo upload
- Owner listing status view
- Basic platform-admin listing review interface (requires an authorized admin profile)

## Supabase project
Project ref: `bpavcqtttadzenuvvkkv`
Region: EU West (Paris)

The database has the core tables for profiles, listings, photos, contacts, agent access requests, listing payments and audit logs. The migration `ful454_auth_profile_storage_setup` installs auth profile creation, protects role fields, and configures the public listing photo bucket.

## Deploy to Cloudflare Pages
1. In Cloudflare Dashboard open **Workers & Pages**.
2. Select **Create application** → **Pages** → **Connect to Git**.
3. Connect GitHub account and select `Eckson2621/PROJECT-FUL454`.
4. Production branch: `main`.
5. Framework preset: **None**.
6. Build command: leave empty.
7. Build output directory: `/`.
8. Deploy. Cloudflare will provide a `.pages.dev` URL.
9. Keep automatic deployments enabled; future commits to `main` update the same site.

Do not connect this repository to the AMWEMARI Worker. FUL454 is a separate Cloudflare Pages project.

## Important production work still required
- Assign and verify the first FUL454 and EAM platform administrator accounts securely.
- Complete agent access request approval workflow and administrator user management.
- Complete listing payment plans, manual payment review and publication/expiry rules.
- Review and correct any pre-existing RLS policies before accepting public traffic.
- Add full listing detail pages, report/fraud workflow, pagination and production QA.
- Configure Supabase Auth email templates and allowed redirect URLs for the final Pages domain.

Never put a Supabase service-role key in this repository or browser code. Only the publishable key is used by the frontend.
