-- FUL454 listing fraud/report workflow
-- Applied to Supabase project ieeyvhcluywkoymliswq on 2026-11-23.
-- Users may report approved listings they do not own. Only platform admins
-- can read all reports and update moderation outcomes.

create table if not exists public.listing_reports (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.property_listings(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in (
    'suspected_scam', 'wrong_information', 'duplicate',
    'prohibited_content', 'other'
  )),
  details text check (details is null or char_length(details) <= 1500),
  status text not null default 'pending'
    check (status in ('pending', 'resolved', 'rejected')),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  admin_note text check (admin_note is null or char_length(admin_note) <= 1500),
  created_at timestamptz not null default now(),
  constraint listing_reports_review_fields_check check (
    (status = 'pending' and reviewed_by is null and reviewed_at is null)
    or (status <> 'pending' and reviewed_by is not null and reviewed_at is not null)
  )
);

alter table public.listing_reports enable row level security;
grant select, insert, update on public.listing_reports to authenticated;

drop policy if exists listing_reports_insert_self on public.listing_reports;
create policy listing_reports_insert_self on public.listing_reports
for insert to authenticated
with check (
  reporter_id = (select auth.uid())
  and status = 'pending'
  and reviewed_by is null
  and reviewed_at is null
  and exists (
    select 1 from public.property_listings l
    where l.id = listing_reports.listing_id
      and l.status = 'approved'
      and l.owner_id <> (select auth.uid())
  )
);

drop policy if exists listing_reports_read_reporter_or_admin on public.listing_reports;
create policy listing_reports_read_reporter_or_admin on public.listing_reports
for select to authenticated
using (reporter_id = (select auth.uid()) or public.is_platform_admin());

drop policy if exists listing_reports_admin_update on public.listing_reports;
create policy listing_reports_admin_update on public.listing_reports
for update to authenticated
using (public.is_platform_admin())
with check (public.is_platform_admin());

create index if not exists listing_reports_listing_id_idx
  on public.listing_reports(listing_id);
create index if not exists listing_reports_reporter_id_idx
  on public.listing_reports(reporter_id);
create index if not exists listing_reports_status_created_at_idx
  on public.listing_reports(status, created_at desc);
