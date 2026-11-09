// Drivers: registration, approval, online, dispatch, pickup, delivery.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows, denied } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a'; // customer
const O = 'cccccccc-0000-4000-8000-00000000000c'; // pizzeria owner
const D1 = 'd1d1d1d1-0000-4000-8000-0000000000d1';
const D2 = 'd2d2d2d2-0000-4000-8000-0000000000d2';
const D3 = 'd3d3d3d3-0000-4000-8000-0000000000d3'; // never approved
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let addr;
let margherita;

const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));

async function newOrder({ accept = true, ready = false } = {}) {
  const [o] = await asU(C, () =>
    rows(db, `select * from place_order($1, $2::jsonb, $3, '0550123456')`, [
      PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr,
    ]));
  if (accept) await call(O, `select owner_set_order_status($1, 'accepted')`, [o.id]);
  if (ready) await call(O, `select owner_set_order_status($1, 'ready')`, [o.id]);
  return o.id;
}

const claim = (d, id) => call(d, `select driver_claim_order($1)`, [id]);
const move = (d, id, s) => call(d, `select driver_set_order_status($1, $2)`, [id, s]);
const order = async (id) => (await rows(db, `select * from orders where id = $1`, [id]))[0];

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [C, 'c@test.dz', 'Amina'],
    [O, 'o@test.dz', 'Omar'],
    [D1, 'd1@test.dz', 'Rachid'],
    [D2, 'd2@test.dz', 'Sofiane'],
    [D3, 'd3@test.dz', 'Nouveau'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  addr = (await asU(C, () =>
    rows(db, `insert into addresses (label, address_text, area, lat, lng) values ('home', 'Rue Didouche 12', 'Alger Centre', 36.77, 3.06) returning id`)))[0].id;

  // Three drivers register; the admin approves two of them.
  await call(D1, `select register_driver('0661000001', 'moto')`);
  await call(D2, `select register_driver('0661000002', 'car')`);
  await call(D3, `select register_driver('0661000003', 'bike')`);
  await call(ADMIN, `select admin_set_driver_approved($1, true)`, [D1]);
  await call(ADMIN, `select admin_set_driver_approved($1, true)`, [D2]);
});

test.beforeEach(async () => {
  await db.query(`delete from orders`);
  await db.query(`update drivers set is_online = true where is_approved`);
});

// ---------- registration & approval ----------
test('register: role driver, not approved, input checked, once only', async () => {
  const [p] = await rows(db, `select role, phone from profiles where id = $1`, [D3]);
  assert.equal(p.role, 'driver');
  assert.equal(p.phone, '0661000003');
  const [me] = await asU(D3, () => rows(db, `select * from my_driver()`));
  assert.equal(me.full_name, 'Nouveau');
  assert.equal(me.vehicle, 'bike');
  assert.equal(me.is_approved, false);

  await asU(D3, () => assert.rejects(db.query(`select register_driver('0661000003', 'moto')`), /account_has_role/));
  await asU(O, () => assert.rejects(db.query(`select register_driver('0661000004', 'moto')`), /account_has_role/));
  await asU(C, () => assert.rejects(db.query(`select register_driver('0123', 'moto')`), /invalid_phone/));
  await asU(C, () => assert.rejects(db.query(`select register_driver('0661000005', 'plane')`), /invalid_vehicle/));
  await as(db, 'anon', null, () => denied(db.query(`select register_driver('0661000005', 'moto')`)));
});

test('only approved drivers can go online; nobody approves themselves', async () => {
  await asU(D3, () => assert.rejects(db.query(`select driver_set_online(true)`), /not_approved/));
  await asU(D3, () => db.query(`select driver_set_online(false)`)); // allowed
  await asU(D3, () => denied(db.query(`update drivers set is_approved = true where id = $1`, [D3])));
  await asU(D3, () => assert.rejects(db.query(`select admin_set_driver_approved($1, true)`, [D3]), /admin only/));
  await asU(C, () => assert.rejects(db.query(`select driver_set_online(true)`), /not_a_driver/));

  // Admin deactivating a driver also takes them offline.
  await call(ADMIN, `select admin_set_driver_approved($1, false)`, [D2]);
  const [d] = await rows(db, `select is_approved, is_online from drivers where id = $1`, [D2]);
  assert.deepEqual([d.is_approved, d.is_online], [false, false]);
  await call(ADMIN, `select admin_set_driver_approved($1, true)`, [D2]);
});

