-- =====================================================================
-- Ratings.
--   * After a delivered order the customer rates the FOOD (restaurant,
--     public) and the DELIVERY (driver, private) separately, each with
--     1-5 stars, quick reasons and an optional comment.
--     Both: within 7 days of the delivery; editable 24 h after rating.
--   * The restaurant can reply once (public) and flag a review; the admin
--     decides (hide / keep). Hidden reviews count nowhere.
--   * Restaurants and drivers can report a customer (private, admin only);
--     the admin can warn or block the customer.
--   * A reminder push is sent ~40 minutes after a delivery.
-- Nothing here is readable directly: everything goes through functions.
-- =====================================================================

-- ---------- ratings ----------------------------------------------------------
create table public.order_ratings (
  order_id        uuid primary key references public.orders (id) on delete cascade,
  restaurant_id   uuid not null references public.restaurants (id),
  driver_id       uuid references public.profiles (id) on delete set null,
  customer_id     uuid references public.profiles (id) on delete set null,
  -- "Amina B." shown on public reviews; kept even if the account goes.
  customer_label  text not null default 'Client' check (char_length(customer_label) <= 40),
  -- food
  food_stars      smallint check (food_stars between 1 and 5),
  food_reasons    text[] not null default '{}',
  food_comment    text not null default '' check (char_length(food_comment) <= 300),
  food_rated_at   timestamptz,
  -- delivery
  driver_stars    smallint check (driver_stars between 1 and 5),
  driver_reasons  text[] not null default '{}',
  driver_comment  text not null default '' check (char_length(driver_comment) <= 300),
  driver_rated_at timestamptz,
  -- the restaurant's public reply (once)
  reply           text check (char_length(reply) between 1 and 300),
  reply_at        timestamptz,
  -- moderation
  flagged_at      timestamptz,
  flag_reason     text check (char_length(flag_reason) <= 200),
  flag_decision   text check (flag_decision in ('hidden', 'kept')),
  hidden          boolean not null default false,
  created_at      timestamptz not null default now()
);
create index order_ratings_restaurant_idx
  on public.order_ratings (restaurant_id, food_rated_at desc) where food_stars is not null;
create index order_ratings_driver_idx
  on public.order_ratings (driver_id, driver_rated_at desc) where driver_stars is not null;
alter table public.order_ratings enable row level security;
revoke all on public.order_ratings from anon, authenticated;

-- A deleted account stops being named on its reviews.
create or replace function public.order_ratings_anonymise()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.customer_id is null and old.customer_id is not null then
    new.customer_label := 'Client';
  end if;
  return new;
end $$;
create trigger order_ratings_anonymise before update of customer_id
  on public.order_ratings for each row execute function public.order_ratings_anonymise();

create or replace function public.rating_reasons_ok(p_part text, p_reasons text[])
returns boolean language sql immutable set search_path = '' as $$
  select coalesce(cardinality(p_reasons), 0) <= 5
     and not exists (
       select 1 from unnest(coalesce(p_reasons, '{}')) r(x)
        where x <> all (case p_part
          when 'food' then array['cold', 'missing_item', 'wrong_order',
                                 'small_portion', 'bad_taste', 'bad_packaging']
          else array['late', 'rude', 'careless', 'no_contact', 'wrong_place'] end));
$$;

-- ---------- customer: rate -----------------------------------------------------
-- p_part: 'food' | 'driver'. Errors: not_signed_in, invalid_part,
-- invalid_stars, invalid_reasons, invalid_comment, order_not_found,
-- not_delivered, window_closed, no_driver, rating_locked
create or replace function public.rate_order(
  p_order_id uuid,
  p_part     text,
  p_stars    integer,
  p_reasons  text[] default '{}',
  p_comment  text default ''
)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid       uuid := auth.uid();
  o         record;
  r         public.order_ratings;
  v_comment text := btrim(coalesce(p_comment, ''));
  v_name    text;
  v_label   text;
  v_reasons text[] := coalesce(p_reasons, '{}');
