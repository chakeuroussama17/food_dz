-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261111000001_cash_and_proof.sql
-- Run AFTER 2026-11-10_drivers.sql (and the demo driver file).
begin;

-- =====================================================================
-- Proof of delivery (photo) and cash handover driver -> restaurant.
--
-- * Delivering requires a photo the driver takes in the app. It is stored
--   privately; the customer, the driver and the admin can see it.
-- * After delivery the driver owes the food total to the restaurant. The
--   driver marks "handed", the restaurant confirms "received" (it can also
--   confirm directly). A driver with money unconfirmed for more than
--   app_config.cash_handover_hours (24 h) can't take new orders.
-- =====================================================================

alter table public.orders add column delivery_photo_path text
  check (char_length(delivery_photo_path) <= 200);

alter table public.app_config
  add column cash_handover_hours integer not null default 24
  check (cash_handover_hours between 1 and 168);

create index orders_cash_open_idx on public.orders (driver_id, delivered_at)
  where status = 'delivered' and cash_confirmed_at is null;

-- ---------- storage: delivery-proofs/<order id>/<file> (private) ---------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('delivery-proofs', 'delivery-proofs', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- Folder name -> order id, or null when it isn't a uuid.
create or replace function public.proof_order_id(p_name text)
returns uuid language sql immutable set search_path = '' as $$
  select case when (storage.foldername(p_name))[1]
                   ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
              then ((storage.foldername(p_name))[1])::uuid end;
$$;
grant execute on function public.proof_order_id(text) to authenticated;

-- Upload: only the assigned driver, only while the order is on its way.
create or replace function public.can_upload_proof(p_name text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.orders o
                  where o.id = public.proof_order_id(p_name)
                    and o.driver_id = auth.uid()
                    and o.status = 'picked_up');
$$;
revoke all on function public.can_upload_proof(text) from public, anon;
grant execute on function public.can_upload_proof(text) to authenticated;

-- See: the order's driver and customer, and the admin.
create or replace function public.can_view_proof(p_name text)
returns boolean language sql stable security definer set search_path = '' as $$
  select public.is_admin()
      or exists (select 1 from public.orders o
                  where o.id = public.proof_order_id(p_name)
                    and auth.uid() in (o.driver_id, o.customer_id));
$$;
revoke all on function public.can_view_proof(text) from public, anon;
grant execute on function public.can_view_proof(text) to authenticated;

create policy "delivery-proofs: driver uploads"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'delivery-proofs' and public.can_upload_proof(name));
create policy "delivery-proofs: involved people read"
  on storage.objects for select to authenticated
  using (bucket_id = 'delivery-proofs' and public.can_view_proof(name));

-- ---------- delivery with photo -----------------------------------------
-- The only way to mark an order delivered. The photo must already be
-- uploaded under delivery-proofs/<order id>/.
-- Errors: order_not_found, not_allowed, photo_required
create or replace function public.driver_complete_delivery(
  p_order_id uuid, p_photo_path text)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_status public.order_status;
begin
  select o.status into v_status from public.orders o
   where o.id = p_order_id and o.driver_id = auth.uid() for update;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
  if v_status <> 'picked_up' then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_photo_path is null
     or public.proof_order_id(p_photo_path) is distinct from p_order_id
     or not exists (select 1 from storage.objects s
                     where s.bucket_id = 'delivery-proofs' and s.name = p_photo_path) then
    raise exception 'photo_required' using errcode = 'P0001';
  end if;
  update public.orders
     set status = 'delivered', delivery_photo_path = p_photo_path
   where id = p_order_id;
end $$;
revoke all on function public.driver_complete_delivery(uuid, text) from public, anon;
grant execute on function public.driver_complete_delivery(uuid, text) to authenticated;

-- Pickup only now: delivering goes through driver_complete_delivery.
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
  if not (v_status = 'ready' and p_status = 'picked_up') then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.orders set status = p_status where id = p_order_id;
end $$;

-- ---------- cash handover -----------------------------------------------
-- Delivered orders whose food money the restaurant hasn't confirmed.
create or replace function public.cash_overdue(p_driver uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.orders o cross join public.app_config c
     where o.driver_id = p_driver
       and o.status = 'delivered'
       and o.cash_confirmed_at is null
       and o.delivered_at < now() - make_interval(hours => c.cash_handover_hours));
$$;
revoke all on function public.cash_overdue(uuid) from public, anon, authenticated;

