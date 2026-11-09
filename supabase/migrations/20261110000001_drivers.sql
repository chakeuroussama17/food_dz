-- =====================================================================
-- Drivers: register, admin approval, online/offline, first come first
-- served dispatch, pickup and delivery. Clients never write to orders.
-- =====================================================================

create table public.drivers (
  id          uuid primary key references public.profiles (id) on delete cascade,
  phone       text not null check (phone ~ '^0[567][0-9]{8}$'),
  vehicle     text not null check (vehicle in ('moto', 'car', 'bike')),
  is_approved boolean not null default false,   -- admin switch
  is_online   boolean not null default false,   -- driver switch
  online_at   timestamptz,
  created_at  timestamptz not null default now()
);
alter table public.drivers enable row level security;
revoke all on public.drivers from anon, authenticated;
grant select on public.drivers to authenticated;
create policy "drivers: read own" on public.drivers
  for select to authenticated using (id = (select auth.uid()));

create index orders_driver_idx on public.orders (driver_id, placed_at desc);
create index orders_open_for_drivers_idx on public.orders (status)
  where driver_id is null and status in ('accepted', 'ready');

-- A driver reads the orders assigned to them (also what Realtime uses).
create policy "orders: driver reads assigned" on public.orders
  for select to authenticated using (driver_id = (select auth.uid()));

-- ---------- registration ----------------------------------------------
-- Errors: not_signed_in, account_has_role, invalid_phone, invalid_vehicle
create or replace function public.register_driver(p_phone text, p_vehicle text)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  v_role public.app_role;
  v_phone text := btrim(coalesce(p_phone, ''));
begin
  if uid is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  select role into v_role from public.profiles where id = uid for update;
  if v_role is distinct from 'customer'
     or exists (select 1 from public.drivers d where d.id = uid) then
    raise exception 'account_has_role' using errcode = 'P0001';
  end if;
  if v_phone !~ '^0[567][0-9]{8}$' then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;
  if coalesce(p_vehicle, '') not in ('moto', 'car', 'bike') then
    raise exception 'invalid_vehicle' using errcode = '22023';
  end if;
  insert into public.drivers (id, phone, vehicle) values (uid, v_phone, p_vehicle);
  update public.profiles set role = 'driver', phone = coalesce(phone, v_phone)
   where id = uid;
end $$;
revoke all on function public.register_driver(text, text) from public, anon;
grant execute on function public.register_driver(text, text) to authenticated;

create or replace function public.my_driver()
returns table (id uuid, full_name text, phone text, vehicle text,
               is_approved boolean, is_online boolean)
language sql stable security definer set search_path = '' as $$
  select d.id, p.full_name, d.phone, d.vehicle, d.is_approved, d.is_online
    from public.drivers d join public.profiles p on p.id = d.id
   where d.id = auth.uid();
$$;
revoke all on function public.my_driver() from public, anon;
grant execute on function public.my_driver() to authenticated;

-- Errors: not_a_driver, not_approved
create or replace function public.driver_set_online(p_online boolean)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  d record;
begin
  select x.is_approved into d from public.drivers x where x.id = auth.uid() for update;
  if not found then
    raise exception 'not_a_driver' using errcode = '42501';
  end if;
  if coalesce(p_online, false) and not d.is_approved then
    raise exception 'not_approved' using errcode = 'P0001';
  end if;
  update public.drivers
     set is_online = coalesce(p_online, false),
         online_at = case when coalesce(p_online, false) then now() else online_at end
   where id = auth.uid();
end $$;
revoke all on function public.driver_set_online(boolean) from public, anon;
grant execute on function public.driver_set_online(boolean) to authenticated;

-- ---------- dispatch ---------------------------------------------------
-- Orders the restaurant accepted and no driver took yet. Only for approved
-- drivers who are online. The customer's exact address and phone are only
-- shown once the driver takes the order (area + map point before).
create or replace function public.driver_available_orders()
returns table (
  id uuid, code text, status public.order_status,
  restaurant_name text, restaurant_address text, restaurant_area text,
  restaurant_lat double precision, restaurant_lng double precision,
  area text, lat double precision, lng double precision,
  delivery_fee integer, total integer, item_count integer,
  placed_at timestamptz, accepted_at timestamptz, ready_at timestamptz
)
language sql stable security definer set search_path = '' as $$
  select o.id, o.code, o.status,
         r.name, r.address, r.area, r.lat, r.lng,
         o.area, o.lat, o.lng,
         o.delivery_fee, o.total,
         (select coalesce(sum(i.quantity), 0)::int from public.order_items i
           where i.order_id = o.id),
         o.placed_at, o.accepted_at, o.ready_at
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
   where o.driver_id is null
     and o.status in ('accepted', 'ready')
     and exists (select 1 from public.drivers d
                  where d.id = auth.uid() and d.is_approved and d.is_online)
   order by (o.status = 'ready') desc, o.accepted_at asc
   limit 30;
$$;
revoke all on function public.driver_available_orders() from public, anon;
grant execute on function public.driver_available_orders() to authenticated;

