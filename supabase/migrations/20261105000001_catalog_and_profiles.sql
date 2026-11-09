-- =====================================================================
-- Customers' profiles & addresses, and the public catalogue
-- (categories, restaurants, menu items). Orders come in a later step.
-- Every table has RLS on. Anonymous visitors can only read the catalogue.
-- =====================================================================

-- ---------- roles & profiles -----------------------------------------
create type public.app_role as enum ('customer', 'restaurant', 'driver', 'admin');

create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  role        public.app_role not null default 'customer',
  full_name   text not null default ''
              check (char_length(full_name) <= 80),
  -- Algerian mobile, local form 05/06/07 + 8 digits
  phone       text check (phone ~ '^0[567][0-9]{8}$'),
  avatar_url  text check (char_length(avatar_url) <= 500),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
alter table public.profiles enable row level security;

create policy "profiles: read own"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

create policy "profiles: update own"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Users may only change these columns (never role).
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, phone, avatar_url) on public.profiles to authenticated;

create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

-- A profile row is created for every new auth user.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    left(coalesce(trim(new.raw_user_meta_data ->> 'full_name'), ''), 80)
  )
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Back-fill users created before this migration.
insert into public.profiles (id, full_name)
select u.id, left(coalesce(trim(u.raw_user_meta_data ->> 'full_name'), ''), 80)
from auth.users u
on conflict (id) do nothing;

-- ---------- delivery addresses ---------------------------------------
create table public.addresses (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid()
               references public.profiles (id) on delete cascade,
  label        text not null default 'home'
               check (label in ('home', 'work', 'other')),
  address_text text not null check (char_length(address_text) between 3 and 200),
  area         text not null default '' check (char_length(area) <= 80),
  details      text not null default '' check (char_length(details) <= 120),
  lat          double precision check (lat between -90 and 90),
  lng          double precision check (lng between -180 and 180),
  is_default   boolean not null default false,
  created_at   timestamptz not null default now()
);
create index addresses_user_idx on public.addresses (user_id);
-- At most one default address per user.
create unique index addresses_one_default
  on public.addresses (user_id) where is_default;

alter table public.addresses enable row level security;

create policy "addresses: own rows"
  on public.addresses for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.addresses from anon, authenticated;
grant select, insert, update, delete on public.addresses to authenticated;

-- Max 10 addresses per user.
create or replace function public.addresses_limit()
returns trigger language plpgsql set search_path = '' as $$
begin
  if (select count(*) from public.addresses where user_id = new.user_id) >= 10 then
    raise exception 'address limit reached' using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger addresses_limit before insert on public.addresses
  for each row execute function public.addresses_limit();

-- Makes one address the default and clears the others, atomically.
create or replace function public.set_default_address(p_address_id uuid)
returns void language plpgsql security invoker set search_path = '' as $$
begin
  update public.addresses set is_default = false
   where user_id = (select auth.uid()) and is_default and id <> p_address_id;
  update public.addresses set is_default = true
   where user_id = (select auth.uid()) and id = p_address_id;
  if not found then
    raise exception 'address not found' using errcode = 'P0002';
  end if;
end $$;
revoke all on function public.set_default_address(uuid) from public, anon;
grant execute on function public.set_default_address(uuid) to authenticated;

-- ---------- app config (single row) ----------------------------------
create table public.app_config (
  id                      boolean primary key default true check (id),
  delivery_fee            integer not null default 200 check (delivery_fee between 0 and 5000),
  default_commission_rate numeric(5,4) not null default 0.08
                          check (default_commission_rate between 0 and 0.5),
  handover_grace_hours    integer not null default 24,
  max_active_jobs_per_driver integer not null default 2
);
insert into public.app_config default values;
alter table public.app_config enable row level security;

create policy "app_config: public read" on public.app_config
  for select to anon, authenticated using (true);
revoke all on public.app_config from anon, authenticated;
-- Only the fee is public; commission settings stay private.
grant select (id, delivery_fee) on public.app_config to anon, authenticated;

-- ---------- catalogue -------------------------------------------------
create table public.categories (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null check (slug ~ '^[a-z0-9-]{2,40}$'),
  name_ar     text not null check (char_length(name_ar) between 1 and 40),
  name_fr     text not null check (char_length(name_fr) between 1 and 40),
  name_en     text not null check (char_length(name_en) between 1 and 40),
  image_url   text,
  sort_order  integer not null default 0,
  is_active   boolean not null default true
);
alter table public.categories enable row level security;
create policy "categories: public read active" on public.categories
  for select to anon, authenticated using (is_active);
revoke all on public.categories from anon, authenticated;
grant select on public.categories to anon, authenticated;

