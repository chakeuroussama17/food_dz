// Rider profile: edit, stats (totals, stars, 5-star run), delete account.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a';
const O = 'cccccccc-0000-4000-8000-00000000000c';
const D = 'd1d1d1d1-0000-4000-8000-0000000000d1';
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let margherita;
let addr;
const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));
const q = (u, sql, params) => asU(u, () => rows(db, sql, params));
const rejects = (u, sql, params, re) => asU(u, () => assert.rejects(db.query(sql, params), re));
const stats = async () => (await q(D, `select * from driver_profile_stats()`))[0];

/** An order taken by the rider, up to [until]. */
async function order(until = 'delivered') {
  const [o] = await q(C, `select * from place_order($1, $2::jsonb, $3, '0550123456')`,
    [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr]);
  await call(O, `select owner_set_order_status($1, 'accepted')`, [o.id]);
  await call(D, `select driver_claim_order($1)`, [o.id]);
  if (until === 'accepted') return o.id;
  await call(O, `select owner_set_order_status($1, 'ready')`, [o.id]);
  await call(D, `select driver_set_order_status($1, 'picked_up')`, [o.id]);
  await call(D, `insert into storage.objects (bucket_id, name, owner) values ('delivery-proofs', $1, $2)`, [`${o.id}/p.jpg`, D]);
  await call(D, `select driver_complete_delivery($1, $2)`, [o.id, `${o.id}/p.jpg`]);
  return o.id;
}
const settle = () => db.query(
  `update orders set cash_handed_at = now(), cash_confirmed_at = now() where status = 'delivered'`);

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [C, 'c@test.dz', 'Amina Benali'],
    [O, 'o@test.dz', 'Omar'],
    [D, 'd@test.dz', 'Rachid'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  addr = (await q(C, `insert into addresses (label, address_text, area) values ('home', 'Rue 1', 'Kouba') returning id`))[0].id;
  await call(D, `select register_driver('0661000001', 'moto')`);
  await call(ADMIN, `select admin_set_driver_approved($1, true)`, [D]);
  await call(D, `select driver_set_online(true)`);
});

test('edit name, phone and vehicle; bad values refused', async () => {
  await call(D, `select driver_update_profile('  Rachid   Benali ', '0661 22 33 44', 'car')`);
  const [me] = await q(D, `select * from my_driver()`);
  assert.equal(me.full_name, 'Rachid Benali');
  assert.equal(me.phone, '0661223344');
  assert.equal(me.vehicle, 'car');
  await rejects(D, `select driver_update_profile('R', '0661223344', 'car')`, [], /invalid_name/);
  await rejects(D, `select driver_update_profile('Rachid', '123', 'car')`, [], /invalid_phone/);
  await rejects(D, `select driver_update_profile('Rachid', '0661223344', 'plane')`, [], /invalid_vehicle/);
  await rejects(C, `select driver_update_profile('Amina', '0661223344', 'car')`, [], /not_a_driver/);
});

test('stats: totals, stars, 30 days and the 5-star run', async () => {
  const s0 = await stats();
  assert.equal(s0.deliveries_total, 0);
  assert.equal(s0.rating_avg, null);
  assert.deepEqual(s0.stars, { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 });

  // Oldest first: 4, 2, 5, 5, 5, 5 → average 4.3, run of four 5s.
  const given = [4, 2, 5, 5, 5, 5];
  for (let i = 0; i < given.length; i++) {
    const id = await order();
    await settle();
    await call(C, `select rate_order($1, 'driver', $2, $3::text[], '')`,
      [id, given[i], given[i] <= 3 ? ['late'] : []]);
    await db.query(`update order_ratings set driver_rated_at = now() - make_interval(mins => $2) where order_id = $1`,
      [id, 100 - i]);
  }
  const s = await stats();
  assert.equal(s.deliveries_total, 6);
  assert.equal(Number(s.earned_total), 6 * 200);
  assert.equal(s.deliveries_30d, 6);
  assert.equal(s.rating_count, 6);
  assert.equal(Number(s.rating_avg), 4.3);
  assert.equal(Number(s.rating_avg_30d), 4.3);
  assert.deepEqual(s.stars, { 1: 0, 2: 1, 3: 0, 4: 1, 5: 4 });
  assert.equal(s.five_star_streak, 4);
  assert.ok(s.member_since);
});

test('delete: refused while delivering or owing money, then done', async () => {
  const running = await order('accepted');
  await rejects(D, `select delete_my_driver_account()`, [], /active_orders/);
  await call(D, `select driver_release_order($1)`, [running]);

  const owed = await order();
  await rejects(D, `select delete_my_driver_account()`, [], /cash_pending/);
  await settle();

  await call(D, `select delete_my_driver_account()`);
  assert.equal((await rows(db, `select * from profiles where id = $1`, [D])).length, 0);
  assert.equal((await rows(db, `select * from drivers where id = $1`, [D])).length, 0);
  // Orders stay for the restaurant, without the rider.
  const [o] = await rows(db, `select driver_id, status from orders where id = $1`, [owed]);
  assert.equal(o.driver_id, null);
  assert.equal(o.status, 'delivered');
  assert.ok((await rows(db, `select count(*)::int n from order_ratings where driver_id is null`))[0].n >= 6);
  // Customers can't use it.
  await rejects(C, `select delete_my_driver_account()`, [], /not_a_driver/);
});
