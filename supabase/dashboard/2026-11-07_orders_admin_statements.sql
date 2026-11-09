-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261107000001_orders_admin_statements.sql
-- Run AFTER 2026-11-06_restaurant_owners.sql (already applied).
begin;

-- =====================================================================
-- Orders (+ status rules, commission), commission statements, and the
-- admin API. Customers place orders through a function added with the
-- checkout step; clients never write to these tables directly.
-- =====================================================================

-- ---------- admin helpers --------------------------------------------
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles
                  where id = auth.uid() and role = 'admin');
$$;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

create or replace function public.assert_admin()
returns void language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
end $$;
revoke all on function public.assert_admin() from public, anon, authenticated;

-- Business details printed on the commission statements.
alter table public.app_config
  add column business_name    text not null default 'Food' check (char_length(business_name) <= 80),
  add column business_phone   text not null default '' check (char_length(business_phone) <= 30),
  add column business_email   text not null default '' check (char_length(business_email) <= 254),
  add column business_address text not null default '' check (char_length(business_address) <= 200),
  add column business_tax_id  text not null default '' check (char_length(business_tax_id) <= 40);

-- ---------- orders ---------------------------------------------------
create type public.order_status as enum
  ('placed', 'accepted', 'rejected', 'ready', 'picked_up', 'delivered', 'cancelled');

-- 6-character code customers and restaurants can read out loud
-- (no 0/O/1/I).
create or replace function public.gen_order_code()
returns text language plpgsql volatile set search_path = '' as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  c text;
begin
  loop
    c := '';
    for i in 1..6 loop
      c := c || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.orders where code = c);
  end loop;
  return c;
end $$;

create table public.statements (
  id               uuid primary key default gen_random_uuid(),
  number           text unique not null,
  restaurant_id    uuid not null references public.restaurants (id),
  period_start     date not null,
  period_end       date not null check (period_end >= period_start),
  orders_count     integer not null,
  food_total       integer not null,
  commission_total integer not null,
  status           text not null default 'issued' check (status in ('issued', 'paid')),
  issued_at        timestamptz not null default now(),
  paid_at          timestamptz,
  created_by       uuid references public.profiles (id)
);
create index statements_restaurant_idx on public.statements (restaurant_id, period_start);
alter table public.statements enable row level security;
revoke all on public.statements from anon, authenticated;
create sequence public.statement_number_seq;

create table public.orders (
  id                uuid primary key default gen_random_uuid(),
  code              text unique not null default public.gen_order_code(),
  customer_id       uuid references public.profiles (id) on delete set null,
  restaurant_id     uuid not null references public.restaurants (id),
  driver_id         uuid references public.profiles (id),
  status            public.order_status not null default 'placed',
  customer_name     text not null check (char_length(customer_name) between 1 and 80),
  customer_phone    text not null check (customer_phone ~ '^0[567][0-9]{8}$'),
  address_text      text not null check (char_length(address_text) between 3 and 200),
  area              text not null default '' check (char_length(area) <= 80),
  address_details   text not null default '' check (char_length(address_details) <= 120),
  lat               double precision check (lat between -90 and 90),
  lng               double precision check (lng between -180 and 180),
  notes             text not null default '' check (char_length(notes) <= 300),
  food_total        integer not null check (food_total > 0),
  delivery_fee      integer not null check (delivery_fee >= 0),
  total             integer not null,
  commission_rate   numeric(5,4) not null check (commission_rate between 0 and 0.5),
  commission_amount integer,          -- set when delivered
  reject_reason     text check (char_length(reject_reason) <= 200),
  placed_at         timestamptz not null default now(),
  accepted_at       timestamptz,
  ready_at          timestamptz,
  picked_up_at      timestamptz,
  delivered_at      timestamptz,
  cancelled_at      timestamptz,
  cash_handed_at    timestamptz,      -- driver: "food money handed over"
  cash_confirmed_at timestamptz,      -- restaurant: "received"
  statement_id      uuid references public.statements (id) on delete set null
);
create index orders_restaurant_idx on public.orders (restaurant_id, placed_at desc);
create index orders_customer_idx on public.orders (customer_id, placed_at desc);
create index orders_status_idx on public.orders (status);
create index orders_billing_idx on public.orders (restaurant_id, delivered_at)
  where status = 'delivered' and statement_id is null;
alter table public.orders enable row level security;
revoke all on public.orders from anon, authenticated;
grant select on public.orders to authenticated;

