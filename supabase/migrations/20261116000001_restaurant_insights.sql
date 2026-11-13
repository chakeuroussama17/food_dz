-- =====================================================================
-- Restaurant side v2:
--   * owner_report(from, to): every order of a period, for the orders
--     table, the CSV export and the trends page (computed in the app).
--   * delete_my_restaurant_account(): the owner closes their account.
--     The restaurant is archived (hidden, no owner) so orders, receipts
--     and commission statements stay for the books.
-- =====================================================================

-- ---------- report ----------------------------------------------------
create or replace function public.owner_report(
  p_from timestamptz,
  p_to   timestamptz
)
returns table (
  id uuid, code text, status public.order_status,
  customer_name text, area text,
  food_total integer, delivery_fee integer, total integer,
  commission_amount integer,
  reject_reason text,
  placed_at timestamptz, accepted_at timestamptz, ready_at timestamptz,
  picked_up_at timestamptz, delivered_at timestamptz, cancelled_at timestamptz,
  items jsonb,
  driver_name text
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  if p_from is null or p_to is null or p_to <= p_from
     or p_to - p_from > interval '400 days' then
    raise exception 'bad_period' using errcode = '22023';
  end if;
  return query
  select o.id, o.code, o.status,
         o.customer_name, o.area,
         o.food_total, o.delivery_fee, o.total,
         o.commission_amount,
         o.reject_reason,
         o.placed_at, o.accepted_at, o.ready_at,
         o.picked_up_at, o.delivered_at, o.cancelled_at,
         coalesce((select jsonb_agg(jsonb_build_object(
                     'name', i.name, 'unit_price', i.unit_price,
                     'quantity', i.quantity, 'line_total', i.line_total)
                   order by i.id)
                     from public.order_items i where i.order_id = o.id),
                  '[]'::jsonb),
         dp.full_name
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
    left join public.profiles dp on dp.id = o.driver_id
   where r.owner_id = auth.uid()
     and o.placed_at >= p_from
     and o.placed_at <  p_to
   order by o.placed_at desc
   limit 5000;
end $$;
revoke all on function public.owner_report(timestamptz, timestamptz) from public, anon;
grant execute on function public.owner_report(timestamptz, timestamptz) to authenticated;

-- ---------- account deletion -------------------------------------------
alter table public.restaurants add column if not exists deleted_at timestamptz;

create or replace function public.delete_my_restaurant_account()
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  v_role public.app_role;
  rid uuid;
begin
  if uid is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  select role into v_role from public.profiles where id = uid for update;
  if v_role is distinct from 'restaurant' then
    raise exception 'not_a_restaurant' using errcode = 'P0001';
  end if;
  select r.id into rid from public.restaurants r where r.owner_id = uid for update;

  if rid is not null then
    if exists (select 1 from public.orders o
                where o.restaurant_id = rid
                  and o.status in ('placed', 'accepted', 'ready', 'picked_up')) then
      raise exception 'active_orders' using errcode = 'P0001';
    end if;
    -- Food money still with a driver.
    if exists (select 1 from public.orders o
                where o.restaurant_id = rid and o.status = 'delivered'
                  and o.cash_confirmed_at is null) then
      raise exception 'cash_pending' using errcode = 'P0001';
    end if;
    -- Commission not billed yet, or a statement not paid.
    if exists (select 1 from public.orders o
                where o.restaurant_id = rid and o.status = 'delivered'
                  and o.statement_id is null
                  and coalesce(o.commission_amount, 0) > 0)
       or exists (select 1 from public.statements s
                   where s.restaurant_id = rid and s.status <> 'paid') then
      raise exception 'unpaid_commission' using errcode = 'P0001';
    end if;

    update public.restaurants
       set owner_id = null,
           is_active = false,
           is_open = false,
           phone = null,
           email = null,
           deleted_at = now()
     where id = rid;
  end if;

  -- Cascades to the profile and push tokens.
  delete from auth.users where id = uid;
end $$;
revoke all on function public.delete_my_restaurant_account() from public, anon;
grant execute on function public.delete_my_restaurant_account() to authenticated;

-- An archived restaurant can't be switched back on.
create or replace function public.admin_set_restaurant_active(p_id uuid, p_active boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  if p_active and exists (select 1 from public.restaurants
                           where id = p_id and deleted_at is not null) then
    raise exception 'restaurant_deleted' using errcode = 'P0001';
  end if;
  update public.restaurants
     set is_active = p_active,
         is_open = case when p_active then is_open else false end
   where id = p_id;
  if not found then raise exception 'restaurant not found' using errcode = 'P0002'; end if;
end $$;
