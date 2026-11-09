-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261109000001_restaurant_orders.sql
-- Run AFTER 2026-11-08_checkout.sql.
begin;

-- =====================================================================
-- Restaurant live orders: the owner sees their restaurant's orders and
-- moves them on (accept / reject / ready / cancel). Clients still never
-- write to the orders table; the status rules trigger applies as well.
-- =====================================================================

-- ---------- owner_orders ----------------------------------------------
-- p_active = true: orders in progress, oldest first (kitchen order).
-- p_active = false: finished orders, newest first.
create or replace function public.owner_orders(
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
  items jsonb
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
                  '[]'::jsonb)
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
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

-- ---------- owner_set_order_status -------------------------------------
-- What a restaurant may do:
--   placed   -> accepted
--   placed   -> rejected   (reason required)
--   accepted -> ready
--   accepted -> cancelled  (reason required, e.g. customer unreachable)
--   ready    -> cancelled  (reason required)
-- Pickup and delivery belong to the driver (next step).
-- Errors: order_not_found, not_allowed, reason_required.
create or replace function public.owner_set_order_status(
  p_order_id uuid,
  p_status   public.order_status,
  p_reason   text default null
)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_status public.order_status;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  select o.status into v_status
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
   where o.id = p_order_id and r.owner_id = auth.uid()
   for update of o;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;

  if not ((v_status, p_status) in (
            ('placed'::public.order_status, 'accepted'::public.order_status),
            ('placed', 'rejected'),
            ('accepted', 'ready'),
            ('accepted', 'cancelled'),
            ('ready', 'cancelled'))) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;

  if p_status in ('rejected', 'cancelled') then
    if v_reason is null then
      raise exception 'reason_required' using errcode = 'P0001';
    end if;
    if char_length(v_reason) > 200 then
      v_reason := left(v_reason, 200);
    end if;
  else
    v_reason := null;
  end if;

  update public.orders
     set status = p_status,
         reject_reason = coalesce(v_reason, reject_reason)
   where id = p_order_id;
end $$;

revoke all on function public.owner_set_order_status(uuid, public.order_status, text)
  from public, anon;
grant execute on function public.owner_set_order_status(uuid, public.order_status, text)
  to authenticated;

commit;
