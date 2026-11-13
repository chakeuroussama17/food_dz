-- =====================================================================
-- Cancelling an order, and sanctions for bad behaviour.
--
-- Cancelling (customer):
--   * before the restaurant accepts: cancelled at once, with a reason;
--   * accepted or ready (not picked up): a cancellation REQUEST with a
--     reason; the restaurant accepts (order cancelled) or refuses (the
--     order goes on). One request per order. A pickup closes a request
--     still waiting ("expired");
--   * picked up: no cancelling.
--   Every order remembers who cancelled it (customer, restaurant, admin,
--   system) and why.
--
-- Sanctions (admin), for customers and riders, always with a reason:
--   warning (shown once to the person), suspension for N days, or a
--   permanent ban. A suspended / banned customer can't order; a rider
--   can't go online or take deliveries. History is kept; a sanction can
--   be lifted. Customers who cancel 3+ times in 30 days are listed for
--   the admin to look at.
-- =====================================================================

-- ---------- order columns ---------------------------------------------------
alter table public.orders
  add column if not exists cancelled_by text
    check (cancelled_by in ('customer', 'restaurant', 'admin', 'system')),
  add column if not exists cancel_reason text
    check (cancel_reason in ('changed_mind', 'too_long', 'wrong_address',
                             'wrong_items', 'duplicate', 'other')),
  add column if not exists cancel_request_status text
    check (cancel_request_status in ('pending', 'accepted', 'refused', 'expired')),
  add column if not exists cancel_request_reason text
    check (cancel_request_reason in ('changed_mind', 'too_long', 'wrong_address',
                                     'wrong_items', 'duplicate', 'other')),
  add column if not exists cancel_request_note text
    check (char_length(cancel_request_note) <= 200),
  add column if not exists cancel_requested_at timestamptz,
  add column if not exists cancel_answered_at timestamptz;

create index if not exists orders_cancel_request_idx
  on public.orders (restaurant_id) where cancel_request_status = 'pending';

-- Who cancelled, and what happens to a waiting request.
create or replace function public.orders_cancel_bookkeeping()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'cancelled' and old.status is distinct from 'cancelled' then
    if new.cancel_request_status = 'pending' then
      -- The restaurant cancelled while the customer asked to: accepted.
      new.cancel_request_status := 'accepted';
      new.cancel_answered_at := now();
      new.cancelled_by := 'customer';
      new.cancel_reason := coalesce(new.cancel_reason, new.cancel_request_reason);
    elsif new.cancelled_by is null then
      new.cancelled_by := case
        when auth.uid() is null then 'system'
        when auth.uid() = new.customer_id then 'customer'
        when exists (select 1 from public.profiles
                      where id = auth.uid() and role = 'admin') then 'admin'
        else 'restaurant' end;
    end if;
  elsif new.status = 'picked_up' and new.cancel_request_status = 'pending' then
    new.cancel_request_status := 'expired';
    new.cancel_answered_at := now();
  end if;
  return new;
end $$;
drop trigger if exists orders_cancel_bookkeeping on public.orders;
create trigger orders_cancel_bookkeeping before update on public.orders
  for each row execute function public.orders_cancel_bookkeeping();

-- ---------- the customer cancels -------------------------------------------
-- Returns 'cancelled' (done) or 'requested' (the restaurant decides).
-- Errors: order_not_found, invalid_reason, cannot_cancel (picked up or
-- finished), already_requested, request_refused (one request per order)
drop function if exists public.cancel_my_order(uuid);
create or replace function public.cancel_my_order(
  p_order_id uuid,
  p_reason   text default 'other',
  p_note     text default ''
)
returns text language plpgsql volatile security definer set search_path = '' as $$
declare
  o public.orders;
  v_reason text := coalesce(p_reason, 'other');
  v_note text := left(btrim(coalesce(p_note, '')), 200);