begin
  if uid is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  if p_part not in ('food', 'driver') then
    raise exception 'invalid_part' using errcode = '22023';
  end if;
  if p_stars is null or p_stars not between 1 and 5 then
    raise exception 'invalid_stars' using errcode = '22023';
  end if;
  if not public.rating_reasons_ok(p_part, v_reasons) then
    raise exception 'invalid_reasons' using errcode = '22023';
  end if;
  if char_length(v_comment) > 300 then
    raise exception 'invalid_comment' using errcode = '22023';
  end if;

  select x.id, x.status, x.delivered_at, x.restaurant_id, x.driver_id into o
    from public.orders x where x.id = p_order_id and x.customer_id = uid;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
  if o.status <> 'delivered' then
    raise exception 'not_delivered' using errcode = 'P0001';
  end if;
  if o.delivered_at < now() - interval '7 days' then
    raise exception 'window_closed' using errcode = 'P0001';
  end if;
  if p_part = 'driver' and o.driver_id is null then
    raise exception 'no_driver' using errcode = 'P0001';
  end if;

  select btrim(coalesce(full_name, '')) into v_name from public.profiles where id = uid;
  v_label := case
    when v_name = '' then 'Client'
    when position(' ' in v_name) > 0 then
      left(split_part(v_name, ' ', 1), 30) || ' '
      || upper(left(btrim(substr(v_name, position(' ' in v_name))), 1)) || '.'
    else left(v_name, 30) end;

  insert into public.order_ratings (order_id, restaurant_id, driver_id, customer_id, customer_label)
  values (p_order_id, o.restaurant_id, o.driver_id, uid, v_label)
  on conflict (order_id) do nothing;

  select * into r from public.order_ratings where order_id = p_order_id for update;
  if (p_part = 'food' and r.food_rated_at < now() - interval '24 hours')
     or (p_part = 'driver' and r.driver_rated_at < now() - interval '24 hours') then
    raise exception 'rating_locked' using errcode = 'P0001';
  end if;

  -- Reasons only make sense for a poor rating.
  if p_stars > 3 then v_reasons := '{}'; end if;

  if p_part = 'food' then
    update public.order_ratings
       set food_stars = p_stars, food_reasons = v_reasons, food_comment = v_comment,
           food_rated_at = coalesce(food_rated_at, now())
     where order_id = p_order_id;
  else
    update public.order_ratings
       set driver_stars = p_stars, driver_reasons = v_reasons, driver_comment = v_comment,
           driver_rated_at = coalesce(driver_rated_at, now())
     where order_id = p_order_id;
  end if;
end $$;
revoke all on function public.rate_order(uuid, text, integer, text[], text) from public, anon;
grant execute on function public.rate_order(uuid, text, integer, text[], text) to authenticated;

-- My delivered orders (last 30 days, or one order) with what I rated.
create or replace function public.my_order_ratings(p_order_id uuid default null)
returns table (
  order_id uuid, delivered_at timestamptz, has_driver boolean,
  food_stars integer, food_reasons text[], food_comment text, food_rated_at timestamptz,
  driver_stars integer, driver_reasons text[], driver_comment text, driver_rated_at timestamptz,
  reply text, reply_at timestamptz
)
language sql stable security definer set search_path = '' as $$
  select o.id, o.delivered_at, o.driver_id is not null,
         r.food_stars::int, coalesce(r.food_reasons, '{}'), coalesce(r.food_comment, ''), r.food_rated_at,
         r.driver_stars::int, coalesce(r.driver_reasons, '{}'), coalesce(r.driver_comment, ''), r.driver_rated_at,
         r.reply, r.reply_at
    from public.orders o
    left join public.order_ratings r on r.order_id = o.id
   where o.customer_id = auth.uid() and o.status = 'delivered'
     and (case when p_order_id is not null then o.id = p_order_id
               else o.delivered_at > now() - interval '30 days' end)
   order by o.delivered_at desc
   limit 100;
$$;
revoke all on function public.my_order_ratings(uuid) from public, anon;
grant execute on function public.my_order_ratings(uuid) to authenticated;

