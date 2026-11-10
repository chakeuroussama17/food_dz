-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261115000001_banners.sql
begin;

-- =====================================================================
-- Home banners (ads and news): pictures the admin adds, shown in the
-- carousel at the top of the customer home. Optionally open a restaurant.
-- =====================================================================

create table public.banners (
  id            uuid primary key default gen_random_uuid(),
  image_url     text not null check (char_length(image_url) between 10 and 500),
  title         text not null default '' check (char_length(title) <= 80),
  restaurant_id uuid references public.restaurants (id) on delete set null,
  sort_order    integer not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);
create index banners_order_idx on public.banners (sort_order, created_at);
alter table public.banners enable row level security;
revoke all on public.banners from anon, authenticated;
grant select on public.banners to anon, authenticated;

-- Everybody sees the active banners; the admin sees all of them.
create policy "banners: active are public" on public.banners
  for select to anon, authenticated using (is_active);
create policy "banners: admin reads all" on public.banners
  for select to authenticated using (public.is_admin());

-- Customer home: active banners in order, with the restaurant to open.
create or replace function public.home_banners()
returns table (id uuid, image_url text, title text, restaurant_slug text)
language sql stable security definer set search_path = '' as $$
  select b.id, b.image_url, b.title,
         case when r.is_active then r.slug end
    from public.banners b
    left join public.restaurants r on r.id = b.restaurant_id
   where b.is_active
   order by b.sort_order, b.created_at
   limit 10;
$$;
grant execute on function public.home_banners() to anon, authenticated;

-- ---------- admin --------------------------------------------------------
create or replace function public.admin_list_banners()
returns table (id uuid, image_url text, title text, restaurant_id uuid,
               restaurant_name text, sort_order integer, is_active boolean,
               created_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select b.id, b.image_url, b.title, b.restaurant_id, r.name,
         b.sort_order, b.is_active, b.created_at
    from public.banners b
    left join public.restaurants r on r.id = b.restaurant_id
   order by b.sort_order, b.created_at;
end $$;
revoke all on function public.admin_list_banners() from public, anon;
grant execute on function public.admin_list_banners() to authenticated;

-- Adds a banner at the end. Errors: invalid image
create or replace function public.admin_add_banner(
  p_image_url text, p_title text default '', p_restaurant_id uuid default null)
returns uuid language plpgsql volatile security definer set search_path = '' as $$
declare
  new_id uuid;
begin
  perform public.assert_admin();
  if coalesce(p_image_url, '') !~ '^https://' then
    raise exception 'invalid image' using errcode = '22023';
  end if;
  insert into public.banners (image_url, title, restaurant_id, sort_order)
  values (p_image_url, left(btrim(coalesce(p_title, '')), 80), p_restaurant_id,
          coalesce((select max(sort_order) + 1 from public.banners), 0))
  returning id into new_id;
  return new_id;
end $$;
revoke all on function public.admin_add_banner(text, text, uuid) from public, anon;
grant execute on function public.admin_add_banner(text, text, uuid) to authenticated;

create or replace function public.admin_update_banner(
  p_id uuid, p_title text, p_restaurant_id uuid, p_is_active boolean)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  update public.banners
     set title = left(btrim(coalesce(p_title, '')), 80),
         restaurant_id = p_restaurant_id,
         is_active = coalesce(p_is_active, true)
   where id = p_id;
  if not found then raise exception 'banner not found' using errcode = 'P0002'; end if;
end $$;
revoke all on function public.admin_update_banner(uuid, text, uuid, boolean) from public, anon;
grant execute on function public.admin_update_banner(uuid, text, uuid, boolean) to authenticated;

-- Moves a banner one place up (-1) or down (+1).
create or replace function public.admin_move_banner(p_id uuid, p_delta integer)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  ids uuid[];
  i integer;
  j integer;
begin
  perform public.assert_admin();
  select array_agg(b.id order by b.sort_order, b.created_at) into ids from public.banners b;
  i := array_position(ids, p_id);
  if i is null then raise exception 'banner not found' using errcode = 'P0002'; end if;
  j := i + sign(coalesce(p_delta, 0))::int;
  if j < 1 or j > array_length(ids, 1) then return; end if;
  ids[i] := ids[j];
  ids[j] := p_id;
  update public.banners b set sort_order = x.pos
    from unnest(ids) with ordinality as x(id, pos)
   where b.id = x.id;
end $$;
revoke all on function public.admin_move_banner(uuid, integer) from public, anon;
grant execute on function public.admin_move_banner(uuid, integer) to authenticated;

create or replace function public.admin_delete_banner(p_id uuid)
returns text language plpgsql volatile security definer set search_path = '' as $$
declare
  url text;
begin
  perform public.assert_admin();
  delete from public.banners where id = p_id returning image_url into url;
  if url is null then raise exception 'banner not found' using errcode = 'P0002'; end if;
  return url; -- the app removes the picture file
end $$;
revoke all on function public.admin_delete_banner(uuid) from public, anon;
grant execute on function public.admin_delete_banner(uuid) to authenticated;

-- ---------- storage: banners/<file> (public pictures, admin writes) -------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('banners', 'banners', true, 3145728,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "banners: admin uploads" on storage.objects
  for insert to authenticated with check (bucket_id = 'banners' and public.is_admin());
create policy "banners: admin reads" on storage.objects
  for select to authenticated using (bucket_id = 'banners' and public.is_admin());
create policy "banners: admin deletes" on storage.objects
  for delete to authenticated using (bucket_id = 'banners' and public.is_admin());

commit;