begin
  select * into o from public.orders
   where id = p_order_id and customer_id = auth.uid()
   for update;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
  if v_reason not in ('changed_mind', 'too_long', 'wrong_address',
                      'wrong_items', 'duplicate', 'other') then
    raise exception 'invalid_reason' using errcode = 'P0001';
  end if;

  if o.status = 'placed' then
    update public.orders
       set status = 'cancelled', cancelled_by = 'customer', cancel_reason = v_reason
     where id = o.id;
    return 'cancelled';
  end if;

  if o.status in ('accepted', 'ready') then
    if o.cancel_request_status = 'pending' then
      raise exception 'already_requested' using errcode = 'P0001';
    end if;
    if o.cancel_request_status is not null then
      raise exception 'request_refused' using errcode = 'P0001';
    end if;
    update public.orders
       set cancel_request_status = 'pending',
           cancel_request_reason = v_reason,
           cancel_request_note = v_note,
           cancel_requested_at = now()
     where id = o.id;
    return 'requested';
  end if;

  raise exception 'cannot_cancel' using errcode = 'P0001';
end $$;
revoke all on function public.cancel_my_order(uuid, text, text) from public, anon;
grant execute on function public.cancel_my_order(uuid, text, text) to authenticated;

-- ---------- the restaurant answers --------------------------------------------
-- Errors: order_not_found, no_request
create or replace function public.owner_answer_cancel_request(p_order_id uuid, p_accept boolean)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  o public.orders;
begin
  select x.* into o from public.orders x
   where x.id = p_order_id and public.has_restaurant_role(x.restaurant_id, 'staff')
   for update of x;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
  if o.cancel_request_status is distinct from 'pending'
     or o.status not in ('accepted', 'ready') then
    raise exception 'no_request' using errcode = 'P0001';
  end if;
  if coalesce(p_accept, false) then
    -- The bookkeeping trigger marks the request accepted, by the customer.
    update public.orders set status = 'cancelled' where id = o.id;
  else
    update public.orders
       set cancel_request_status = 'refused', cancel_answered_at = now()
     where id = o.id;
  end if;
end $$;
revoke all on function public.owner_answer_cancel_request(uuid, boolean) from public, anon;
grant execute on function public.owner_answer_cancel_request(uuid, boolean) to authenticated;

-- ---------- push: request sent / refused ------------------------------------------
create or replace function public.orders_push()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  cfg record;
  v_event text;
begin
  if tg_op = 'INSERT' then
    v_event := 'placed';
  elsif new.status is distinct from old.status then
    v_event := new.status::text;
  elsif new.cancel_request_status is distinct from old.cancel_request_status
        and new.cancel_request_status in ('pending', 'refused') then
    v_event := case when new.cancel_request_status = 'pending'
                    then 'cancel_request' else 'cancel_refused' end;
  elsif new.driver_id is distinct from old.driver_id
        and new.status in ('accepted', 'ready', 'picked_up') then
    v_event := case when new.driver_id is null then 'available'
                    else 'driver_assigned' end;
  else
    return null;
  end if;

  select * into cfg from private.push_config;
  if not found or to_regproc('net.http_post') is null then
    return null; -- push not set up (or local test database)
  end if;

  begin
    -- pg_net queues the request; the order change never waits for it.
    execute 'select net.http_post(url := $1, body := $2, headers := $3)'
      using cfg.function_url,
            jsonb_build_object(
              'order_id', new.id,
              'event', v_event,
              'by_customer', auth.uid() is not null
                             and auth.uid() = new.customer_id),
            jsonb_build_object(
              'Content-Type', 'application/json',
              'x-push-secret', cfg.secret);
  exception when others then
    raise warning 'push not queued: %', sqlerrm;
  end;
  return null;
end $$;

-- ---------- the customer's and the restaurant's order lists ------------------------
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
  delivery_photo_path text,
  discount_amount integer, tax_amount integer, promo_code text,
  payment_method text,
  cancelled_by text, cancel_reason text,
  cancel_request_status text, cancel_request_reason text
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
         o.delivery_photo_path,
         o.discount_amount, o.tax_amount, o.promo_code, o.payment_method,
         o.cancelled_by, o.cancel_reason,
         o.cancel_request_status, o.cancel_request_reason
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

