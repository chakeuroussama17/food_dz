-- DEMO ACCOUNTS: paste into Supabase Dashboard → SQL Editor → Run.
-- Run AFTER 2026-11-08_checkout.sql. Safe to run more than once.
--
--   admin.demo@foodapp-dz.com     → admin
--   pizzeria.demo@foodapp-dz.com  → owner of "Pizzeria El Bahdja" (approved, open)
--   client.demo@foodapp-dz.com    → customer, with a delivery address
--
-- Before launch: delete these three users in Authentication → Users.
begin;

-- Admin.
update public.profiles set role = 'admin'
 where id = (select id from auth.users where email = 'admin.demo@foodapp-dz.com');

-- Restaurant owner of the seeded pizzeria.
update public.profiles set role = 'restaurant', phone = '0550111222'
 where id = (select id from auth.users where email = 'pizzeria.demo@foodapp-dz.com');

update public.restaurants
   set owner_id  = (select id from auth.users where email = 'pizzeria.demo@foodapp-dz.com'),
       is_active = true,
       is_open   = true
 where id = '11111111-1111-4111-8111-111111111111';

-- Customer: phone + one default address in Algiers.
update public.profiles set phone = '0661234567'
 where id = (select id from auth.users where email = 'client.demo@foodapp-dz.com');

insert into public.addresses (user_id, label, address_text, area, details, lat, lng, is_default)
select u.id, 'home', '12 Rue Didouche Mourad', 'Alger Centre', '2e étage', 36.7703, 3.0560, true
  from auth.users u
 where u.email = 'client.demo@foodapp-dz.com'
   and not exists (select 1 from public.addresses a where a.user_id = u.id);

-- Check: should list the 3 accounts with their roles.
select u.email, p.role, r.name as restaurant
  from auth.users u
  join public.profiles p on p.id = u.id
  left join public.restaurants r on r.owner_id = u.id
 where u.email like '%.demo@foodapp-dz.com'
 order by u.email;

commit;
