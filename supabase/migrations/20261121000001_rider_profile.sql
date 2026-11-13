-- =====================================================================
-- Rider profile: edit name / phone / vehicle, a richer "my rating and my
-- work" view, and deleting the rider account.
-- =====================================================================

-- A deleted rider leaves the past orders without a rider (the money of
-- those orders is settled before deletion is allowed).
alter table public.orders drop constraint if exists orders_driver_id_fkey;
alter table public.orders
  add constraint orders_driver_id_fkey
  foreign key (driver_id) references public.profiles (id) on delete set null;

-- ---------- edit my rider profile ---------------------------------------
-- Errors: not_a_driver, invalid_name, invalid_phone, invalid_vehicle
create or replace function public.driver_update_profile(
  p_full_name text, p_phone text, p_vehicle text)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  v_name text := btrim(regexp_replace(coalesce(p_full_name, ''), '\s+', ' ', 'g'));
  v_phone text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
begin
  if uid is null or not exists (select 1 from public.drivers where id = uid) then
    raise exception 'not_a_driver' using errcode = '42501';
  end if;
  if char_length(v_name) not between 2 and 60 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  if v_phone !~ '^0[567][0-9]{8}$' then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;
  if coalesce(p_vehicle, '') not in ('moto', 'car', 'bike') then
    raise exception 'invalid_vehicle' using errcode = '22023';
  end if;
  update public.drivers set phone = v_phone, vehicle = p_vehicle where id = uid;
  update public.profiles set full_name = v_name, phone = v_phone where id = uid;
end $$;
revoke all on function public.driver_update_profile(text, text, text) from public, anon;
grant execute on function public.driver_update_profile(text, text, text) to authenticated;

-- ---------- my work and my rating ----------------------------------------
-- Totals, the last 30 days, how many ratings of each star, the current
-- run of 5-star ratings. Never who rated.
create or replace function public.driver_profile_stats()
returns table (
  member_since timestamptz,
  deliveries_total integer,
  earned_total bigint,
  deliveries_30d integer,
  rating_avg numeric,
  rating_count integer,
  rating_avg_30d numeric,
  rating_count_30d integer,
  stars jsonb,
  five_star_streak integer)
language plpgsql stable security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null or not exists (select 1 from public.drivers where id = uid) then
    raise exception 'not_a_driver' using errcode = '42501';
  end if;
  return query
  with mine as (
    select o.delivered_at, o.delivery_fee
      from public.orders o
     where o.driver_id = uid and o.status = 'delivered'
  ), rated as (
    select r.driver_stars s, r.driver_rated_at at
      from public.order_ratings r
     where r.driver_id = uid and r.driver_stars is not null
  )
  select d.created_at,
         (select count(*)::int from mine),
         (select coalesce(sum(delivery_fee), 0)::bigint from mine),
         (select count(*)::int from mine where delivered_at > now() - interval '30 days'),
         (select case when count(*) >= 5 then round(avg(s)::numeric, 1) end from rated),
         (select count(*)::int from rated),
         (select case when count(*) >= 5 then round(avg(s)::numeric, 1) end
            from rated where at > now() - interval '30 days'),
         (select count(*)::int from rated where at > now() - interval '30 days'),
         (select jsonb_build_object(
                   '1', count(*) filter (where s = 1), '2', count(*) filter (where s = 2),
                   '3', count(*) filter (where s = 3), '4', count(*) filter (where s = 4),
                   '5', count(*) filter (where s = 5))
            from rated),
         (select count(*)::int from (
             select s, sum(case when s < 5 then 1 else 0 end)
                         over (order by at desc rows unbounded preceding) broken
               from rated) t
           where t.broken = 0)
    from public.drivers d
   where d.id = uid;
end $$;
revoke all on function public.driver_profile_stats() from public, anon;
grant execute on function public.driver_profile_stats() to authenticated;

-- ---------- delete my rider account -------------------------------------
-- Refused while a delivery runs or food money is not settled with a
-- restaurant. Past orders stay (without the rider) for the restaurants'
-- accounts; ratings lose the rider too. The app removes the photo first.
-- Errors: not_a_driver, active_orders, cash_pending
create or replace function public.delete_my_driver_account()
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null or not exists (select 1 from public.drivers where id = uid) then
    raise exception 'not_a_driver' using errcode = '42501';
  end if;
  if exists (select 1 from public.orders o
              where o.driver_id = uid
                and o.status in ('accepted', 'ready', 'picked_up')) then
    raise exception 'active_orders' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.orders o
              where o.driver_id = uid and o.status = 'delivered'
                and o.cash_confirmed_at is null) then
    raise exception 'cash_pending' using errcode = 'P0001';
  end if;
  -- Cascades: profile, rider row, last position, push tokens, reports
  -- the rider wrote. Orders and ratings keep a null rider.
  delete from auth.users where id = uid;
end $$;
revoke all on function public.delete_my_driver_account() from public, anon;
grant execute on function public.delete_my_driver_account() to authenticated;