drop function if exists public.owner_orders(boolean, integer, uuid);
create function public.owner_orders(
  p_active        boolean default true,
  p_limit         integer default 100,
  p_restaurant_id uuid default null
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
  driver_name text, driver_phone text,
  restaurant_id uuid, restaurant_name text,
  discount_amount integer, tax_amount integer, promo_code text,
  discount_funded_by text,
  cancelled_by text, cancel_reason text,
  cancel_request_status text, cancel_request_reason text, cancel_request_note text
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
         dp.full_name, d.phone,
         r.id, r.name,
         o.discount_amount, o.tax_amount, o.promo_code, o.discount_funded_by,
         o.cancelled_by, o.cancel_reason,
         o.cancel_request_status, o.cancel_request_reason, o.cancel_request_note
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
    join public.restaurant_members m
      on m.restaurant_id = r.id and m.user_id = auth.uid()
    left join public.drivers d on d.id = o.driver_id
    left join public.profiles dp on dp.id = o.driver_id
   where (p_restaurant_id is null or r.id = p_restaurant_id)
     and (case when coalesce(p_active, true)
               then o.status in ('placed', 'accepted', 'ready', 'picked_up')
               else o.status in ('delivered', 'rejected', 'cancelled') end)
   order by case when coalesce(p_active, true) then o.placed_at end asc,
            o.placed_at desc
   limit least(greatest(coalesce(p_limit, 100), 1), 200);
$$;
revoke all on function public.owner_orders(boolean, integer, uuid) from public, anon;
grant execute on function public.owner_orders(boolean, integer, uuid) to authenticated;

-- =====================================================================
-- Sanctions
-- =====================================================================
create table if not exists public.user_sanctions (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  kind        text not null check (kind in ('warning', 'suspension', 'ban')),
  reason      text not null check (reason in
                ('fake_orders', 'no_show', 'refused_to_pay', 'abuse', 'fraud',
                 'too_many_cancellations', 'unsafe_driving', 'cash_not_returned', 'other')),
  -- Shown to the person.
  message     text not null default '' check (char_length(message) <= 300),
  -- Only for the admin.
  admin_note  text not null default '' check (char_length(admin_note) <= 300),
  starts_at   timestamptz not null default now(),
  ends_at     timestamptz,
  seen_at     timestamptz,
  lifted_at   timestamptz,
  lifted_by   uuid references public.profiles (id) on delete set null,
  created_by  uuid references public.profiles (id) on delete set null,
  report_id   bigint references public.customer_reports (id) on delete set null,
  created_at  timestamptz not null default now(),
  check ((kind = 'suspension') = (ends_at is not null))
);
create index if not exists user_sanctions_user_idx on public.user_sanctions (user_id, created_at desc);
alter table public.user_sanctions enable row level security;
-- No policies: read through my_restriction() and the admin functions.

-- The suspension or ban in force for a user (null if none).
create or replace function public.active_restriction(p_user uuid)
returns public.user_sanctions
language sql stable security definer set search_path = '' as $$
  select s.* from public.user_sanctions s
   where s.user_id = p_user and s.lifted_at is null
     and (s.kind = 'ban' or (s.kind = 'suspension' and s.ends_at > now()))
   order by (s.kind = 'ban') desc, s.ends_at desc
   limit 1;
$$;
revoke all on function public.active_restriction(uuid) from public, anon, authenticated;

create or replace function public.is_restricted(p_user uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.user_sanctions s
     where s.user_id = p_user and s.lifted_at is null
       and (s.kind = 'ban' or (s.kind = 'suspension' and s.ends_at > now())));
$$;
revoke all on function public.is_restricted(uuid) from public, anon, authenticated;

-- A blocked (old switch), suspended or banned customer can't order.
create or replace function public.orders_block_check()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.customer_id is not null and (
       exists (select 1 from public.profiles
                where id = new.customer_id and blocked_at is not null)
       or public.is_restricted(new.customer_id)) then
    raise exception 'account_blocked' using errcode = 'P0001';
  end if;
  return new;
end $$;

-- A suspended or banned rider can't go online or take a delivery.
create or replace function public.drivers_restriction_check()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.is_online and not old.is_online and public.is_restricted(new.id) then
    raise exception 'account_suspended' using errcode = 'P0001';
  end if;
  return new;
end $$;
drop trigger if exists drivers_restriction_check on public.drivers;
create trigger drivers_restriction_check before update of is_online on public.drivers
  for each row execute function public.drivers_restriction_check();

create or replace function public.orders_driver_restriction_check()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.driver_id is not null and new.driver_id is distinct from old.driver_id
     and public.is_restricted(new.driver_id) then
    raise exception 'account_suspended' using errcode = 'P0001';
  end if;
  return new;
end $$;
drop trigger if exists orders_driver_restriction_check on public.orders;
create trigger orders_driver_restriction_check before update of driver_id on public.orders
  for each row execute function public.orders_driver_restriction_check();

-- ---------- what the person sees ---------------------------------------------------
-- The suspension / ban in force, otherwise the latest warning not yet seen.
create or replace function public.my_restriction()
returns table (id bigint, kind text, reason text, message text,
               ends_at timestamptz, created_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select x.id, x.kind, x.reason, x.message, x.ends_at, x.created_at
    from (
      select s.*, 0 as rank from public.user_sanctions s
       where s.user_id = auth.uid() and s.lifted_at is null
         and (s.kind = 'ban' or (s.kind = 'suspension' and s.ends_at > now()))
      union all
      select s.*, 1 from public.user_sanctions s
       where s.user_id = auth.uid() and s.kind = 'warning'
         and s.lifted_at is null and s.seen_at is null
    ) x
   order by x.rank, (x.kind = 'ban') desc, x.created_at desc
   limit 1;
$$;
revoke all on function public.my_restriction() from public, anon;
grant execute on function public.my_restriction() to authenticated;

create or replace function public.acknowledge_warning(p_id bigint)
returns void language sql volatile security definer set search_path = '' as $$
  update public.user_sanctions set seen_at = coalesce(seen_at, now())
   where id = p_id and user_id = auth.uid() and kind = 'warning';
$$;
revoke all on function public.acknowledge_warning(bigint) from public, anon;
grant execute on function public.acknowledge_warning(bigint) to authenticated;

-- ---------- admin --------------------------------------------------------------------
-- Errors: not_found (no such customer / rider), invalid_kind,
-- invalid_reason, invalid_days (suspension: 1–365 days)
create or replace function public.admin_sanction_user(
  p_user_id    uuid,
  p_kind       text,
  p_reason     text,
  p_message    text default '',
  p_days       integer default null,
  p_admin_note text default '',
  p_report_id  bigint default null
)
returns bigint language plpgsql volatile security definer set search_path = '' as $$
declare
  v_id bigint;
begin
  perform public.assert_admin();
  if not exists (select 1 from public.profiles
                  where id = p_user_id and role in ('customer', 'driver')) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if p_kind not in ('warning', 'suspension', 'ban') then
    raise exception 'invalid_kind' using errcode = 'P0001';
  end if;
  if p_reason not in ('fake_orders', 'no_show', 'refused_to_pay', 'abuse', 'fraud',
                      'too_many_cancellations', 'unsafe_driving', 'cash_not_returned', 'other') then
    raise exception 'invalid_reason' using errcode = 'P0001';
  end if;
  if p_kind = 'suspension' and (p_days is null or p_days not between 1 and 365) then
    raise exception 'invalid_days' using errcode = 'P0001';
  end if;
  insert into public.user_sanctions
    (user_id, kind, reason, message, admin_note, ends_at, created_by, report_id)
  values (p_user_id, p_kind, p_reason,
          left(btrim(coalesce(p_message, '')), 300),
          left(btrim(coalesce(p_admin_note, '')), 300),
          case when p_kind = 'suspension' then now() + make_interval(days => p_days) end,
          auth.uid(), p_report_id)
  returning id into v_id;
  if p_kind in ('suspension', 'ban') then
    -- A rider stops receiving deliveries right away.
    update public.drivers set is_online = false where id = p_user_id and is_online;
    if p_kind = 'ban' then
      update public.profiles set blocked_at = coalesce(blocked_at, now()) where id = p_user_id;
    end if;
  end if;
  return v_id;
end $$;
revoke all on function public.admin_sanction_user(uuid, text, text, text, integer, text, bigint) from public, anon;
grant execute on function public.admin_sanction_user(uuid, text, text, text, integer, text, bigint) to authenticated;

-- Ends a warning, suspension or ban early. Errors: not_found
create or replace function public.admin_lift_sanction(p_id bigint)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_user uuid;
begin
  perform public.assert_admin();
  update public.user_sanctions set lifted_at = now(), lifted_by = auth.uid()
   where id = p_id and lifted_at is null
  returning user_id into v_user;
  if v_user is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if not exists (select 1 from public.user_sanctions
                  where user_id = v_user and kind = 'ban' and lifted_at is null) then
    update public.profiles set blocked_at = null where id = v_user;
  end if;
end $$;
revoke all on function public.admin_lift_sanction(bigint) from public, anon;
grant execute on function public.admin_lift_sanction(bigint) to authenticated;

-- A person's history, newest first.
create or replace function public.admin_user_sanctions(p_user_id uuid)
returns table (id bigint, kind text, reason text, message text, admin_note text,
               starts_at timestamptz, ends_at timestamptz, seen_at timestamptz,
               lifted_at timestamptz, created_at timestamptz, created_by_name text,
               active boolean)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select s.id, s.kind, s.reason, s.message, s.admin_note, s.starts_at, s.ends_at,
         s.seen_at, s.lifted_at, s.created_at, coalesce(a.full_name, ''),
         s.lifted_at is null and (s.kind = 'ban'
                                  or (s.kind = 'suspension' and s.ends_at > now()))
    from public.user_sanctions s
    left join public.profiles a on a.id = s.created_by
   where s.user_id = p_user_id
   order by s.created_at desc;
end $$;
revoke all on function public.admin_user_sanctions(uuid) from public, anon;
grant execute on function public.admin_user_sanctions(uuid) to authenticated;

-- The old block switch (reports page) now makes / lifts a ban.
create or replace function public.admin_set_customer_blocked(p_customer_id uuid, p_blocked boolean)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  s record;
begin
  perform public.assert_admin();
  if not exists (select 1 from public.profiles where id = p_customer_id and role = 'customer') then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if coalesce(p_blocked, false) then
    if not exists (select 1 from public.user_sanctions
                    where user_id = p_customer_id and kind = 'ban' and lifted_at is null) then
      perform public.admin_sanction_user(p_customer_id, 'ban', 'other');
    end if;
  else
    for s in select id from public.user_sanctions
              where user_id = p_customer_id and kind in ('ban', 'suspension')
                and lifted_at is null loop
      perform public.admin_lift_sanction(s.id);
    end loop;
    update public.profiles set blocked_at = null where id = p_customer_id;
  end if;
end $$;

-- Reports: "warned" sends a warning, "blocked" bans, both linked to the report.
create or replace function public.admin_handle_report(
  p_id bigint, p_status text, p_note text default '')
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  c public.customer_reports;
  v_reason text;
begin
  perform public.assert_admin();
  if p_status not in ('open', 'warned', 'blocked', 'dismissed') then
    raise exception 'invalid_status' using errcode = '22023';
  end if;
  select * into c from public.customer_reports where id = p_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  update public.customer_reports
     set status = p_status, admin_note = left(btrim(coalesce(p_note, '')), 300),
         handled_at = case when p_status = 'open' then null else now() end
   where id = p_id;
  if p_status in ('warned', 'blocked') and c.customer_id is not null
     and c.status is distinct from p_status then
    v_reason := case c.reason
      when 'fake_order' then 'fake_orders'
      when 'no_answer' then 'no_show'
      when 'refused_to_pay' then 'refused_to_pay'
      when 'rude' then 'abuse'
      else 'other' end;
    perform public.admin_sanction_user(
      c.customer_id, case when p_status = 'warned' then 'warning' else 'ban' end,
      v_reason, '', null, p_note, p_id);
  end if;
end $$;

-- Customers who cancelled (or asked to) 3 times or more in 30 days.
create or replace function public.admin_watchlist()
returns table (user_id uuid, full_name text, email text, phone text,
               cancels_30d integer, open_reports integer, last_cancel_at timestamptz,
               restricted boolean)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  with c as (
    select o.customer_id,
           count(*)::int as n,
           max(coalesce(o.cancelled_at, o.cancel_requested_at)) as last_at
      from public.orders o
     where o.customer_id is not null
       and ((o.status = 'cancelled' and o.cancelled_by = 'customer'
             and o.cancelled_at > now() - interval '30 days')
            or (o.cancel_request_status in ('pending', 'refused', 'expired')
                and o.cancel_requested_at > now() - interval '30 days'))
     group by o.customer_id
  )
  select p.id, p.full_name, u.email::text, p.phone, c.n,
         (select count(*)::int from public.customer_reports r
           where r.customer_id = p.id and r.status = 'open'),
         c.last_at, public.is_restricted(p.id)
    from c
    join public.profiles p on p.id = c.customer_id
    join auth.users u on u.id = p.id
   where c.n >= 3
   order by c.n desc, c.last_at desc;
end $$;
revoke all on function public.admin_watchlist() from public, anon;
grant execute on function public.admin_watchlist() to authenticated;

-- The customers list with cancellations and the sanction in force.
drop function if exists public.admin_list_customers(text, integer, integer);
create or replace function public.admin_list_customers(
  p_search text default '', p_limit integer default 50, p_offset integer default 0)
returns table (
  id uuid, full_name text, email text, phone text, created_at timestamptz,
  orders_count integer, delivered_count integer, cancelled_count integer,
  spent integer, last_order_at timestamptz,
  birth_date date, gender text, wilaya smallint, commune text,
  referral_source text, signup_platform text, last_platform text,
  last_app_version text, last_device text, last_os text, last_lang text,
  last_seen_at timestamptz, active_days_30 integer, blocked_at timestamptz,
  cancels_30d integer, warnings integer,
  restriction_kind text, restriction_ends_at timestamptz
)
language plpgsql stable security definer set search_path = '' as $$
declare
  pat text := '%' || replace(replace(left(btrim(coalesce(p_search, '')), 60), '%', ''), '_', '') || '%';
begin
  perform public.assert_admin();
  return query
  select p.id, p.full_name, u.email::text, p.phone, p.created_at,
         coalesce(o.n, 0), coalesce(o.delivered, 0), coalesce(o.cancelled, 0),
         coalesce(o.spent, 0), o.last_at,
         p.birth_date, p.gender, p.wilaya, p.commune,
         p.referral_source, p.signup_platform, p.last_platform,
         p.last_app_version, p.last_device, p.last_os, p.last_lang,
         p.last_seen_at,
         (select count(*)::int from public.user_activity_days d
           where d.user_id = p.id and d.day > current_date - 30),
         p.blocked_at,
         coalesce(o.cancels_30d, 0),
         (select count(*)::int from public.user_sanctions s
           where s.user_id = p.id and s.kind = 'warning'),
         ar.kind, ar.ends_at
    from public.profiles p
    join auth.users u on u.id = p.id
    left join lateral (
      select count(*)::int as n,
             count(*) filter (where x.status = 'delivered')::int as delivered,
             count(*) filter (where x.status = 'cancelled')::int as cancelled,
             coalesce(sum(x.total) filter (where x.status = 'delivered'), 0)::int as spent,
             max(x.placed_at) as last_at,
             count(*) filter (where
               (x.status = 'cancelled' and x.cancelled_by = 'customer'
                and x.cancelled_at > now() - interval '30 days')
               or (x.cancel_request_status in ('pending', 'refused', 'expired')
                   and x.cancel_requested_at > now() - interval '30 days'))::int as cancels_30d
        from public.orders x where x.customer_id = p.id
    ) o on true
    left join lateral (select r.kind, r.ends_at
                         from public.active_restriction(p.id) r
                        where r.id is not null) ar on true
   where p.role = 'customer'
     and (p.full_name ilike pat or u.email ilike pat or coalesce(p.phone, '') ilike pat
          or coalesce(p.commune, '') ilike pat)
   order by p.created_at desc
   limit least(greatest(p_limit, 1), 5000) offset greatest(p_offset, 0);
end $$;
revoke all on function public.admin_list_customers(text, integer, integer) from public, anon;
grant execute on function public.admin_list_customers(text, integer, integer) to authenticated;

-- Every suspension / ban in force (the admin's rider and customer lists
-- show a badge).
create or replace function public.admin_restrictions()
returns table (user_id uuid, kind text, ends_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select distinct on (s.user_id) s.user_id, s.kind, s.ends_at
    from public.user_sanctions s
   where s.lifted_at is null
     and (s.kind = 'ban' or (s.kind = 'suspension' and s.ends_at > now()))
   order by s.user_id, (s.kind = 'ban') desc, s.ends_at desc;
end $$;
revoke all on function public.admin_restrictions() from public, anon;
grant execute on function public.admin_restrictions() to authenticated;
