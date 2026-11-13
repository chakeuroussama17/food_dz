-- =====================================================================
-- Checkout: promo codes, a 1% tax, and the payment method.
--
-- Money of an order (all whole DA):
--   food_total      menu price of the dishes (unchanged meaning)
--   discount_amount promo code reduction (never more than the food)
--   tax_amount      app_config.tax_rate × (food − discount), rounded
--   delivery_fee    kept by the rider
--   total           = food − discount + tax + delivery fee  (customer pays)
--   restaurant_cash = total − delivery fee: what the rider hands to the
--                     restaurant (food after discount, plus the tax)
--
-- Who pays a discount is chosen per code (promo_codes.funded_by):
--   platform   the restaurant's statement is reduced by the discount, and
--              the commission is on the full food price;
--   restaurant the commission is on the food after discount, nothing is
--              credited.
-- The tax always goes to the platform through the statement.
-- Statement amount due = commission + tax − platform-funded discounts.
--
-- Payment: only cash for now (card and CCP are shown as "coming soon").
-- =====================================================================

-- ---------- config ----------------------------------------------------------
alter table public.app_config
  add column if not exists tax_rate numeric(5, 4) not null default 0
    check (tax_rate between 0 and 0.2);
update public.app_config set tax_rate = 0.01;
grant select (tax_rate) on public.app_config to anon, authenticated;

-- ---------- promo codes ----------------------------------------------------
create table public.promo_codes (
  id            uuid primary key default gen_random_uuid(),
  code          text not null unique check (code ~ '^[A-Z0-9]{3,20}$'),
  kind          text not null check (kind in ('percent', 'amount')),
  -- percent: 1..90; amount: DA
  value         integer not null check (value > 0),
  -- cap of a percent discount (DA), optional
  max_discount  integer check (max_discount > 0),
  min_order     integer not null default 0 check (min_order >= 0),
  -- uses in total / per customer (orders not rejected or cancelled)
  max_uses      integer check (max_uses > 0),
  per_customer  integer check (per_customer > 0),
  starts_at     timestamptz,
  ends_at       timestamptz,
  -- null: every restaurant
  restaurant_id uuid references public.restaurants (id) on delete cascade,
  funded_by     text not null default 'platform'
                check (funded_by in ('platform', 'restaurant')),
  is_active     boolean not null default true,
  note          text not null default '' check (char_length(note) <= 200),
  created_at    timestamptz not null default now(),
  check (kind <> 'percent' or value <= 90),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);
alter table public.promo_codes enable row level security;
revoke all on public.promo_codes from anon, authenticated;

-- ---------- order columns ---------------------------------------------------
alter table public.orders
  add column promo_code_id      uuid references public.promo_codes (id) on delete set null,
  add column promo_code         text,
  add column discount_amount    integer not null default 0 check (discount_amount >= 0),
  add column discount_funded_by text check (discount_funded_by in ('platform', 'restaurant')),
  add column tax_amount         integer not null default 0 check (tax_amount >= 0),
  add column payment_method     text not null default 'cash'
    check (payment_method in ('cash', 'card', 'ccp'));
-- What the rider hands to the restaurant: always computed by the database.
alter table public.orders
  add column restaurant_cash integer
    generated always as (food_total - discount_amount + tax_amount) stored;
create index orders_promo_idx on public.orders (promo_code_id) where promo_code_id is not null;

alter table public.statements
  add column tax_total      integer not null default 0,
  add column discount_total integer not null default 0,
  add column amount_due     integer;
update public.statements set amount_due = commission_total where amount_due is null;
alter table public.statements alter column amount_due set not null;

-- Commission of one order, given who pays its discount.
create or replace function public.order_commission(
  p_food integer, p_discount integer, p_funded_by text, p_rate numeric)
returns integer language sql immutable set search_path = '' as $$
  select round((p_food - case when p_funded_by = 'restaurant'
                               then coalesce(p_discount, 0) else 0 end) * p_rate)::int;
