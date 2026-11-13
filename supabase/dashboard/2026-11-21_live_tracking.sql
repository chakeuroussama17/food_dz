-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261120000001_live_tracking.sql
-- Run 2026-11-20_ratings.sql first.
begin;

-- =====================================================================
-- Live tracking of the rider.
--   * During a delivery (order accepted / ready / picked up and assigned)
--     the rider's phone sends its position every few seconds.
--   * Only one point per rider is kept (the last one). Nothing is kept
--     once the rider has no delivery running: no history, no tracking
--     outside deliveries.
--   * The customer of the order, its restaurant team and the admin read
--     that point while the delivery runs, and only if it is fresh
--     (< 10 minutes).
-- =====================================================================

create table public.driver_locations (
  driver_id  uuid primary key references public.drivers (id) on delete cascade,
  lat        double precision not null check (lat between -90 and 90),
  lng        double precision not null check (lng between -180 and 180),
  updated_at timestamptz not null default now()
);
alter table public.driver_locations enable row level security;
-- Only through the functions below.
revoke all on public.driver_locations from anon, authenticated;

-- The rider's phone: "I am here". Ignored (and the old point removed)
-- when the rider has no delivery running.
-- Errors: not_allowed, invalid_location
create or replace function public.driver_update_location(
  p_lat double precision, p_lng double precision)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null or not exists (
       select 1 from public.drivers d where d.id = uid and d.is_approved) then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_lat is null or p_lng is null
     or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'invalid_location' using errcode = '22023';
  end if;
  if not exists (
       select 1 from public.orders o
        where o.driver_id = uid
          and o.status in ('accepted', 'ready', 'picked_up')) then
    delete from public.driver_locations where driver_id = uid;
    return;
  end if;
  insert into public.driver_locations as l (driver_id, lat, lng, updated_at)
  values (uid, p_lat, p_lng, now())
  on conflict (driver_id) do update
     set lat = excluded.lat, lng = excluded.lng, updated_at = excluded.updated_at;
end $$;
revoke all on function public.driver_update_location(double precision, double precision)
  from public, anon;
grant execute on function public.driver_update_location(double precision, double precision)
  to authenticated;

-- Where the rider of this order is now, with the restaurant and the
-- delivery point to draw the map. No row when the delivery is not
-- running, the point is too old, or the caller may not see it.
create or replace function public.order_driver_location(p_order_id uuid)
returns table (lat double precision, lng double precision, updated_at timestamptz,
               to_lat double precision, to_lng double precision,
               shop_lat double precision, shop_lng double precision)
language sql stable security definer set search_path = '' as $$
  select l.lat, l.lng, l.updated_at, o.lat, o.lng, r.lat, r.lng
    from public.orders o
    join public.driver_locations l on l.driver_id = o.driver_id
    join public.restaurants r on r.id = o.restaurant_id
   where o.id = p_order_id
     and o.status in ('accepted', 'ready', 'picked_up')
     and l.updated_at > now() - interval '10 minutes'
     and (o.customer_id = auth.uid()
          or public.has_restaurant_role(o.restaurant_id, 'staff')
          or public.is_admin());
$$;
revoke all on function public.order_driver_location(uuid) from public, anon;
grant execute on function public.order_driver_location(uuid) to authenticated;

-- When a delivery ends (delivered, cancelled, given back), forget the
-- point if the rider has nothing else running.
create or replace function public.forget_driver_location()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if old.driver_id is not null
     and (new.driver_id is distinct from old.driver_id
          or new.status not in ('accepted', 'ready', 'picked_up'))
     and not exists (
       select 1 from public.orders o
        where o.driver_id = old.driver_id and o.id <> new.id
          and o.status in ('accepted', 'ready', 'picked_up')) then
    delete from public.driver_locations where driver_id = old.driver_id;
  end if;
  return new;
end $$;
revoke all on function public.forget_driver_location() from public, anon, authenticated;

create trigger orders_forget_driver_location
  after update of status, driver_id on public.orders
  for each row execute function public.forget_driver_location();

notify pgrst, 'reload schema';

commit;
