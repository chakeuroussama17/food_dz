-- =====================================================================
-- Checkout: customers place, follow and cancel their orders.
-- Clients never write to the orders tables. Everything goes through
-- these functions, and prices always come from the database.
-- =====================================================================

-- Same "Place order" tap sent twice (double tap, network retry) creates
-- one order only.
alter table public.orders add column client_ref uuid;
create unique index orders_client_ref_idx
  on public.orders (customer_id, client_ref) where client_ref is not null;

-- ---------- place_order ----------------------------------------------
-- p_items: [{"id": "<menu item uuid>", "qty": 2}, ...]
-- p_expected_total: the total the customer saw. If prices changed in the
-- meantime the order is refused with 'prices_changed' instead of charging
-- a different amount.
--
-- Errors (message = key the app translates):
--   not_signed_in, customers_only, too_many_active_orders, too_many_orders,
--   restaurant_unavailable, restaurant_closed, invalid_phone, invalid_notes,
--   address_not_found, invalid_items, item_unavailable, prices_changed
create or replace function public.place_order(
  p_restaurant_id  uuid,
  p_items          jsonb,
  p_address_id     uuid,
  p_phone          text,
  p_notes          text default '',
  p_expected_total integer default null,
  p_client_ref     uuid default null
)
returns table (id uuid, code text, food_total integer, delivery_fee integer, total integer)
language plpgsql volatile security definer set search_path = '' as $$
#variable_conflict use_column
declare
  uid        uuid := auth.uid();
  v_role     public.app_role;
  v_name     text;
  v_phone    text := btrim(coalesce(p_phone, ''));
  v_notes    text := btrim(coalesce(p_notes, ''));
  r          record;
  a          record;
  v_fee      integer;
  v_rate     numeric;
  v_food     integer;
  v_wanted   integer;
  v_found    integer;
  v_order    uuid;
begin
  if uid is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;

  select p.role, btrim(coalesce(p.full_name, '')) into v_role, v_name
    from public.profiles p where p.id = uid for update;
  if v_role is distinct from 'customer' then
    raise exception 'customers_only' using errcode = '42501';
  end if;

  -- Retry of an order already placed: return it unchanged.
  if p_client_ref is not null then
    return query
      select o.id, o.code, o.food_total, o.delivery_fee, o.total
        from public.orders o
       where o.customer_id = uid and o.client_ref = p_client_ref;
    if found then return; end if;
  end if;

  -- Abuse limits.
  if (select count(*) from public.orders o
       where o.customer_id = uid
         and o.status in ('placed', 'accepted', 'ready', 'picked_up')) >= 3 then
    raise exception 'too_many_active_orders' using errcode = 'P0001';
  end if;
  if (select count(*) from public.orders o
       where o.customer_id = uid
         and o.placed_at > now() - interval '1 hour') >= 10 then
    raise exception 'too_many_orders' using errcode = 'P0001';
  end if;

  select x.is_active, x.is_open, x.commission_rate into r
    from public.restaurants x where x.id = p_restaurant_id for share;
  if not found or not r.is_active then
    raise exception 'restaurant_unavailable' using errcode = 'P0001';
  end if;
  if not r.is_open then
    raise exception 'restaurant_closed' using errcode = 'P0001';
  end if;

  if v_phone !~ '^0[567][0-9]{8}$' then
    raise exception 'invalid_phone' using errcode = 'P0001';
  end if;
  if char_length(v_notes) > 300 then
    raise exception 'invalid_notes' using errcode = 'P0001';
  end if;

  select ad.address_text, ad.area, ad.details, ad.lat, ad.lng into a
    from public.addresses ad
   where ad.id = p_address_id and ad.user_id = uid;
  if not found then
    raise exception 'address_not_found' using errcode = 'P0001';
  end if;

  -- Items: 1..30 lines, 1..20 of each dish, ids must be uuids.
  if jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) not between 1 and 30
     or exists (
       select 1 from jsonb_array_elements(p_items) e
        where jsonb_typeof(e) <> 'object'
           or coalesce(e->>'id', '') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
           or coalesce(e->>'qty', '') !~ '^[0-9]{1,2}$'
           or (e->>'qty')::int not between 1 and 20) then
    raise exception 'invalid_items' using errcode = 'P0001';
  end if;

  create temporary table if not exists pg_temp.checkout_lines (
    menu_item_id uuid primary key, qty integer not null
  ) on commit drop;
  truncate pg_temp.checkout_lines;
  insert into pg_temp.checkout_lines (menu_item_id, qty)
  select (e->>'id')::uuid, sum((e->>'qty')::int)
    from jsonb_array_elements(p_items) e
   group by 1;
  if exists (select 1 from pg_temp.checkout_lines l where l.qty > 20) then
    raise exception 'invalid_items' using errcode = 'P0001';
  end if;

  select count(*) into v_wanted from pg_temp.checkout_lines;
  select count(*), coalesce(sum(m.price * l.qty), 0)
    into v_found, v_food
    from pg_temp.checkout_lines l
    join public.menu_items m on m.id = l.menu_item_id
   where m.restaurant_id = p_restaurant_id and m.is_available;
  if v_found <> v_wanted then
    raise exception 'item_unavailable' using errcode = 'P0001';
  end if;

  select c.delivery_fee, coalesce(r.commission_rate, c.default_commission_rate)
    into v_fee, v_rate
    from public.app_config c limit 1;

  if p_expected_total is not null and p_expected_total <> v_food + v_fee then
    raise exception 'prices_changed' using errcode = 'P0001';
  end if;

  insert into public.orders
    (customer_id, restaurant_id, customer_name, customer_phone,
     address_text, area, address_details, lat, lng, notes,
     food_total, delivery_fee, commission_rate, client_ref)
  values
    (uid, p_restaurant_id,
     left(case when char_length(v_name) = 0 then 'Client' else v_name end, 80),
     v_phone, left(a.address_text, 200), left(coalesce(a.area, ''), 80),
     left(coalesce(a.details, ''), 120), a.lat, a.lng, v_notes,
     v_food, v_fee, v_rate, p_client_ref)
  returning orders.id into v_order;

  insert into public.order_items (order_id, menu_item_id, name, unit_price, quantity)
  select v_order, m.id, m.name, m.price, l.qty
    from pg_temp.checkout_lines l
    join public.menu_items m on m.id = l.menu_item_id
   order by m.sort_order, m.name;

  -- First order: remember the phone on the profile.
  update public.profiles p set phone = v_phone
   where p.id = uid and (p.phone is null or p.phone = '');

  return query
    select o.id, o.code, o.food_total, o.delivery_fee, o.total
      from public.orders o where o.id = v_order;
