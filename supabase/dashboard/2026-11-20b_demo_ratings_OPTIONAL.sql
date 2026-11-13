-- OPTIONAL DEMO DATA: ratings, reviews, replies and reports, for all roles.
-- Paste into Supabase Dashboard → SQL Editor → Run, AFTER 2026-11-20_ratings.sql
-- and after the demo accounts exist (client@, driver@, restaurant@gmail.com).
--
-- What it creates (every order is marked notes = 'DEMO-RATINGS'):
--   * ~50 delivered orders over the last 4 weeks for the 3 demo restaurants,
--     delivered by the demo driver, with food ratings, delivery ratings,
--     comments in French / Arabic / English and replies from the restaurants.
--   * For the demo customer (client@gmail.com), 4 orders to try the screens:
--       - delivered 2 h ago, NOT rated      -> the delivery pop-up + both cards
--       - delivered 3 days ago, driver rated, food NOT rated -> "4 days left"
--       - delivered 70 min ago, both rated, with a restaurant reply -> "Modifier"
--       - delivered 8 days ago, not rated   -> too late, nothing to rate
--   * 2 flagged reviews (1 waiting for you, 1 already kept) and 4 private
--     reports about the demo customer, for the admin "Avis" tab.
--     (If you press "Block customer", client@gmail.com can no longer order:
--      press "Unblock" on the same page to undo it.)
--   * Cash of these orders is already settled, and no push notification is sent.
--
-- Remove it all: run 2026-11-20c_remove_demo_ratings.sql

-- ---------- helpers (live only for this run) ---------------------------------
create or replace function pg_temp.demo_pick(arr text[])
returns text language sql volatile as $$
  select arr[1 + floor(random() * cardinality(arr))::int];
$$;

-- 1 or 2 different reasons from the pool.
create or replace function pg_temp.demo_reasons(pool text[])
returns text[] language plpgsql volatile as $$
declare a text := pg_temp.demo_pick(pool); b text := pg_temp.demo_pick(pool);
begin
  return case when random() < 0.5 or a = b then array[a] else array[a, b] end;
end $$;

create or replace function pg_temp.demo_stars()
returns integer language plpgsql volatile as $$
declare r numeric := random();
begin
  -- mostly good, a few poor ones: average around 4.4
  return case when r < 0.60 then 5 when r < 0.87 then 4 when r < 0.95 then 3
              when r < 0.99 then 2 else 1 end;
end $$;

-- A delivered order of [p_rest] with 1-3 dishes, money fixed, cash settled.
create or replace function pg_temp.demo_order(
  p_rest uuid, p_customer uuid, p_name text, p_delivered timestamptz,
  p_driver uuid, p_rate numeric)
returns uuid language plpgsql volatile as $$
declare
  oid uuid;
  food integer;
  n integer := 1 + floor(random() * 3)::int;
begin
  insert into public.orders
    (restaurant_id, customer_id, driver_id, status, customer_name, customer_phone,
     address_text, area, food_total, delivery_fee, total, commission_rate, notes,
     placed_at, accepted_at, ready_at, picked_up_at, delivered_at)
  values
    (p_rest, p_customer, p_driver, 'delivered', p_name, '0550123456',
     'Adresse de démonstration',
     (array['Kouba', 'Hydra', 'Bab Ezzouar', 'El Biar', 'Alger Centre'])[1 + floor(random() * 5)::int],
     1, 200, 201, p_rate, 'DEMO-RATINGS',
     p_delivered - interval '50 minutes', p_delivered - interval '45 minutes',
     p_delivered - interval '25 minutes', p_delivered - interval '15 minutes',
     p_delivered)
  returning id into oid;

  insert into public.order_items (order_id, menu_item_id, name, unit_price, quantity)
  select oid, m.id, m.name, m.price, 1 + floor(random() * 2)::int
    from public.menu_items m
   where m.restaurant_id = p_rest
   order by random()
   limit n;

  select sum(line_total) into food from public.order_items where order_id = oid;
  update public.orders
     set food_total = food, total = food + delivery_fee,
         commission_amount = round(food * commission_rate),
         cash_handed_at = least(p_delivered + interval '1 hour', now() - interval '1 minute'),
         cash_confirmed_at = least(p_delivered + interval '2 hours', now() - interval '1 minute')
   where id = oid;
  return oid;
end $$;