test('admin lists drivers with email, deliveries and current order', async () => {
  const list = await asU(ADMIN, () => rows(db, `select * from admin_list_drivers()`));
  assert.equal(list.length, 3);
  assert.equal(list[0].email, 'd3@test.dz'); // to approve first
  await asU(C, () => assert.rejects(db.query(`select * from admin_list_drivers()`), /admin only/));
});

// ---------- dispatch ----------
test('available: accepted/ready orders without driver, only for online approved drivers', async () => {
  const placedOnly = await newOrder({ accept: false });
  const accepted = await newOrder();
  const ready = await newOrder({ ready: true });

  const list = await asU(D1, () => rows(db, `select * from driver_available_orders()`));
  assert.deepEqual(list.map((r) => r.id), [ready, accepted]); // ready first
  assert.ok(!list.some((r) => r.id === placedOnly));
  assert.equal(list[0].restaurant_name, 'Pizzeria El Bahdja');
  assert.equal(list[0].area, 'Alger Centre');
  assert.equal(list[0].delivery_fee, 200);
  assert.equal(list[0].item_count, 1);
  // No customer phone / name / exact address before taking it.
  assert.ok(!('customer_phone' in list[0]));
  assert.ok(!('address_text' in list[0]));

  await call(D1, `select driver_set_online(false)`);
  assert.equal((await asU(D1, () => rows(db, `select id from driver_available_orders()`))).length, 0);
  assert.equal((await asU(D3, () => rows(db, `select id from driver_available_orders()`))).length, 0);
  assert.equal((await asU(C, () => rows(db, `select id from driver_available_orders()`))).length, 0);
  // Drivers can't read unassigned orders from the table either.
  assert.equal((await asU(D2, () => rows(db, `select id from orders`))).length, 0);
});

test('first tap wins; the other driver gets already_taken', async () => {
  const id = await newOrder();
  await claim(D1, id);
  await asU(D2, () => assert.rejects(db.query(`select driver_claim_order($1)`, [id]), /already_taken/));
  assert.equal((await order(id)).driver_id, D1);
  // Gone from the list for everyone.
  assert.equal((await asU(D2, () => rows(db, `select id from driver_available_orders()`))).length, 0);
  // Now D1 reads it (table + RLS for Realtime), D2 doesn't.
  assert.equal((await asU(D1, () => rows(db, `select id from orders`))).length, 1);
  assert.equal((await asU(D2, () => rows(db, `select id from orders`))).length, 0);
});

test('one delivery at a time; offline / unapproved / placed orders refused', async () => {
  const a = await newOrder();
  const b = await newOrder();
  await claim(D1, a);
  await asU(D1, () => assert.rejects(db.query(`select driver_claim_order($1)`, [b]), /busy/));

  await call(D2, `select driver_set_online(false)`);
  await asU(D2, () => assert.rejects(db.query(`select driver_claim_order($1)`, [b]), /not_online/));
  await asU(D3, () => assert.rejects(db.query(`select driver_claim_order($1)`, [b]), /not_approved/));
  await asU(C, () => assert.rejects(db.query(`select driver_claim_order($1)`, [b]), /not_a_driver/));

  const placed = await newOrder({ accept: false });
  await call(D2, `select driver_set_online(true)`);
  await asU(D2, () => assert.rejects(db.query(`select driver_claim_order($1)`, [placed]), /already_taken/));
});