create table public.order_items (
  id           bigint generated always as identity primary key,
  order_id     uuid not null references public.orders (id) on delete cascade,
  menu_item_id uuid references public.menu_items (id) on delete set null,
  name         text not null,
  unit_price   integer not null check (unit_price > 0),
  quantity     integer not null check (quantity between 1 and 20),
  line_total   integer generated always as (unit_price * quantity) stored
);
create index order_items_order_idx on public.order_items (order_id);
alter table public.order_items enable row level security;
revoke all on public.order_items from anon, authenticated;
grant select on public.order_items to authenticated;

-- Audit trail of every status change.
create table public.order_events (
  id          bigint generated always as identity primary key,
  order_id    uuid not null references public.orders (id) on delete cascade,
  from_status public.order_status,
  to_status   public.order_status not null,
  actor_id    uuid,
  created_at  timestamptz not null default now()
);
create index order_events_order_idx on public.order_events (order_id);
alter table public.order_events enable row level security;
revoke all on public.order_events from anon, authenticated;

-- Who can read an order: its customer, the restaurant's owner, the admin.
-- (Drivers come with the driver step.)
create policy "orders: customer reads own" on public.orders
  for select to authenticated using (customer_id = (select auth.uid()));
create policy "orders: owner reads restaurant's" on public.orders
  for select to authenticated using (public.owns_restaurant(restaurant_id));
create policy "orders: admin reads all" on public.orders
  for select to authenticated using (public.is_admin());

create policy "order_items: visible with the order" on public.order_items
  for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_id));

create policy "statements: owner reads own" on public.statements
  for select to authenticated using (public.owns_restaurant(restaurant_id));
create policy "statements: admin reads all" on public.statements
  for select to authenticated using (public.is_admin());
grant select on public.statements to authenticated;

-- ---------- order rules (apply to every write path) -------------------
create or replace function public.order_status_allowed(
  p_from public.order_status, p_to public.order_status)
returns boolean language sql immutable set search_path = '' as $$
  select (p_from, p_to) in (
    ('placed'::public.order_status,   'accepted'::public.order_status),
    ('placed',    'rejected'),
    ('placed',    'cancelled'),
    ('accepted',  'ready'),
    ('accepted',  'cancelled'),
    ('ready',     'picked_up'),
    ('ready',     'cancelled'),
    ('picked_up', 'delivered')
  );
$$;

create or replace function public.orders_before_write()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    new.total := new.food_total + new.delivery_fee;
    if new.status = 'delivered' then
      new.delivered_at := coalesce(new.delivered_at, now());
      new.commission_amount := round(new.food_total * new.commission_rate);
    end if;
    return new;
  end if;

  -- Money and identity never change after the order is placed.
  if new.food_total <> old.food_total or new.delivery_fee <> old.delivery_fee
     or new.commission_rate <> old.commission_rate
     or new.restaurant_id <> old.restaurant_id
     or new.customer_id is distinct from old.customer_id
     or new.code <> old.code then
    raise exception 'order amounts cannot change' using errcode = 'P0001';
  end if;
  new.total := new.food_total + new.delivery_fee;

  if new.status <> old.status then
    if not public.order_status_allowed(old.status, new.status) then
      raise exception 'invalid status change % -> %', old.status, new.status
        using errcode = 'P0001';
    end if;
    case new.status
      when 'accepted'  then new.accepted_at  := now();
      when 'ready'     then new.ready_at     := now();
      when 'picked_up' then new.picked_up_at := now();
      when 'delivered' then
        new.delivered_at := now();
        new.commission_amount := round(new.food_total * new.commission_rate);
      when 'rejected', 'cancelled' then new.cancelled_at := now();
      else null;
    end case;
  end if;

  -- A billed order stays billed (only cancelling the statement frees it).
  if old.statement_id is not null and new.statement_id is not null
     and new.statement_id <> old.statement_id then
    raise exception 'order already billed' using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger orders_before_write before insert or update on public.orders
  for each row execute function public.orders_before_write();

create or replace function public.orders_log_status()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' or new.status <> old.status then
    insert into public.order_events (order_id, from_status, to_status, actor_id)
    values (new.id, case when tg_op = 'UPDATE' then old.status end,
            new.status, auth.uid());
  end if;
  return null;
end $$;

create trigger orders_log_status after insert or update of status on public.orders
  for each row execute function public.orders_log_status();