-- Ratings (and a restaurant reply) for one order. Stars 0 = not rated.
create or replace function pg_temp.demo_rating(
  p_order uuid, p_rest uuid, p_driver uuid, p_customer uuid, p_label text,
  p_delivered timestamptz, p_food integer, p_drv integer, p_reply boolean)
returns void language plpgsql volatile as $$
declare
  food_at timestamptz := p_delivered + make_interval(mins => 30 + (random() * 900)::int);
  drv_at  timestamptz := p_delivered + make_interval(mins => 1 + (random() * 40)::int);
  f_reasons text[] := '{}';
  d_reasons text[] := '{}';
  f_comment text := '';
  d_comment text := '';
  v_reply text;
begin
  if p_food > 0 and p_food <= 3 then
    f_reasons := pg_temp.demo_reasons(array['cold', 'missing_item', 'wrong_order',
                                            'small_portion', 'bad_taste', 'bad_packaging']);
  end if;
  if p_drv > 0 and p_drv <= 3 then
    d_reasons := pg_temp.demo_reasons(array['late', 'rude', 'careless', 'no_contact', 'wrong_place']);
  end if;

  if p_food >= 4 and random() < 0.55 then
    f_comment := pg_temp.demo_pick(array[
      'Excellente pizza, livrée chaude et à l''heure !',
      'Très bon, portions généreuses.',
      'Le meilleur du quartier, je recommande.',
      'Rapide et délicieux, merci !',
      'Super rapport qualité/prix.',
      'ممتاز، الأكل ساخن والتوصيل سريع',
      'طعم رائع، سأطلب مجددًا إن شاء الله',
      'Great food, will order again.',
      'Tout était parfait, bravo à toute l''équipe.']);
  elsif p_food = 3 then
    f_comment := pg_temp.demo_pick(array[
      'Correct sans plus.', 'Un peu cher pour la quantité.',
      'Bon mais un peu salé.', 'مقبول لكن يمكن أن يكون أفضل', '']);
  elsif p_food between 1 and 2 then
    f_comment := pg_temp.demo_pick(array[
      'Froid à l''arrivée, dommage.', 'Il manquait une boisson dans le sac.',
      'Ce n''est pas ce que j''ai commandé.', 'Portion vraiment petite pour le prix.',
      'الأكل وصل بارد', 'نقص في الطلب']);
  end if;

  if p_drv >= 4 and random() < 0.4 then
    d_comment := pg_temp.demo_pick(array['Livreur très aimable.', 'Rapide, merci !',
                                         'سائق محترم وسريع', 'Very polite driver.']);
  elsif p_drv between 1 and 3 then
    d_comment := pg_temp.demo_pick(array['Livraison en retard de 30 minutes.',
                                         'Il m''a appelé plusieurs fois.', 'تأخر كثيرًا', '']);
  end if;

  if p_reply and p_food > 0 then
    v_reply := case
      when p_food >= 4 then pg_temp.demo_pick(array[
        'Merci beaucoup, à très bientôt !', 'Merci pour votre confiance !',
        'شكرًا جزيلًا، نتشرف بخدمتكم دائمًا', 'Thank you! See you soon.',
        'Ravis que vous ayez apprécié, merci !'])
      else pg_temp.demo_pick(array[
        'Nous sommes désolés pour ce désagrément, nous allons corriger cela.',
        'Toutes nos excuses. Contactez-nous à votre prochaine commande.',
        'نعتذر عن هذا الخطأ وسنعمل على تحسين الخدمة'])
    end;
  end if;

  insert into public.order_ratings
    (order_id, restaurant_id, driver_id, customer_id, customer_label,
     food_stars, food_reasons, food_comment, food_rated_at,
     driver_stars, driver_reasons, driver_comment, driver_rated_at,
     reply, reply_at, created_at)
  values
    (p_order, p_rest, p_driver, p_customer, p_label,
     nullif(p_food, 0), f_reasons, f_comment, case when p_food > 0 then food_at end,
     nullif(p_drv, 0), d_reasons, d_comment, case when p_drv > 0 then drv_at end,
     v_reply, case when v_reply is not null then food_at + make_interval(mins => 60 + (random() * 300)::int) end,
     p_delivered);
end $$;