-- ---------- public: averages and reviews ---------------------------------------
-- The average is shown from 5 ratings on; before that: null ("New").
create or replace function public.rating_stats(rid uuid)
returns table (rating_avg numeric, rating_count integer)
language sql stable security definer set search_path = '' as $$
  select case when count(*) >= 5 then round(avg(food_stars)::numeric, 1) end,
         count(*)::int
    from public.order_ratings
   where restaurant_id = rid and food_stars is not null and not hidden;
$$;
revoke all on function public.rating_stats(uuid) from public, anon, authenticated;

-- Restaurant cards: + rating.
drop function if exists public.list_restaurants(text);
create function public.list_restaurants(p_category_slug text default null)
returns table (
  id uuid, slug text, name text, description text, area text,
  lat double precision, lng double precision, cover_url text, logo_url text,
  prep_minutes integer, is_open boolean,
  category_slugs text[], min_price integer, next_open_at timestamptz,
  rating_avg numeric, rating_count integer
)
language sql stable security definer set search_path = '' as $$
  select r.id, r.slug, r.name, r.description, r.area, r.lat, r.lng,
         r.cover_url, r.logo_url, r.prep_minutes, public.open_now(r),
         coalesce(array_agg(distinct c.slug) filter (where c.slug is not null), '{}'),
         min(m.price) filter (where m.is_available),
         public.next_open_at(r),
         (select s.rating_avg from public.rating_stats(r.id) s),
         (select s.rating_count from public.rating_stats(r.id) s)
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

-- Restaurant page: open now + rating.
drop function if exists public.restaurant_status(uuid);
create function public.restaurant_status(p_id uuid)
returns table (open_now boolean, next_open_at timestamptz,
               rating_avg numeric, rating_count integer)
language sql stable security definer set search_path = '' as $$
  select public.open_now(r), public.next_open_at(r),
         (select s.rating_avg from public.rating_stats(r.id) s),
         (select s.rating_count from public.rating_stats(r.id) s)
    from public.restaurants r
   where r.id = p_id and r.is_active;
$$;
grant execute on function public.restaurant_status(uuid) to anon, authenticated;

-- Public reviews of a restaurant, newest first.
create or replace function public.restaurant_reviews(
  p_slug text, p_limit integer default 20, p_offset integer default 0)
returns table (
  customer_label text, stars integer, reasons text[], comment text,
  rated_at timestamptz, reply text, reply_at timestamptz
)
language sql stable security definer set search_path = '' as $$
  select x.customer_label, x.food_stars::int, x.food_reasons, x.food_comment,
         x.food_rated_at, x.reply, x.reply_at
    from public.order_ratings x
    join public.restaurants r on r.id = x.restaurant_id
   where r.slug = p_slug and r.is_active
     and x.food_stars is not null and not x.hidden
   order by x.food_rated_at desc
   limit least(greatest(coalesce(p_limit, 20), 1), 50)
  offset greatest(coalesce(p_offset, 0), 0);
$$;
grant execute on function public.restaurant_reviews(text, integer, integer) to anon, authenticated;

