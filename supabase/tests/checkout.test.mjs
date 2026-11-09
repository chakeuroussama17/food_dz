// Checkout: place_order, cancel_my_order, my_orders.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows, denied } from './helpers.mjs';

const A = 'aaaaaaaa-0000-4000-8000-00000000000a'; // customer
const B = 'bbbbbbbb-0000-4000-8000-00000000000b'; // other customer
const O = 'cccccccc-0000-4000-8000-00000000000c'; // restaurant owner
const PIZZA = '11111111-1111-4111-8111-111111111111';
const BURGER = '22222222-2222-4222-8222-222222222222';

let db;
let addrA; // A's address
let addrB; // B's address
let margherita; // 700 DA, PIZZA
let thon; // 900 DA, PIZZA
let smash; // 850 DA, BURGER

const place = (args) =>
  rows(
    db,
    `select * from place_order($1, $2::jsonb, $3, $4, $5, $6, $7)`,
    [
      args.restaurant ?? PIZZA,
      JSON.stringify(args.items ?? [{ id: margherita, qty: 2 }]),
      args.address ?? addrA,
      args.phone ?? '0550123456',
      args.notes ?? '',
      args.expected ?? null,
      args.ref ?? null,
    ],
  );

const asA = (fn) => as(db, 'authenticated', A, fn);

/** Moves an order on as the database owner (restaurant/driver come later). */
const setStatus = (id, s) => db.query(`update orders set status = $2 where id = $1`, [id, s]);

test.before(async () => {
  db = await freshDb([
    [A, 'a@test.dz', 'Amina'],
    [B, 'b@test.dz', 'Bilal'],
    [O, 'o@test.dz', 'Omar'],
  ]);
  await db.query(`update restaurants set is_open = true, is_active = true where id in ($1, $2)`, [PIZZA, BURGER]);
  const item = async (name) =>
    (await rows(db, `select id from menu_items where name = $1`, [name]))[0].id;
  margherita = await item('Pizza Margherita');
  thon = await item('Pizza Thon');
  smash = await item('Smash Burger');
  addrA = (await as(db, 'authenticated', A, () =>
    rows(db, `insert into addresses (label, address_text, area, lat, lng) values ('home', 'Rue Didouche 12', 'Alger Centre', 36.77, 3.06) returning id`)))[0].id;
  addrB = (await as(db, 'authenticated', B, () =>
    rows(db, `insert into addresses (label, address_text) values ('home', 'Rue B') returning id`)))[0].id;
  await as(db, 'authenticated', O, () =>
    db.query(`select register_restaurant('Chez Omar', '0550111222', 'Rue X', 'Alger')`));
});

test.afterEach(async () => {
  // Keep tests independent: no active orders left between tests.
  await db.query(`delete from orders`);
});

test('prices, fee and commission come from the database', async () => {
  const [o] = await asA(() =>
    place({ items: [{ id: margherita, qty: 2 }, { id: thon, qty: 1 }], notes: '  sans oignons ' }));
  assert.equal(o.food_total, 2 * 700 + 900);
  assert.equal(o.delivery_fee, 200);
  assert.equal(o.total, 2500);
  assert.match(o.code, /^[A-Z2-9]{6}$/);

  const [row] = await rows(db, `select * from orders where id = $1`, [o.id]);
  assert.equal(row.customer_id, A);
  assert.equal(row.status, 'placed');
  assert.equal(row.customer_name, 'Amina');
  assert.equal(row.address_text, 'Rue Didouche 12');
  assert.equal(row.area, 'Alger Centre');
  assert.equal(row.notes, 'sans oignons');
  assert.equal(Number(row.commission_rate), 0.08);
  assert.equal(row.commission_amount, null);

  const items = await rows(db, `select name, unit_price, quantity, line_total from order_items where order_id = $1 order by unit_price`, [o.id]);
  assert.deepEqual(items.map((i) => [i.name, i.unit_price, i.quantity, i.line_total]), [
    ['Pizza Margherita', 700, 2, 1400],
    ['Pizza Thon', 900, 1, 900],
  ]);

  // The status change is logged with the customer as actor.
  const [ev] = await rows(db, `select to_status, actor_id from order_events where order_id = $1`, [o.id]);
  assert.equal(ev.to_status, 'placed');
  assert.equal(ev.actor_id, A);
});