-- ---------- the demo ------------------------------------------------------------
do $$
declare
  v_client uuid;
  v_driver uuid;
  v_owner uuid;
  v_label text;
  r record;
  i integer;
  oid uuid;
  ts timestamptz;
  rate numeric;
  cust uuid;
  lbl text;
  names text[] := array['Karim B.', 'Amina T.', 'Yacine M.', 'Sarah K.', 'Nassim H.',
                        'Lina D.', 'Bilal Z.', 'Meriem A.', 'Walid S.', 'Inès R.',
                        'Rania F.', 'Samir O.'];
  R1 constant uuid := '11111111-1111-4111-8111-111111111111';
  R2 constant uuid := '22222222-2222-4222-8222-222222222222';
  R3 constant uuid := '33333333-3333-4333-8333-333333333333';
  o_a uuid; o_b uuid; o_c uuid; o_d uuid; o_f1 uuid; o_f2 uuid;
  has_push boolean;
begin
  select id into v_client from auth.users where lower(email) = 'client@gmail.com';
  select id into v_driver from auth.users where lower(email) = 'driver@gmail.com';
  select id into v_owner  from auth.users where lower(email) = 'restaurant@gmail.com';
  if v_client is null or v_driver is null then
    raise exception 'Demo accounts client@gmail.com / driver@gmail.com not found: run the demo accounts SQL first.';
  end if;
  if not exists (select 1 from public.drivers where id = v_driver) then
    raise exception 'The demo driver is not registered: run 2026-11-10b_demo_driver.sql first.';
  end if;
  if to_regclass('public.order_ratings') is null then
    raise exception 'Run 2026-11-20_ratings.sql first.';
  end if;
  if exists (select 1 from public.orders where notes = 'DEMO-RATINGS') then
    raise notice 'demo ratings already present, skipping';
    return;
  end if;

  -- The customer's short name, like the app does ("Amina B.").
  select case
           when btrim(coalesce(full_name, '')) = '' then 'Client'
           when position(' ' in btrim(full_name)) > 0 then
             split_part(btrim(full_name), ' ', 1) || ' '
             || upper(left(btrim(substr(btrim(full_name), position(' ' in btrim(full_name)))), 1)) || '.'
           else btrim(full_name) end
    into v_label from public.profiles where id = v_client;

  -- No "new order" alerts for demo rows; amounts are set by hand.
  has_push := exists (select 1 from pg_trigger
                       where tgname = 'orders_push' and tgrelid = 'public.orders'::regclass);
  if has_push then execute 'alter table public.orders disable trigger orders_push'; end if;
  alter table public.orders disable trigger orders_before_write;

  -- ---- ~50 delivered orders with ratings, 3 restaurants ------------------------
  for r in select x.id, coalesce(x.commission_rate, c.default_commission_rate) as rate,
                  case x.id when R1 then 20 when R2 then 16 else 14 end as n
             from public.restaurants x cross join public.app_config c
            where x.id in (R1, R2, R3) loop
    for i in 1..r.n loop
      ts := now() - make_interval(days => 2 + (random() * 26)::int,
                                  hours => (random() * 10)::int - 5);
      -- One in five of these orders is the demo customer's.
      cust := case when i % 5 = 0 then v_client end;
      lbl := case when cust is not null then v_label
                  else names[1 + floor(random() * cardinality(names))::int] end;
      oid := pg_temp.demo_order(r.id, cust, lbl, ts, v_driver, r.rate);
      perform pg_temp.demo_rating(
        oid, r.id, v_driver, cust, lbl, ts,
        case when random() < 0.92 then pg_temp.demo_stars() else 0 end,
        case when random() < 0.75 then pg_temp.demo_stars() else 0 end,
        random() < 0.6);
    end loop;
  end loop;

  -- A few low reviews with replies, so the complaints chart has data.
  -- (Already included by chance, this makes sure of it.)
  for i in 1..3 loop
    ts := now() - make_interval(days => 3 + i * 4);
    oid := pg_temp.demo_order(R1, null, names[i], ts, v_driver,
                              (select coalesce(commission_rate, 0.08) from public.restaurants where id = R1));
    perform pg_temp.demo_rating(oid, R1, v_driver, null, names[i], ts, 2, 3, true);
  end loop;

  rate := (select coalesce(commission_rate, (select default_commission_rate from public.app_config limit 1))
             from public.restaurants where id = R1);

  -- ---- flagged reviews for the admin -------------------------------------------
  ts := now() - interval '6 days';
  o_f1 := pg_temp.demo_order(R1, null, 'Sofia M.', ts, v_driver, rate);
  insert into public.order_ratings
    (order_id, restaurant_id, driver_id, customer_label, food_stars, food_comment,
     food_rated_at, driver_stars, driver_reasons, driver_comment, driver_rated_at,
     flagged_at, flag_reason, created_at)
  values
    (o_f1, R1, v_driver, 'Sofia M.', 1,
     'Le livreur m''a mal parlé, une honte !!! Je ne commanderai plus jamais.',
     ts + interval '3 hours', 1, array['rude'], 'Très impoli', ts + interval '10 minutes',
     now() - interval '5 hours',
     'Parle de la livraison et pas de la cuisine : ne concerne pas le restaurant.', ts);

  ts := now() - interval '12 days';
  o_f2 := pg_temp.demo_order(R1, null, 'Walid S.', ts, v_driver, rate);
  insert into public.order_ratings
    (order_id, restaurant_id, driver_id, customer_label, food_stars, food_reasons,
     food_comment, food_rated_at, driver_stars, driver_rated_at,
     flagged_at, flag_reason, flag_decision, created_at)
  values
    (o_f2, R1, v_driver, 'Walid S.', 2, array['small_portion'],
     'Trop cher pour ce que c''est.', ts + interval '4 hours', 5, ts + interval '5 minutes',
     now() - interval '10 days', 'Avis sur les prix, pas sur la qualité.', 'kept', ts);

  -- ---- the demo customer's four orders to try the screens ---------------------------
  -- A: delivered 2 h ago, nothing rated yet.
  o_a := pg_temp.demo_order(R1, v_client, v_label, now() - interval '2 hours', v_driver, rate);
  insert into public.order_ratings (order_id, restaurant_id, driver_id, customer_id, customer_label)
  values (o_a, R1, v_driver, v_client, v_label);

  -- B: delivered 3 days ago, driver already rated, food not yet.
  ts := now() - interval '3 days';
  o_b := pg_temp.demo_order(R2, v_client, v_label, ts, v_driver,
                            (select coalesce(commission_rate, 0.08) from public.restaurants where id = R2));
  insert into public.order_ratings
    (order_id, restaurant_id, driver_id, customer_id, customer_label,
     driver_stars, driver_comment, driver_rated_at)
  values (o_b, R2, v_driver, v_client, v_label, 5, 'Livreur au top !', ts + interval '10 minutes');

  -- C: delivered 70 min ago; both rated (still editable) and the restaurant answered.
  o_c := pg_temp.demo_order(R1, v_client, v_label, now() - interval '70 minutes', v_driver, rate);
  insert into public.order_ratings
    (order_id, restaurant_id, driver_id, customer_id, customer_label,
     food_stars, food_comment, food_rated_at, driver_stars, driver_rated_at,
     reply, reply_at)
  values
    (o_c, R1, v_driver, v_client, v_label,
     5, 'Super pizza, merci !', now() - interval '40 minutes',
     4, now() - interval '60 minutes',
     'Merci beaucoup, à très bientôt !', now() - interval '20 minutes');

  -- D: delivered 8 days ago, never rated: the 7 days are over.
  o_d := pg_temp.demo_order(R1, v_client, v_label, now() - interval '8 days', v_driver, rate);

  -- ---- private reports about the demo customer (admin "Avis" tab) -----------------------
  if v_owner is not null then
    insert into public.customer_reports
      (order_id, reporter_id, reporter_role, customer_id, customer_name,
       customer_phone, reason, note, status, created_at)
    values
      (o_d, v_owner, 'restaurant', v_client, v_label, '0550123456', 'fake_order',
       'Commande jamais récupérée, le téléphone sonne dans le vide.', 'open', now() - interval '7 days');
  end if;
  insert into public.customer_reports
    (order_id, reporter_id, reporter_role, customer_id, customer_name,
     customer_phone, reason, note, status, admin_note, handled_at, created_at)
  values
    (o_b, v_driver, 'driver', v_client, v_label, '0550123456', 'no_answer',
     'Impossible de joindre le client à l''arrivée.', 'open', '', null, now() - interval '2 days'),
    (o_a, v_driver, 'driver', v_client, v_label, '0550123456', 'wrong_address',
     'L''adresse indiquée était incorrecte.', 'warned', 'Premier avertissement envoyé.',
     now() - interval '1 day', now() - interval '2 hours'),
    (o_c, v_driver, 'driver', v_client, v_label, '0550123456', 'rude',
     'Client agressif au téléphone.', 'dismissed', 'Pas de suite, malentendu.',
     now() - interval '30 minutes', now() - interval '50 minutes');

  alter table public.orders enable trigger orders_before_write;
  if has_push then execute 'alter table public.orders enable trigger orders_push'; end if;

  raise notice 'demo ratings created';
end $$;
