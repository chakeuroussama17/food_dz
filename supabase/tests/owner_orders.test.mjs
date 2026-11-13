// Restaurant live orders: owner_orders, owner_set_order_status.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows, denied } from './helpers.mjs';

const C = 'aaaaaaaa-0000-4000-8000-00000000000a'; // customer
const O = 'cccccccc-0000-4000-8000-00000000000c'; // owner of PIZZA
const O2 = 'dddddddd-0000-4000-8000-00000000000d'; // owner of another restaurant
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let addr;
let margherita;

const asC = (fn) => as(db, 'authenticated', C, fn);
const asO = (fn) => as(db, 'authenticated', O, fn);

async function placeOrder() {
  const [o] = await asC(() =>
    rows(db, `select * from place_order($1, $2::jsonb, $3, '0550123456', 'sans oignons')`, [
      PIZZA,
      JSON.stringify([{ id: margherita, qty: 2 }]),
      addr,
    ]));
  return o.id;
}

const setStatus = (id, s, reason = null) =>
  db.query(`select owner_set_order_status($1, $2, $3)`, [id, s, reason]);
const statusOf = async (id) =>
  (await rows(db, `select status, reject_reason, accepted_at, ready_at, cancelled_at from orders where id = $1`, [id]))[0];

test.before(async () => {
  db = await freshDb([
    [C, 'c@test.dz', 'Amina'],
    [O, 'o@test.dz', 'Omar'],
    [O2, 'o2@test.dz', 'Other'],
  ]);
  // The seeded pizzeria belongs to O, like the demo accounts SQL does.
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  await as(db, 'authenticated', O2, () =>
    db.query(`select register_restaurant('Chez Other', '0550999888', 'Rue Y', 'Oran')`));
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  addr = (await asC(() =>
    rows(db, `insert into addresses (label, address_text, area) values ('home', 'Rue Didouche 12', 'Alger Centre') returning id`)))[0].id;
});

test.afterEach(() => db.query(`delete from orders`));

test('owner sees the order with customer contact, items and notes', async () => {
  const id = await placeOrder();
  const [o] = await asO(() => rows(db, `select * from owner_orders()`));
  assert.equal(o.id, id);
  assert.equal(o.status, 'placed');
  assert.equal(o.customer_name, 'Amina');
  assert.equal(o.customer_phone, '0550123456');
  assert.equal(o.address_text, 'Rue Didouche 12');
  assert.equal(o.notes, 'sans oignons');
  assert.equal(o.total, 1600);
  assert.deepEqual(o.items, [{ name: 'Pizza Margherita', unit_price: 700, quantity: 2, line_total: 1400 }]);
  // Finished orders aren't in the active list, but in history.
  const hist = await asO(() => rows(db, `select id from owner_orders(false)`));
  assert.equal(hist.length, 0);
});

test('other owners, customers and visitors never see it', async () => {
  await placeOrder();
  const other = await as(db, 'authenticated', O2, () => rows(db, `select id from owner_orders()`));
  assert.equal(other.length, 0);
  const cust = await asC(() => rows(db, `select id from owner_orders()`));
  assert.equal(cust.length, 0);
  await as(db, 'anon', null, () => denied(db.query(`select * from owner_orders()`)));
  // RLS on the table itself (used by Realtime) agrees.
  const direct = await as(db, 'authenticated', O2, () => rows(db, `select id from orders`));
  assert.equal(direct.length, 0);
  const mine = await asO(() => rows(db, `select id from orders`));
  assert.equal(mine.length, 1);
});

test('accept then ready: timestamps set, logged with the owner as actor', async () => {
  const id = await placeOrder();
  await asO(() => setStatus(id, 'accepted'));
  let s = await statusOf(id);
  assert.equal(s.status, 'accepted');
  assert.ok(s.accepted_at);
  await asO(() => setStatus(id, 'ready'));
  s = await statusOf(id);
  assert.equal(s.status, 'ready');
  assert.ok(s.ready_at);
  const ev = await rows(db, `select to_status, actor_id from order_events where order_id = $1 order by id`, [id]);
  assert.deepEqual(ev.map((e) => e.to_status), ['placed', 'accepted', 'ready']);
  assert.equal(ev[1].actor_id, O);
  // Once accepted, the customer can only ask; the order goes on.
  await asC(() => db.query(`select cancel_my_order($1, 'changed_mind')`, [id]));
  assert.equal((await statusOf(id)).status, 'ready');
});

