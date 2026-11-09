-- =====================================================================
-- Restaurant owners: self-registration (inactive until the admin
-- approves), editing their restaurant, menu management, photos.
-- =====================================================================

-- ---------- slug helper ----------------------------------------------
-- "Pizzeria El Bahdja" -> "pizzeria-el-bahdja" (ASCII only; Arabic names
-- fall back to "restaurant"). A number is added if the slug is taken.
create or replace function public.make_restaurant_slug(p_name text)
returns text language plpgsql set search_path = '' as $$
declare
  base text;
  candidate text;
  n int := 1;
begin
  base := lower(p_name);
  base := translate(base,
    'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ',
    'aaaaaaceeeeiiiinooooouuuuyy');
  base := regexp_replace(base, '[^a-z0-9]+', '-', 'g');
  base := trim(both '-' from base);
  base := left(base, 34);
  base := trim(both '-' from base);
  if char_length(base) < 3 then
    base := 'restaurant';
  end if;
  candidate := base;
  while exists (select 1 from public.restaurants where slug = candidate) loop
    n := n + 1;
    candidate := base || '-' || n;
  end loop;
  return candidate;
end $$;
revoke all on function public.make_restaurant_slug(text) from public, anon, authenticated;

-- ---------- registration ---------------------------------------------
-- Called by a signed-in account that has no restaurant yet. Makes the
-- account a restaurant owner and creates an INACTIVE, closed restaurant.
-- Customers can't see it until the admin sets is_active = true.
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
  if v_role <> 'customer' then
    raise exception 'account already has a role' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.restaurants where owner_id = uid) then
    raise exception 'restaurant already registered' using errcode = 'P0001';
  end if;

  -- Input checks (table constraints check them again).
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

  update public.profiles set role = 'restaurant' where id = uid;
  return new_id;
end $$;
revoke all on function public.register_restaurant(text, text, text, text, double precision, double precision, integer) from public, anon;
grant execute on function public.register_restaurant(text, text, text, text, double precision, double precision, integer) to authenticated;

-- ---------- the owner's own restaurant --------------------------------
-- owner_id isn't readable by clients (column grants), so the dashboard
-- loads its restaurant through this function. Includes is_active so the
-- owner sees "waiting for approval".
create or replace function public.my_restaurant()
returns table (
  id uuid, slug text, name text, description text, phone text,
  address text, area text, lat double precision, lng double precision,
  cover_url text, logo_url text, prep_minutes integer,
  is_active boolean, is_open boolean, created_at timestamptz
)
language sql stable security definer set search_path = '' as $$
  select r.id, r.slug, r.name, r.description, r.phone, r.address, r.area,
         r.lat, r.lng, r.cover_url, r.logo_url, r.prep_minutes,
         r.is_active, r.is_open, r.created_at
    from public.restaurants r
   where r.owner_id = auth.uid();
$$;
revoke all on function public.my_restaurant() from public, anon;
grant execute on function public.my_restaurant() to authenticated;

-- Owners can read their own row even before approval. Needed for UPDATE
-- too: Postgres only updates rows the user is allowed to SELECT.
create policy "restaurants: owner reads own" on public.restaurants
  for select to authenticated
  using (owner_id = (select auth.uid()));

-- Owners can update their restaurant's public details and open/closed,
-- never is_active, owner_id, slug or commission.
create policy "restaurants: owner updates own" on public.restaurants
  for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
grant update (name, description, phone, address, area, lat, lng,
              cover_url, logo_url, prep_minutes, is_open)
  on public.restaurants to authenticated;

-- ---------- menu management --------------------------------------------
-- True when the signed-in user owns restaurant [rid].
create or replace function public.owns_restaurant(rid uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.restaurants
                  where id = rid and owner_id = auth.uid());
$$;
revoke all on function public.owns_restaurant(uuid) from public, anon;
grant execute on function public.owns_restaurant(uuid) to authenticated;

-- Owners see all their dishes, even while the restaurant is inactive.
create policy "menu_items: owner reads own" on public.menu_items
  for select to authenticated
  using (public.owns_restaurant(restaurant_id));

create policy "menu_items: owner inserts own" on public.menu_items
  for insert to authenticated
  with check (public.owns_restaurant(restaurant_id));

create policy "menu_items: owner updates own" on public.menu_items
  for update to authenticated
  using (public.owns_restaurant(restaurant_id))
  with check (public.owns_restaurant(restaurant_id));

create policy "menu_items: owner deletes own" on public.menu_items
  for delete to authenticated
  using (public.owns_restaurant(restaurant_id));

grant insert (restaurant_id, category_id, name, description, price,
              photo_url, is_available, sort_order)
  on public.menu_items to authenticated;
grant update (category_id, name, description, price, photo_url,
              is_available, sort_order)
  on public.menu_items to authenticated;
grant delete on public.menu_items to authenticated;

-- Max 200 dishes per restaurant.
create or replace function public.menu_items_limit()
returns trigger language plpgsql set search_path = '' as $$
begin
  if (select count(*) from public.menu_items
       where restaurant_id = new.restaurant_id) >= 200 then
    raise exception 'menu limit reached' using errcode = 'P0001';
  end if;
  return new;
end $$;
create trigger menu_items_limit before insert on public.menu_items
  for each row execute function public.menu_items_limit();

-- ---------- storage: restaurant photos ---------------------------------
-- Path: restaurant-media/<restaurant id>/<file>
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('restaurant-media', 'restaurant-media', true, 3145728,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "restaurant-media: owner uploads"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'restaurant-media'
              and public.owns_restaurant(((storage.foldername(name))[1])::uuid));
create policy "restaurant-media: owner updates"
  on storage.objects for update to authenticated
  using (bucket_id = 'restaurant-media'
         and public.owns_restaurant(((storage.foldername(name))[1])::uuid));
create policy "restaurant-media: owner deletes"
  on storage.objects for delete to authenticated
  using (bucket_id = 'restaurant-media'
         and public.owns_restaurant(((storage.foldername(name))[1])::uuid));
