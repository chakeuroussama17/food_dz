-- DEMO DRIVER: paste into Supabase Dashboard → SQL Editor → Run.
-- Run AFTER 2026-11-10_drivers.sql. Safe to run more than once.
--
--   livreur.demo@foodapp-dz.com → driver, approved (can go online)
--
-- Before launch: delete this user in Authentication → Users.
begin;

update public.profiles set role = 'driver', phone = '0661000001'
 where id = (select id from auth.users where email = 'livreur.demo@foodapp-dz.com');

insert into public.drivers (id, phone, vehicle, is_approved)
select u.id, '0661000001', 'moto', true
  from auth.users u
 where u.email = 'livreur.demo@foodapp-dz.com'
on conflict (id) do update set is_approved = true;

-- Check: should show the driver, approved.
select u.email, p.role, d.vehicle, d.is_approved
  from auth.users u
  join public.profiles p on p.id = u.id
  left join public.drivers d on d.id = u.id
 where u.email = 'livreur.demo@foodapp-dz.com';

commit;