-- First tap wins: the update only matches while nobody has the order.
-- One delivery at a time per driver (cash safety).
-- Errors: not_a_driver, not_approved, not_online, busy, already_taken
create or replace function public.driver_claim_order(p_order_id uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  d record;
begin
  -- Locking the driver row serialises two taps by the same driver.
  select x.is_approved, x.is_online into d
    from public.drivers x where x.id = uid for update;
  if not found then
    raise exception 'not_a_driver' using errcode = '42501';
  end if;
  if not d.is_approved then
    raise exception 'not_approved' using errcode = 'P0001';
  end if;
  if not d.is_online then
    raise exception 'not_online' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.orders o
              where o.driver_id = uid
                and o.status in ('accepted', 'ready', 'picked_up')) then
    raise exception 'busy' using errcode = 'P0001';
  end if;

  update public.orders o set driver_id = uid
   where o.id = p_order_id
     and o.driver_id is null
     and o.status in ('accepted', 'ready');
  if not found then
    raise exception 'already_taken' using errcode = 'P0001';
  end if;
end $$;
revoke all on function public.driver_claim_order(uuid) from public, anon;
grant execute on function public.driver_claim_order(uuid) to authenticated;

-- Give an order back before pickup (it goes back to the other drivers).
-- Errors: order_not_found, not_allowed
create or replace function public.driver_release_order(p_order_id uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_status public.order_status;
begin
  select o.status into v_status from public.orders o
   where o.id = p_order_id and o.driver_id = auth.uid() for update;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
  if v_status not in ('accepted', 'ready') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.orders set driver_id = null where id = p_order_id;
end $$;
revoke all on function public.driver_release_order(uuid) from public, anon;
grant execute on function public.driver_release_order(uuid) to authenticated;

-- ready -> picked_up, picked_up -> delivered (commission is computed by
-- the orders trigger at delivery). Errors: order_not_found, not_allowed
create or replace function public.driver_set_order_status(
  p_order_id uuid, p_status public.order_status)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_status public.order_status;
begin
  select o.status into v_status from public.orders o
   where o.id = p_order_id and o.driver_id = auth.uid() for update;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
  if not ((v_status, p_status) in (
            ('ready'::public.order_status, 'picked_up'::public.order_status),
            ('picked_up', 'delivered'))) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.orders set status = p_status where id = p_order_id;
end $$;
revoke all on function public.driver_set_order_status(uuid, public.order_status)
  from public, anon;
grant execute on function public.driver_set_order_status(uuid, public.order_status)
  to authenticated;

-- The driver's own orders with everything needed to deliver.
-- p_active = true: in progress; false: finished (newest first).
create or replace function public.driver_orders(
  p_active boolean default true,
  p_limit  integer default 50
)
returns table (
  id uuid, code text, status public.order_status,
  restaurant_name text, restaurant_address text, restaurant_area text,
  restaurant_phone text,
  restaurant_lat double precision, restaurant_lng double precision,
  customer_name text, customer_phone text,
  address_text text, area text, address_details text,
  lat double precision, lng double precision, notes text,
  food_total integer, delivery_fee integer, total integer,
  reject_reason text,
  placed_at timestamptz, accepted_at timestamptz, ready_at timestamptz,
  picked_up_at timestamptz, delivered_at timestamptz, cancelled_at timestamptz,
  items jsonb
)
language sql stable security definer set search_path = '' as $$
  select o.id, o.code, o.status,
         r.name, r.address, r.area, r.phone, r.lat, r.lng,
         o.customer_name, o.customer_phone,
         o.address_text, o.area, o.address_details,
         o.lat, o.lng, o.notes,
         o.food_total, o.delivery_fee, o.total,
         o.reject_reason,
         o.placed_at, o.accepted_at, o.ready_at,
         o.picked_up_at, o.delivered_at, o.cancelled_at,
         coalesce((select jsonb_agg(jsonb_build_object(
                     'name', i.name, 'unit_price', i.unit_price,
                     'quantity', i.quantity, 'line_total', i.line_total)
                   order by i.id)
                     from public.order_items i where i.order_id = o.id),
                  '[]'::jsonb)
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
   where o.driver_id = auth.uid()
     and (case when coalesce(p_active, true)
               then o.status in ('accepted', 'ready', 'picked_up')
               else o.status in ('delivered', 'cancelled', 'rejected') end)
   order by o.placed_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;
revoke all on function public.driver_orders(boolean, integer) from public, anon;
grant execute on function public.driver_orders(boolean, integer) to authenticated;

-- ---------- customer + restaurant now see the driver ---------------------
-- (Return columns change, so the functions are dropped and recreated.)
drop function if exists public.my_orders(uuid, integer);
create function public.my_orders(
  p_order_id uuid default null,
  p_limit    integer default 50
)
returns table (
  id uuid, code text, status public.order_status,
  restaurant_id uuid, restaurant_name text, restaurant_logo text,
  restaurant_slug text, restaurant_phone text,
  address_text text, area text, address_details text,
  customer_phone text, notes text,
  food_total integer, delivery_fee integer, total integer,
  reject_reason text,
  placed_at timestamptz, accepted_at timestamptz, ready_at timestamptz,
  picked_up_at timestamptz, delivered_at timestamptz, cancelled_at timestamptz,
  items jsonb,
  driver_name text, driver_phone text
)
language sql stable security definer set search_path = '' as $$
  select o.id, o.code, o.status,
         r.id, r.name, r.logo_url, r.slug, r.phone,
         o.address_text, o.area, o.address_details,
         o.customer_phone, o.notes,
         o.food_total, o.delivery_fee, o.total,
         o.reject_reason,
         o.placed_at, o.accepted_at, o.ready_at,
         o.picked_up_at, o.delivered_at, o.cancelled_at,
         coalesce((select jsonb_agg(jsonb_build_object(
                     'name', i.name, 'unit_price', i.unit_price,
                     'quantity', i.quantity, 'line_total', i.line_total)
                   order by i.id)
                     from public.order_items i where i.order_id = o.id),
                  '[]'::jsonb),
         dp.full_name, d.phone
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
    left join public.drivers d on d.id = o.driver_id
    left join public.profiles dp on dp.id = o.driver_id
   where o.customer_id = auth.uid()
     and (p_order_id is null or o.id = p_order_id)
   order by o.placed_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;
revoke all on function public.my_orders(uuid, integer) from public, anon;
grant execute on function public.my_orders(uuid, integer) to authenticated;

drop function if exists public.owner_orders(boolean, integer);
create function public.owner_orders(
  p_active boolean default true,
  p_limit  integer default 100
)
returns table (
  id uuid, code text, status public.order_status,
  customer_name text, customer_phone text,
  address_text text, area text, address_details text,
  lat double precision, lng double precision, notes text,
  food_total integer, delivery_fee integer, total integer,
  reject_reason text,
  placed_at timestamptz, accepted_at timestamptz, ready_at timestamptz,
  picked_up_at timestamptz, delivered_at timestamptz, cancelled_at timestamptz,
  items jsonb,
  driver_name text, driver_phone text
)
language sql stable security definer set search_path = '' as $$
  select o.id, o.code, o.status,
         o.customer_name, o.customer_phone,
         o.address_text, o.area, o.address_details,
         o.lat, o.lng, o.notes,
         o.food_total, o.delivery_fee, o.total,
         o.reject_reason,
         o.placed_at, o.accepted_at, o.ready_at,
         o.picked_up_at, o.delivered_at, o.cancelled_at,
         coalesce((select jsonb_agg(jsonb_build_object(
                     'name', i.name, 'unit_price', i.unit_price,
                     'quantity', i.quantity, 'line_total', i.line_total)
                   order by i.id)
                     from public.order_items i where i.order_id = o.id),
                  '[]'::jsonb),
         dp.full_name, d.phone
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
    left join public.drivers d on d.id = o.driver_id
    left join public.profiles dp on dp.id = o.driver_id
   where r.owner_id = auth.uid()
     and (case when coalesce(p_active, true)
               then o.status in ('placed', 'accepted', 'ready', 'picked_up')
               else o.status in ('delivered', 'rejected', 'cancelled') end)
   order by case when coalesce(p_active, true) then o.placed_at end asc,
            o.placed_at desc
   limit least(greatest(coalesce(p_limit, 100), 1), 200);
$$;
revoke all on function public.owner_orders(boolean, integer) from public, anon;
grant execute on function public.owner_orders(boolean, integer) to authenticated;

-- ---------- admin --------------------------------------------------------
create or replace function public.admin_list_drivers()
returns table (
  id uuid, full_name text, email text, phone text, vehicle text,
  is_approved boolean, is_online boolean, created_at timestamptz,
  delivered_count integer, active_order_code text
)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select d.id, p.full_name, u.email::text, d.phone, d.vehicle,
         d.is_approved, d.is_online, d.created_at,
         (select count(*)::int from public.orders o
           where o.driver_id = d.id and o.status = 'delivered'),
         (select o.code from public.orders o
           where o.driver_id = d.id
             and o.status in ('accepted', 'ready', 'picked_up')
           limit 1)
    from public.drivers d
    join public.profiles p on p.id = d.id
    left join auth.users u on u.id = d.id
   order by d.is_approved, d.created_at desc;
end $$;
revoke all on function public.admin_list_drivers() from public, anon;
grant execute on function public.admin_list_drivers() to authenticated;

create or replace function public.admin_set_driver_approved(p_id uuid, p_approved boolean)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  update public.drivers
     set is_approved = coalesce(p_approved, false),
         is_online = case when coalesce(p_approved, false) then is_online else false end
   where id = p_id;
  if not found then
    raise exception 'driver not found' using errcode = 'P0002';
  end if;
end $$;
revoke all on function public.admin_set_driver_approved(uuid, boolean) from public, anon;
grant execute on function public.admin_set_driver_approved(uuid, boolean) to authenticated;
