-- Demo catalogue (Algiers). Safe to re-run: uses fixed ids + upserts.
-- Photos are empty on purpose; the app shows the design's grey placeholder.

insert into public.categories (slug, name_ar, name_fr, name_en, sort_order) values
  ('burger',      'برغر',        'Burger',        'Burger',       1),
  ('pizza',       'بيتزا',       'Pizza',         'Pizza',        2),
  ('sandwich',    'سندويتش',     'Sandwich',      'Sandwich',     3),
  ('tacos',       'تاكوس',       'Tacos',         'Tacos',        4),
  ('chawarma',    'شاورما',      'Chawarma',      'Shawarma',     5),
  ('traditionnel','أطباق تقليدية','Traditionnel',  'Traditional',  6),
  ('dessert',     'حلويات',      'Desserts',      'Desserts',     7),
  ('boisson',     'مشروبات',     'Boissons',      'Drinks',       8)
on conflict (slug) do update
  set name_ar = excluded.name_ar, name_fr = excluded.name_fr,
      name_en = excluded.name_en, sort_order = excluded.sort_order;

insert into public.restaurants
  (id, slug, name, description, phone, address, area, lat, lng, prep_minutes, is_active, is_open)
values
  ('11111111-1111-4111-8111-111111111111', 'pizzeria-el-bahdja', 'Pizzeria El Bahdja',
   'Pizzas au feu de bois, tacos et sandwichs.', '0550000001',
   'Cité 1200 logements, Bab Ezzouar', 'Bab Ezzouar', 36.7213, 3.1834, 25, true, true),
  ('22222222-2222-4222-8222-222222222222', 'burger-house-hydra', 'Burger House',
   'Burgers smash, frites maison et milkshakes.', '0550000002',
   'Rue Ahmed Ouaked, Hydra', 'Hydra', 36.7422, 3.0350, 20, true, true),
  ('33333333-3333-4333-8333-333333333333', 'dar-lgharbi', 'Dar Lgharbi',
   'Couscous, chorba et plats traditionnels comme à la maison.', '0550000003',
   'Boulevard Krim Belkacem, Kouba', 'Kouba', 36.7280, 3.0850, 35, true, false)
on conflict (id) do update
  set name = excluded.name, description = excluded.description,
      area = excluded.area, is_active = excluded.is_active, is_open = excluded.is_open;

-- Menu items: (restaurant, category slug, name, description, price, order)
with data (rid, cat, name, descr, price, ord) as (values
  ('11111111-1111-4111-8111-111111111111'::uuid, 'pizza',    'Pizza Margherita',   'Sauce tomate, mozzarella, basilic.',            700, 1),
  ('11111111-1111-4111-8111-111111111111'::uuid, 'pizza',    'Pizza Thon',         'Thon, olives, oignons, fromage.',               900, 2),
  ('11111111-1111-4111-8111-111111111111'::uuid, 'pizza',    'Pizza 4 Fromages',   'Mozzarella, cheddar, gouda, camembert.',       1200, 3),
  ('11111111-1111-4111-8111-111111111111'::uuid, 'tacos',    'Tacos Poulet XL',    'Poulet mariné, frites, sauce fromagère.',       650, 4),
  ('11111111-1111-4111-8111-111111111111'::uuid, 'sandwich', 'Sandwich Kebab',     'Viande hachée, salade, sauce blanche.',         450, 5),
  ('11111111-1111-4111-8111-111111111111'::uuid, 'boisson',  'Hamoud Boualem 1L',  'Boisson gazeuse.',                              150, 6),
  ('22222222-2222-4222-8222-222222222222'::uuid, 'burger',   'Smash Burger',       'Double steak, cheddar, oignons caramélisés.',   850, 1),
  ('22222222-2222-4222-8222-222222222222'::uuid, 'burger',   'Chicken Burger',     'Poulet croustillant, salade, sauce maison.',    750, 2),
  ('22222222-2222-4222-8222-222222222222'::uuid, 'burger',   'Burger Royal',       'Steak 180 g, œuf, cheddar, viande fumée.',     1300, 3),
  ('22222222-2222-4222-8222-222222222222'::uuid, 'sandwich', 'Frites Maison',      'Grande portion.',                               250, 4),
  ('22222222-2222-4222-8222-222222222222'::uuid, 'dessert',  'Milkshake Oreo',     'Glace vanille, Oreo.',                          400, 5),
  ('33333333-3333-4333-8333-333333333333'::uuid, 'traditionnel', 'Couscous Poulet', 'Semoule, légumes, poulet.',                   1000, 1),
  ('33333333-3333-4333-8333-333333333333'::uuid, 'traditionnel', 'Chorba Frik',     'Soupe traditionnelle au frik.',                350, 2),
  ('33333333-3333-4333-8333-333333333333'::uuid, 'traditionnel', 'Rechta',          'Pâtes fraîches, sauce blanche, poulet.',       900, 3),
  ('33333333-3333-4333-8333-333333333333'::uuid, 'chawarma',     'Chawarma Viande', 'Pain libanais, viande, crudités.',             500, 4),
  ('33333333-3333-4333-8333-333333333333'::uuid, 'dessert',      'Kalb el Louz',    'Gâteau de semoule aux amandes.',               200, 5)
)
insert into public.menu_items (id, restaurant_id, category_id, name, description, price, sort_order)
select md5(d.rid::text || d.name)::uuid, d.rid, c.id, d.name, d.descr, d.price, d.ord
  from data d join public.categories c on c.slug = d.cat
on conflict (id) do update
  set name = excluded.name, description = excluded.description,
      price = excluded.price, category_id = excluded.category_id,
      sort_order = excluded.sort_order;
