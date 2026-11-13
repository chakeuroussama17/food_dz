-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261124000001_customer_data.sql
-- Run 2026-11-24_restaurant_qr.sql first.
begin;

-- =====================================================================
-- More about each user, for analysis.
--
-- Asked at sign-up: wilaya + commune (with name, email, phone).
-- Asked once after sign-up ("complete your profile", can be skipped):
--   birth date, gender, how they heard about foodfennec.
-- Collected automatically on every app start: platform, app version,
--   phone model, OS, language, last time seen, and one row per active
--   day (retention: daily / monthly active users, cohorts).
-- Orders, spending, cancellations and addresses (GPS) are already kept.
-- Only the admin reads it all (admin_list_customers, admin_customer_insights).
-- =====================================================================

alter table public.profiles
  add column if not exists birth_date        date,
  add column if not exists gender            text check (gender in ('male', 'female')),
  add column if not exists wilaya            smallint check (wilaya between 1 and 58),
  add column if not exists commune           text check (char_length(commune) <= 80),
  add column if not exists referral_source   text check (referral_source in
                             ('friend', 'social', 'search', 'restaurant', 'ad', 'other')),
  -- When the "complete your profile" card was answered or skipped.
  add column if not exists profile_prompt_at timestamptz,
  add column if not exists signup_platform   text check (char_length(signup_platform) <= 20),
  add column if not exists signup_app_version text check (char_length(signup_app_version) <= 20),
  add column if not exists signup_lang       text check (char_length(signup_lang) <= 5),
  add column if not exists last_seen_at      timestamptz,
  add column if not exists last_platform     text check (char_length(last_platform) <= 20),
  add column if not exists last_app_version  text check (char_length(last_app_version) <= 20),
  add column if not exists last_os           text check (char_length(last_os) <= 60),
  add column if not exists last_device       text check (char_length(last_device) <= 80),
  add column if not exists last_lang         text check (char_length(last_lang) <= 5);

-- The user reads their own new fields (profiles: read own). They change
-- them only through update_my_details (validated).

-- One row per user per day the app was opened.
create table if not exists public.user_activity_days (
  user_id  uuid not null references public.profiles (id) on delete cascade,
  day      date not null default ((now() at time zone 'Africa/Algiers')::date),
  platform text not null default '' check (char_length(platform) <= 20),
  primary key (user_id, day)
);
create index if not exists user_activity_days_day_idx on public.user_activity_days (day);
alter table public.user_activity_days enable row level security;
-- No policies: written by touch_session, read by the admin functions.

-- ---------- sign-up: wilaya and commune from the form -------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  m        jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_phone  text := btrim(coalesce(m ->> 'phone', ''));
  v_wilaya text := btrim(coalesce(m ->> 'wilaya', ''));
  v_lang   text := btrim(coalesce(m ->> 'lang', ''));
  v_plat   text := btrim(coalesce(m ->> 'platform', ''));
begin
  insert into public.profiles (id, full_name, phone, wilaya, commune,
                               signup_platform, signup_lang)
  values (
    new.id,
    left(coalesce(btrim(m ->> 'full_name'), ''), 80),
    case when v_phone ~ '^0[567][0-9]{8}$' then v_phone end,
    case when v_wilaya ~ '^[0-9]{1,2}$' and v_wilaya::int between 1 and 58
         then v_wilaya::smallint end,
    nullif(left(regexp_replace(btrim(coalesce(m ->> 'commune', '')), '\s+', ' ', 'g'), 80), ''),
    case when v_plat in ('android', 'ios', 'web') then v_plat end,
    case when v_lang in ('ar', 'fr', 'en') then v_lang end
  )
  on conflict (id) do nothing;
  return new;
end $$;