$$;

-- What one delivered order adds to the restaurant's statement.
create or replace function public.order_platform_due(o public.orders)
returns integer language sql stable set search_path = '' as $$
  select coalesce(o.commission_amount, 0) + o.tax_amount
         - case when o.discount_funded_by = 'platform' then o.discount_amount else 0 end;
$$;

create or replace function public.orders_before_write()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    if new.discount_amount > new.food_total then
      raise exception 'discount above food' using errcode = 'P0001';
    end if;
    new.total := new.food_total - new.discount_amount + new.tax_amount + new.delivery_fee;
    if new.status = 'delivered' then
      new.delivered_at := coalesce(new.delivered_at, now());
      new.commission_amount := public.order_commission(
        new.food_total, new.discount_amount, new.discount_funded_by, new.commission_rate);
    end if;
    return new;
  end if;

  -- Money and identity never change after the order is placed.
  if new.food_total <> old.food_total or new.delivery_fee <> old.delivery_fee
     or new.discount_amount <> old.discount_amount
     or new.tax_amount <> old.tax_amount
     or new.discount_funded_by is distinct from old.discount_funded_by
     or new.payment_method <> old.payment_method
     or new.commission_rate <> old.commission_rate
     or new.restaurant_id <> old.restaurant_id
     or (new.customer_id is distinct from old.customer_id
         and new.customer_id is not null) -- null: account deleted
     or new.code <> old.code then
    raise exception 'order amounts cannot change' using errcode = 'P0001';
  end if;
  new.total := new.food_total - new.discount_amount + new.tax_amount + new.delivery_fee;

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
        new.commission_amount := public.order_commission(
          new.food_total, new.discount_amount, new.discount_funded_by, new.commission_rate);
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


-- ---------- the discount of a code --------------------------------------------
-- Checks the code for this customer, restaurant and food amount and returns
-- the discount. Errors: promo_invalid, promo_not_here, promo_not_started,
-- promo_expired, promo_min_order, promo_used_up, promo_already_used
create or replace function public.promo_quote(
  p_code text, p_restaurant_id uuid, p_food integer, p_customer uuid,
  p_lock boolean default false)
returns table (promo_id uuid, code text, discount integer, funded_by text,
               kind text, value integer, min_order integer)
language plpgsql volatile security definer set search_path = '' as $$
declare
  c public.promo_codes;
  v_code text := upper(btrim(coalesce(p_code, '')));
  v_disc integer;
begin
  if p_lock then
    select * into c from public.promo_codes x where x.code = v_code for update;
  else
    select * into c from public.promo_codes x where x.code = v_code;
  end if;
  if not found or not c.is_active then
    raise exception 'promo_invalid' using errcode = 'P0001';
  end if;
  if c.restaurant_id is not null and c.restaurant_id <> p_restaurant_id then
    raise exception 'promo_not_here' using errcode = 'P0001';
  end if;
  if c.starts_at is not null and c.starts_at > now() then
    raise exception 'promo_not_started' using errcode = 'P0001';
  end if;
  if c.ends_at is not null and c.ends_at <= now() then
    raise exception 'promo_expired' using errcode = 'P0001';
  end if;
  if coalesce(p_food, 0) < c.min_order then
    raise exception 'promo_min_order' using errcode = 'P0001';
  end if;
  if c.max_uses is not null and (
       select count(*) from public.orders o
        where o.promo_code_id = c.id
          and o.status not in ('rejected', 'cancelled')) >= c.max_uses then
    raise exception 'promo_used_up' using errcode = 'P0001';
  end if;
  if c.per_customer is not null and (
       select count(*) from public.orders o
        where o.promo_code_id = c.id and o.customer_id = p_customer
          and o.status not in ('rejected', 'cancelled')) >= c.per_customer then
    raise exception 'promo_already_used' using errcode = 'P0001';
  end if;
  v_disc := case c.kind
              when 'percent' then floor(p_food * c.value / 100.0)::int
              else c.value end;
  if c.max_discount is not null then v_disc := least(v_disc, c.max_discount); end if;
  v_disc := greatest(least(v_disc, p_food), 0);
  return query select c.id, c.code, v_disc, c.funded_by, c.kind, c.value, c.min_order;
