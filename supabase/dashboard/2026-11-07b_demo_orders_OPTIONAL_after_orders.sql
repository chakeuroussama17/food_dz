-- OPTIONAL demo data: ~120 orders for the 3 demo restaurants (last 45 days).
-- Paste into SQL Editor → Run, after 2026-11-07_orders_admin_statements.sql.
-- Removal instructions are inside.

-- Demo orders for the admin dashboard and commission statements.
-- ~120 orders over the last 45 days for the 3 seeded restaurants, mostly
-- delivered, some rejected/cancelled. All are marked notes = 'DEMO'.
--
-- Remove them before launch:
--   delete from public.statements s where not exists
--     (select 1 from public.orders o where o.statement_id = s.id and o.notes <> 'DEMO');
--   delete from public.orders where notes = 'DEMO';

do $$
declare
  r record;
  d integer;
  n integer;
  oid uuid;
  food integer;
  st public.order_status;
  placed timestamptz;
  rate numeric;
  names text[] := array['Karim B.', 'Amina T.', 'Yacine M.', 'Sarah K.', 'Nassim H.', 'Lina D.'];
  areas text[] := array['Kouba', 'Hydra', 'Bab Ezzouar', 'El Biar', 'Alger Centre'];
begin
  if exists (select 1 from public.orders where notes = 'DEMO') then
    raise notice 'demo orders already present, skipping';
    return;
  end if;

  for r in select id from public.restaurants
            where id in ('11111111-1111-4111-8111-111111111111',
                         '22222222-2222-4222-8222-222222222222',
                         '33333333-3333-4333-8333-333333333333') loop
    select coalesce(x.commission_rate, c.default_commission_rate) into rate
      from public.restaurants x cross join public.app_config c where x.id = r.id;

    for d in 1..45 loop
      for n in 1..(case when random() < 0.4 then 1 else 0 end
                   + case when random() < 0.5 then 1 else 0 end) loop
        placed := (now() - make_interval(days => d))
                  + make_interval(hours => (random() * 10)::int - 5);
        st := case
                when random() < 0.85 then 'delivered'
                when random() < 0.5 then 'rejected'
                else 'cancelled'
              end;

        insert into public.orders
          (restaurant_id, status, customer_name, customer_phone, address_text,
           area, food_total, delivery_fee, commission_rate, notes, placed_at,
           delivered_at, cancelled_at)
        values
          (r.id, st, names[1 + floor(random() * 6)::int], '0550000000',
           'Adresse de démonstration', areas[1 + floor(random() * 5)::int],
           1, 200, rate, 'DEMO', placed,
           case when st = 'delivered' then placed + interval '40 minutes' end,
           case when st <> 'delivered' then placed + interval '10 minutes' end)
        returning id into oid;

        -- 1 to 3 dishes from this restaurant's menu.
        insert into public.order_items (order_id, menu_item_id, name, unit_price, quantity)
        select oid, m.id, m.name, m.price, 1 + floor(random() * 2)::int
          from public.menu_items m
         where m.restaurant_id = r.id
         order by random()
         limit 1 + floor(random() * 3)::int;

        select sum(line_total) into food from public.order_items where order_id = oid;

        -- Fix the totals (the trigger blocks amount changes, so bypass it
        -- just for this seed).
        alter table public.orders disable trigger orders_before_write;
        update public.orders
           set food_total = food,
               total = food + delivery_fee,
               commission_amount = case when st = 'delivered'
                                        then round(food * rate) end
         where id = oid;
        alter table public.orders enable trigger orders_before_write;
      end loop;
    end loop;
  end loop;
end $$;