-- ---------- restaurant: reviews, reply, flag (managers) ----------------------------
create or replace function public.owner_reviews(
  p_restaurant_ids uuid[] default null,
  p_from timestamptz default null,
  p_to   timestamptz default null
)
returns table (
  order_id uuid, code text, restaurant_id uuid, restaurant_name text,
  customer_label text, stars integer, reasons text[], comment text,
  rated_at timestamptz, reply text, reply_at timestamptz,
  flagged_at timestamptz, flag_decision text,
  items text, total integer
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  return query
  select x.order_id, o.code, r.id, r.name, x.customer_label,
         x.food_stars::int, x.food_reasons, x.food_comment, x.food_rated_at,
         x.reply, x.reply_at, x.flagged_at, x.flag_decision,
         (select string_agg(i.name, ', ' order by i.id)
            from public.order_items i where i.order_id = o.id),
         o.total
    from public.order_ratings x
    join public.orders o on o.id = x.order_id
    join public.restaurants r on r.id = x.restaurant_id
   where public.has_restaurant_role(r.id, 'manager')
     and (p_restaurant_ids is null or r.id = any (p_restaurant_ids))
     and x.food_stars is not null and not x.hidden
     and x.food_rated_at >= coalesce(p_from, now() - interval '400 days')
     and x.food_rated_at <  coalesce(p_to, now() + interval '1 day')
   order by x.food_rated_at desc
   limit 2000;
end $$;
revoke all on function public.owner_reviews(uuid[], timestamptz, timestamptz) from public, anon;
grant execute on function public.owner_reviews(uuid[], timestamptz, timestamptz) to authenticated;

-- One public reply per review. Errors: not_found, already_replied, invalid_reply
create or replace function public.owner_reply_review(p_order_id uuid, p_text text)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_text text := btrim(coalesce(p_text, ''));
  x public.order_ratings;
begin
  select * into x from public.order_ratings
   where order_id = p_order_id and food_stars is not null and not hidden
     and public.has_restaurant_role(restaurant_id, 'manager')
   for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if x.reply is not null then
    raise exception 'already_replied' using errcode = 'P0001';
  end if;
  if char_length(v_text) not between 1 and 300 then
    raise exception 'invalid_reply' using errcode = '22023';
  end if;
  update public.order_ratings set reply = v_text, reply_at = now() where order_id = p_order_id;
end $$;
revoke all on function public.owner_reply_review(uuid, text) from public, anon;
grant execute on function public.owner_reply_review(uuid, text) to authenticated;

-- Ask the admin to look at a review. Errors: not_found, already_flagged, invalid_reason
create or replace function public.owner_flag_review(p_order_id uuid, p_reason text)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_reason text := btrim(coalesce(p_reason, ''));
  x public.order_ratings;
begin
  select * into x from public.order_ratings
   where order_id = p_order_id and food_stars is not null and not hidden
     and public.has_restaurant_role(restaurant_id, 'manager')
   for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if x.flagged_at is not null then
    raise exception 'already_flagged' using errcode = 'P0001';
  end if;
  if char_length(v_reason) not between 3 and 200 then
    raise exception 'invalid_reason' using errcode = '22023';
  end if;
  update public.order_ratings
     set flagged_at = now(), flag_reason = v_reason, flag_decision = null
   where order_id = p_order_id;
end $$;
revoke all on function public.owner_flag_review(uuid, text) from public, anon;
grant execute on function public.owner_flag_review(uuid, text) to authenticated;

-- ---------- driver: my rating ---------------------------------------------------------
-- Average from 5 ratings on, and how often each reason came up. Never who.
create or replace function public.driver_rating_summary()
returns table (rating_avg numeric, rating_count integer, reasons jsonb)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.drivers where id = auth.uid()) then
    raise exception 'not_a_driver' using errcode = '42501';
  end if;
  return query
  select case when count(*) >= 5 then round(avg(x.driver_stars)::numeric, 1) end,
         count(*)::int,
         coalesce((select jsonb_object_agg(z.reason, z.n)
                     from (select u.reason, count(*)::int n
                             from public.order_ratings y, unnest(y.driver_reasons) u(reason)
                            where y.driver_id = auth.uid() and y.driver_stars is not null
                            group by u.reason) z), '{}'::jsonb)
    from public.order_ratings x
   where x.driver_id = auth.uid() and x.driver_stars is not null;
end $$;
revoke all on function public.driver_rating_summary() from public, anon;
grant execute on function public.driver_rating_summary() to authenticated;