test('reject needs a reason, which the customer then sees', async () => {
  const id = await placeOrder();
  await asO(() => assert.rejects(setStatus(id, 'rejected'), /reason_required/));
  await asO(() => assert.rejects(setStatus(id, 'rejected', '   '), /reason_required/));
  await asO(() => setStatus(id, 'rejected', 'Plus de pâte'));
  const s = await statusOf(id);
  assert.equal(s.status, 'rejected');
  assert.equal(s.reject_reason, 'Plus de pâte');
  assert.ok(s.cancelled_at);
  const [mine] = await asC(() => rows(db, `select status, reject_reason from my_orders($1)`, [id]));
  assert.equal(mine.reject_reason, 'Plus de pâte');
  const hist = await asO(() => rows(db, `select id from owner_orders(false)`));
  assert.equal(hist.length, 1);
});

test('cancel after accepting or when ready, with a reason', async () => {
  const a = await placeOrder();
  await asO(() => setStatus(a, 'accepted'));
  await asO(() => assert.rejects(setStatus(a, 'cancelled'), /reason_required/));
  await asO(() => setStatus(a, 'cancelled', 'Client injoignable'));
  assert.equal((await statusOf(a)).status, 'cancelled');

  const b = await placeOrder();
  await asO(() => setStatus(b, 'accepted'));
  await asO(() => setStatus(b, 'ready'));
  await asO(() => setStatus(b, 'cancelled', 'x'.repeat(250)));
  assert.equal((await statusOf(b)).reject_reason.length, 200);
});

test('refused moves: skipping steps, driver steps, going back, finished orders', async () => {
  const id = await placeOrder();
  for (const s of ['ready', 'picked_up', 'delivered', 'placed']) {
    await asO(() => assert.rejects(setStatus(id, s), /not_allowed/));
  }
  await asO(() => assert.rejects(setStatus(id, 'cancelled', 'r'), /not_allowed/)); // reject, not cancel
  await asO(() => setStatus(id, 'accepted'));
  for (const s of ['accepted', 'rejected', 'placed', 'picked_up', 'delivered']) {
    await asO(() => assert.rejects(setStatus(id, s, 'r'), /not_allowed/));
  }
  await asO(() => setStatus(id, 'ready'));
  for (const s of ['accepted', 'picked_up', 'delivered']) {
    await asO(() => assert.rejects(setStatus(id, s), /not_allowed/));
  }
  await asO(() => setStatus(id, 'cancelled', 'r'));
  await asO(() => assert.rejects(setStatus(id, 'accepted'), /not_allowed/));
});

test('only the restaurant owner can change it', async () => {
  const id = await placeOrder();
  await as(db, 'authenticated', O2, () => assert.rejects(setStatus(id, 'accepted'), /order_not_found/));
  await asC(() => assert.rejects(setStatus(id, 'accepted'), /order_not_found/));
  await as(db, 'anon', null, () => denied(setStatus(id, 'accepted')));
  // And never by writing the table directly.
  await asO(() => denied(db.query(`update orders set status = 'accepted' where id = $1`, [id])));
  assert.equal((await statusOf(id)).status, 'placed');
});

test('active list is oldest first; history is newest first', async () => {
  const a = await placeOrder();
  await db.query(`update orders set placed_at = now() - interval '10 minutes' where id = $1`, [a]);
  const b = await placeOrder();
  const act = await asO(() => rows(db, `select id from owner_orders()`));
  assert.deepEqual(act.map((r) => r.id), [a, b]);
  await asO(() => setStatus(a, 'rejected', 'r'));
  await asO(() => setStatus(b, 'rejected', 'r'));
  const hist = await asO(() => rows(db, `select id from owner_orders(false)`));
  assert.deepEqual(hist.map((r) => r.id), [b, a]);
});
