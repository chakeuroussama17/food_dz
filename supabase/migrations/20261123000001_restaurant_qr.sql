-- =====================================================================
-- Restaurant QR codes.
--
-- Every restaurant's QR code opens  <public_base_url>/r/<slug>?src=qr.
-- The address is a setting (no domain yet: the admin changes it later,
-- before printing). The in-app scanner reads any foodfennec link.
-- Each visit from a QR code (or a shared link) is counted, so the
-- restaurant sees how many people scanned its code.
-- =====================================================================

alter table public.app_config
  add column if not exists public_base_url text not null
    default 'https://foodfennec.com'
    check (public_base_url ~ '^https?://[a-z0-9.-]+(:[0-9]{1,5})?$');
grant select (public_base_url) on public.app_config to anon, authenticated;

-- The new brand name on receipts, unless the admin already chose one.
alter table public.app_config alter column business_name set default 'foodfennec';
update public.app_config set business_name = 'foodfennec' where business_name = 'Food';

-- Errors: invalid_url
create or replace function public.admin_set_public_url(p_url text)
returns text language plpgsql volatile security definer set search_path = '' as $$
declare
  v text := lower(regexp_replace(btrim(coalesce(p_url, '')), '/+$', ''));
begin
  perform public.assert_admin();
  if v !~ '^https?://[a-z0-9.-]+(:[0-9]{1,5})?$' or v !~ '\.' and v !~ '//localhost' then
    raise exception 'invalid_url' using errcode = 'P0001';
  end if;
  update public.app_config set public_base_url = v;
  return v;
end $$;
revoke all on function public.admin_set_public_url(text) from public, anon;
grant execute on function public.admin_set_public_url(text) to authenticated;

-- ---------- visits --------------------------------------------------------
-- qr_app: scanned with the in-app scanner; qr_web: phone camera / browser
-- (the link carries ?src=qr); link: a shared link.
create table if not exists public.restaurant_visits (
  id            bigint generated always as identity primary key,
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  source        text not null check (source in ('qr_app', 'qr_web', 'link')),
  user_id       uuid references auth.users (id) on delete set null,
  created_at    timestamptz not null default now()
);
create index if not exists restaurant_visits_restaurant_idx
  on public.restaurant_visits (restaurant_id, created_at);
create index if not exists restaurant_visits_user_idx
  on public.restaurant_visits (user_id, created_at);
alter table public.restaurant_visits enable row level security;
-- No policies: read through the functions below only.

-- Counts one visit (the same person, restaurant and source at most once
-- every 10 minutes, so reloading the page doesn't inflate the count).
-- Unknown or inactive restaurants are ignored silently.
create or replace function public.log_restaurant_visit(p_slug text, p_source text)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_rid uuid;
begin
  if p_source not in ('qr_app', 'qr_web', 'link') then
    return;
  end if;
  select r.id into v_rid from public.restaurants r
   where r.slug = lower(btrim(coalesce(p_slug, ''))) and r.is_active;
  if v_rid is null then
    return;
  end if;
  if exists (
    select 1 from public.restaurant_visits v
     where v.restaurant_id = v_rid and v.source = p_source
       and v.user_id is not distinct from auth.uid()
       and v.created_at > now() - interval '10 minutes') then
    return;
  end if;
  insert into public.restaurant_visits (restaurant_id, source, user_id)
  values (v_rid, p_source, auth.uid());
end $$;
revoke all on function public.log_restaurant_visit(text, text) from public, anon;
grant execute on function public.log_restaurant_visit(text, text) to authenticated;

-- Scan numbers for the restaurant team (any role) and the admin.
-- Errors: not_allowed
create or replace function public.restaurant_qr_stats(p_restaurant_id uuid)
returns table (
  scans_total integer, scans_30d integer, scans_7d integer,
  app_scans integer, web_scans integer, people integer, orders_after integer
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not (public.has_restaurant_role(p_restaurant_id, 'staff')
          or exists (select 1 from public.profiles
                      where id = auth.uid() and role = 'admin')) then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  return query
  with v as (
    select * from public.restaurant_visits
     where restaurant_id = p_restaurant_id and source in ('qr_app', 'qr_web')
  )
  select
    count(*)::integer,
    count(*) filter (where v.created_at > now() - interval '30 days')::integer,
    count(*) filter (where v.created_at > now() - interval '7 days')::integer,
    count(*) filter (where v.source = 'qr_app')::integer,
    count(*) filter (where v.source = 'qr_web')::integer,
    count(distinct v.user_id)::integer,
    -- People who ordered here within 24 h after scanning.
    (select count(distinct o.id)::integer
       from public.orders o
      where o.restaurant_id = p_restaurant_id
        and exists (select 1 from v v2
                     where v2.user_id = o.customer_id
                       and o.placed_at between v2.created_at
                                           and v2.created_at + interval '24 hours'))
  from v;
end $$;
revoke all on function public.restaurant_qr_stats(uuid) from public, anon;
grant execute on function public.restaurant_qr_stats(uuid) to authenticated;
