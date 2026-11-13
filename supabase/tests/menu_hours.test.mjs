// Portal step 2: dish options, bulk edits, opening hours and holidays.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows } from './helpers.mjs';

const C = 'aaaaaaaa-0000-4000-8000-00000000000a'; // customer
const O = 'cccccccc-0000-4000-8000-00000000000c'; // owner
const S = '99999999-0000-4000-8000-000000000009'; // staff
const X = 'dddddddd-0000-4000-8000-00000000000d'; // other owner
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let addr;
let margherita;
let marPrice;
let size; // group id
let sizes; // {Petite, Grande} -> choice id
let extras;
let cheese;

const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));
const q = (u, sql, params) => asU(u, () => rows(db, sql, params));

function place(items, expected) {
  return q(C, `select * from place_order($1, $2::jsonb, $3, '0550123456', '', $4)`, [
    PIZZA, JSON.stringify(items), addr, expected ?? null,
  ]);
}

test.before(async () => {
  db = await freshDb([
    [C, 'c@test.dz', 'Amina'],
    [O, 'o@test.dz', 'Omar'],
    [S, 's@test.dz', 'Samia'],
    [X, 'x@test.dz', 'Xavier'],
  ]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  await call(O, `select owner_add_member($1, 's@test.dz', 'staff')`, [PIZZA]);
  await call(X, `select register_restaurant('Chez X', '0550999888', 'Rue Y', 'Oran')`);
  [{ id: margherita, price: marPrice }] = await rows(db, `select id, price from menu_items where name = 'Pizza Margherita'`);
  addr = (await q(C, `insert into addresses (label, address_text) values ('home', 'Rue 1') returning id`))[0].id;
});

async function groups() {
  return q(O, `select g.id, g.name, g.min_select, g.max_select,
                      (select json_agg(json_build_object('id', c.id, 'name', c.name, 'price', c.price) order by c.sort_order)
                         from option_choices c where c.group_id = g.id) as choices
                 from option_groups g where g.restaurant_id = $1 order by g.sort_order`, [PIZZA]);
}

test('managers create option groups with choices, linked to dishes', async () => {
  const [{ id }] = await q(O, `select owner_save_option_group($1, $2::jsonb) as id`, [PIZZA, JSON.stringify({
    name: 'Taille', min: 1, max: 1,
    choices: [{ name: 'Petite', price: 0 }, { name: 'Grande', price: 300 }],
    item_ids: [margherita],
  })]);
  size = id;
  const [{ id: e }] = await q(O, `select owner_save_option_group($1, $2::jsonb) as id`, [PIZZA, JSON.stringify({
    name: 'Suppléments', min: 0, max: 2,
    choices: [{ name: 'Fromage', price: 100 }, { name: 'Olives', price: 50 }, { name: 'Oeuf', price: 80 }],
    item_ids: [margherita],
  })]);
  extras = e;
  const g = await groups();
  sizes = Object.fromEntries(g[0].choices.map((c) => [c.name, c.id]));
  cheese = g[1].choices[0].id;
  assert.deepEqual(g.map((x) => [x.name, x.min_select, x.max_select]), [['Taille', 1, 1], ['Suppléments', 0, 2]]);

  // Customers (even visitors) see them on the menu.
  const seen = await as(db, 'anon', null, () => rows(db,
    `select g.name from menu_item_groups mig join option_groups g on g.id = mig.group_id where mig.menu_item_id = $1`, [margherita]));
  assert.equal(seen.length, 2);
});

test('option groups: checked input, managers only, own dishes only', async () => {
  const bad = [
    { name: '', choices: [{ name: 'A' }] },
    { name: 'X', min: 2, max: 1, choices: [{ name: 'A' }, { name: 'B' }] },
    { name: 'X', min: 2, max: 2, choices: [{ name: 'A' }] },
    { name: 'X', choices: [] },
    { name: 'X', choices: [{ name: 'A', price: -5 }] },
  ];
  for (const g of bad) {
    await asU(O, () => assert.rejects(db.query(`select owner_save_option_group($1, $2::jsonb)`, [PIZZA, JSON.stringify(g)]), /invalid_group/));
  }
  const [{ id: other }] = await q(X, `insert into menu_items (restaurant_id, name, price) select id, 'Dish X', 500 from restaurants where name = 'Chez X' returning id`);
  await asU(O, () => assert.rejects(db.query(`select owner_save_option_group($1, $2::jsonb)`,
    [PIZZA, JSON.stringify({ name: 'X', choices: [{ name: 'A' }], item_ids: [other] })]), /invalid_group/));
  await asU(S, () => assert.rejects(db.query(`select owner_save_option_group($1, $2::jsonb)`,
    [PIZZA, JSON.stringify({ name: 'X', choices: [{ name: 'A' }] })]), /not_allowed/));
  await asU(X, () => assert.rejects(db.query(`select owner_delete_option_group($1)`, [size]), /not_found/));
});

test('order with options: priced here, rules enforced, shown in the line name', async () => {
  const fee = (await rows(db, `select delivery_fee from app_config`))[0].delivery_fee;
  // Large + cheese: price + 300 + 100.
  const unit = marPrice + 400;
  const [o] = await place([{ id: margherita, qty: 2, options: [sizes.Grande, cheese] }], unit * 2 + fee);
  assert.equal(o.food_total, unit * 2);
  const [line] = await rows(db, `select name, unit_price, options from order_items where order_id = $1`, [o.id]);
  assert.equal(line.name, 'Pizza Margherita (Grande, Fromage)');
  assert.equal(line.unit_price, unit);
  assert.deepEqual(line.options.map((x) => x.name), ['Grande', 'Fromage']);

  // Two lines of the same dish with different options.
  const [o2] = await place([
    { id: margherita, qty: 1, options: [sizes.Petite] },
    { id: margherita, qty: 1, options: [sizes.Grande] },
  ]);
  assert.equal(o2.food_total, marPrice * 2 + 300);

  // Required group missing, too many extras, duplicates, a choice of nothing.
  for (const opts of [[], [sizes.Petite, sizes.Grande], [sizes.Petite, cheese, cheese],
                      [sizes.Petite, ...Object.values(sizes).slice(0, 0), cheese,
                       (await groups())[1].choices[1].id, (await groups())[1].choices[2].id],
                      [sizes.Petite, '00000000-0000-4000-8000-000000000000']]) {
    await asU(C, () => assert.rejects(
      db.query(`select * from place_order($1, $2::jsonb, $3, '0550123456')`,
        [PIZZA, JSON.stringify([{ id: margherita, qty: 1, options: opts }]), addr]),
      /options_invalid/), JSON.stringify(opts));
  }
  // Malformed options.
  await asU(C, () => assert.rejects(db.query(`select * from place_order($1, $2::jsonb, $3, '0550123456')`,
    [PIZZA, JSON.stringify([{ id: margherita, qty: 1, options: 'x' }]), addr]), /invalid_items/));
  for (const id of [o.id, o2.id]) await call(O, `select owner_set_order_status($1, 'rejected', 'Test')`, [id]);
});

test('a choice out of stock, or a group edited, refuses stale carts', async () => {
  await call(O, `select owner_set_choice_available($1, false)`, [cheese]);
  await asU(C, () => assert.rejects(
    db.query(`select * from place_order($1, $2::jsonb, $3, '0550123456')`,
      [PIZZA, JSON.stringify([{ id: margherita, qty: 1, options: [sizes.Petite, cheese] }]), addr]),
    /options_invalid/));
  await call(O, `select owner_set_choice_available($1, true)`, [cheese]);

  // Editing keeps the ids of choices sent back; others are removed.
  const g = (await groups())[0];
  await call(O, `select owner_save_option_group($1, $2::jsonb)`, [PIZZA, JSON.stringify({
    id: g.id, name: 'Taille', min: 1, max: 1,
    choices: [{ id: sizes.Grande, name: 'Grande', price: 350 }, { name: 'XL', price: 600 }],
    item_ids: [margherita],
  })]);
  const after = (await groups())[0].choices;
  assert.deepEqual(after.map((c) => c.name), ['Grande', 'XL']);
  assert.equal(after[0].id, sizes.Grande);
  assert.equal(after[0].price, 350);
  await asU(C, () => assert.rejects(
    db.query(`select * from place_order($1, $2::jsonb, $3, '0550123456')`,
      [PIZZA, JSON.stringify([{ id: margherita, qty: 1, options: [sizes.Petite] }]), addr]),
    /options_invalid/));

  // Unlinking the groups from the dish: plain orders work again.
  await call(O, `select owner_set_item_groups($1, '{}')`, [margherita]);
  const [o] = await place([{ id: margherita, qty: 1 }]);
  await call(O, `select owner_set_order_status($1, 'rejected', 'Test')`, [o.id]);
  await call(O, `select owner_set_item_groups($1, $2::uuid[])`, [margherita, [size, extras]]);
  await call(O, `select owner_delete_option_group($1)`, [extras]);
  assert.equal((await groups()).length, 1);
});

test('bulk edits: hide/show, category, prices rounded and kept in range, delete', async () => {
  const ids = (await rows(db, `select id from menu_items where restaurant_id = $1`, [PIZZA])).map((r) => r.id);
  const before = await rows(db, `select id, price from menu_items where restaurant_id = $1`, [PIZZA]);

  assert.equal((await q(O, `select owner_bulk_items($1, $2::uuid[], 'hide') as n`, [PIZZA, ids]))[0].n, ids.length);
  assert.ok((await rows(db, `select bool_and(not is_available) ok from menu_items where restaurant_id = $1`, [PIZZA]))[0].ok);
  await call(O, `select owner_bulk_items($1, $2::uuid[], 'show')`, [PIZZA, ids]);

  await call(O, `select owner_bulk_items($1, $2::uuid[], 'price_percent', 10)`, [PIZZA, ids]);
  const after = await rows(db, `select id, price from menu_items where restaurant_id = $1`, [PIZZA]);
  for (const b of before) {
    const a = after.find((x) => x.id === b.id);
    assert.equal(a.price, Math.max(10, Math.round(b.price * 1.1 / 10) * 10));
    assert.equal(a.price % 10, 0);
  }
  await call(O, `select owner_bulk_items($1, $2::uuid[], 'price_add', -1000000)`, [PIZZA, ids])
    .catch((e) => assert.match(e.message, /invalid_action/));
  await call(O, `select owner_bulk_items($1, $2::uuid[], 'price_add', -99999)`, [PIZZA, [ids[0]]]);
  assert.equal((await rows(db, `select price from menu_items where id = $1`, [ids[0]]))[0].price, 10);

  const [{ id: cat }] = await rows(db, `select id from categories limit 1`);
  await call(O, `select owner_bulk_items($1, $2::uuid[], 'category', null, $3)`, [PIZZA, [ids[0]], cat]);
  assert.equal((await rows(db, `select category_id from menu_items where id = $1`, [ids[0]]))[0].category_id, cat);

  // Staff and other owners can't; dishes of another restaurant are untouched.
  await asU(S, () => assert.rejects(db.query(`select owner_bulk_items($1, $2::uuid[], 'hide')`, [PIZZA, ids]), /not_allowed/));
  const xItem = (await rows(db, `select m.id from menu_items m join restaurants r on r.id = m.restaurant_id where r.name = 'Chez X'`))[0].id;
  assert.equal((await q(O, `select owner_bulk_items($1, $2::uuid[], 'delete') as n`, [PIZZA, [xItem]]))[0].n, 0);
  await asU(O, () => assert.rejects(db.query(`select owner_bulk_items($1, $2::uuid[], 'paint')`, [PIZZA, ids]), /invalid_action/));

  // Price back for the next tests.
  await db.query(`update menu_items set price = $2 where id = $1`, [ids[0], before.find((b) => b.id === ids[0]).price]);
});

// Algiers is UTC+1 all year.
const at = (iso) => `'${iso}+01'::timestamptz`;
const open = async (iso) => (await rows(db, `select hours_open_at($1, ${at(iso)}) ok`, [PIZZA]))[0].ok;

test('hours: weekly slots, after midnight, holidays and special hours', async () => {
  // No hours: always open.
  assert.equal(await open('2026-11-16 04:00'), true);

  // Saturday (0) 11:00-15:00 and 18:00-02:00; Monday 12:00-23:00.
  await call(O, `select owner_set_hours($1, $2::jsonb)`, [PIZZA, JSON.stringify([
    { weekday: 0, opens: '11:00', closes: '15:00' },
    { weekday: 0, opens: '18:00', closes: '02:00' },
    { weekday: 2, opens: '12:00', closes: '23:00' },
  ])]);
  // 2026-11-14 is a Saturday, 2026-11-16 a Monday.
  assert.equal(await open('2026-11-14 10:59'), false);
  assert.equal(await open('2026-11-14 11:00'), true);
  assert.equal(await open('2026-11-14 16:00'), false);
  assert.equal(await open('2026-11-14 23:30'), true);
  assert.equal(await open('2026-11-15 01:30'), true); // Sunday night, still Saturday's slot
  assert.equal(await open('2026-11-15 02:00'), false);
  assert.equal(await open('2026-11-15 13:00'), false); // Sunday: no hours
  assert.equal(await open('2026-11-16 22:59'), true);

  // Holiday on a Monday, special hours on a Sunday.
  const today = (await rows(db, `select (now() at time zone 'Africa/Algiers')::date d`))[0].d;
  await db.query(`insert into special_days (restaurant_id, day, closed) values ($1, '2026-11-16', true)`, [PIZZA]);
  await db.query(`insert into special_days (restaurant_id, day, closed, opens, closes, note) values ($1, '2026-11-15', false, '10:00', '12:00', 'Mawlid')`, [PIZZA]);
  assert.equal(await open('2026-11-16 13:00'), false);
  assert.equal(await open('2026-11-15 11:00'), true);
  assert.equal(await open('2026-11-15 01:30'), true); // Saturday night still runs
  await db.query(`delete from special_days where restaurant_id = $1`, [PIZZA]);
  assert.ok(today);
});

test('hours: input checked, managers only', async () => {
  for (const h of [
    [{ weekday: 7, opens: '10:00', closes: '12:00' }],
    [{ weekday: 1, opens: '25:00', closes: '12:00' }],
    [{ weekday: 1, opens: '10:00', closes: '10:00' }],
    Array.from({ length: 4 }, () => ({ weekday: 1, opens: '10:00', closes: '12:00' })),
  ]) {
    await asU(O, () => assert.rejects(db.query(`select owner_set_hours($1, $2::jsonb)`, [PIZZA, JSON.stringify(h)]), /invalid_hours/));
  }
  await asU(S, () => assert.rejects(db.query(`select owner_set_hours($1, '[]'::jsonb)`, [PIZZA]), /not_allowed/));
  await asU(O, () => assert.rejects(db.query(`select owner_set_special_day($1, '2020-01-01', true)`, [PIZZA]), /invalid_day/));
  await asU(O, () => assert.rejects(db.query(`select owner_set_special_day($1, current_date + 3, false)`, [PIZZA]), /invalid_day/));
  // Staff can read the hours (the app shows them).
  const h = (await q(S, `select owner_hours($1) h`, [PIZZA]))[0].h;
  assert.equal(h.hours.length, 3);
});

test('closed by the hours: no orders, customers see it, next opening given', async () => {
  // Holiday today: closed for customers even with the switch on.
  await call(O, `select owner_set_special_day($1, (now() at time zone 'Africa/Algiers')::date, true, null, null, 'Aïd')`, [PIZZA]);
  await asU(C, () => assert.rejects(
    db.query(`select * from place_order($1, $2::jsonb, $3, '0550123456')`,
      [PIZZA, JSON.stringify([{ id: margherita, qty: 1, options: [sizes.Grande] }]), addr]),
    /restaurant_closed/));
  const [card] = await as(db, 'anon', null, () => rows(db,
    `select is_open, next_open_at from list_restaurants() where id = $1`, [PIZZA]));
  assert.equal(card.is_open, false);
  // Weekly hours exist (Saturday / Monday), so the next opening is known.
  assert.ok(card.next_open_at);
  const [direct] = await as(db, 'anon', null, () => rows(db,
    `select * from restaurant_status($1)`, [PIZZA]));
  assert.equal(direct.open_now, false);
  assert.ok(direct.next_open_at);
  const mine = (await q(O, `select is_open, open_now from my_restaurants() where id = $1`, [PIZZA]))[0];
  assert.deepEqual([mine.is_open, mine.open_now], [true, false]);

  // Remove the holiday and the weekly hours: open again.
  await call(O, `select owner_delete_special_day($1, (now() at time zone 'Africa/Algiers')::date)`, [PIZZA]);
  await call(O, `select owner_set_hours($1, '[]'::jsonb)`, [PIZZA]);
  const [o] = await place([{ id: margherita, qty: 1, options: [sizes.Grande] }]);
  assert.ok(o.id);
});
