-- Removes everything created by 2026-11-20b_demo_ratings_OPTIONAL.sql:
-- the demo orders and, with them (cascade), their dishes, ratings, replies,
-- flags and reports about customers.
-- Paste into Supabase Dashboard → SQL Editor → Run.

-- Commission statements that only contain demo orders.
delete from public.statements s
 where exists (select 1 from public.orders o
                where o.statement_id = s.id and o.notes = 'DEMO-RATINGS')
   and not exists (select 1 from public.orders o
                    where o.statement_id = s.id and o.notes not in ('DEMO', 'DEMO-RATINGS'));

delete from public.orders where notes = 'DEMO-RATINGS';

-- If you pressed "Block customer" on the demo customer:
update public.profiles set blocked_at = null
 where id in (select id from auth.users where lower(email) = 'client@gmail.com');