create table public.restaurants (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid unique references public.profiles (id),
  slug            text unique not null check (slug ~ '^[a-z0-9-]{3,40}$'),
  name            text not null check (char_length(name) between 2 and 80),
  description     text not null default '' check (char_length(description) <= 300),
  phone           text check (phone ~ '^0[2-7][0-9]{7,8}$'),
  email           text check (char_length(email) <= 254),
  address         text not null default '' check (char_length(address) <= 200),
  area            text not null default '' check (char_length(area) <= 80),
  lat             double precision check (lat between -90 and 90),
  lng             double precision check (lng between -180 and 180),
  cover_url       text,
  logo_url        text,
  prep_minutes    integer not null default 20 check (prep_minutes between 5 and 120),
  is_active       boolean not null default false,  -- admin switch
  is_open         boolean not null default false,  -- restaurant switch
  commission_rate numeric(5,4) check (commission_rate between 0 and 0.5),
  created_at      timestamptz not null default now()
);
create index restaurants_active_idx on public.restaurants (is_active, is_open);
alter table public.restaurants enable row level security;

create policy "restaurants: public read active" on public.restaurants
  for select to anon, authenticated using (is_active);

revoke all on public.restaurants from anon, authenticated;
-- Public columns only: no owner, email or commission.
grant select (id, slug, name, description, phone, address, area, lat, lng,
              cover_url, logo_url, prep_minutes, is_active, is_open, created_at)
  on public.restaurants to anon, authenticated;

create table public.menu_items (
  id            uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  category_id   uuid references public.categories (id) on delete set null,
  name          text not null check (char_length(name) between 1 and 80),
  description   text not null default '' check (char_length(description) <= 300),
  price         integer not null check (price between 10 and 100000),  -- DZD
  photo_url     text,
  is_available  boolean not null default true,
  sort_order    integer not null default 0,
  created_at    timestamptz not null default now()
);
create index menu_items_restaurant_idx on public.menu_items (restaurant_id, sort_order);
create index menu_items_category_idx on public.menu_items (category_id);
alter table public.menu_items enable row level security;

create policy "menu_items: public read of active restaurants" on public.menu_items
  for select to anon, authenticated
  using (exists (select 1 from public.restaurants r
                 where r.id = restaurant_id and r.is_active));
revoke all on public.menu_items from anon, authenticated;
grant select on public.menu_items to anon, authenticated;

-- ---------- read helpers (run with the caller's rights, so RLS applies) --
-- Restaurant cards for the home / category pages.
create or replace function public.list_restaurants(p_category_slug text default null)
returns table (
  id uuid, slug text, name text, description text, area text,
  lat double precision, lng double precision, cover_url text, logo_url text,
  prep_minutes integer, is_open boolean,
  category_slugs text[], min_price integer
)
language sql stable security invoker set search_path = '' as $$
  select r.id, r.slug, r.name, r.description, r.area, r.lat, r.lng,
         r.cover_url, r.logo_url, r.prep_minutes, r.is_open,
         coalesce(array_agg(distinct c.slug) filter (where c.slug is not null), '{}'),
         min(m.price) filter (where m.is_available)
    from public.restaurants r
    left join public.menu_items m on m.restaurant_id = r.id
    left join public.categories c on c.id = m.category_id
   where r.is_active
   group by r.id
  having p_category_slug is null
      or bool_or(c.slug = p_category_slug)
   order by r.is_open desc, r.name;
$$;
grant execute on function public.list_restaurants(text) to anon, authenticated;

-- Simple search over restaurant names and dishes (max 30 rows each).
create or replace function public.search_catalog(p_query text)
returns table (kind text, id uuid, restaurant_id uuid, restaurant_slug text,
               title text, subtitle text, image_url text, price integer)
language sql stable security invoker set search_path = '' as $$
  with q as (
    select '%' || replace(replace(trim(left(p_query, 60)), '%', ''), '_', '') || '%' as pat
  )
  (select 'restaurant', r.id, r.id, r.slug, r.name, r.area, r.cover_url, null::integer
     from public.restaurants r, q
    where r.is_active and char_length(q.pat) > 3 and r.name ilike q.pat
    order by r.name limit 30)
  union all
  (select 'item', m.id, r.id, r.slug, m.name, r.name, m.photo_url, m.price
     from public.menu_items m
     join public.restaurants r on r.id = m.restaurant_id, q
    where r.is_active and char_length(q.pat) > 3
      and (m.name ilike q.pat or m.description ilike q.pat)
    order by m.name limit 30);
$$;
grant execute on function public.search_catalog(text) to anon, authenticated;

-- ---------- storage: profile photos ----------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- Files live under avatars/<user id>/...
create policy "avatars: owner can upload"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars: owner can update"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars: owner can delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text);
