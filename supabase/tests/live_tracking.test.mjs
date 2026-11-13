// Live tracking: the rider's last point, seen only during the delivery by
// the customer, the restaurant team and the admin; forgotten afterwards.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a';
const C2 = 'abababab-0000-4000-8000-0000000000ab';
const O = 'cccccccc-0000-4000-8000-00000000000c';
const S = '99999999-0000-4000-8000-000000000009';
const X = 'dddddddd-0000-4000-8000-00000000000d';
const D = 'd1d1d1d1-0000-4000-8000-0000000000d1';
const D2 = 'd2d2d2d2-0000-4000-8000-0000000000d2';
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let margherita;
let addr;
const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));
const q = (u, sql, params) => asU(u, () => rows(db, sql, params));
const where = (u, id) => q(u, `select * from order_driver_location($1)`, [id]);
const move = (u, lat, lng) => call(u, `select driver_update_location($1, $2)`, [lat, lng]);
const stored = async (u) => rows(db, `select * from driver_locations where driver_id = $1`, [u]);

async function claimed() {
  const [o] = await q(C, `select * from place_order($1, $2::jsonb, $3, '0550123456')`,
    [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr]);
  await call(O, `select owner_set_order_status($1, 'accepted')`, [o.id]);
  await call(D, `select driver_claim_order($1)`, [o.id]);
  return o.id;
}

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [C, 'c@test.dz', 'Amina'],
    [C2, 'c2@test.dz', 'Bilal'],
    [O, 'o@test.dz', 'Omar'],
    [S, 's@test.dz', 'Samia'],
    [X, 'x@test.dz', 'Xavier'],
    [D, 'd@test.dz', 'Rachid'],
    [D2, 'd2@test.dz', 'Sofiane'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  await call(O, `select owner_add_member($1, 's@test.dz', 'staff')`, [PIZZA]);
  await call(X, `select register_restaurant('Chez X', '0550999888', 'Rue Y', 'Oran')`);
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  addr = (await q(C, `insert into addresses (label, address_text, area) values ('home', 'Rue 1', 'Kouba') returning id`))[0].id;
  for (const [d, phone] of [[D, '0661000001'], [D2, '0661000002']]) {
    await call(d, `select register_driver($1, 'moto')`, [phone]);
    await call(ADMIN, `select admin_set_driver_approved($1, true)`, [d]);
    await call(d, `select driver_set_online(true)`);
  }
});

test('no delivery running: the point is not kept', async () => {
  await move(D, 36.77, 3.06);
  assert.equal((await stored(D)).length, 0);
});

test('during the delivery: customer, restaurant team and admin see the rider', async () => {
  const id = await claimed();
  await move(D, 36.7700, 3.0600);
  await move(D, 36.7710, 3.0590); // only the last point is kept
  assert.equal((await stored(D)).length, 1);
  for (const u of [C, O, S, ADMIN]) {
    const [p] = await where(u, id);
    assert.ok(p, `user ${u} sees it`);
    assert.equal(p.lat, 36.771);
    assert.equal(p.lng, 3.059);
  }
  // Nobody else: another customer, another restaurant, another rider.
  for (const u of [C2, X, D2]) assert.equal((await where(u, id)).length, 0);
  // Anonymous visitors can't even call it.
  await as(db, 'anon', null, () => assert.rejects(db.query(`select * from order_driver_location($1)`, [id])));
  // Nobody reads the table directly.
  await asU(C, () => assert.rejects(db.query(`select * from driver_locations`)));

  // A point older than 10 minutes is not shown.
  await db.query(`update driver_locations set updated_at = now() - interval '11 minutes'`);
  assert.equal((await where(C, id)).length, 0);
  await move(D, 36.772, 3.058);
  assert.equal((await where(C, id)).length, 1);

  // Delivered: the point is forgotten.
  await call(O, `select owner_set_order_status($1, 'ready')`, [id]);
  await call(D, `select driver_set_order_status($1, 'picked_up')`, [id]);
  assert.equal((await where(C, id)).length, 1);
  await call(D, `insert into storage.objects (bucket_id, name, owner) values ('delivery-proofs', $1, $2)`, [`${id}/p.jpg`, D]);
  await call(D, `select driver_complete_delivery($1, $2)`, [id, `${id}/p.jpg`]);
  assert.equal((await where(C, id)).length, 0);
  assert.equal((await stored(D)).length, 0);
});

test('given back: forgotten too', async () => {
  await db.query(`update orders set cash_handed_at = now(), cash_confirmed_at = now() where status = 'delivered'`);
  const id = await claimed();
  await move(D, 36.77, 3.06);
  assert.equal((await stored(D)).length, 1);
  await call(D, `select driver_release_order($1)`, [id]);
  assert.equal((await stored(D)).length, 0);
});

test('only approved riders, only real coordinates', async () => {
  await asU(C, () => assert.rejects(db.query(`select driver_update_location(36.7, 3.0)`), /not_allowed/));
  await asU(D, () => assert.rejects(db.query(`select driver_update_location(95, 3.0)`), /invalid_location/));
  await asU(D, () => assert.rejects(db.query(`select driver_update_location(null, 3.0)`), /invalid_location/));
});