-- =====================================================================
-- Admin API (every function checks the caller is admin)
-- =====================================================================

-- Delivered orders count in a day by Algiers local time.
create or replace function public.dz_date(ts timestamptz)
returns date language sql immutable set search_path = '' as $$
  select (ts at time zone 'Africa/Algiers')::date;
$$;

create or replace function public.admin_list_restaurants()
returns table (
  id uuid, slug text, name text, area text, address text, phone text,
  owner_name text, owner_email text,
  is_active boolean, is_open boolean,
  commission_rate numeric, effective_rate numeric,
  created_at timestamptz,
  delivered_count integer, unbilled_count integer, unbilled_commission integer
)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select r.id, r.slug, r.name, r.area, r.address, r.phone,
         p.full_name, u.email::text,
         r.is_active, r.is_open,
         r.commission_rate,
         coalesce(r.commission_rate, c.default_commission_rate),
         r.created_at,
         (select count(*)::int from public.orders o
           where o.restaurant_id = r.id and o.status = 'delivered'),
         (select count(*)::int from public.orders o
           where o.restaurant_id = r.id and o.status = 'delivered'
             and o.statement_id is null),
         (select coalesce(sum(o.commission_amount), 0)::int from public.orders o
           where o.restaurant_id = r.id and o.status = 'delivered'
             and o.statement_id is null)
    from public.restaurants r
    cross join public.app_config c
    left join public.profiles p on p.id = r.owner_id
    left join auth.users u on u.id = r.owner_id
   order by r.is_active, r.created_at desc;
end $$;

