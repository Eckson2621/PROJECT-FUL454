-- FUL454 performance hardening
-- Applied to Supabase project ieeyvhcluywkoymliswq on 2026-11-23.
-- Idempotent: safe to re-run. These indexes cover previously unindexed FK columns.

create index if not exists brokerage_companies_approved_by_idx
  on public.brokerage_companies (approved_by);
create index if not exists brokerage_companies_created_by_idx
  on public.brokerage_companies (created_by);
create index if not exists brokerage_members_user_id_idx
  on public.brokerage_members (user_id);
create index if not exists listing_promotions_listing_id_idx
  on public.listing_promotions (listing_id);
create index if not exists listing_promotions_owner_id_idx
  on public.listing_promotions (owner_id);
create index if not exists listing_promotions_plan_id_idx
  on public.listing_promotions (plan_id);
create index if not exists listing_promotions_reviewed_by_idx
  on public.listing_promotions (reviewed_by);
create index if not exists listing_reviews_reviewer_id_idx
  on public.listing_reviews (reviewer_id);
create index if not exists profiles_approved_by_idx
  on public.profiles (approved_by);
create index if not exists property_listings_brokerage_company_id_idx
  on public.property_listings (brokerage_company_id);
create index if not exists saved_listings_listing_id_idx
  on public.saved_listings (listing_id);