end $$;
revoke all on function public.promo_quote(text, uuid, integer, uuid, boolean)
  from public, anon, authenticated;

-- The customer's checkout: "what would this code give me?" (the order
-- itself is priced again by place_order).
create or replace function public.check_promo(
  p_restaurant_id uuid, p_code text, p_food_total integer)
returns table (code text, discount integer, kind text, value integer, min_order integer)
language plpgsql volatile security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  return query
  select q.code, q.discount, q.kind, q.value, q.min_order
    from public.promo_quote(p_code, p_restaurant_id, p_food_total, auth.uid()) q;
end $$;
revoke all on function public.check_promo(uuid, text, integer) from public, anon;
grant execute on function public.check_promo(uuid, text, integer) to authenticated;

-- ---------- place_order: promo code, tax, payment method -------------------------
drop function if exists public.place_order(uuid, jsonb, uuid, text, text, integer, uuid);
create function public.place_order(
  p_restaurant_id  uuid,
  p_items          jsonb,
  p_address_id     uuid,
  p_phone          text,
  p_notes          text default '',
  p_expected_total integer default null,
  p_client_ref     uuid default null,
  p_promo_code     text default null,
  p_payment_method text default 'cash'
)
returns table (id uuid, code text, food_total integer, delivery_fee integer, total integer,
               discount_amount integer, tax_amount integer)
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
  v_order    uuid;
  v_tax_rate numeric;
  v_disc     integer := 0;
  v_tax      integer;
  v_promo    record;
  uuid_re    constant text :=
    '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