-- ---------- my details ----------------------------------------------------
-- Every argument is optional: null leaves the value as it is.
-- p_complete = true also records that the "complete profile" card was
-- answered (it stops showing).
-- Errors: invalid_birth_date (under 13, over 100, future), invalid_gender,
--         invalid_wilaya, invalid_commune, invalid_referral
create or replace function public.update_my_details(
  p_birth_date date    default null,
  p_gender     text    default null,
  p_wilaya     integer default null,
  p_commune    text    default null,
  p_referral   text    default null,
  p_complete   boolean default false
)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_commune text := nullif(regexp_replace(btrim(coalesce(p_commune, '')), '\s+', ' ', 'g'), '');
begin
  if auth.uid() is null then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_birth_date is not null and (
       p_birth_date > current_date - interval '13 years'
       or p_birth_date < current_date - interval '100 years') then
    raise exception 'invalid_birth_date' using errcode = 'P0001';
  end if;
  if p_gender is not null and p_gender not in ('male', 'female') then
    raise exception 'invalid_gender' using errcode = 'P0001';
  end if;
  if p_wilaya is not null and p_wilaya not between 1 and 58 then
    raise exception 'invalid_wilaya' using errcode = 'P0001';
  end if;
  if p_commune is not null and (v_commune is null or char_length(v_commune) > 80) then
    raise exception 'invalid_commune' using errcode = 'P0001';
  end if;
  if p_referral is not null and p_referral not in
       ('friend', 'social', 'search', 'restaurant', 'ad', 'other') then
    raise exception 'invalid_referral' using errcode = 'P0001';
  end if;
  update public.profiles set
    birth_date        = coalesce(p_birth_date, birth_date),
    gender            = coalesce(p_gender, gender),
    wilaya            = coalesce(p_wilaya::smallint, wilaya),
    commune           = coalesce(v_commune, commune),
    referral_source   = coalesce(p_referral, referral_source),
    profile_prompt_at = case when coalesce(p_complete, false)
                             then coalesce(profile_prompt_at, now())
                             else profile_prompt_at end,
    updated_at        = now()
  where id = auth.uid();
end $$;
revoke all on function public.update_my_details(date, text, integer, text, text, boolean) from public, anon;
grant execute on function public.update_my_details(date, text, integer, text, text, boolean) to authenticated;

-- "Later" on the complete-profile card.
create or replace function public.skip_profile_prompt()
returns void language sql volatile security definer set search_path = '' as $$
  update public.profiles set profile_prompt_at = coalesce(profile_prompt_at, now())
   where id = auth.uid();
$$;
revoke all on function public.skip_profile_prompt() from public, anon;
grant execute on function public.skip_profile_prompt() to authenticated;

-- ---------- app start -------------------------------------------------------
-- Called by the app when it starts (signed in) and after logging in.
-- Values are cut to size; unknown platforms are stored as ''.
create or replace function public.touch_session(
  p_platform    text default '',
  p_app_version text default '',
  p_os          text default '',
  p_device      text default '',
  p_lang        text default ''
)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_plat text := case when p_platform in ('android', 'ios', 'web') then p_platform else '' end;
  v_ver  text := left(regexp_replace(coalesce(p_app_version, ''), '[^0-9A-Za-z.+-]', '', 'g'), 20);
  v_lang text := case when p_lang in ('ar', 'fr', 'en') then p_lang end;
begin
  if auth.uid() is null then
    return;
  end if;
  update public.profiles set
    last_seen_at       = now(),
    last_platform      = nullif(v_plat, ''),
    last_app_version   = nullif(v_ver, ''),
    last_os            = nullif(left(btrim(coalesce(p_os, '')), 60), ''),
    last_device        = nullif(left(btrim(coalesce(p_device, '')), 80), ''),
    last_lang          = coalesce(v_lang, last_lang),
    signup_platform    = coalesce(signup_platform, nullif(v_plat, '')),
    signup_app_version = coalesce(signup_app_version, nullif(v_ver, '')),
    signup_lang        = coalesce(signup_lang, v_lang)
  where id = auth.uid();
  insert into public.user_activity_days (user_id, platform)
  values (auth.uid(), v_plat)
  on conflict (user_id, day) do nothing;
