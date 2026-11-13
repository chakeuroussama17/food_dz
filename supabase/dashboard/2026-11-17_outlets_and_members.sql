-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261117000001_outlets_and_members.sql
-- Run 2026-11-16_restaurant_insights.sql first.
begin;

-- =====================================================================
-- Outlets and team members.
--
--   * An owner can run several restaurants (outlets).
--   * Each restaurant has members with a role:
--       owner   - everything, including the team and closing the account
--       manager - orders, menu, photos, details, open/closed, reports,
--                 statements
--       staff   - orders only (accept, refuse, ready, cash received)
--   * restaurants.owner_id stays the account that created the restaurant
--     (shown to the admin). Access now comes from restaurant_members.
--
-- Every restaurant function below returns the data of ALL the user's
-- outlets, with the outlet's id and name, and takes an optional outlet
-- filter (the app sends the outlet it shows; the portal can send several).
-- =====================================================================

-- ---------- members ------------------------------------------------------
create table public.restaurant_members (
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  user_id       uuid not null references public.profiles (id) on delete cascade,
  role          text not null check (role in ('owner', 'manager', 'staff')),
  created_at    timestamptz not null default now(),
  primary key (restaurant_id, user_id)
);
create index restaurant_members_user_idx on public.restaurant_members (user_id);
alter table public.restaurant_members enable row level security;
revoke all on public.restaurant_members from anon, authenticated;

-- Everyone who owned a restaurant becomes its owner member.
insert into public.restaurant_members (restaurant_id, user_id, role)
select id, owner_id, 'owner' from public.restaurants where owner_id is not null
on conflict do nothing;

-- Several restaurants per owner.
do $$
declare c text;
begin
  select con.conname into c
    from pg_constraint con
    join pg_attribute a on a.attrelid = con.conrelid and a.attnum = any (con.conkey)
   where con.conrelid = 'public.restaurants'::regclass
     and con.contype = 'u' and a.attname = 'owner_id'
     and array_length(con.conkey, 1) = 1;
  if c is not null then
    execute format('alter table public.restaurants drop constraint %I', c);
  end if;
end $$;
create index if not exists restaurants_owner_idx on public.restaurants (owner_id);

-- Whoever is set as owner_id (registration, admin SQL, demo scripts) is
-- always an owner member too.
create or replace function public.restaurants_owner_member()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.owner_id is not null then
    insert into public.restaurant_members (restaurant_id, user_id, role)
    values (new.id, new.owner_id, 'owner')
    on conflict (restaurant_id, user_id) do update set role = 'owner';
  end if;
  return new;
end $$;
create trigger restaurants_owner_member
  after insert or update of owner_id on public.restaurants
  for each row execute function public.restaurants_owner_member();

create or replace function public.role_rank(p_role text)
returns integer language sql immutable set search_path = '' as $$
  select case p_role when 'owner' then 3 when 'manager' then 2
                     when 'staff' then 1 else 0 end;
$$;

-- The signed-in user's role in restaurant [rid], or null.
create or replace function public.restaurant_role(rid uuid)
returns text language sql stable security definer set search_path = '' as $$
  select m.role from public.restaurant_members m
   where m.restaurant_id = rid and m.user_id = auth.uid();
$$;
revoke all on function public.restaurant_role(uuid) from public, anon;
grant execute on function public.restaurant_role(uuid) to authenticated;

-- At least role [p_min] ('staff' < 'manager' < 'owner') in restaurant [rid].
create or replace function public.has_restaurant_role(rid uuid, p_min text)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce(public.role_rank(public.restaurant_role(rid))
                  >= public.role_rank(p_min), false);
$$;
revoke all on function public.has_restaurant_role(uuid, text) from public, anon;
grant execute on function public.has_restaurant_role(uuid, text) to authenticated;

