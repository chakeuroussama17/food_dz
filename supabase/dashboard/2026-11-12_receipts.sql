-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261112000001_receipts.sql
-- Run AFTER 2026-11-11_cash_and_proof.sql.
begin;

-- =====================================================================
-- Receipts in the app (no email): customer order receipts, restaurant
-- commission statements, driver earnings statements. Plus the admin
-- setting for the driver cash block.
-- =====================================================================

-- Business details printed on every receipt (public information).
create or replace function public.business_info()
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'business_name', c.business_name, 'business_phone', c.business_phone,
    'business_email', c.business_email, 'business_address', c.business_address,
    'business_tax_id', c.business_tax_id)
    from public.app_config c limit 1;
$$;
revoke all on function public.business_info() from public, anon;
grant execute on function public.business_info() to authenticated;

-- Admin: hours before a driver with unconfirmed cash is blocked.
create or replace function public.admin_set_cash_hours(p_hours integer)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  if p_hours is null or p_hours not between 1 and 168 then
    raise exception 'invalid hours' using errcode = '22023';
  end if;
  update public.app_config set cash_handover_hours = p_hours;
end $$;
revoke all on function public.admin_set_cash_hours(integer) from public, anon;
grant execute on function public.admin_set_cash_hours(integer) to authenticated;

-- ---------- restaurant: its commission statements ------------------------
create or replace function public.owner_statements()
returns table (id uuid, number text, period_start date, period_end date,
               orders_count integer, food_total integer,
               commission_total integer, status text,
               issued_at timestamptz, paid_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select s.id, s.number, s.period_start, s.period_end, s.orders_count,
         s.food_total, s.commission_total, s.status, s.issued_at, s.paid_at
    from public.statements s
    join public.restaurants r on r.id = s.restaurant_id
   where r.owner_id = auth.uid()
   order by s.issued_at desc;
$$;
revoke all on function public.owner_statements() from public, anon;
grant execute on function public.owner_statements() to authenticated;

-- Same document as admin_statement_detail, for the restaurant's owner.
create or replace function public.owner_statement_detail(p_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  result jsonb;
begin
  select jsonb_build_object(
    'statement', to_jsonb(s),
    'restaurant', jsonb_build_object(
      'name', r.name, 'address', r.address, 'area', r.area, 'phone', r.phone,
      'owner_name', p.full_name, 'owner_email', u.email),
    'business', public.business_info(),
    'orders', coalesce((
      select jsonb_agg(jsonb_build_object(
               'code', o.code, 'delivered_at', o.delivered_at,
               'food_total', o.food_total, 'commission_rate', o.commission_rate,
               'commission_amount', o.commission_amount)
             order by o.delivered_at)
        from public.orders o where o.statement_id = s.id), '[]'::jsonb)
  ) into result
  from public.statements s
  join public.restaurants r on r.id = s.restaurant_id
  left join public.profiles p on p.id = r.owner_id
  left join auth.users u on u.id = r.owner_id
  where s.id = p_id and r.owner_id = auth.uid();

  if result is null then
    raise exception 'statement not found' using errcode = 'P0002';
  end if;
  return result;
end $$;
revoke all on function public.owner_statement_detail(uuid) from public, anon;
grant execute on function public.owner_statement_detail(uuid) to authenticated;

-- ---------- driver: deliveries of a period (Algiers dates) ----------------
-- Errors: invalid_period (end before start, or more than 92 days)
create or replace function public.driver_statement(p_from date, p_to date)
returns table (code text, delivered_at timestamptz, restaurant_name text,
               total integer, food_total integer, delivery_fee integer,
               cash_confirmed_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  if p_from is null or p_to is null or p_to < p_from or p_to - p_from > 92 then
    raise exception 'invalid_period' using errcode = '22023';
  end if;
  return query
  select o.code, o.delivered_at, r.name, o.total, o.food_total,
         o.delivery_fee, o.cash_confirmed_at
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
   where o.driver_id = auth.uid()
     and o.status = 'delivered'
     and public.dz_date(o.delivered_at) between p_from and p_to
   order by o.delivered_at;
end $$;
revoke all on function public.driver_statement(date, date) from public, anon;
grant execute on function public.driver_statement(date, date) to authenticated;

commit;