begin
  if uid is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;

  select p.role, btrim(coalesce(p.full_name, '')) into v_role, v_name
    from public.profiles p where p.id = uid for update;
  if v_role is distinct from 'customer' then
    raise exception 'customers_only' using errcode = '42501';
  end if;

  if p_client_ref is not null then
    return query
      select o.id, o.code, o.food_total, o.delivery_fee, o.total,
             o.discount_amount, o.tax_amount
        from public.orders o
       where o.customer_id = uid and o.client_ref = p_client_ref;
    if found then return; end if;
  end if;

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
  if not (r.is_open and public.hours_open_at(p_restaurant_id, now())) then
    raise exception 'restaurant_closed' using errcode = 'P0001';
  end if;

  if v_phone !~ '^0[567][0-9]{8}$' then
    raise exception 'invalid_phone' using errcode = 'P0001';
  end if;
  -- Card and CCP are announced in the app but not open yet.
  if coalesce(p_payment_method, 'cash') <> 'cash' then
    raise exception 'payment_unavailable' using errcode = 'P0001';
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

  -- 1..30 lines; 1..20 of each; options = up to 20 choice ids.
  if jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) not between 1 and 30
     or exists (
       select 1 from jsonb_array_elements(p_items) e
        where jsonb_typeof(e) <> 'object'
           or coalesce(e->>'id', '') !~* uuid_re
           or coalesce(e->>'qty', '') !~ '^[0-9]{1,2}$'
           or (e->>'qty')::int not between 1 and 20
           or (e ? 'options' and (
                 jsonb_typeof(e->'options') <> 'array'
                 or jsonb_array_length(e->'options') > 20
                 or exists (select 1 from jsonb_array_elements(e->'options') x
                             where jsonb_typeof(x) <> 'string'
                                or (x #>> '{}') !~* uuid_re)))) then
    raise exception 'invalid_items' using errcode = 'P0001';
  end if;

  create temporary table if not exists pg_temp.order_lines (
    line integer primary key, menu_item_id uuid not null,
    qty integer not null, choices uuid[] not null
  ) on commit drop;
  truncate pg_temp.order_lines;
  -- The same dish with the same options sent twice = one line.
  insert into pg_temp.order_lines (line, menu_item_id, qty, choices)
  select row_number() over (order by min(t.n)), t.item, sum(t.qty), t.choices
    from (select e.n, (e.e->>'id')::uuid item, (e.e->>'qty')::int qty,
                 coalesce(array(select (x #>> '{}')::uuid c
                                  from jsonb_array_elements(coalesce(e.e->'options', '[]')) x
                                 order by 1), '{}') choices
            from jsonb_array_elements(p_items) with ordinality e(e, n)) t
   group by t.item, t.choices;

  if exists (select 1 from pg_temp.order_lines l
              group by l.menu_item_id having sum(l.qty) > 20) then
    raise exception 'invalid_items' using errcode = 'P0001';
  end if;
  if exists (select 1 from pg_temp.order_lines l
               left join public.menu_items m
                 on m.id = l.menu_item_id and m.restaurant_id = p_restaurant_id
                and m.is_available
              where m.id is null) then
    raise exception 'item_unavailable' using errcode = 'P0001';
  end if;

  -- Options: no duplicates, each one valid for its dish and available,
  -- and every group's min / max respected.
  if exists (select 1 from pg_temp.order_lines l
              where cardinality(l.choices)
                    <> (select count(distinct c) from unnest(l.choices) c))
     or exists (select 1 from pg_temp.order_lines l, unnest(l.choices) c(id)
                 where not exists (
                   select 1 from public.option_choices ch
                     join public.menu_item_groups mig on mig.group_id = ch.group_id
                    where ch.id = c.id and mig.menu_item_id = l.menu_item_id
                      and ch.is_available))
     or exists (select 1 from pg_temp.order_lines l
                  join public.menu_item_groups mig on mig.menu_item_id = l.menu_item_id
                  join public.option_groups g on g.id = mig.group_id
                 where (select count(*) from public.option_choices ch
                         where ch.group_id = g.id and ch.id = any (l.choices))
                       not between g.min_select and g.max_select) then
    raise exception 'options_invalid' using errcode = 'P0001';
  end if;

  select coalesce(sum((m.price + coalesce((select sum(ch.price)
                                              from public.option_choices ch
                                             where ch.id = any (l.choices)), 0)) * l.qty), 0)
    into v_food
    from pg_temp.order_lines l
    join public.menu_items m on m.id = l.menu_item_id;

  select c.delivery_fee, coalesce(r.commission_rate, c.default_commission_rate), c.tax_rate
    into v_fee, v_rate, v_tax_rate
    from public.app_config c limit 1;

  -- Promo code (locked, so the last use can't be taken twice).
  if nullif(btrim(coalesce(p_promo_code, '')), '') is not null then
    select * into v_promo
      from public.promo_quote(p_promo_code, p_restaurant_id, v_food, uid, true);
    v_disc := v_promo.discount;
  end if;
  if v_disc = 0 then
    select null::uuid promo_id, null::text code, null::text funded_by into v_promo;
  end if;
  v_tax := round((v_food - v_disc) * coalesce(v_tax_rate, 0));

  -- The app shows the final total; refuse if anything changed meanwhile.
  if p_expected_total is not null
     and p_expected_total <> v_food - v_disc + v_tax + v_fee then
    raise exception 'prices_changed' using errcode = 'P0001';
  end if;

  insert into public.orders
    (customer_id, restaurant_id, customer_name, customer_phone,
     address_text, area, address_details, lat, lng, notes,
     food_total, delivery_fee, commission_rate, client_ref,
     promo_code_id, promo_code, discount_amount, discount_funded_by,
     tax_amount, payment_method)
  values
    (uid, p_restaurant_id,
     left(case when char_length(v_name) = 0 then 'Client' else v_name end, 80),
     v_phone, left(a.address_text, 200), left(coalesce(a.area, ''), 80),
     left(coalesce(a.details, ''), 120), a.lat, a.lng, v_notes,
     v_food, v_fee, v_rate, p_client_ref,
     v_promo.promo_id, v_promo.code, v_disc,
     case when v_disc > 0 then v_promo.funded_by end,
     v_tax, 'cash')
  returning orders.id into v_order;

  insert into public.order_items (order_id, menu_item_id, name, unit_price, quantity, options)
  select v_order, m.id,
         left(m.name || coalesce(' (' || o.names || ')', ''), 200),
         m.price + coalesce(o.extra, 0), l.qty, coalesce(o.js, '[]'::jsonb)
    from pg_temp.order_lines l
    join public.menu_items m on m.id = l.menu_item_id
    left join lateral (
      select string_agg(ch.name, ', ' order by mig.sort_order, g.sort_order, ch.sort_order) names,
             sum(ch.price)::int extra,
             jsonb_agg(jsonb_build_object('group', g.name, 'name', ch.name, 'price', ch.price)
                       order by mig.sort_order, g.sort_order, ch.sort_order) js
        from public.option_choices ch
        join public.option_groups g on g.id = ch.group_id
        join public.menu_item_groups mig
          on mig.group_id = g.id and mig.menu_item_id = l.menu_item_id
       where ch.id = any (l.choices)
    ) o on true
   order by l.line;

  update public.profiles p set phone = v_phone
   where p.id = uid and (p.phone is null or p.phone = '');

  return query
    select o.id, o.code, o.food_total, o.delivery_fee, o.total,
           o.discount_amount, o.tax_amount
      from public.orders o where o.id = v_order;
end $$;

revoke all on function public.place_order(uuid, jsonb, uuid, text, text, integer, uuid, text, text)
  from public, anon;
grant execute on function public.place_order(uuid, jsonb, uuid, text, text, integer, uuid, text, text)
  to authenticated;

-- ---------- the customer's orders: discount, tax, payment ----------------------
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
  payment_method text
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
         o.discount_amount, o.tax_amount, o.promo_code, o.payment_method
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


-- ---------- the restaurant's orders: discount and tax too ----------------------
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
  discount_funded_by text
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
         o.discount_amount, o.tax_amount, o.promo_code, o.discount_funded_by
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

-- ---------- cash to hand: food after discount, plus the tax --------------------
create or replace function public.driver_cash_pending()
returns table (id uuid, code text, restaurant_name text, restaurant_phone text,
               food_total integer, delivered_at timestamptz,
               cash_handed_at timestamptz, overdue boolean)
language sql stable security definer set search_path = '' as $$
  select o.id, o.code, r.name, r.phone, o.restaurant_cash, o.delivered_at,
         o.cash_handed_at,
         o.delivered_at < now() - make_interval(hours => c.cash_handover_hours)
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
    cross join public.app_config c
   where o.driver_id = auth.uid()
     and o.status = 'delivered' and o.cash_confirmed_at is null
   order by o.delivered_at;
$$;

create or replace function public.owner_cash_pending(p_restaurant_id uuid default null)
returns table (id uuid, code text, driver_name text, driver_phone text,
               food_total integer, delivered_at timestamptz,
               cash_handed_at timestamptz,
               restaurant_id uuid, restaurant_name text)
language sql stable security definer set search_path = '' as $$
  select o.id, o.code, dp.full_name, d.phone, o.restaurant_cash, o.delivered_at,
         o.cash_handed_at, r.id, r.name
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
    join public.restaurant_members m
      on m.restaurant_id = r.id and m.user_id = auth.uid()
    left join public.drivers d on d.id = o.driver_id
    left join public.profiles dp on dp.id = o.driver_id
   where (p_restaurant_id is null or r.id = p_restaurant_id)
     and o.status = 'delivered' and o.driver_id is not null
     and o.cash_confirmed_at is null
   order by o.delivered_at;
$$;

create or replace function public.my_driver()
returns table (id uuid, full_name text, phone text, vehicle text,
               is_approved boolean, is_online boolean,
               cash_owed integer, cash_blocked boolean)
language sql stable security definer set search_path = '' as $$
  select d.id, p.full_name, d.phone, d.vehicle, d.is_approved, d.is_online,
         (select coalesce(sum(o.restaurant_cash), 0)::int from public.orders o
           where o.driver_id = d.id and o.status = 'delivered'
             and o.cash_confirmed_at is null),
         public.cash_overdue(d.id)
    from public.drivers d join public.profiles p on p.id = d.id
   where d.id = auth.uid();
$$;

create or replace function public.admin_list_drivers()
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
      select coalesce(sum(o.restaurant_cash), 0)::int as owed,
             count(*)::int as n,
             min(o.delivered_at) as oldest
        from public.orders o
       where o.driver_id = d.id and o.status = 'delivered'
         and o.cash_confirmed_at is null) c
   order by d.is_approved, c.owed desc, d.created_at desc;
end $$;

-- Rider statement: "food handed" is now the cash for the restaurant.
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
  select o.code, o.delivered_at, r.name, o.total, o.restaurant_cash,
         o.delivery_fee, o.cash_confirmed_at
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
   where o.driver_id = auth.uid()
     and o.status = 'delivered'
     and public.dz_date(o.delivered_at) between p_from and p_to
   order by o.delivered_at;
end $$;

-- ---------- statements: tax and platform discounts ------------------------------
create or replace function public.admin_preview_statement(
  p_restaurant_id uuid, p_start date, p_end date)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return (
    select jsonb_build_object(
      'orders_count', count(*),
      'food_total', coalesce(sum(o.food_total), 0),
      'commission_total', coalesce(sum(o.commission_amount), 0),
      'tax_total', coalesce(sum(o.tax_amount), 0),
      'discount_total', coalesce(sum(o.discount_amount)
                          filter (where o.discount_funded_by = 'platform'), 0),
      'amount_due', coalesce(sum(public.order_platform_due(o)), 0)
    )
    from public.orders o
    where o.restaurant_id = p_restaurant_id and o.status = 'delivered'
      and o.statement_id is null
      and public.dz_date(o.delivered_at) between p_start and p_end
  );
end $$;

create or replace function public.admin_generate_statement(
  p_restaurant_id uuid, p_start date, p_end date)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  sid uuid;
  t record;
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

  select count(*)::int n,
         coalesce(sum(o.food_total), 0)::int food,
         coalesce(sum(o.commission_amount), 0)::int comm,
         coalesce(sum(o.tax_amount), 0)::int tax,
         coalesce(sum(o.discount_amount)
                    filter (where o.discount_funded_by = 'platform'), 0)::int disc,
         coalesce(sum(public.order_platform_due(o)), 0)::int due
    into t
    from public.orders o
   where o.restaurant_id = p_restaurant_id and o.status = 'delivered'
     and o.statement_id is null
     and public.dz_date(o.delivered_at) between p_start and p_end;

  if t.n = 0 then
    raise exception 'no orders to bill' using errcode = 'P0001';
  end if;

  insert into public.statements
    (number, restaurant_id, period_start, period_end, orders_count,
     food_total, commission_total, tax_total, discount_total, amount_due, created_by)
  values
    ('FD-' || extract(year from p_end)::int || '-' ||
       lpad(nextval('public.statement_number_seq')::text, 4, '0'),
     p_restaurant_id, p_start, p_end, t.n, t.food, t.comm, t.tax, t.disc, t.due,
     auth.uid())
  returning id into sid;

  update public.orders set statement_id = sid
   where restaurant_id = p_restaurant_id and status = 'delivered'
     and statement_id is null
     and public.dz_date(delivered_at) between p_start and p_end;

  return sid;
end $$;

drop function if exists public.admin_list_statements(uuid);
create function public.admin_list_statements(p_restaurant_id uuid default null)
returns table (id uuid, number text, restaurant_id uuid, restaurant_name text,
               period_start date, period_end date, orders_count integer,
               food_total integer, commission_total integer, status text,
               issued_at timestamptz, paid_at timestamptz,
               tax_total integer, discount_total integer, amount_due integer)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select s.id, s.number, s.restaurant_id, r.name, s.period_start, s.period_end,
         s.orders_count, s.food_total, s.commission_total, s.status,
         s.issued_at, s.paid_at, s.tax_total, s.discount_total, s.amount_due
    from public.statements s
    join public.restaurants r on r.id = s.restaurant_id
   where p_restaurant_id is null or s.restaurant_id = p_restaurant_id
   order by s.issued_at desc;
end $$;
revoke all on function public.admin_list_statements(uuid) from public, anon;
grant execute on function public.admin_list_statements(uuid) to authenticated;

drop function if exists public.owner_statements(uuid);
create function public.owner_statements(p_restaurant_id uuid default null)
returns table (id uuid, number text, period_start date, period_end date,
               orders_count integer, food_total integer,
               commission_total integer, status text,
               issued_at timestamptz, paid_at timestamptz,
               restaurant_id uuid, restaurant_name text,
               tax_total integer, discount_total integer, amount_due integer)
language sql stable security definer set search_path = '' as $$
  select s.id, s.number, s.period_start, s.period_end, s.orders_count,
         s.food_total, s.commission_total, s.status, s.issued_at, s.paid_at,
         r.id, r.name, s.tax_total, s.discount_total, s.amount_due
    from public.statements s
    join public.restaurants r on r.id = s.restaurant_id
   where (p_restaurant_id is null or r.id = p_restaurant_id)
     and public.has_restaurant_role(r.id, 'manager')
   order by s.issued_at desc;
$$;
revoke all on function public.owner_statements(uuid) from public, anon;
grant execute on function public.owner_statements(uuid) to authenticated;

-- Statement lines for the PDF: each order's tax and platform discount too.
create or replace function public.statement_lines(p_statement uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'code', o.code, 'delivered_at', o.delivered_at,
           'food_total', o.food_total, 'commission_rate', o.commission_rate,
           'commission_amount', o.commission_amount,
           'tax_amount', o.tax_amount,
           'discount_amount', case when o.discount_funded_by = 'platform'
                                   then o.discount_amount else 0 end,
           'amount_due', public.order_platform_due(o))
         order by o.delivered_at), '[]'::jsonb)
    from public.orders o where o.statement_id = p_statement;
$$;
revoke all on function public.statement_lines(uuid) from public, anon, authenticated;

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
    'business', public.business_info(),
    'orders', public.statement_lines(s.id)
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
    'orders', public.statement_lines(s.id)
  ) into result
  from public.statements s
  join public.restaurants r on r.id = s.restaurant_id
  left join public.profiles p on p.id = r.owner_id
  left join auth.users u on u.id = r.owner_id
  where s.id = p_id and public.has_restaurant_role(r.id, 'manager');

  if result is null then
    raise exception 'statement not found' using errcode = 'P0002';
  end if;
  return result;
end $$;

-- ---------- admin: promo codes ---------------------------------------------------
create or replace function public.admin_promo_codes()
returns table (id uuid, code text, kind text, value integer, max_discount integer,
               min_order integer, max_uses integer, per_customer integer,
               starts_at timestamptz, ends_at timestamptz,
               restaurant_id uuid, restaurant_name text, funded_by text,
               is_active boolean, note text, created_at timestamptz,
               uses integer, discount_given bigint)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select c.id, c.code, c.kind, c.value, c.max_discount, c.min_order, c.max_uses,
         c.per_customer, c.starts_at, c.ends_at, c.restaurant_id, r.name,
         c.funded_by, c.is_active, c.note, c.created_at,
         (select count(*)::int from public.orders o
           where o.promo_code_id = c.id and o.status not in ('rejected', 'cancelled')),
         (select coalesce(sum(o.discount_amount), 0)::bigint from public.orders o
           where o.promo_code_id = c.id and o.status = 'delivered')
    from public.promo_codes c
    left join public.restaurants r on r.id = c.restaurant_id
   order by c.is_active desc, c.created_at desc;
end $$;
revoke all on function public.admin_promo_codes() from public, anon;
grant execute on function public.admin_promo_codes() to authenticated;

-- Creates (p_id null) or updates a code. Errors: invalid_code, code_taken,
-- invalid_value, invalid_dates
create or replace function public.admin_save_promo_code(
  p_id uuid, p_code text, p_kind text, p_value integer,
  p_max_discount integer, p_min_order integer, p_max_uses integer,
  p_per_customer integer, p_starts_at timestamptz, p_ends_at timestamptz,
  p_restaurant_id uuid, p_funded_by text, p_note text)
returns uuid language plpgsql volatile security definer set search_path = '' as $$
declare
  v_code text := upper(btrim(coalesce(p_code, '')));
  v_id uuid;
begin
  perform public.assert_admin();
  if v_code !~ '^[A-Z0-9]{3,20}$' then
    raise exception 'invalid_code' using errcode = '22023';
  end if;
  if exists (select 1 from public.promo_codes c
              where c.code = v_code and c.id is distinct from p_id) then
    raise exception 'code_taken' using errcode = '23505';
  end if;
  if coalesce(p_kind, '') not in ('percent', 'amount')
     or coalesce(p_value, 0) <= 0
     or (p_kind = 'percent' and p_value > 90)
     or (p_kind = 'amount' and p_value > 100000)
     or coalesce(p_min_order, 0) < 0
     or coalesce(p_max_discount, 1) <= 0
     or coalesce(p_max_uses, 1) <= 0
     or coalesce(p_per_customer, 1) <= 0
     or coalesce(p_funded_by, '') not in ('platform', 'restaurant') then
    raise exception 'invalid_value' using errcode = '22023';
  end if;
  if p_starts_at is not null and p_ends_at is not null and p_ends_at <= p_starts_at then
    raise exception 'invalid_dates' using errcode = '22023';
  end if;
  if p_id is null then
    insert into public.promo_codes
      (code, kind, value, max_discount, min_order, max_uses, per_customer,
       starts_at, ends_at, restaurant_id, funded_by, note)
    values
      (v_code, p_kind, p_value, p_max_discount, coalesce(p_min_order, 0), p_max_uses,
       p_per_customer, p_starts_at, p_ends_at, p_restaurant_id, p_funded_by,
       left(coalesce(btrim(p_note), ''), 200))
    returning id into v_id;
  else
    update public.promo_codes
       set code = v_code, kind = p_kind, value = p_value, max_discount = p_max_discount,
           min_order = coalesce(p_min_order, 0), max_uses = p_max_uses,
           per_customer = p_per_customer, starts_at = p_starts_at, ends_at = p_ends_at,
           restaurant_id = p_restaurant_id, funded_by = p_funded_by,
           note = left(coalesce(btrim(p_note), ''), 200)
     where id = p_id
    returning id into v_id;
    if v_id is null then
      raise exception 'not_found' using errcode = 'P0002';
    end if;
  end if;
  return v_id;
end $$;
revoke all on function public.admin_save_promo_code(uuid, text, text, integer, integer,
  integer, integer, integer, timestamptz, timestamptz, uuid, text, text) from public, anon;
grant execute on function public.admin_save_promo_code(uuid, text, text, integer, integer,
  integer, integer, integer, timestamptz, timestamptz, uuid, text, text) to authenticated;

create or replace function public.admin_set_promo_active(p_id uuid, p_active boolean)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  update public.promo_codes set is_active = coalesce(p_active, false) where id = p_id;
end $$;
revoke all on function public.admin_set_promo_active(uuid, boolean) from public, anon;
grant execute on function public.admin_set_promo_active(uuid, boolean) to authenticated;

-- ---------- push: a rider change only matters on an open order -----------------
-- (Deleting a rider account empties the rider of old delivered orders:
-- that must not tell other riders "order available".)
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
