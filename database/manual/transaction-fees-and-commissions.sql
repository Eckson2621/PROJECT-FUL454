-- FUL454 listing fees, completed-deal commissions, and immutable audit events.
-- REVIEW REQUIRED: apply only after confirming the active FUL454 Supabase project.
-- Listing promotion payments remain separate and are not changed by this schema.

create table if not exists public.listing_fee_payments (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.property_listings(id) on delete restrict,
  owner_id uuid not null references public.profiles(id) on delete restrict,
  fee_type text not null check (fee_type in ('rental_listing','sale_listing')),
  amount numeric(14,2) not null check (amount > 0),
  currency_code text not null default 'TZS' check (currency_code = 'TZS'),
  status text not null default 'pending' check (status in ('pending','paid','rejected')),
  payment_method text not null default 'manual',
  payment_reference text,
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  constraint listing_fee_amount_check check (
    (fee_type = 'rental_listing' and amount = 2000)
    or (fee_type = 'sale_listing' and amount = 10000)
  ),
  constraint listing_fee_verification_check check (
    (status = 'paid' and verified_by is not null and verified_at is not null)
    or (status <> 'paid' and verified_by is null and verified_at is null)
  )
);

create table if not exists public.property_deals (
  id uuid primary key default gen_random_uuid(),
  transaction_code text not null unique,
  listing_id uuid not null references public.property_listings(id) on delete restrict,
  advertiser_id uuid not null references public.profiles(id) on delete restrict,
  counterparty_id uuid references public.profiles(id) on delete restrict,
  deal_type text not null check (deal_type in ('rental','sale')),
  agreed_amount numeric(16,2) not null check (agreed_amount > 0),
  currency_code text not null default 'TZS' check (currency_code = 'TZS'),
  first_month_rent numeric(16,2),
  advertiser_confirmed_at timestamptz,
  counterparty_confirmed_at timestamptz,
  status text not null default 'reported'
    check (status in ('reported','awaiting_counterparty','confirmed','disputed','cancelled')),
  commission_rate numeric(5,4) not null,
  commission_amount numeric(16,2) not null check (commission_amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint deal_commission_rule_check check (
    (deal_type = 'rental' and commission_rate = 0.0500
      and first_month_rent is not null and first_month_rent > 0
      and commission_amount = round(first_month_rent * 0.05, 2))
    or
    (deal_type = 'sale' and commission_rate = 0.0100
      and first_month_rent is null
      and commission_amount = round(agreed_amount * 0.01, 2))
  ),
  constraint deal_confirmation_status_check check (
    status <> 'confirmed'
    or (advertiser_confirmed_at is not null and counterparty_confirmed_at is not null
        and counterparty_id is not null)
  )
);

create table if not exists public.deal_commission_payments (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null unique references public.property_deals(id) on delete restrict,
  advertiser_id uuid not null references public.profiles(id) on delete restrict,
  amount_due numeric(16,2) not null check (amount_due > 0),
  amount_paid numeric(16,2) not null default 0 check (amount_paid >= 0),
  status text not null default 'due' check (status in ('due','part_paid','paid','waived')),
  payment_reference text,
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  constraint commission_payment_status_check check (
    (status = 'due' and amount_paid = 0)
    or (status = 'part_paid' and amount_paid > 0 and amount_paid < amount_due)
    or (status in ('paid','waived') and (amount_paid = amount_due or status = 'waived'))
  )
);

create table if not exists public.deal_audit_events (
  id bigint generated always as identity primary key,
  deal_id uuid not null references public.property_deals(id) on delete restrict,
  actor_id uuid not null references public.profiles(id) on delete restrict,
  event_type text not null check (event_type in (
    'deal_reported','advertiser_confirmed','counterparty_confirmed',
    'deal_disputed','deal_cancelled','commission_payment_submitted',
    'commission_payment_verified','admin_note'
  )),
  event_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.listing_fee_payments enable row level security;
alter table public.property_deals enable row level security;
alter table public.deal_commission_payments enable row level security;
alter table public.deal_audit_events enable row level security;

grant select, insert on public.listing_fee_payments to authenticated;
grant update on public.listing_fee_payments to authenticated;
grant select, insert, update on public.property_deals to authenticated;
grant select on public.deal_commission_payments to authenticated;
grant select, insert on public.deal_audit_events to authenticated;

drop policy if exists listing_fee_owner_read on public.listing_fee_payments;
create policy listing_fee_owner_read on public.listing_fee_payments
for select to authenticated using (owner_id = (select auth.uid()) or public.is_platform_admin());

drop policy if exists listing_fee_owner_insert on public.listing_fee_payments;
create policy listing_fee_owner_insert on public.listing_fee_payments
for insert to authenticated with check (
  owner_id = (select auth.uid()) and status = 'pending'
  and verified_by is null and verified_at is null
  and exists (
    select 1 from public.property_listings l
    where l.id = listing_id and l.owner_id = (select auth.uid())
  )
);

drop policy if exists listing_fee_admin_update on public.listing_fee_payments;
create policy listing_fee_admin_update on public.listing_fee_payments
for update to authenticated using (public.is_platform_admin())
with check (public.is_platform_admin());

drop policy if exists property_deals_participant_read on public.property_deals;
create policy property_deals_participant_read on public.property_deals
for select to authenticated using (
  advertiser_id = (select auth.uid())
  or counterparty_id = (select auth.uid())
  or public.is_platform_admin()
);

drop policy if exists property_deals_advertiser_insert on public.property_deals;
create policy property_deals_advertiser_insert on public.property_deals
for insert to authenticated with check (
  advertiser_id = (select auth.uid())
  and status in ('reported','awaiting_counterparty')
  and advertiser_confirmed_at is not null
  and counterparty_confirmed_at is null
  and exists (
    select 1 from public.property_listings l
    where l.id = listing_id and l.owner_id = (select auth.uid())
  )
);

drop policy if exists property_deals_participant_update on public.property_deals;
create policy property_deals_participant_update on public.property_deals
for update to authenticated using (
  advertiser_id = (select auth.uid())
  or counterparty_id = (select auth.uid())
  or public.is_platform_admin()
) with check (
  advertiser_id = (select auth.uid())
  or counterparty_id = (select auth.uid())
  or public.is_platform_admin()
);

drop policy if exists commission_participant_read on public.deal_commission_payments;
create policy commission_participant_read on public.deal_commission_payments
for select to authenticated using (
  advertiser_id = (select auth.uid()) or public.is_platform_admin()
);

drop policy if exists audit_event_participant_read on public.deal_audit_events;
create policy audit_event_participant_read on public.deal_audit_events
for select to authenticated using (
  exists (
    select 1 from public.property_deals d where d.id = deal_id
      and (d.advertiser_id = (select auth.uid())
        or d.counterparty_id = (select auth.uid())
        or public.is_platform_admin())
  )
);

drop policy if exists audit_event_participant_insert on public.deal_audit_events;
create policy audit_event_participant_insert on public.deal_audit_events
for insert to authenticated with check (
  actor_id = (select auth.uid())
  and exists (
    select 1 from public.property_deals d where d.id = deal_id
      and (d.advertiser_id = (select auth.uid())
        or d.counterparty_id = (select auth.uid())
        or public.is_platform_admin())
  )
);

create or replace function public.prevent_deal_audit_mutation()
returns trigger language plpgsql security invoker
set search_path = ''
as $$
begin
  raise exception 'Deal audit events are append-only and cannot be changed or deleted';
end;
$$;

drop trigger if exists deal_audit_events_no_update on public.deal_audit_events;
create trigger deal_audit_events_no_update
before update or delete on public.deal_audit_events
for each row execute function public.prevent_deal_audit_mutation();

create index if not exists listing_fee_payments_owner_status_idx
  on public.listing_fee_payments(owner_id, status, created_at desc);
create index if not exists property_deals_advertiser_status_idx
  on public.property_deals(advertiser_id, status, created_at desc);
create index if not exists property_deals_counterparty_idx
  on public.property_deals(counterparty_id, status);
create index if not exists deal_commission_payments_status_idx
  on public.deal_commission_payments(status, created_at desc);
create index if not exists deal_audit_events_deal_created_idx
  on public.deal_audit_events(deal_id, created_at);