end $$;

revoke all on function public.place_order(uuid, jsonb, uuid, text, text, integer, uuid)
  from public, anon;
grant execute on function public.place_order(uuid, jsonb, uuid, text, text, integer, uuid)
  to authenticated;

-- ---------- cancel_my_order -------------------------------------------
-- A customer can cancel only until the restaurant accepts the order.
create or replace function public.cancel_my_order(p_order_id uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_status public.order_status;
begin
  select o.status into v_status from public.orders o
   where o.id = p_order_id and o.customer_id = auth.uid()
   for update;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
  if v_status <> 'placed' then
    raise exception 'cannot_cancel' using errcode = 'P0001';
  end if;
  update public.orders set status = 'cancelled' where id = p_order_id;
end $$;

revoke all on function public.cancel_my_order(uuid) from public, anon;
grant execute on function public.cancel_my_order(uuid) to authenticated;

-- ---------- my_orders -------------------------------------------------
-- The customer's orders with restaurant name/logo and items (the
-- restaurant may have been deactivated since, so it isn't read through
-- the public restaurants policy). p_order_id = one order only.
create or replace function public.my_orders(
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
  items jsonb
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
                  '[]'::jsonb)
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
   where o.customer_id = auth.uid()
     and (p_order_id is null or o.id = p_order_id)
   order by o.placed_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

revoke all on function public.my_orders(uuid, integer) from public, anon;
grant execute on function public.my_orders(uuid, integer) to authenticated;

-- ---------- Realtime --------------------------------------------------
-- Status changes are pushed to the apps (customer tracking now, the
-- restaurant's live orders next). Realtime applies the RLS policies, so
-- each user only receives orders they are allowed to read.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (select 1 from pg_publication_tables
                      where pubname = 'supabase_realtime'
                        and schemaname = 'public' and tablename = 'orders') then
    alter publication supabase_realtime add table public.orders;
  end if;
end $$;