-- ---------- admin ------------------------------------------------------------------------
create or replace function public.admin_driver_ratings()
returns table (
  driver_id uuid, name text, phone text, rated_count integer,
  rating_avg numeric, avg_30d numeric, low_30d integer, reasons jsonb
)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select d.id, p.full_name, d.phone,
         count(x.driver_stars)::int,
         round(avg(x.driver_stars)::numeric, 2),
         round(avg(x.driver_stars) filter (where x.driver_rated_at > now() - interval '30 days')::numeric, 2),
         (count(*) filter (where x.driver_stars <= 2 and x.driver_rated_at > now() - interval '30 days'))::int,
         coalesce((select jsonb_object_agg(z.reason, z.n)
                     from (select u.reason, count(*)::int n
                             from public.order_ratings y, unnest(y.driver_reasons) u(reason)
                            where y.driver_id = d.id and y.driver_stars is not null
                            group by u.reason) z), '{}'::jsonb)
    from public.drivers d
    join public.profiles p on p.id = d.id
    left join public.order_ratings x on x.driver_id = d.id and x.driver_stars is not null
   group by d.id, p.full_name, d.phone
   order by avg(x.driver_stars) asc nulls last, p.full_name;
end $$;
revoke all on function public.admin_driver_ratings() from public, anon;
grant execute on function public.admin_driver_ratings() to authenticated;

create or replace function public.admin_restaurant_ratings()
returns table (
  restaurant_id uuid, name text, rated_count integer, rating_avg numeric,
  avg_30d numeric, flagged_pending integer
)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select r.id, r.name,
         count(x.food_stars) filter (where not x.hidden)::int,
         round(avg(x.food_stars) filter (where not x.hidden)::numeric, 2),
         round(avg(x.food_stars) filter (where not x.hidden
               and x.food_rated_at > now() - interval '30 days')::numeric, 2),
         (count(*) filter (where x.flagged_at is not null and x.flag_decision is null))::int
    from public.restaurants r
    left join public.order_ratings x on x.restaurant_id = r.id and x.food_stars is not null
   where r.deleted_at is null
   group by r.id, r.name
   order by avg(x.food_stars) filter (where not x.hidden) asc nulls last, r.name;
end $$;
revoke all on function public.admin_restaurant_ratings() from public, anon;
grant execute on function public.admin_restaurant_ratings() to authenticated;

-- Flagged reviews: waiting first, then decided in the last 30 days.
create or replace function public.admin_flagged_reviews()
returns table (
  order_id uuid, code text, restaurant_name text, customer_label text,
  stars integer, reasons text[], comment text, rated_at timestamptz,
  reply text, flagged_at timestamptz, flag_reason text,
  flag_decision text, hidden boolean
)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select x.order_id, o.code, r.name, x.customer_label, x.food_stars::int,
         x.food_reasons, x.food_comment, x.food_rated_at, x.reply,
         x.flagged_at, x.flag_reason, x.flag_decision, x.hidden
    from public.order_ratings x
    join public.orders o on o.id = x.order_id
    join public.restaurants r on r.id = x.restaurant_id
   where x.flagged_at is not null
     and (x.flag_decision is null or x.flagged_at > now() - interval '30 days')
   order by (x.flag_decision is null) desc, x.flagged_at desc
   limit 200;
end $$;
revoke all on function public.admin_flagged_reviews() from public, anon;
grant execute on function public.admin_flagged_reviews() to authenticated;

-- Hide or keep a review (flagged or not).
create or replace function public.admin_review_decision(p_order_id uuid, p_hide boolean)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  update public.order_ratings
     set hidden = coalesce(p_hide, false),
         flag_decision = case when flagged_at is null then flag_decision
                              when coalesce(p_hide, false) then 'hidden' else 'kept' end
   where order_id = p_order_id and food_stars is not null;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
end $$;
revoke all on function public.admin_review_decision(uuid, boolean) from public, anon;
grant execute on function public.admin_review_decision(uuid, boolean) to authenticated;

-- ---------- reports about customers (private) ----------------------------------------------
alter table public.profiles add column if not exists blocked_at timestamptz;

