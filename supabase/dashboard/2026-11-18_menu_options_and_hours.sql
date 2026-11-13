-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261118000001_menu_options_and_hours.sql
-- Run 2026-11-16 and 2026-11-17 first.
begin;

-- =====================================================================
-- Partner portal step 2:
--   * Dish options: reusable option groups ("Size", "Extras") with
--     choices and an extra price, linked to dishes. Prices are always
--     computed here when the order is placed.
--   * Bulk menu edits (show / hide / category / prices / delete).
--   * Opening hours and holidays / special hours (Africa/Algiers time).
--     A restaurant takes orders when its switch is on AND it is within
--     its hours. No weekly hours set = open whenever the switch is on.
-- =====================================================================

-- The 2-argument report (from 2026-11-16) must not exist next to the
-- 3-argument one (2026-11-17): PostgREST can't choose between them
-- (PGRST203). Happens when the 11-16 file is run again after 11-17.
drop function if exists public.owner_report(timestamptz, timestamptz);

-- ---------- option groups --------------------------------------------------
create table public.option_groups (
  id            uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  name          text not null check (char_length(name) between 1 and 60),
  min_select    integer not null default 0 check (min_select between 0 and 10),
  max_select    integer not null default 1 check (max_select between 1 and 10),
  sort_order    integer not null default 0,
  created_at    timestamptz not null default now(),
  check (max_select >= min_select)
);
create index option_groups_restaurant_idx on public.option_groups (restaurant_id);

create table public.option_choices (
  id           uuid primary key default gen_random_uuid(),
  group_id     uuid not null references public.option_groups (id) on delete cascade,
  name         text not null check (char_length(name) between 1 and 60),
  price        integer not null default 0 check (price between 0 and 100000),
  is_available boolean not null default true,
  sort_order   integer not null default 0
);
create index option_choices_group_idx on public.option_choices (group_id);

create table public.menu_item_groups (
  menu_item_id uuid not null references public.menu_items (id) on delete cascade,
  group_id     uuid not null references public.option_groups (id) on delete cascade,
  sort_order   integer not null default 0,
  primary key (menu_item_id, group_id)
);
create index menu_item_groups_group_idx on public.menu_item_groups (group_id);

alter table public.option_groups enable row level security;
alter table public.option_choices enable row level security;
alter table public.menu_item_groups enable row level security;
revoke all on public.option_groups, public.option_choices, public.menu_item_groups
  from anon, authenticated;
grant select on public.option_groups, public.option_choices, public.menu_item_groups
  to anon, authenticated;

create policy "option_groups: public read of active restaurants" on public.option_groups
  for select to anon, authenticated
  using (exists (select 1 from public.restaurants r
                  where r.id = restaurant_id and r.is_active));
create policy "option_groups: managers read own" on public.option_groups
  for select to authenticated
  using (public.has_restaurant_role(restaurant_id, 'manager'));
create policy "option_choices: visible with the group" on public.option_choices
  for select to anon, authenticated
  using (exists (select 1 from public.option_groups g where g.id = group_id));
create policy "menu_item_groups: visible with the dish" on public.menu_item_groups
  for select to anon, authenticated
  using (exists (select 1 from public.menu_items m where m.id = menu_item_id));

-- What was chosen, kept with the order line (the line's name also shows
-- it: "Pizza (Large, Extra cheese)").
alter table public.order_items
  add column if not exists options jsonb not null default '[]'::jsonb;

-- Create or update a group with its choices and the dishes using it.
-- p_group: {"id"?, "name", "min", "max",
--           "choices": [{"id"?, "name", "price", "available"}],
--           "item_ids": [...]}
-- Errors: not_allowed, invalid_group, not_found, too_many_groups
create or replace function public.owner_save_option_group(
  p_restaurant_id uuid, p_group jsonb)
returns uuid language plpgsql volatile security definer set search_path = '' as $$
declare
  v_id     uuid := nullif(p_group->>'id', '')::uuid;
  v_name   text := btrim(coalesce(p_group->>'name', ''));
  v_min    integer;
  v_max    integer;
  v_items  uuid[];
  c        jsonb;
  i        integer := 0;
  kept     uuid[] := '{}';
  cid      uuid;
