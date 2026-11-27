-- FUL454: staged fix for recursive brokerage RLS policies.
-- Apply ONLY to an isolated Supabase preview database after review.
-- Do not execute against production as part of this PR.
--
-- Root cause: brokerage_companies SELECT reads brokerage_members while
-- brokerage_members SELECT/INSERT reads brokerage_companies. These lookups
-- recurse through each other's RLS policies.
--
-- The private SECURITY DEFINER helpers perform narrowly scoped lookups,
-- bind every decision to auth.uid(), and are executable only by authenticated.
-- They do not accept a caller-supplied user ID and expose no row data.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create or replace function private.is_brokerage_member(p_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog
as $function$
  select exists (
    select 1
    from public.brokerage_members as m
    where m.company_id = p_company_id
      and m.user_id = (select auth.uid())
  );
$function$;

create or replace function private.is_brokerage_company_owner(
  p_company_id uuid,
  p_require_approved boolean default false
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog
as $function$
  select exists (
    select 1
    from public.brokerage_companies as c
    where c.id = p_company_id
      and c.created_by = (select auth.uid())
      and (
        not p_require_approved
        or c.approval_status = 'approved'
      )
  );
$function$;

revoke all on function private.is_brokerage_member(uuid) from public, anon;
revoke all on function private.is_brokerage_company_owner(uuid, boolean) from public, anon;
grant execute on function private.is_brokerage_member(uuid) to authenticated;
grant execute on function private.is_brokerage_company_owner(uuid, boolean) to authenticated;

drop policy if exists brokerage_company_read_member on public.brokerage_companies;
create policy brokerage_company_read_member
on public.brokerage_companies
for select
to authenticated
using (
  created_by = (select auth.uid())
  or private.is_brokerage_member(id)
  or public.is_platform_admin()
);

drop policy if exists brokerage_member_read_self on public.brokerage_members;
create policy brokerage_member_read_self
on public.brokerage_members
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.is_brokerage_company_owner(company_id, false)
  or public.is_platform_admin()
);

drop policy if exists brokerage_member_add_owner on public.brokerage_members;
create policy brokerage_member_add_owner
on public.brokerage_members
for insert
to authenticated
with check (
  private.is_brokerage_company_owner(company_id, true)
);

-- Preview verification checklist:
-- 1. Run EXPLAIN/SELECT as an authenticated company owner, member, and unrelated user.
-- 2. Confirm owner can read own company and members, approved owner can add members.
-- 3. Confirm member can read only their company and unrelated users see no rows.
-- 4. Confirm platform admin access still works.
-- 5. Run Supabase security advisors and inspect function grants/ownership.
-- 6. Confirm PostgreSQL no longer reports SQLSTATE 42P17.
-- No user data is deleted or modified by this script.