test('full delivery: pickup after ready, delivered, commission computed', async () => {
  const id = await newOrder();
  await claim(D1, id);
  // Can't pick up before the restaurant marks it ready.
  await asU(D1, () => assert.rejects(db.query(`select driver_set_order_status($1, 'picked_up')`, [id]), /not_allowed/));
  await call(O, `select owner_set_order_status($1, 'ready')`, [id]);
  await asU(D1, () => assert.rejects(db.query(`select driver_set_order_status($1, 'delivered')`, [id]), /not_allowed/));
  await move(D1, id, 'picked_up');
  // Can't give it back once picked up; restaurant can't cancel it now.
  await asU(D1, () => assert.rejects(db.query(`select driver_release_order($1)`, [id]), /not_allowed/));
  await asU(O, () => assert.rejects(db.query(`select owner_set_order_status($1, 'cancelled', 'x')`, [id]), /not_allowed/));
  // Delivering now needs the photo (see cash.test.mjs for the details).
  await asU(D1, () => assert.rejects(db.query(`select driver_set_order_status($1, 'delivered')`, [id]), /not_allowed/));
  await asU(D1, () => db.query(`insert into storage.objects (bucket_id, name, owner) values ('delivery-proofs', $1, $2)`, [`${id}/p.jpg`, D1]));
  await call(D1, `select driver_complete_delivery($1, $2)`, [id, `${id}/p.jpg`]);

  const o = await order(id);
  assert.equal(o.status, 'delivered');
  assert.ok(o.picked_up_at && o.delivered_at);
  assert.equal(o.commission_amount, 56); // 700 × 8 %
  const ev = await rows(db, `select to_status, actor_id from order_events where order_id = $1 order by id`, [id]);
  assert.deepEqual(ev.map((e) => e.to_status), ['placed', 'accepted', 'ready', 'picked_up', 'delivered']);
  assert.equal(ev[3].actor_id, D1);

  // Driver history.
  const hist = await asU(D1, () => rows(db, `select id, status from driver_orders(false)`));
  assert.deepEqual(hist.map((h) => h.status), ['delivered']);
  // And D1 is free again.
  const next = await newOrder();
  await claim(D1, next);
});

test('driver sees full details only for their order; others refused', async () => {
  const id = await newOrder({ ready: true });
  await claim(D1, id);
  const [o] = await asU(D1, () => rows(db, `select * from driver_orders()`));
  assert.equal(o.customer_name, 'Amina');
  assert.equal(o.customer_phone, '0550123456');
  assert.equal(o.address_text, 'Rue Didouche 12');
  assert.equal(o.restaurant_name, 'Pizzeria El Bahdja');
  assert.equal(o.items.length, 1);
  assert.equal((await asU(D2, () => rows(db, `select id from driver_orders()`))).length, 0);
  await asU(D2, () => assert.rejects(db.query(`select driver_set_order_status($1, 'picked_up')`, [id]), /order_not_found/));
  await asU(D2, () => assert.rejects(db.query(`select driver_release_order($1)`, [id]), /order_not_found/));
  await asU(D1, () => denied(db.query(`update orders set status = 'delivered' where id = $1`, [id])));
});

test('release before pickup: back in the list for others', async () => {
  const id = await newOrder();
  await claim(D1, id);
  await call(D1, `select driver_release_order($1)`, [id]);
  assert.equal((await order(id)).driver_id, null);
  const list = await asU(D2, () => rows(db, `select id from driver_available_orders()`));
  assert.deepEqual(list.map((r) => r.id), [id]);
  await claim(D2, id);
});

test('customer and restaurant see the driver name and phone', async () => {
  const id = await newOrder();
  const before = await asU(C, () => rows(db, `select driver_name from my_orders($1)`, [id]));
  assert.equal(before[0].driver_name, null);
  await claim(D1, id);
  const [mine] = await asU(C, () => rows(db, `select driver_name, driver_phone from my_orders($1)`, [id]));
  assert.deepEqual([mine.driver_name, mine.driver_phone], ['Rachid', '0661000001']);
  const [own] = await asU(O, () => rows(db, `select driver_name, driver_phone from owner_orders()`));
  assert.deepEqual([own.driver_name, own.driver_phone], ['Rachid', '0661000001']);
});

test('restaurant cancels a taken order: driver sees it in history, is free', async () => {
  const id = await newOrder();
  await claim(D1, id);
  await call(O, `select owner_set_order_status($1, 'cancelled', 'Rupture')`, [id]);
  assert.equal((await asU(D1, () => rows(db, `select id from driver_orders()`))).length, 0);
  const [h] = await asU(D1, () => rows(db, `select status, reject_reason from driver_orders(false)`));
  assert.deepEqual([h.status, h.reject_reason], ['cancelled', 'Rupture']);
  await claim(D1, await newOrder());
});