begin
  if not public.has_restaurant_role(p_restaurant_id, 'manager') then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  begin
    v_min := coalesce((p_group->>'min')::int, 0);
    v_max := coalesce((p_group->>'max')::int, 1);
    v_items := coalesce(array(select jsonb_array_elements_text(
                                coalesce(p_group->'item_ids', '[]'))::uuid), '{}');
  exception when others then
    raise exception 'invalid_group' using errcode = '22023';
  end;
  if char_length(v_name) not between 1 and 60
     or v_min not between 0 and 10 or v_max not between 1 and 10 or v_max < v_min
     or jsonb_typeof(p_group->'choices') is distinct from 'array'
     or jsonb_array_length(p_group->'choices') not between 1 and 30
     or v_min > jsonb_array_length(p_group->'choices') then
    raise exception 'invalid_group' using errcode = '22023';
  end if;
  for c in select * from jsonb_array_elements(p_group->'choices') loop
    if char_length(btrim(coalesce(c->>'name', ''))) not between 1 and 60
       or coalesce(c->>'price', '0') !~ '^[0-9]{1,6}$'
       or (c->>'price')::int > 100000 then
      raise exception 'invalid_group' using errcode = '22023';
    end if;
  end loop;
  if exists (select 1 from unnest(v_items) x(id)
              where not exists (select 1 from public.menu_items m
                                 where m.id = x.id and m.restaurant_id = p_restaurant_id)) then
    raise exception 'invalid_group' using errcode = '22023';
  end if;

  if v_id is null then
    if (select count(*) from public.option_groups
         where restaurant_id = p_restaurant_id) >= 100 then
      raise exception 'too_many_groups' using errcode = 'P0001';
    end if;
    insert into public.option_groups (restaurant_id, name, min_select, max_select, sort_order)
    values (p_restaurant_id, v_name, v_min, v_max,
            (select coalesce(max(sort_order), 0) + 1 from public.option_groups
              where restaurant_id = p_restaurant_id))
    returning id into v_id;
  else
    update public.option_groups
       set name = v_name, min_select = v_min, max_select = v_max
     where id = v_id and restaurant_id = p_restaurant_id;
    if not found then
      raise exception 'not_found' using errcode = 'P0002';
    end if;
  end if;

  -- Choices: update the ones sent with an id, add the new ones, drop the rest.
  for c in select * from jsonb_array_elements(p_group->'choices') loop
    i := i + 1;
    cid := nullif(c->>'id', '')::uuid;
    if cid is not null then
      update public.option_choices
         set name = btrim(c->>'name'),
             price = coalesce((c->>'price')::int, 0),
             is_available = coalesce((c->>'available')::boolean, true),
             sort_order = i
       where id = cid and group_id = v_id;
      if not found then cid := null; end if;
    end if;
    if cid is null then
      insert into public.option_choices (group_id, name, price, is_available, sort_order)
      values (v_id, btrim(c->>'name'), coalesce((c->>'price')::int, 0),
              coalesce((c->>'available')::boolean, true), i)
      returning id into cid;
    end if;
    kept := kept || cid;
  end loop;
  delete from public.option_choices where group_id = v_id and not (id = any (kept));

  -- Dishes using the group.
  delete from public.menu_item_groups where group_id = v_id and not (menu_item_id = any (v_items));
  insert into public.menu_item_groups (menu_item_id, group_id, sort_order)
  select x.id, v_id,
         (select coalesce(max(sort_order), 0) + 1 from public.menu_item_groups
           where menu_item_id = x.id)
    from unnest(v_items) x(id)
  on conflict do nothing;
  return v_id;
end $$;
revoke all on function public.owner_save_option_group(uuid, jsonb) from public, anon;
grant execute on function public.owner_save_option_group(uuid, jsonb) to authenticated;