test('the same dish twice is merged; restaurant-specific rate is frozen', async () => {
  await db.query(`update restaurants set commission_rate = 0.1 where id = $1`, [PIZZA]);
  try {
    const [o] = await asA(() => place({ items: [{ id: margherita, qty: 1 }, { id: margherita, qty: 2 }] }));
    const items = await rows(db, `select quantity from order_items where order_id = $1`, [o.id]);
    assert.deepEqual(items.map((i) => i.quantity), [3]);
    // Changing the rate later doesn't change this order.
    await db.query(`update restaurants set commission_rate = 0.2 where id = $1`, [PIZZA]);
    await setStatus(o.id, 'accepted');
    await setStatus(o.id, 'ready');
    await setStatus(o.id, 'picked_up');
    await setStatus(o.id, 'delivered');
    const [row] = await rows(db, `select commission_rate, commission_amount from orders where id = $1`, [o.id]);
    assert.equal(Number(row.commission_rate), 0.1);
    assert.equal(row.commission_amount, 210);
  } finally {
    await db.query(`update restaurants set commission_rate = null where id = $1`, [PIZZA]);
  }
});

test('first order saves the phone on the profile', async () => {
  await db.query(`update profiles set phone = null where id = $1`, [A]);
  await asA(() => place({ phone: '0661234567' }));
  const [p] = await rows(db, `select phone from profiles where id = $1`, [A]);
  assert.equal(p.phone, '0661234567');
  // An existing phone isn't overwritten.
  await db.query(`delete from orders`);
  await asA(() => place({ phone: '0771234567' }));
  const [p2] = await rows(db, `select phone from profiles where id = $1`, [A]);
  assert.equal(p2.phone, '0661234567');
});

test('expected total protects against price changes', async () => {
  await asA(() => assert.rejects(place({ expected: 1599 }), /prices_changed/));
  const [o] = await asA(() => place({ expected: 1600 }));
  assert.equal(o.total, 1600);
});

test('a retried tap (same client_ref) creates one order only', async () => {
  const ref = '99999999-0000-4000-8000-000000000001';
  const [o1] = await asA(() => place({ ref }));
  const [o2] = await asA(() => place({ ref }));
  assert.equal(o1.id, o2.id);
  const [{ n }] = await rows(db, `select count(*)::int as n from orders`);
  assert.equal(n, 1);
});

test('refused: closed, inactive restaurant, unavailable or foreign dishes', async () => {
  await db.query(`update restaurants set is_open = false where id = $1`, [PIZZA]);
  await asA(() => assert.rejects(place({}), /restaurant_closed/));
  await db.query(`update restaurants set is_open = true, is_active = false where id = $1`, [PIZZA]);
  await asA(() => assert.rejects(place({}), /restaurant_unavailable/));
  await db.query(`update restaurants set is_active = true where id = $1`, [PIZZA]);

  await db.query(`update menu_items set is_available = false where id = $1`, [margherita]);
  await asA(() => assert.rejects(place({}), /item_unavailable/));
  await db.query(`update menu_items set is_available = true where id = $1`, [margherita]);

  // A burger can't be ordered from the pizzeria.
  await asA(() => assert.rejects(place({ items: [{ id: smash, qty: 1 }] }), /item_unavailable/));
  await asA(() => assert.rejects(place({ restaurant: '00000000-0000-4000-8000-000000000000' }), /restaurant_unavailable/));
});

test('refused: bad input', async () => {
  const bad = [
    [{ items: [] }, /invalid_items/],
    [{ items: [{ id: margherita, qty: 0 }] }, /invalid_items/],
    [{ items: [{ id: margherita, qty: 21 }] }, /invalid_items/],
    [{ items: [{ id: margherita, qty: 15 }, { id: margherita, qty: 10 }] }, /invalid_items/],
    [{ items: [{ id: 'not-a-uuid', qty: 1 }] }, /invalid_items/],
    [{ items: [{ id: margherita, qty: -1 }] }, /invalid_items/],
    [{ items: [{ id: margherita, qty: '1.5' }] }, /invalid_items/],
    [{ items: { id: margherita, qty: 1 } }, /invalid_items/],
    [{ items: Array.from({ length: 31 }, () => ({ id: margherita, qty: 1 })) }, /invalid_items/],
    [{ phone: '0123' }, /invalid_phone/],
    [{ phone: '0450123456' }, /invalid_phone/],
    [{ notes: 'x'.repeat(301) }, /invalid_notes/],
    [{ address: addrB }, /address_not_found/], // someone else's address
  ];
  for (const [args, err] of bad) {
    await asA(() => assert.rejects(place(args), err));
  }
  const [{ n }] = await rows(db, `select count(*)::int as n from orders`);
  assert.equal(n, 0);
});