end $$;
revoke all on function public.touch_session(text, text, text, text, text) from public, anon;
grant execute on function public.touch_session(text, text, text, text, text) to authenticated;

-- ---------- admin: the customers with everything ---------------------------
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
  last_seen_at timestamptz, active_days_30 integer, blocked_at timestamptz
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
         p.blocked_at
    from public.profiles p
    join auth.users u on u.id = p.id
    left join lateral (
      select count(*)::int as n,
             count(*) filter (where x.status = 'delivered')::int as delivered,
             count(*) filter (where x.status = 'cancelled')::int as cancelled,
             coalesce(sum(x.total) filter (where x.status = 'delivered'), 0)::int as spent,
             max(x.placed_at) as last_at
        from public.orders x where x.customer_id = p.id
    ) o on true
   where p.role = 'customer'
     and (p.full_name ilike pat or u.email ilike pat or coalesce(p.phone, '') ilike pat
          or coalesce(p.commune, '') ilike pat)
   order by p.created_at desc
   limit least(greatest(p_limit, 1), 5000) offset greatest(p_offset, 0);
end $$;
revoke all on function public.admin_list_customers(text, integer, integer) from public, anon;
grant execute on function public.admin_list_customers(text, integer, integer) to authenticated;

-- A summary for the admin's customers page.
create or replace function public.admin_customer_insights()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  today date := (now() at time zone 'Africa/Algiers')::date;
begin
  perform public.assert_admin();
  return (
    with c as (select * from public.profiles where role = 'customer')
    select jsonb_build_object(
      'customers', (select count(*) from c),
      'new_7d', (select count(*) from c where created_at > now() - interval '7 days'),
      'new_30d', (select count(*) from c where created_at > now() - interval '30 days'),
      'active_1d', (select count(distinct d.user_id) from public.user_activity_days d
                     join c on c.id = d.user_id where d.day = today),
      'active_7d', (select count(distinct d.user_id) from public.user_activity_days d
                     join c on c.id = d.user_id where d.day > today - 7),
      'active_30d', (select count(distinct d.user_id) from public.user_activity_days d
                      join c on c.id = d.user_id where d.day > today - 30),
      'ordered', (select count(*) from c where exists (
                    select 1 from public.orders o
                     where o.customer_id = c.id and o.status = 'delivered')),
      'profile_done', (select count(*) from c where birth_date is not null
                         or gender is not null or referral_source is not null),
      'gender', (select coalesce(jsonb_object_agg(k, n), '{}'::jsonb) from (
                   select coalesce(gender, 'unknown') k, count(*) n from c group by 1) g),
      'age', (select coalesce(jsonb_object_agg(k, n), '{}'::jsonb) from (
                select case
                         when birth_date is null then 'unknown'
                         when age(birth_date) < interval '18 years' then '13-17'
                         when age(birth_date) < interval '25 years' then '18-24'
                         when age(birth_date) < interval '35 years' then '25-34'
                         when age(birth_date) < interval '45 years' then '35-44'
                         else '45+' end k, count(*) n
                  from c group by 1) a),
      'wilaya', (select coalesce(jsonb_object_agg(k, n), '{}'::jsonb) from (
                   select coalesce(wilaya::text, 'unknown') k, count(*) n from c group by 1) w),
      'referral', (select coalesce(jsonb_object_agg(k, n), '{}'::jsonb) from (
                     select coalesce(referral_source, 'unknown') k, count(*) n from c group by 1) r),
      'platform', (select coalesce(jsonb_object_agg(k, n), '{}'::jsonb) from (
                     select coalesce(last_platform, signup_platform, 'unknown') k, count(*) n
                       from c group by 1) pl)
    )
  );
end $$;
revoke all on function public.admin_customer_insights() from public, anon;
grant execute on function public.admin_customer_insights() to authenticated;

notify pgrst, 'reload schema';

commit;