create or replace function public.owner_delete_option_group(p_group_id uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  delete from public.option_groups g
   where g.id = p_group_id
     and public.has_restaurant_role(g.restaurant_id, 'manager');
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
end $$;
revoke all on function public.owner_delete_option_group(uuid) from public, anon;
grant execute on function public.owner_delete_option_group(uuid) to authenticated;

-- The option groups of one dish, in this order.
create or replace function public.owner_set_item_groups(
  p_item_id uuid, p_group_ids uuid[])
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  rid uuid;
begin
  select m.restaurant_id into rid from public.menu_items m where m.id = p_item_id;
  if rid is null or not public.has_restaurant_role(rid, 'manager') then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if exists (select 1 from unnest(coalesce(p_group_ids, '{}')) x(id)
              where not exists (select 1 from public.option_groups g
                                 where g.id = x.id and g.restaurant_id = rid)) then
    raise exception 'invalid_group' using errcode = '22023';
  end if;
  delete from public.menu_item_groups where menu_item_id = p_item_id;
  insert into public.menu_item_groups (menu_item_id, group_id, sort_order)
  select p_item_id, x.id, x.n
    from unnest(coalesce(p_group_ids, '{}')) with ordinality x(id, n)
  on conflict do nothing;
end $$;
revoke all on function public.owner_set_item_groups(uuid, uuid[]) from public, anon;
grant execute on function public.owner_set_item_groups(uuid, uuid[]) to authenticated;

-- "Out of stock" on one choice (e.g. no more cheese).
create or replace function public.owner_set_choice_available(
  p_choice_id uuid, p_available boolean)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  update public.option_choices ch
     set is_available = coalesce(p_available, true)
    from public.option_groups g
   where ch.id = p_choice_id and g.id = ch.group_id
     and public.has_restaurant_role(g.restaurant_id, 'manager');
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
end $$;
revoke all on function public.owner_set_choice_available(uuid, boolean) from public, anon;
grant execute on function public.owner_set_choice_available(uuid, boolean) to authenticated;

-- ---------- bulk menu edits ------------------------------------------------------
-- p_action: show | hide | category (p_category, null = none) |
--           price_percent (p_number, -90..300) | price_add (p_number) | delete
-- New prices are rounded to 10 DA and kept between 10 and 100 000.
-- Returns how many dishes changed. Errors: not_allowed, invalid_action
create or replace function public.owner_bulk_items(
  p_restaurant_id uuid,
  p_ids           uuid[],
  p_action        text,
  p_number        numeric default null,
  p_category      uuid default null
)
returns integer language plpgsql volatile security definer set search_path = '' as $$
declare
  n integer;
begin
  if not public.has_restaurant_role(p_restaurant_id, 'manager') then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if coalesce(cardinality(p_ids), 0) not between 1 and 200 then
    raise exception 'invalid_action' using errcode = '22023';
  end if;
  case p_action
    when 'show', 'hide' then
      update public.menu_items set is_available = (p_action = 'show')
       where restaurant_id = p_restaurant_id and id = any (p_ids);
    when 'category' then
      if p_category is not null
         and not exists (select 1 from public.categories where id = p_category) then
        raise exception 'invalid_action' using errcode = '22023';
      end if;
      update public.menu_items set category_id = p_category
       where restaurant_id = p_restaurant_id and id = any (p_ids);
    when 'price_percent' then
      if p_number is null or p_number not between -90 and 300 then
        raise exception 'invalid_action' using errcode = '22023';
      end if;
      update public.menu_items
         set price = least(100000, greatest(10,
                       (round(price * (1 + p_number / 100) / 10) * 10)::int))
       where restaurant_id = p_restaurant_id and id = any (p_ids);
    when 'price_add' then
      if p_number is null or p_number not between -100000 and 100000 then
        raise exception 'invalid_action' using errcode = '22023';
      end if;
      update public.menu_items
         set price = least(100000, greatest(10, (price + round(p_number))::int))
       where restaurant_id = p_restaurant_id and id = any (p_ids);
    when 'delete' then
      delete from public.menu_items
       where restaurant_id = p_restaurant_id and id = any (p_ids);
    else
      raise exception 'invalid_action' using errcode = '22023';
  end case;
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public.owner_bulk_items(uuid, uuid[], text, numeric, uuid) from public, anon;
grant execute on function public.owner_bulk_items(uuid, uuid[], text, numeric, uuid) to authenticated;

-- ---------- opening hours ----------------------------------------------------------
-- weekday: 0 = Saturday ... 6 = Friday (the Algerian week).
-- closes <= opens means after midnight (18:00 -> 02:00).
create table public.opening_hours (
  id            bigint generated always as identity primary key,
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  weekday       smallint not null check (weekday between 0 and 6),
  opens         time not null,
  closes        time not null,
  check (opens <> closes)
);
create index opening_hours_restaurant_idx on public.opening_hours (restaurant_id, weekday);

-- Holidays (closed) and special hours for one date.
create table public.special_days (
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  day           date not null,
  closed        boolean not null default true,
  opens         time,
  closes        time,
  note          text not null default '' check (char_length(note) <= 80),
  primary key (restaurant_id, day),
  check (closed or (opens is not null and closes is not null and opens <> closes))
);

alter table public.opening_hours enable row level security;
alter table public.special_days enable row level security;
revoke all on public.opening_hours, public.special_days from anon, authenticated;
grant select on public.opening_hours, public.special_days to anon, authenticated;
create policy "opening_hours: public read of active restaurants" on public.opening_hours
  for select to anon, authenticated
  using (exists (select 1 from public.restaurants r
                  where r.id = restaurant_id and r.is_active));
create policy "opening_hours: members read own" on public.opening_hours
  for select to authenticated
  using (public.has_restaurant_role(restaurant_id, 'staff'));
create policy "special_days: public read of active restaurants" on public.special_days
  for select to anon, authenticated
  using (exists (select 1 from public.restaurants r
                  where r.id = restaurant_id and r.is_active));
create policy "special_days: members read own" on public.special_days
  for select to authenticated
  using (public.has_restaurant_role(restaurant_id, 'staff'));

-- Slots of one date: the special day if there is one, else the weekly hours.
create or replace function public.day_slots(rid uuid, d date)
returns table (opens time, closes time)
language sql stable security definer set search_path = '' as $$
  select s.opens, s.closes from public.special_days s
   where s.restaurant_id = rid and s.day = d and not s.closed
  union all
  select h.opens, h.closes from public.opening_hours h
   where h.restaurant_id = rid
     and h.weekday = (extract(dow from d)::int + 1) % 7
     and not exists (select 1 from public.special_days s
                      where s.restaurant_id = rid and s.day = d);
$$;

-- Within the restaurant's hours at [ts] (ignores the on / off switch).
create or replace function public.hours_open_at(rid uuid, ts timestamptz)
returns boolean language plpgsql stable security definer set search_path = '' as $$
declare
  local timestamp := ts at time zone 'Africa/Algiers';
  d date := local::date;
  t time := local::time;
begin
  if not exists (select 1 from public.opening_hours where restaurant_id = rid)
     and not exists (select 1 from public.special_days
                      where restaurant_id = rid and day = d) then
    return true;  -- no weekly hours: always, unless today is special
  end if;
  return exists (select 1 from public.day_slots(rid, d) s
                  where (s.opens < s.closes and t >= s.opens and t < s.closes)
                     or (s.opens > s.closes and t >= s.opens))
      or exists (select 1 from public.day_slots(rid, d - 1) s
                  where s.opens > s.closes and t < s.closes);
end $$;
grant execute on function public.hours_open_at(uuid, timestamptz) to anon, authenticated;

-- Taking orders right now (switch on and within hours). Takes the whole
-- row, so only definer functions use it (clients can't read every column).
create or replace function public.open_now(r public.restaurants)
returns boolean language sql stable set search_path = '' as $$
  select r.is_open and public.hours_open_at(r.id, now());
$$;
revoke all on function public.open_now(public.restaurants) from public, anon, authenticated;

-- When a closed restaurant opens next (null: open now, switched off, or
-- nothing in the next 7 days).
create or replace function public.next_open_at(r public.restaurants)
returns timestamptz language plpgsql stable set search_path = '' as $$
declare
  today date := (now() at time zone 'Africa/Algiers')::date;
  weekly boolean;
  d date;
  s record;
  cand timestamptz;
begin
  if not r.is_open or public.hours_open_at(r.id, now()) then
    return null;
  end if;
  weekly := exists (select 1 from public.opening_hours where restaurant_id = r.id);
  for i in 0..7 loop
    d := today + i;
    if not weekly and not exists (select 1 from public.special_days
                                   where restaurant_id = r.id and day = d) then
      cand := d::timestamp at time zone 'Africa/Algiers';
      if cand > now() then return cand; end if;
    end if;
    for s in select * from public.day_slots(r.id, d) order by 1 loop
      cand := (d + s.opens) at time zone 'Africa/Algiers';
      if cand > now() then return cand; end if;
    end loop;
  end loop;
  return null;
end $$;
revoke all on function public.next_open_at(public.restaurants) from public, anon, authenticated;

-- For the restaurant page: open now, and when it opens next.
create or replace function public.restaurant_status(p_id uuid)
returns table (open_now boolean, next_open_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select public.open_now(r), public.next_open_at(r)
    from public.restaurants r
   where r.id = p_id and r.is_active;
$$;
grant execute on function public.restaurant_status(uuid) to anon, authenticated;

-- The outlet's hours for the portal.
create or replace function public.owner_hours(p_restaurant_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  r public.restaurants;
begin
  if not public.has_restaurant_role(p_restaurant_id, 'staff') then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  select * into r from public.restaurants where id = p_restaurant_id;
  return jsonb_build_object(
    'hours', coalesce((select jsonb_agg(jsonb_build_object(
                'weekday', h.weekday,
                'opens', to_char(h.opens, 'HH24:MI'),
                'closes', to_char(h.closes, 'HH24:MI'))
              order by h.weekday, h.opens)
              from public.opening_hours h where h.restaurant_id = p_restaurant_id), '[]'),
    'special', coalesce((select jsonb_agg(jsonb_build_object(
                'day', s.day, 'closed', s.closed,
                'opens', to_char(s.opens, 'HH24:MI'),
                'closes', to_char(s.closes, 'HH24:MI'),
                'note', s.note)
              order by s.day)
              from public.special_days s
             where s.restaurant_id = p_restaurant_id
               and s.day >= (now() at time zone 'Africa/Algiers')::date - 1), '[]'),
    'switch_on', r.is_open,
    'open_now', public.open_now(r),
    'next_open_at', public.next_open_at(r));
end $$;
revoke all on function public.owner_hours(uuid) from public, anon;
grant execute on function public.owner_hours(uuid) to authenticated;

-- Replaces the weekly hours. p_hours: [{"weekday":0,"opens":"11:00","closes":"23:00"}]
-- (up to 3 slots a day; [] = no weekly hours). Errors: not_allowed, invalid_hours
create or replace function public.owner_set_hours(p_restaurant_id uuid, p_hours jsonb)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  if not public.has_restaurant_role(p_restaurant_id, 'manager') then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if jsonb_typeof(p_hours) is distinct from 'array'
     or jsonb_array_length(p_hours) > 21
     or exists (select 1 from jsonb_array_elements(p_hours) e
                 where coalesce(e->>'weekday', '') !~ '^[0-6]$'
                    or coalesce(e->>'opens', '') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
                    or coalesce(e->>'closes', '') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
                    or e->>'opens' = e->>'closes')
     or exists (select 1 from jsonb_array_elements(p_hours) e
                 group by e->>'weekday' having count(*) > 3) then
    raise exception 'invalid_hours' using errcode = '22023';
  end if;
  delete from public.opening_hours where restaurant_id = p_restaurant_id;
  insert into public.opening_hours (restaurant_id, weekday, opens, closes)
  select p_restaurant_id, (e->>'weekday')::smallint, (e->>'opens')::time, (e->>'closes')::time
    from jsonb_array_elements(p_hours) e;
end $$;
revoke all on function public.owner_set_hours(uuid, jsonb) from public, anon;
grant execute on function public.owner_set_hours(uuid, jsonb) to authenticated;

-- Adds or replaces a holiday / special-hours date (today .. one year).
-- Errors: not_allowed, invalid_day
create or replace function public.owner_set_special_day(
  p_restaurant_id uuid,
  p_day    date,
  p_closed boolean,
  p_opens  time default null,
  p_closes time default null,
  p_note   text default ''
)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  today date := (now() at time zone 'Africa/Algiers')::date;
begin
  if not public.has_restaurant_role(p_restaurant_id, 'manager') then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_day is null or p_day < today or p_day > today + 366
     or char_length(coalesce(p_note, '')) > 80
     or (not coalesce(p_closed, true)
         and (p_opens is null or p_closes is null or p_opens = p_closes)) then
    raise exception 'invalid_day' using errcode = '22023';
  end if;
  insert into public.special_days (restaurant_id, day, closed, opens, closes, note)
  values (p_restaurant_id, p_day, coalesce(p_closed, true),
          case when p_closed then null else p_opens end,
          case when p_closed then null else p_closes end,
          btrim(coalesce(p_note, '')))
  on conflict (restaurant_id, day) do update
     set closed = excluded.closed, opens = excluded.opens,
         closes = excluded.closes, note = excluded.note;
end $$;
revoke all on function public.owner_set_special_day(uuid, date, boolean, time, time, text) from public, anon;
grant execute on function public.owner_set_special_day(uuid, date, boolean, time, time, text) to authenticated;

create or replace function public.owner_delete_special_day(p_restaurant_id uuid, p_day date)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  if not public.has_restaurant_role(p_restaurant_id, 'manager') then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  delete from public.special_days where restaurant_id = p_restaurant_id and day = p_day;
end $$;
revoke all on function public.owner_delete_special_day(uuid, date) from public, anon;
grant execute on function public.owner_delete_special_day(uuid, date) to authenticated;

-- ---------- customers: restaurant cards follow the hours -------------------------
-- is_open now means "taking orders now"; next_open_at for "Opens at 18:00".
drop function if exists public.list_restaurants(text);
create function public.list_restaurants(p_category_slug text default null)
returns table (
  id uuid, slug text, name text, description text, area text,
  lat double precision, lng double precision, cover_url text, logo_url text,
  prep_minutes integer, is_open boolean,
  category_slugs text[], min_price integer, next_open_at timestamptz
)
-- Definer: the hours functions need the whole restaurant row. Only active
-- restaurants and public columns are returned.
language sql stable security definer set search_path = '' as $$
  select r.id, r.slug, r.name, r.description, r.area, r.lat, r.lng,
         r.cover_url, r.logo_url, r.prep_minutes, public.open_now(r),
         coalesce(array_agg(distinct c.slug) filter (where c.slug is not null), '{}'),
         min(m.price) filter (where m.is_available),
         public.next_open_at(r)
    from public.restaurants r
    left join public.menu_items m on m.restaurant_id = r.id
    left join public.categories c on c.id = m.category_id
   where r.is_active
   group by r.id
  having p_category_slug is null
      or bool_or(c.slug = p_category_slug)
   order by public.open_now(r) desc, r.name;
$$;
grant execute on function public.list_restaurants(text) to anon, authenticated;

-- Outlets for the team, with the hours status.
drop function if exists public.my_restaurant();
drop function if exists public.my_restaurants();
create function public.my_restaurants()
returns table (
  id uuid, slug text, name text, description text, phone text,
  address text, area text, lat double precision, lng double precision,
  cover_url text, logo_url text, prep_minutes integer,
  is_active boolean, is_open boolean, created_at timestamptz,
  my_role text, open_now boolean, next_open_at timestamptz
)
language sql stable security definer set search_path = '' as $$
  select r.id, r.slug, r.name, r.description, r.phone, r.address, r.area,
         r.lat, r.lng, r.cover_url, r.logo_url, r.prep_minutes,
         r.is_active, r.is_open, r.created_at, m.role,
         public.open_now(r), public.next_open_at(r)
    from public.restaurant_members m
    join public.restaurants r on r.id = m.restaurant_id
   where m.user_id = auth.uid() and r.deleted_at is null
   order by r.created_at, r.name;
$$;
revoke all on function public.my_restaurants() from public, anon;
grant execute on function public.my_restaurants() to authenticated;

create function public.my_restaurant()
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
revoke all on function public.my_restaurant() from public, anon;
grant execute on function public.my_restaurant() to authenticated;

-- ---------- place_order with options and hours -----------------------------------
-- p_items: [{"id": "<dish>", "qty": 2, "options": ["<choice>", ...]}, ...]
-- New error: options_invalid (a choice is gone / unavailable, or a group's
-- rule isn't met). restaurant_closed now also covers "outside the hours".
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
  v_order    uuid;
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
      select o.id, o.code, o.food_total, o.delivery_fee, o.total
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
    select o.id, o.code, o.food_total, o.delivery_fee, o.total
      from public.orders o where o.id = v_order;
end $$;

commit;
