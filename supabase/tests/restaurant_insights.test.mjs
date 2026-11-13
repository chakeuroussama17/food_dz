// Restaurant v2: period report (table / CSV / trends) and account deletion.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a';
const O = 'cccccccc-0000-4000-8000-00000000000c'; // pizzeria owner
const O2 = 'dddddddd-0000-4000-8000-00000000000d'; // other owner
const D = 'd1d1d1d1-0000-4000-8000-0000000000d1';
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let addr;
let margherita;

const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));
const DAY = `now() - interval '1 day', now() + interval '1 day'`;

async function placed() {
  const [o] = await asU(C, () =>
    rows(db, `select * from place_order($1, $2::jsonb, $3, '0550123456')`, [
      PIZZA, JSON.stringify([{ id: margherita, qty: 2 }]), addr,
    ]));
  return o.id;
}

async function delivered() {
  const id = await placed();
  await call(O, `select owner_set_order_status($1, 'accepted')`, [id]);
  await call(D, `select driver_claim_order($1)`, [id]);
  await call(O, `select owner_set_order_status($1, 'ready')`, [id]);
  await call(D, `select driver_set_order_status($1, 'picked_up')`, [id]);
  await call(D, `insert into storage.objects (bucket_id, name, owner) values ('delivery-proofs', $1, $2)`, [`${id}/p.jpg`, D]);
  await call(D, `select driver_complete_delivery($1, $2)`, [id, `${id}/p.jpg`]);
  return id;
}

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [C, 'c@test.dz', 'Amina'],
    [O, 'o@test.dz', 'Omar'],
    [O2, 'o2@test.dz', 'Other owner'],
    [D, 'd@test.dz', 'Rachid'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  await call(O2, `select register_restaurant('Chez Other', '0550999888', 'Rue Y', 'Oran')`);
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  addr = (await asU(C, () =>
    rows(db, `insert into addresses (label, address_text, area) values ('home', 'Rue Didouche 12', 'Alger') returning id`)))[0].id;
  await call(D, `select register_driver('0661000001', 'moto')`);
  await call(ADMIN, `select admin_set_driver_approved($1, true)`, [D]);
  await call(D, `select driver_set_online(true)`);
});

test('report: own orders of the period, with items, commission and driver', async () => {
  const done = await delivered();
  const fresh = await placed();
  const list = await asU(O, () => rows(db, `select * from owner_report(${DAY})`));
  assert.deepEqual(new Set(list.map((r) => r.id)), new Set([done, fresh]));
  const d = list.find((r) => r.id === done);
  assert.equal(d.status, 'delivered');
  assert.equal(d.driver_name, 'Rachid');
  assert.ok(d.commission_amount > 0);
  assert.equal(d.items[0].quantity, 2);
  assert.equal(d.customer_name, 'Amina');

  // Outside the period: nothing.
  const old = await asU(O, () => rows(db,
    `select * from owner_report(now() - interval '10 days', now() - interval '9 days')`));
  assert.equal(old.length, 0);
  await call(O, `select owner_set_order_status($1, 'rejected', 'Fermé')`, [fresh]);
});

test('report: other owners, customers and visitors get nothing', async () => {
  assert.equal((await asU(O2, () => rows(db, `select * from owner_report(${DAY})`))).length, 0);
  assert.equal((await asU(C, () => rows(db, `select * from owner_report(${DAY})`))).length, 0);
  await as(db, 'anon', null, () =>
    assert.rejects(db.query(`select * from owner_report(${DAY})`), /permission denied/));
});

test('report: period checked', async () => {
  await asU(O, () => assert.rejects(
    db.query(`select * from owner_report(now(), now() - interval '1 day')`), /bad_period/));
  await asU(O, () => assert.rejects(
    db.query(`select * from owner_report(now() - interval '2 years', now())`), /bad_period/));
});

test('delete restaurant account: refused while money or orders are open', async () => {
  // Earlier test left a delivered order whose cash is not confirmed.
  await asU(O, () => assert.rejects(db.query(`select delete_my_restaurant_account()`), /cash_pending/));

  for (const r of await rows(db, `select id from orders where status = 'delivered'`)) {
    await call(D, `select driver_mark_cash_handed($1)`, [r.id]).catch(() => {});
    await call(O, `select owner_confirm_cash($1)`, [r.id]);
  }
  // Commission not billed yet.
  await asU(O, () => assert.rejects(db.query(`select delete_my_restaurant_account()`), /unpaid_commission/));

  // Billed but not paid (statements cover finished periods only).
  await db.query(`update orders set delivered_at = now() - interval '3 days' where status = 'delivered'`);
  const [{ id: st }] = await asU(ADMIN, () => rows(db,
    `select admin_generate_statement($1, current_date - 6, current_date - 1) as id`, [PIZZA]));
  await asU(O, () => assert.rejects(db.query(`select delete_my_restaurant_account()`), /unpaid_commission/));
  await call(ADMIN, `select admin_set_statement_paid($1, true)`, [st]);

  // An order in progress.
  const id = await placed();
  await asU(O, () => assert.rejects(db.query(`select delete_my_restaurant_account()`), /active_orders/));
  await call(O, `select owner_set_order_status($1, 'rejected', 'Fermé')`, [id]);
});

test('delete restaurant account: only for restaurant owners', async () => {
  await asU(C, () => assert.rejects(db.query(`select delete_my_restaurant_account()`), /not_a_restaurant/));
});

test('delete restaurant account: login gone, restaurant archived, books kept', async () => {
  const before = (await rows(db, `select count(*)::int n from orders where restaurant_id = $1`, [PIZZA]))[0].n;
  await call(O, `select delete_my_restaurant_account()`);

  assert.equal((await rows(db, `select 1 from auth.users where id = $1`, [O])).length, 0);
  assert.equal((await rows(db, `select 1 from profiles where id = $1`, [O])).length, 0);
  const [r] = await rows(db, `select * from restaurants where id = $1`, [PIZZA]);
  assert.equal(r.owner_id, null);
  assert.equal(r.is_active, false);
  assert.equal(r.is_open, false);
  assert.ok(r.deleted_at);
  assert.equal((await rows(db, `select count(*)::int n from orders where restaurant_id = $1`, [PIZZA]))[0].n, before);
  assert.equal((await rows(db, `select 1 from statements where restaurant_id = $1`, [PIZZA])).length, 1);

  // Hidden from customers, and the admin can't switch it back on.
  assert.equal((await asU(C, () => rows(db, `select 1 from restaurants where id = $1`, [PIZZA]))).length, 0);
  await asU(ADMIN, () => assert.rejects(
    db.query(`select admin_set_restaurant_active($1, true)`, [PIZZA]), /restaurant_deleted/));
});