-- Menu, photos and details: managers and owners.
create or replace function public.owns_restaurant(rid uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select public.has_restaurant_role(rid, 'manager');
$$;

-- ---------- policies -------------------------------------------------------
drop policy if exists "restaurants: owner reads own" on public.restaurants;
create policy "restaurants: members read own" on public.restaurants
  for select to authenticated
  using (public.has_restaurant_role(id, 'staff'));

drop policy if exists "restaurants: owner updates own" on public.restaurants;
create policy "restaurants: managers update own" on public.restaurants
  for update to authenticated
  using (public.has_restaurant_role(id, 'manager'))
  with check (public.has_restaurant_role(id, 'manager'));

drop policy if exists "orders: owner reads restaurant's" on public.orders;
create policy "orders: members read restaurant's" on public.orders
  for select to authenticated
  using (public.has_restaurant_role(restaurant_id, 'staff'));

drop policy if exists "statements: owner reads own" on public.statements;
create policy "statements: managers read own" on public.statements
  for select to authenticated
  using (public.has_restaurant_role(restaurant_id, 'manager'));

-- ---------- registration / new outlet ---------------------------------------
-- A customer account registers its first restaurant (and becomes an owner);
-- an owner calls it again to add an outlet. Both start inactive and closed.
create or replace function public.register_restaurant(
  p_name text,
  p_phone text,
  p_address text,
  p_area text,
  p_lat double precision default null,
  p_lng double precision default null,
  p_prep_minutes integer default 20
)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  v_role public.app_role;
  new_id uuid;
begin
  if uid is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;

  select role into v_role from public.profiles where id = uid for update;
  if v_role is null then
    raise exception 'profile missing' using errcode = 'P0002';
  end if;
  if not (v_role = 'customer'
          or (v_role = 'restaurant' and exists (
                select 1 from public.restaurant_members
                 where user_id = uid and role = 'owner'))) then
    raise exception 'account already has a role' using errcode = 'P0001';
  end if;
  if (select count(*) from public.restaurant_members
       where user_id = uid and role = 'owner') >= 20 then
    raise exception 'too many outlets' using errcode = 'P0001';
  end if;

  if char_length(trim(coalesce(p_name, ''))) not between 2 and 80 then
    raise exception 'invalid name' using errcode = '22023';
  end if;
  if coalesce(p_phone, '') !~ '^0[2-7][0-9]{7,8}$' then
    raise exception 'invalid phone' using errcode = '22023';
  end if;
  if char_length(trim(coalesce(p_address, ''))) not between 3 and 200 then
    raise exception 'invalid address' using errcode = '22023';
  end if;

  insert into public.restaurants
    (owner_id, slug, name, phone, address, area, lat, lng, prep_minutes,
     is_active, is_open)
  values
    (uid, public.make_restaurant_slug(p_name), trim(p_name), p_phone,
     trim(p_address), left(trim(coalesce(p_area, '')), 80), p_lat, p_lng,
     least(greatest(coalesce(p_prep_minutes, 20), 5), 120),
     false, false)
  returning id into new_id;

  -- (The trigger above adds the owner member.)
  update public.profiles set role = 'restaurant' where id = uid;
  return new_id;
end $$;

-- ---------- my outlets -----------------------------------------------------
create or replace function public.my_restaurants()
returns table (
  id uuid, slug text, name text, description text, phone text,
  address text, area text, lat double precision, lng double precision,
  cover_url text, logo_url text, prep_minutes integer,
  is_active boolean, is_open boolean, created_at timestamptz,
  my_role text
)
language sql stable security definer set search_path = '' as $$
  select r.id, r.slug, r.name, r.description, r.phone, r.address, r.area,
         r.lat, r.lng, r.cover_url, r.logo_url, r.prep_minutes,
         r.is_active, r.is_open, r.created_at, m.role
    from public.restaurant_members m
    join public.restaurants r on r.id = m.restaurant_id
   where m.user_id = auth.uid() and r.deleted_at is null
   order by r.created_at, r.name;
$$;
revoke all on function public.my_restaurants() from public, anon;
grant execute on function public.my_restaurants() to authenticated;

-- Older app versions: the first outlet.
create or replace function public.my_restaurant()
returns table (
  id uuid, slug text, name text, description text, phone text,
  address text, area text, lat double precision, lng double precision,
  cover_url text, logo_url text, prep_minutes integer,
  is_active boolean, is_open boolean, created_at timestamptz
)
language sql stable security definer set search_path = '' as $$
  select id, slug, name, description, phone, address, area, lat, lng,
         cover_url, logo_url, prep_minutes, is_active, is_open, created_at
    from public.my_restaurants()
   limit 1;
$$;

-- ---------- orders -----------------------------------------------------------
drop function if exists public.owner_orders(boolean, integer);
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
  restaurant_id uuid, restaurant_name text
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
         r.id, r.name
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
   where o.id = p_order_id
     and public.has_restaurant_role(o.restaurant_id, 'staff')
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

-- ---------- cash from drivers ----------------------------------------------------
create or replace function public.owner_confirm_cash(p_order_id uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  update public.orders o
     set cash_confirmed_at = now(),
         cash_handed_at = coalesce(o.cash_handed_at, now())
   where o.id = p_order_id
     and public.has_restaurant_role(o.restaurant_id, 'staff')
     and o.status = 'delivered' and o.driver_id is not null
     and o.cash_confirmed_at is null;
  if not found then
    if exists (select 1 from public.orders o
                where o.id = p_order_id
                  and public.has_restaurant_role(o.restaurant_id, 'staff')) then
      raise exception 'not_allowed' using errcode = 'P0001';
    end if;
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
end $$;

drop function if exists public.owner_cash_pending();
create function public.owner_cash_pending(p_restaurant_id uuid default null)
returns table (id uuid, code text, driver_name text, driver_phone text,
               food_total integer, delivered_at timestamptz,
               cash_handed_at timestamptz,
               restaurant_id uuid, restaurant_name text)
language sql stable security definer set search_path = '' as $$
  select o.id, o.code, dp.full_name, d.phone, o.food_total, o.delivered_at,
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
revoke all on function public.owner_cash_pending(uuid) from public, anon;
grant execute on function public.owner_cash_pending(uuid) to authenticated;

-- ---------- commission statements (managers) -----------------------------------
drop function if exists public.owner_statements();
create function public.owner_statements(p_restaurant_id uuid default null)
returns table (id uuid, number text, period_start date, period_end date,
               orders_count integer, food_total integer,
               commission_total integer, status text,
               issued_at timestamptz, paid_at timestamptz,
               restaurant_id uuid, restaurant_name text)
language sql stable security definer set search_path = '' as $$
  select s.id, s.number, s.period_start, s.period_end, s.orders_count,
         s.food_total, s.commission_total, s.status, s.issued_at, s.paid_at,
         r.id, r.name
    from public.statements s
    join public.restaurants r on r.id = s.restaurant_id
   where (p_restaurant_id is null or r.id = p_restaurant_id)
     and public.has_restaurant_role(r.id, 'manager')
   order by s.issued_at desc;
$$;
revoke all on function public.owner_statements(uuid) from public, anon;
grant execute on function public.owner_statements(uuid) to authenticated;

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
  where s.id = p_id and public.has_restaurant_role(r.id, 'manager');

  if result is null then
    raise exception 'statement not found' using errcode = 'P0002';
  end if;
  return result;
end $$;

-- ---------- report (managers) ------------------------------------------------------
drop function if exists public.owner_report(timestamptz, timestamptz);
create function public.owner_report(
  p_from           timestamptz,
  p_to             timestamptz,
  p_restaurant_ids uuid[] default null
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
  driver_name text,
  restaurant_id uuid, restaurant_name text,
  customer_key text,
  customer_phone text, address_text text, address_details text, notes text
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
         dp.full_name,
         r.id, r.name,
         -- Same customer across orders (new vs returning), without
         -- exposing who it is.
         md5(coalesce(o.customer_id::text, o.customer_phone)),
         o.customer_phone, o.address_text, o.address_details, o.notes
    from public.orders o
    join public.restaurants r on r.id = o.restaurant_id
    left join public.profiles dp on dp.id = o.driver_id
   where public.has_restaurant_role(r.id, 'manager')
     and (p_restaurant_ids is null or r.id = any (p_restaurant_ids))
     and o.placed_at >= p_from
     and o.placed_at <  p_to
   order by o.placed_at desc
   limit 10000;
end $$;
revoke all on function public.owner_report(timestamptz, timestamptz, uuid[]) from public, anon;
grant execute on function public.owner_report(timestamptz, timestamptz, uuid[]) to authenticated;

-- ---------- team ------------------------------------------------------------------
-- Members of an outlet (managers and owners can see the team).
create or replace function public.restaurant_team(p_restaurant_id uuid)
returns table (user_id uuid, full_name text, email text, role text,
               created_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.has_restaurant_role(p_restaurant_id, 'manager') then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  return query
  select m.user_id, p.full_name, u.email::text, m.role, m.created_at
    from public.restaurant_members m
    join public.profiles p on p.id = m.user_id
    join auth.users u on u.id = m.user_id
   where m.restaurant_id = p_restaurant_id
   order by public.role_rank(m.role) desc, p.full_name;
end $$;
revoke all on function public.restaurant_team(uuid) from public, anon;
grant execute on function public.restaurant_team(uuid) to authenticated;

-- The owner adds an existing account (signed up in the app) by email.
-- Errors: not_allowed, bad_role, user_not_found, user_has_other_role,
--         already_member
create or replace function public.owner_add_member(
  p_restaurant_id uuid, p_email text, p_role text)
returns uuid language plpgsql volatile security definer set search_path = '' as $$
declare
  v_user uuid;
  v_role public.app_role;
begin
  if not public.has_restaurant_role(p_restaurant_id, 'owner') then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_role not in ('owner', 'manager', 'staff') then
    raise exception 'bad_role' using errcode = '22023';
  end if;
  select u.id into v_user from auth.users u
   where lower(u.email) = lower(trim(coalesce(p_email, '')));
  if v_user is null then
    raise exception 'user_not_found' using errcode = 'P0002';
  end if;
  select role into v_role from public.profiles where id = v_user for update;
  if v_role not in ('customer', 'restaurant') then
    raise exception 'user_has_other_role' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.restaurant_members
              where restaurant_id = p_restaurant_id and user_id = v_user) then
    raise exception 'already_member' using errcode = 'P0001';
  end if;
  insert into public.restaurant_members (restaurant_id, user_id, role)
  values (p_restaurant_id, v_user, p_role);
  update public.profiles set role = 'restaurant' where id = v_user;
  return v_user;
end $$;
revoke all on function public.owner_add_member(uuid, text, text) from public, anon;
grant execute on function public.owner_add_member(uuid, text, text) to authenticated;

-- Errors: not_allowed, bad_role, not_member, last_owner
create or replace function public.owner_set_member_role(
  p_restaurant_id uuid, p_user_id uuid, p_role text)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_old text;
begin
  if not public.has_restaurant_role(p_restaurant_id, 'owner') then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_role not in ('owner', 'manager', 'staff') then
    raise exception 'bad_role' using errcode = '22023';
  end if;
  select role into v_old from public.restaurant_members
   where restaurant_id = p_restaurant_id and user_id = p_user_id for update;
  if v_old is null then
    raise exception 'not_member' using errcode = 'P0002';
  end if;
  if v_old = 'owner' and p_role <> 'owner'
     and (select count(*) from public.restaurant_members
           where restaurant_id = p_restaurant_id and role = 'owner') = 1 then
    raise exception 'last_owner' using errcode = 'P0001';
  end if;
  update public.restaurant_members set role = p_role
   where restaurant_id = p_restaurant_id and user_id = p_user_id;
end $$;
revoke all on function public.owner_set_member_role(uuid, uuid, text) from public, anon;
grant execute on function public.owner_set_member_role(uuid, uuid, text) to authenticated;

-- The owner removes someone, or a member leaves. An account left without
-- any outlet goes back to being a customer.
-- Errors: not_allowed, not_member, last_owner
create or replace function public.owner_remove_member(
  p_restaurant_id uuid, p_user_id uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_old text;
begin
  if not (public.has_restaurant_role(p_restaurant_id, 'owner')
          or p_user_id = auth.uid()) then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  select role into v_old from public.restaurant_members
   where restaurant_id = p_restaurant_id and user_id = p_user_id for update;
  if v_old is null then
    raise exception 'not_member' using errcode = 'P0002';
  end if;
  if v_old = 'owner'
     and (select count(*) from public.restaurant_members
           where restaurant_id = p_restaurant_id and role = 'owner') = 1 then
    raise exception 'last_owner' using errcode = 'P0001';
  end if;
  delete from public.restaurant_members
   where restaurant_id = p_restaurant_id and user_id = p_user_id;
  if not exists (select 1 from public.restaurant_members where user_id = p_user_id) then
    update public.profiles set role = 'customer'
     where id = p_user_id and role = 'restaurant';
  end if;
end $$;
revoke all on function public.owner_remove_member(uuid, uuid) from public, anon;
grant execute on function public.owner_remove_member(uuid, uuid) to authenticated;

-- ---------- account deletion ----------------------------------------------------------
-- Outlets where the user is the only owner are archived (same checks as
-- before, on each of them); team members just lose their access.
create or replace function public.delete_my_restaurant_account()
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  v_role public.app_role;
  rid uuid;
  sole uuid[];
  team uuid[];
begin
  if uid is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  select role into v_role from public.profiles where id = uid for update;
  if v_role is distinct from 'restaurant' then
    raise exception 'not_a_restaurant' using errcode = 'P0001';
  end if;

  select coalesce(array_agg(m.restaurant_id), '{}') into sole
    from public.restaurant_members m
   where m.user_id = uid and m.role = 'owner'
     and not exists (select 1 from public.restaurant_members o
                      where o.restaurant_id = m.restaurant_id
                        and o.role = 'owner' and o.user_id <> uid);

  foreach rid in array sole loop
    perform 1 from public.restaurants where id = rid for update;
    if exists (select 1 from public.orders o
                where o.restaurant_id = rid
                  and o.status in ('placed', 'accepted', 'ready', 'picked_up')) then
      raise exception 'active_orders' using errcode = 'P0001';
    end if;
    if exists (select 1 from public.orders o
                where o.restaurant_id = rid and o.status = 'delivered'
                  and o.cash_confirmed_at is null) then
      raise exception 'cash_pending' using errcode = 'P0001';
    end if;
    if exists (select 1 from public.orders o
                where o.restaurant_id = rid and o.status = 'delivered'
                  and o.statement_id is null
                  and coalesce(o.commission_amount, 0) > 0)
       or exists (select 1 from public.statements s
                   where s.restaurant_id = rid and s.status <> 'paid') then
      raise exception 'unpaid_commission' using errcode = 'P0001';
    end if;
  end loop;

  update public.restaurants
     set owner_id = null, is_active = false, is_open = false,
         phone = null, email = null, deleted_at = now()
   where id = any (sole);
  -- The rest of the team loses access to archived outlets; those left
  -- without any outlet become customers again.
  select coalesce(array_agg(distinct user_id), '{}') into team
    from public.restaurant_members
   where restaurant_id = any (sole) and user_id <> uid;
  delete from public.restaurant_members where restaurant_id = any (sole);
  update public.profiles p set role = 'customer'
   where p.id = any (team) and p.role = 'restaurant'
     and not exists (select 1 from public.restaurant_members m
                      where m.user_id = p.id);
  update public.restaurants set owner_id = null
   where owner_id = uid and not (id = any (sole));

  -- Cascades to the profile, memberships and push tokens.
  delete from auth.users where id = uid;
end $$;

commit;
