-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261113000002_push.sql
begin;

-- =====================================================================
-- Push notifications (alerts while the app is closed).
--
-- * Each phone registers its Firebase token (push_tokens).
-- * Every order change calls the `push` Edge Function (pg_net), which
--   decides who to alert (restaurant, customer, drivers) and sends through
--   Firebase Cloud Messaging.
-- * The function URL and shared secret live in private.push_config, filled
--   once by the admin (see the private SQL file, not in git).
-- =====================================================================

create table public.push_tokens (
  token      text primary key check (char_length(token) between 10 and 4096),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  platform   text not null check (platform in ('android', 'ios', 'web')),
  lang       text not null default 'fr' check (lang in ('fr', 'ar', 'en')),
  updated_at timestamptz not null default now()
);
create index push_tokens_user_idx on public.push_tokens (user_id);
alter table public.push_tokens enable row level security;
revoke all on public.push_tokens from anon, authenticated;

-- A phone signs in: its token now belongs to this user (a phone shared by
-- two accounts alerts the one signed in). At most 10 phones per user.
create or replace function public.register_push_token(
  p_token text, p_platform text, p_lang text default 'fr')
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  if p_token is null or char_length(p_token) not between 10 and 4096
     or p_platform not in ('android', 'ios', 'web') then
    raise exception 'invalid_token' using errcode = '22023';
  end if;
  insert into public.push_tokens (token, user_id, platform, lang)
  values (p_token, uid, p_platform,
          case when p_lang in ('fr', 'ar', 'en') then p_lang else 'fr' end)
  on conflict (token) do update
    set user_id = excluded.user_id, platform = excluded.platform,
        lang = excluded.lang, updated_at = now();
  delete from public.push_tokens t
   where t.user_id = uid
     and t.token not in (select x.token from public.push_tokens x
                          where x.user_id = uid
                          order by x.updated_at desc limit 10);
end $$;
revoke all on function public.register_push_token(text, text, text) from public, anon;
grant execute on function public.register_push_token(text, text, text) to authenticated;

-- Before logging out: stop alerts on this phone.
create or replace function public.unregister_push_token(p_token text)
returns void language sql volatile security definer set search_path = '' as $$
  delete from public.push_tokens where token = p_token and user_id = auth.uid();
$$;
revoke all on function public.unregister_push_token(text) from public, anon;
grant execute on function public.unregister_push_token(text) to authenticated;

-- ---------- server-side settings (never readable by the apps) -------------
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table private.push_config (
  id           boolean primary key default true check (id),
  function_url text not null,
  secret       text not null check (char_length(secret) >= 32)
);

-- ---------- order change -> push function ---------------------------------
-- Events: placed, accepted, rejected, ready, picked_up, delivered,
-- cancelled, driver_assigned, available (a driver gave the order back).
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
  elsif new.driver_id is distinct from old.driver_id then
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

create trigger orders_push after insert or update of status, driver_id
  on public.orders for each row execute function public.orders_push();

-- pg_net exists on Supabase (not in the local test database).
do $outer$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_net') then
    create extension if not exists pg_net;
  end if;
end $outer$;

commit;