-- Driver: "I gave the food money to the restaurant".
-- Errors: order_not_found, not_allowed
create or replace function public.driver_mark_cash_handed(p_order_id uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  update public.orders o set cash_handed_at = now()
   where o.id = p_order_id and o.driver_id = auth.uid()
     and o.status = 'delivered' and o.cash_handed_at is null
     and o.cash_confirmed_at is null;
  if not found then
    if exists (select 1 from public.orders o
                where o.id = p_order_id and o.driver_id = auth.uid()) then
      raise exception 'not_allowed' using errcode = 'P0001';
    end if;
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
end $$;
revoke all on function public.driver_mark_cash_handed(uuid) from public, anon;
grant execute on function public.driver_mark_cash_handed(uuid) to authenticated;

-- Restaurant: "money received" (also when the driver forgot to tap).
-- Errors: order_not_found, not_allowed
create or replace function public.owner_confirm_cash(p_order_id uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  update public.orders o
     set cash_confirmed_at = now(),
         cash_handed_at = coalesce(o.cash_handed_at, now())
    from public.restaurants r
   where o.id = p_order_id and r.id = o.restaurant_id and r.owner_id = auth.uid()
     and o.status = 'delivered' and o.driver_id is not null
     and o.cash_confirmed_at is null;
  if not found then
    if exists (select 1 from public.orders o
                 join public.restaurants r on r.id = o.restaurant_id
                where o.id = p_order_id and r.owner_id = auth.uid()) then
      raise exception 'not_allowed' using errcode = 'P0001';
    end if;
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
end $$;
revoke all on function public.owner_confirm_cash(uuid) from public, anon;
grant execute on function public.owner_confirm_cash(uuid) to authenticated;

-- Money still open, for the driver (what to hand) and the restaurant (what
-- to receive). Oldest first.
create or replace function public.driver_cash_pending()
returns table (id uuid, code text, restaurant_name text, restaurant_phone text,
               food_total integer, delivered_at timestamptz,
               cash_handed_at timestamptz, overdue boolean)
language sql stable security definer set search_path = '' as $$
  select o.id, o.code, r.name, r.phone, o.food_total, o.delivered_at,
         o.cash_handed_at,
         o.delivered_at < now() - make_interval(hours => c.cash_handover_hours)
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
    cross join public.app_config c
   where o.driver_id = auth.uid()
     and o.status = 'delivered' and o.cash_confirmed_at is null
   order by o.delivered_at;
$$;
revoke all on function public.driver_cash_pending() from public, anon;
grant execute on function public.driver_cash_pending() to authenticated;

create or replace function public.owner_cash_pending()
returns table (id uuid, code text, driver_name text, driver_phone text,
               food_total integer, delivered_at timestamptz,
               cash_handed_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select o.id, o.code, dp.full_name, d.phone, o.food_total, o.delivered_at,
         o.cash_handed_at
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
    left join public.drivers d on d.id = o.driver_id
    left join public.profiles dp on dp.id = o.driver_id
   where r.owner_id = auth.uid()
     and o.status = 'delivered' and o.driver_id is not null
     and o.cash_confirmed_at is null
   order by o.delivered_at;
$$;
revoke all on function public.owner_cash_pending() from public, anon;
grant execute on function public.owner_cash_pending() to authenticated;

-- ---------- 24 h block on taking orders -----------------------------------
-- Same as before, plus: refused while food money is overdue.
-- Errors: not_a_driver, not_approved, not_online, cash_overdue, busy,
--         already_taken
create or replace function public.driver_claim_order(p_order_id uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  d record;
begin
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
  if public.cash_overdue(uid) then
    raise exception 'cash_overdue' using errcode = 'P0001';
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

-- ---------- functions whose results gain columns -------------------------
drop function if exists public.my_driver();
create function public.my_driver()
returns table (id uuid, full_name text, phone text, vehicle text,
               is_approved boolean, is_online boolean,
               cash_owed integer, cash_blocked boolean)
language sql stable security definer set search_path = '' as $$
  select d.id, p.full_name, d.phone, d.vehicle, d.is_approved, d.is_online,
         (select coalesce(sum(o.food_total), 0)::int from public.orders o
           where o.driver_id = d.id and o.status = 'delivered'
             and o.cash_confirmed_at is null),
         public.cash_overdue(d.id)
    from public.drivers d join public.profiles p on p.id = d.id
   where d.id = auth.uid();
$$;
revoke all on function public.my_driver() from public, anon;
grant execute on function public.my_driver() to authenticated;

drop function if exists public.admin_list_drivers();
create function public.admin_list_drivers()
returns table (
  id uuid, full_name text, email text, phone text, vehicle text,
  is_approved boolean, is_online boolean, created_at timestamptz,
  delivered_count integer, active_order_code text,
  cash_owed integer, cash_owed_count integer, cash_oldest_at timestamptz,
  cash_blocked boolean
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
           limit 1),
         c.owed, c.n, c.oldest,
         public.cash_overdue(d.id)
    from public.drivers d
    join public.profiles p on p.id = d.id
    left join auth.users u on u.id = d.id
    cross join lateral (
      select coalesce(sum(o.food_total), 0)::int as owed,
             count(*)::int as n,
             min(o.delivered_at) as oldest
        from public.orders o
       where o.driver_id = d.id and o.status = 'delivered'
         and o.cash_confirmed_at is null) c
   order by d.is_approved, c.owed desc, d.created_at desc;
end $$;
revoke all on function public.admin_list_drivers() from public, anon;
grant execute on function public.admin_list_drivers() to authenticated;

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
  driver_name text, driver_phone text,
  delivery_photo_path text
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
         dp.full_name, d.phone,
         o.delivery_photo_path
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

-- Admin: delivery photo, driver and cash state of one order.
create or replace function public.admin_order_delivery(p_order_id uuid)
returns table (driver_name text, driver_phone text, delivery_photo_path text,
               cash_handed_at timestamptz, cash_confirmed_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select dp.full_name, d.phone, o.delivery_photo_path,
         o.cash_handed_at, o.cash_confirmed_at
    from public.orders o
    left join public.drivers d on d.id = o.driver_id
    left join public.profiles dp on dp.id = o.driver_id
   where o.id = p_order_id;
end $$;
revoke all on function public.admin_order_delivery(uuid) from public, anon;
grant execute on function public.admin_order_delivery(uuid) to authenticated;

commit;