create or replace function public.admin_set_restaurant_active(p_id uuid, p_active boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  update public.restaurants
     set is_active = p_active,
         is_open = case when p_active then is_open else false end
   where id = p_id;
  if not found then raise exception 'restaurant not found' using errcode = 'P0002'; end if;
end $$;

-- p_rate null = use the default rate.
create or replace function public.admin_set_commission(p_id uuid, p_rate numeric)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  if p_rate is not null and (p_rate < 0 or p_rate > 0.5) then
    raise exception 'invalid rate' using errcode = '22023';
  end if;
  update public.restaurants set commission_rate = p_rate where id = p_id;
  if not found then raise exception 'restaurant not found' using errcode = 'P0002'; end if;
end $$;

create or replace function public.admin_get_config()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return (select to_jsonb(c) - 'id' from public.app_config c);
end $$;

create or replace function public.admin_update_config(
  p_delivery_fee integer,
  p_default_commission_rate numeric,
  p_business_name text,
  p_business_phone text,
  p_business_email text,
  p_business_address text,
  p_business_tax_id text
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  update public.app_config set
    delivery_fee = p_delivery_fee,
    default_commission_rate = p_default_commission_rate,
    business_name = trim(p_business_name),
    business_phone = trim(p_business_phone),
    business_email = trim(p_business_email),
    business_address = trim(p_business_address),
    business_tax_id = trim(p_business_tax_id);
end $$;

-- Totals for a period (by delivery date, Algiers time) + pending approvals.
create or replace function public.admin_stats(p_from date, p_to date)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  result jsonb;
begin
  perform public.assert_admin();
  select jsonb_build_object(
    'delivered_orders', count(*) filter (where status = 'delivered'),
    'food_total',       coalesce(sum(food_total) filter (where status = 'delivered'), 0),
    'delivery_fees',    coalesce(sum(delivery_fee) filter (where status = 'delivered'), 0),
    'commission',       coalesce(sum(commission_amount) filter (where status = 'delivered'), 0),
    'cancelled_orders', count(*) filter (where status in ('rejected', 'cancelled')),
    'active_orders',    count(*) filter (where status in ('placed', 'accepted', 'ready', 'picked_up'))
  ) into result
  from public.orders
  where public.dz_date(coalesce(delivered_at, cancelled_at, placed_at)) between p_from and p_to;

  return result || jsonb_build_object(
    'pending_restaurants',
      (select count(*) from public.restaurants where not is_active and owner_id is not null),
    'active_restaurants',
      (select count(*) from public.restaurants where is_active),
    'customers',
      (select count(*) from public.profiles where role = 'customer'),
    'unbilled_commission',
      (select coalesce(sum(commission_amount), 0) from public.orders
        where status = 'delivered' and statement_id is null)
  );
end $$;

create or replace function public.admin_stats_by_restaurant(p_from date, p_to date)
returns table (restaurant_id uuid, name text, delivered_orders integer,
               food_total integer, commission integer)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select r.id, r.name,
         count(o.id)::int,
         coalesce(sum(o.food_total), 0)::int,
         coalesce(sum(o.commission_amount), 0)::int
    from public.restaurants r
    left join public.orders o
      on o.restaurant_id = r.id and o.status = 'delivered'
     and public.dz_date(o.delivered_at) between p_from and p_to
   group by r.id, r.name
   order by 4 desc, r.name;
end $$;

create or replace function public.admin_list_orders(
  p_from date, p_to date,
  p_restaurant_id uuid default null,
  p_status public.order_status default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (id uuid, code text, restaurant_id uuid, restaurant_name text,
               customer_name text, customer_phone text, area text,
               status public.order_status, food_total integer,
               delivery_fee integer, total integer, commission_amount integer,
               placed_at timestamptz, delivered_at timestamptz,
               statement_number text)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select o.id, o.code, o.restaurant_id, r.name, o.customer_name,
         o.customer_phone, o.area, o.status, o.food_total, o.delivery_fee,
         o.total, o.commission_amount, o.placed_at, o.delivered_at, s.number
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
    left join public.statements s on s.id = o.statement_id
   where public.dz_date(o.placed_at) between p_from and p_to
     and (p_restaurant_id is null or o.restaurant_id = p_restaurant_id)
     and (p_status is null or o.status = p_status)
   order by o.placed_at desc
   limit least(greatest(p_limit, 1), 200) offset greatest(p_offset, 0);
end $$;

create or replace function public.admin_order_items(p_order_id uuid)
returns table (name text, unit_price integer, quantity integer, line_total integer)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select i.name, i.unit_price, i.quantity, i.line_total
    from public.order_items i where i.order_id = p_order_id order by i.id;
end $$;

create or replace function public.admin_list_customers(
  p_search text default '', p_limit integer default 50, p_offset integer default 0)
returns table (id uuid, full_name text, email text, phone text,
               created_at timestamptz, orders_count integer, spent integer)
language plpgsql stable security definer set search_path = '' as $$
declare
  pat text := '%' || replace(replace(left(trim(coalesce(p_search, '')), 60), '%', ''), '_', '') || '%';
begin
  perform public.assert_admin();
  return query
  select p.id, p.full_name, u.email::text, p.phone, p.created_at,
         (select count(*)::int from public.orders o where o.customer_id = p.id),
         (select coalesce(sum(o.total), 0)::int from public.orders o
           where o.customer_id = p.id and o.status = 'delivered')
    from public.profiles p
    join auth.users u on u.id = p.id
   where p.role = 'customer'
     and (p.full_name ilike pat or u.email ilike pat or coalesce(p.phone, '') ilike pat)
   order by p.created_at desc
   limit least(greatest(p_limit, 1), 200) offset greatest(p_offset, 0);
end $$;

-- ---------- commission statements -------------------------------------
-- Delivered, not-yet-billed orders of a restaurant in a period.
create or replace function public.admin_preview_statement(
  p_restaurant_id uuid, p_start date, p_end date)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return (
    select jsonb_build_object(
      'orders_count', count(*),
      'food_total', coalesce(sum(food_total), 0),
      'commission_total', coalesce(sum(commission_amount), 0)
    )
    from public.orders
    where restaurant_id = p_restaurant_id and status = 'delivered'
      and statement_id is null
      and public.dz_date(delivered_at) between p_start and p_end
  );
end $$;

-- Creates the statement, numbers it FD-YYYY-0001…, and attaches the
-- orders so they can never be billed twice.
create or replace function public.admin_generate_statement(
  p_restaurant_id uuid, p_start date, p_end date)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  sid uuid;
  cnt integer;
  food integer;
  comm integer;
begin
  perform public.assert_admin();
  if p_end < p_start then
    raise exception 'invalid period' using errcode = '22023';
  end if;
  if p_end > public.dz_date(now()) then
    raise exception 'period not finished' using errcode = '22023';
  end if;

  -- Lock the orders being billed.
  perform 1 from public.orders
   where restaurant_id = p_restaurant_id and status = 'delivered'
     and statement_id is null
     and public.dz_date(delivered_at) between p_start and p_end
   for update;

  select count(*), coalesce(sum(food_total), 0), coalesce(sum(commission_amount), 0)
    into cnt, food, comm
    from public.orders
   where restaurant_id = p_restaurant_id and status = 'delivered'
     and statement_id is null
     and public.dz_date(delivered_at) between p_start and p_end;

  if cnt = 0 then
    raise exception 'no orders to bill' using errcode = 'P0001';
  end if;

  insert into public.statements
    (number, restaurant_id, period_start, period_end, orders_count,
     food_total, commission_total, created_by)
  values
    ('FD-' || extract(year from p_end)::int || '-' ||
       lpad(nextval('public.statement_number_seq')::text, 4, '0'),
     p_restaurant_id, p_start, p_end, cnt, food, comm, auth.uid())
  returning id into sid;

  update public.orders set statement_id = sid
   where restaurant_id = p_restaurant_id and status = 'delivered'
     and statement_id is null
     and public.dz_date(delivered_at) between p_start and p_end;

  return sid;
end $$;

create or replace function public.admin_list_statements(p_restaurant_id uuid default null)
returns table (id uuid, number text, restaurant_id uuid, restaurant_name text,
               period_start date, period_end date, orders_count integer,
               food_total integer, commission_total integer, status text,
               issued_at timestamptz, paid_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select s.id, s.number, s.restaurant_id, r.name, s.period_start, s.period_end,
         s.orders_count, s.food_total, s.commission_total, s.status,
         s.issued_at, s.paid_at
    from public.statements s
    join public.restaurants r on r.id = s.restaurant_id
   where p_restaurant_id is null or s.restaurant_id = p_restaurant_id
   order by s.issued_at desc;
end $$;

-- Everything the PDF needs, in one call.
create or replace function public.admin_statement_detail(p_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  result jsonb;
begin
  perform public.assert_admin();
  select jsonb_build_object(
    'statement', to_jsonb(s),
    'restaurant', jsonb_build_object(
      'name', r.name, 'address', r.address, 'area', r.area, 'phone', r.phone,
      'owner_name', p.full_name, 'owner_email', u.email),
    'business', (select to_jsonb(c) - 'id' - 'default_commission_rate'
                   - 'handover_grace_hours' - 'max_active_jobs_per_driver'
                   - 'delivery_fee' from public.app_config c),
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
  where s.id = p_id;

  if result is null then
    raise exception 'statement not found' using errcode = 'P0002';
  end if;
  return result;
end $$;

create or replace function public.admin_set_statement_paid(p_id uuid, p_paid boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  update public.statements
     set status = case when p_paid then 'paid' else 'issued' end,
         paid_at = case when p_paid then now() end
   where id = p_id;
  if not found then raise exception 'statement not found' using errcode = 'P0002'; end if;
end $$;

-- Deletes an issued (unpaid) statement; its orders become billable again.
create or replace function public.admin_cancel_statement(p_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  st text;
begin
  perform public.assert_admin();
  select status into st from public.statements where id = p_id for update;
  if st is null then raise exception 'statement not found' using errcode = 'P0002'; end if;
  if st = 'paid' then raise exception 'statement already paid' using errcode = 'P0001'; end if;
  update public.orders set statement_id = null where statement_id = p_id;
  delete from public.statements where id = p_id;
end $$;

-- Only signed-in users may call the admin API (each also checks admin).
do $$
declare f text;
begin
  foreach f in array array[
    'admin_list_restaurants()',
    'admin_set_restaurant_active(uuid, boolean)',
    'admin_set_commission(uuid, numeric)',
    'admin_get_config()',
    'admin_update_config(integer, numeric, text, text, text, text, text)',
    'admin_stats(date, date)',
    'admin_stats_by_restaurant(date, date)',
    'admin_list_orders(date, date, uuid, public.order_status, integer, integer)',
    'admin_order_items(uuid)',
    'admin_list_customers(text, integer, integer)',
    'admin_preview_statement(uuid, date, date)',
    'admin_generate_statement(uuid, date, date)',
    'admin_list_statements(uuid)',
    'admin_statement_detail(uuid)',
    'admin_set_statement_paid(uuid, boolean)',
    'admin_cancel_statement(uuid)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

revoke all on function public.gen_order_code() from public, anon, authenticated;
revoke all on function public.orders_before_write() from public, anon, authenticated;
revoke all on function public.orders_log_status() from public, anon, authenticated;

insert into supabase_migrations.schema_migrations (version, name) values ('20261107000001', 'orders_admin_statements') on conflict (version) do nothing;

commit;