test('refused: visitors, restaurant owners', async () => {
  await as(db, 'anon', null, () => denied(place({})));
  await as(db, 'authenticated', O, () => assert.rejects(place({}), /customers_only/));
});

test('limits: 3 active orders, 10 per hour', async () => {
  for (let i = 0; i < 3; i++) await asA(() => place({}));
  await asA(() => assert.rejects(place({}), /too_many_active_orders/));

  // Finished orders don't count as active, but count in the hourly limit.
  await db.query(`update orders set status = 'cancelled'`);
  for (let i = 0; i < 3; i++) await asA(() => place({}));
  await db.query(`update orders set status = 'cancelled' where status = 'placed'`);
  for (let i = 0; i < 3; i++) await asA(() => place({}));
  await db.query(`update orders set status = 'cancelled' where status = 'placed'`);
  await asA(() => place({})); // 10th
  await db.query(`update orders set status = 'cancelled' where status = 'placed'`);
  await asA(() => assert.rejects(place({}), /too_many_orders/));
});

test('customers can never write orders directly', async () => {
  const [o] = await asA(() => place({}));
  await asA(async () => {
    await denied(db.query(`update orders set food_total = 1 where id = $1`, [o.id]));
    await denied(db.query(`update orders set status = 'delivered' where id = $1`, [o.id]));
    await denied(db.query(`delete from orders where id = $1`, [o.id]));
    await denied(db.query(`insert into order_items (order_id, name, unit_price, quantity) values ($1, 'x', 1, 1)`, [o.id]));
  });
});

test('cancel: only my own order, only before the restaurant accepts', async () => {
  const [o] = await asA(() => place({}));
  await as(db, 'authenticated', B, () =>
    assert.rejects(db.query(`select cancel_my_order($1)`, [o.id]), /order_not_found/));
  await asA(() => db.query(`select cancel_my_order($1)`, [o.id]));
  const [row] = await rows(db, `select status, cancelled_at from orders where id = $1`, [o.id]);
  assert.equal(row.status, 'cancelled');
  assert.ok(row.cancelled_at);

  const [o2] = await asA(() => place({}));
  await setStatus(o2.id, 'accepted');
  await asA(() => assert.rejects(db.query(`select cancel_my_order($1)`, [o2.id]), /cannot_cancel/));
  await as(db, 'anon', null, () => denied(db.query(`select cancel_my_order($1)`, [o2.id])));
});

test('my_orders: only mine, with restaurant and items, even after deactivation', async () => {
  const [o] = await asA(() => place({ items: [{ id: margherita, qty: 2 }] }));
  await as(db, 'authenticated', B, () => place({ address: addrB }));

  const mine = await asA(() => rows(db, `select * from my_orders()`));
  assert.equal(mine.length, 1);
  assert.equal(mine[0].id, o.id);
  assert.equal(mine[0].restaurant_name, 'Pizzeria El Bahdja');
  assert.deepEqual(mine[0].items, [
    { name: 'Pizza Margherita', unit_price: 700, quantity: 2, line_total: 1400 },
  ]);

  const one = await asA(() => rows(db, `select id from my_orders($1)`, [o.id]));
  assert.equal(one.length, 1);
  const notMine = await as(db, 'authenticated', B, () => rows(db, `select id from my_orders($1)`, [o.id]));
  assert.equal(notMine.length, 0);

  await db.query(`update restaurants set is_active = false where id = $1`, [PIZZA]);
  const still = await asA(() => rows(db, `select restaurant_name from my_orders()`));
  assert.equal(still[0].restaurant_name, 'Pizzeria El Bahdja');
  await db.query(`update restaurants set is_active = true where id = $1`, [PIZZA]);

  await as(db, 'anon', null, () => denied(db.query(`select * from my_orders()`)));
});

test('RLS: customers read their own orders and items only', async () => {
  const [o] = await asA(() => place({}));
  const seen = await as(db, 'authenticated', B, () => rows(db, `select id from orders`));
  assert.equal(seen.length, 0);
  const items = await as(db, 'authenticated', B, () => rows(db, `select id from order_items`));
  assert.equal(items.length, 0);
  const mine = await asA(() => rows(db, `select id from orders`));
  assert.deepEqual(mine.map((r) => r.id), [o.id]);
});