create table public.customer_reports (
  id             bigint generated always as identity primary key,
  order_id       uuid not null references public.orders (id) on delete cascade,
  reporter_id    uuid not null references public.profiles (id) on delete cascade,
  reporter_role  text not null check (reporter_role in ('restaurant', 'driver')),
  customer_id    uuid references public.profiles (id) on delete set null,
  customer_name  text not null default '',
  customer_phone text not null default '',
  reason         text not null check (reason in
                   ('fake_order', 'no_answer', 'wrong_address', 'refused_to_pay', 'rude', 'other')),
  note           text not null default '' check (char_length(note) <= 300),
  status         text not null default 'open' check (status in ('open', 'warned', 'blocked', 'dismissed')),
  admin_note     text not null default '' check (char_length(admin_note) <= 300),
  created_at     timestamptz not null default now(),
  handled_at     timestamptz,
  unique (order_id, reporter_id)
);
create index customer_reports_customer_idx on public.customer_reports (customer_id);
create index customer_reports_status_idx on public.customer_reports (status, created_at desc);
alter table public.customer_reports enable row level security;
revoke all on public.customer_reports from anon, authenticated;

-- The driver of the order, or its restaurant's team, reports its customer.
-- Errors: not_signed_in, invalid_reason, invalid_note, order_not_found,
--         customer_gone, already_reported, too_many_reports
create or replace function public.report_customer(
  p_order_id uuid, p_reason text, p_note text default '')
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  o record;
  v_role text;
  v_note text := btrim(coalesce(p_note, ''));
begin
  if uid is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  if p_reason is null or p_reason not in
     ('fake_order', 'no_answer', 'wrong_address', 'refused_to_pay', 'rude', 'other') then
    raise exception 'invalid_reason' using errcode = '22023';
  end if;
  if char_length(v_note) > 300 then
    raise exception 'invalid_note' using errcode = '22023';
  end if;
  select x.id, x.customer_id, x.customer_name, x.customer_phone, x.driver_id, x.restaurant_id into o
    from public.orders x where x.id = p_order_id;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
  if o.driver_id = uid then
    v_role := 'driver';
  elsif public.has_restaurant_role(o.restaurant_id, 'staff') then
    v_role := 'restaurant';
  else
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;
  if o.customer_id is null then
    raise exception 'customer_gone' using errcode = 'P0001';
  end if;
  if (select count(*) from public.customer_reports
       where reporter_id = uid and created_at > now() - interval '24 hours') >= 20 then
    raise exception 'too_many_reports' using errcode = 'P0001';
  end if;
  begin
    insert into public.customer_reports
      (order_id, reporter_id, reporter_role, customer_id, customer_name,
       customer_phone, reason, note)
    values (p_order_id, uid, v_role, o.customer_id, o.customer_name,
            o.customer_phone, p_reason, v_note);
  exception when unique_violation then
    raise exception 'already_reported' using errcode = 'P0001';
  end;
end $$;
revoke all on function public.report_customer(uuid, text, text) from public, anon;
grant execute on function public.report_customer(uuid, text, text) to authenticated;

-- Did I already report this order? (to hide the button)
create or replace function public.my_reported_orders()
returns table (order_id uuid)
language sql stable security definer set search_path = '' as $$
  select r.order_id from public.customer_reports r where r.reporter_id = auth.uid();
$$;
revoke all on function public.my_reported_orders() from public, anon;
grant execute on function public.my_reported_orders() to authenticated;

create or replace function public.admin_customer_reports(p_status text default null)
returns table (
  id bigint, order_code text, reporter_role text, reporter_name text,
  restaurant_name text, customer_id uuid, customer_name text, customer_phone text,
  reason text, note text, created_at timestamptz, status text, admin_note text,
  customer_reports_total integer, customer_blocked boolean
)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  return query
  select c.id, o.code, c.reporter_role, rp.full_name, r.name,
         c.customer_id, c.customer_name, c.customer_phone,
         c.reason, c.note, c.created_at, c.status, c.admin_note,
         (select count(*)::int from public.customer_reports z
           where z.customer_id is not distinct from c.customer_id and c.customer_id is not null),
         coalesce(cp.blocked_at is not null, false)
    from public.customer_reports c
    join public.orders o on o.id = c.order_id
    join public.restaurants r on r.id = o.restaurant_id
    join public.profiles rp on rp.id = c.reporter_id
    left join public.profiles cp on cp.id = c.customer_id
   where p_status is null or c.status = p_status
   order by (c.status = 'open') desc, c.created_at desc
   limit 300;
