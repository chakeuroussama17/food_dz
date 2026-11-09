-- DEMO ACCOUNTS: new emails. Paste into Supabase → SQL Editor → Run.
-- Renames the existing demo users in place (same passwords, same roles,
-- same restaurant / driver / orders):
--
--   admin.demo@foodapp-dz.com     → admin@gmail.com
--   pizzeria.demo@foodapp-dz.com  → restaurant@gmail.com
--   client.demo@foodapp-dz.com    → client@gmail.com
--   livreur.demo@foodapp-dz.com   → driver@gmail.com
--
-- These gmail addresses belong to other people. That's fine for testing
-- while no emails are sent, but delete these users before launch.
-- Safe to run more than once.
begin;

do $$
declare
  m record;
  v_id uuid;
begin
  for m in select * from (values
      ('admin.demo@foodapp-dz.com',    'admin@gmail.com'),
      ('pizzeria.demo@foodapp-dz.com', 'restaurant@gmail.com'),
      ('client.demo@foodapp-dz.com',   'client@gmail.com'),
      ('livreur.demo@foodapp-dz.com',  'driver@gmail.com')) as t(old_email, new_email)
  loop
    select id into v_id from auth.users where email = m.old_email;
    if v_id is null then
      raise notice '% not found (already renamed?)', m.old_email;
      continue;
    end if;
    if exists (select 1 from auth.users where email = m.new_email) then
      raise exception '% already exists: rename stopped, nothing changed', m.new_email;
    end if;

    update auth.users
       set email = m.new_email,
           email_confirmed_at = coalesce(email_confirmed_at, now()),
           updated_at = now()
     where id = v_id;

    -- The email login identity keeps its own copy of the address.
    update auth.identities
       set identity_data = identity_data || jsonb_build_object('email', m.new_email),
           updated_at = now()
     where user_id = v_id and provider = 'email';
  end loop;
end $$;

-- Check: the four accounts with their roles.
select u.email, p.role, r.name as restaurant, d.is_approved as driver_approved
  from auth.users u
  join public.profiles p on p.id = u.id
  left join public.restaurants r on r.owner_id = u.id
  left join public.drivers d on d.id = u.id
 where u.email in ('admin@gmail.com', 'restaurant@gmail.com',
                   'client@gmail.com', 'driver@gmail.com')
 order by u.email;

commit;
