-- GENERATED: paste into Supabase Dashboard → SQL Editor → Run.
-- Source: migrations/20261113000001_auto_reject.sql
begin;

-- =====================================================================
-- Auto-reject: an order the restaurant doesn't answer within
-- app_config.auto_reject_minutes (10 by default) is rejected, so the
-- customer isn't left waiting. Runs every minute with pg_cron.
-- =====================================================================

alter table public.app_config
  add column auto_reject_minutes integer not null default 10
  check (auto_reject_minutes between 3 and 60);

-- Reason stored on the order; the apps translate this code.
-- Returns how many orders were rejected.
create or replace function public.auto_reject_stale_orders()
returns integer language plpgsql volatile security definer set search_path = '' as $$
declare
  n integer;
begin
  update public.orders o
     set status = 'rejected', reject_reason = 'no_answer'
    from public.app_config c
   where o.status = 'placed'
     and o.placed_at < now() - make_interval(mins => c.auto_reject_minutes);
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public.auto_reject_stale_orders() from public, anon, authenticated;

create or replace function public.admin_set_auto_reject_minutes(p_minutes integer)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  perform public.assert_admin();
  if p_minutes is null or p_minutes not between 3 and 60 then
    raise exception 'invalid minutes' using errcode = '22023';
  end if;
  update public.app_config set auto_reject_minutes = p_minutes;
end $$;
revoke all on function public.admin_set_auto_reject_minutes(integer) from public, anon;
grant execute on function public.admin_set_auto_reject_minutes(integer) to authenticated;

-- Every minute. pg_cron exists on Supabase (not in the local test database).
do $outer$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.schedule('auto-reject-orders', '* * * * *',
                          'select public.auto_reject_stale_orders()');
  else
    raise notice 'pg_cron not available: auto-reject not scheduled';
  end if;
end $outer$;

commit;