end $$;
revoke all on function public.admin_customer_reports(text) from public, anon;
grant execute on function public.admin_customer_reports(text) to authenticated;

-- open | warned | blocked | dismissed. "blocked" also blocks the account.
create or replace function public.admin_handle_report(
  p_id bigint, p_status text, p_note text default '')
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  c public.customer_reports;
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
  if p_status = 'blocked' and c.customer_id is not null then
    update public.profiles set blocked_at = coalesce(blocked_at, now()) where id = c.customer_id;
  end if;
end $$;
revoke all on function public.admin_handle_report(bigint, text, text) from public, anon;
grant execute on function public.admin_handle_report(bigint, text, text) to authenticated;

create or replace function public.admin_set_customer_blocked(p_customer_id uuid, p_blocked boolean)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  update public.profiles
     set blocked_at = case when coalesce(p_blocked, false) then coalesce(blocked_at, now()) end
   where id = p_customer_id and role = 'customer';
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
end $$;
revoke all on function public.admin_set_customer_blocked(uuid, boolean) from public, anon;
grant execute on function public.admin_set_customer_blocked(uuid, boolean) to authenticated;

-- A blocked customer can't place orders (every insert goes through
-- place_order; the check lives on the table so it can't be bypassed).
create or replace function public.orders_block_check()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.customer_id is not null and exists (
       select 1 from public.profiles where id = new.customer_id and blocked_at is not null) then
    raise exception 'account_blocked' using errcode = 'P0001';
  end if;
  return new;
end $$;
create trigger orders_block_check before insert on public.orders
  for each row execute function public.orders_block_check();

-- ---------- reminder push (about 40 minutes after the delivery) -------------------------------
create table public.rating_reminders (
  order_id uuid primary key references public.orders (id) on delete cascade,
  sent_at  timestamptz not null default now()
);
alter table public.rating_reminders enable row level security;
revoke all on public.rating_reminders from anon, authenticated;

-- Delivered 40 min to 3 h ago, food not rated, no reminder yet.
-- Returns how many were queued. Runs every 5 minutes (pg_cron).
create or replace function public.send_rating_reminders()
returns integer language plpgsql volatile security definer set search_path = '' as $$
declare
  cfg record;
  r record;
  n integer := 0;
  can_post boolean;
begin
  select * into cfg from private.push_config;
  can_post := found and to_regproc('net.http_post') is not null;
  for r in
    select o.id from public.orders o
     where o.status = 'delivered' and o.customer_id is not null
       and o.delivered_at between now() - interval '3 hours' and now() - interval '40 minutes'
       and not exists (select 1 from public.rating_reminders x where x.order_id = o.id)
       and not exists (select 1 from public.order_ratings z
                        where z.order_id = o.id and z.food_stars is not null)
     order by o.delivered_at
     limit 200
  loop
    insert into public.rating_reminders (order_id) values (r.id) on conflict do nothing;
    n := n + 1;
    if can_post then
      begin
        execute 'select net.http_post(url := $1, body := $2, headers := $3)'
          using cfg.function_url,
                jsonb_build_object('order_id', r.id, 'event', 'rate_reminder',
                                   'by_customer', false),
                jsonb_build_object('Content-Type', 'application/json',
                                   'x-push-secret', cfg.secret);
      exception when others then
        raise warning 'rating reminder not queued: %', sqlerrm;
      end;
    end if;
  end loop;
  return n;
end $$;
revoke all on function public.send_rating_reminders() from public, anon, authenticated;

do $outer$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.schedule('rating-reminders', '*/5 * * * *',
                          'select public.send_rating_reminders()');
  else
    raise notice 'pg_cron not available: rating reminders not scheduled';
  end if;
end $outer$;
