// Proof of delivery photo + cash handover + 24 h block.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows, denied } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a'; // customer
const C2 = 'abababab-0000-4000-8000-0000000000ab'; // another customer
const O = 'cccccccc-0000-4000-8000-00000000000c'; // pizzeria owner
const O2 = 'dddddddd-0000-4000-8000-00000000000d'; // other owner
const D1 = 'd1d1d1d1-0000-4000-8000-0000000000d1';
const D2 = 'd2d2d2d2-0000-4000-8000-0000000000d2';
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let addr;
let margherita;

const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));
const upload = (u, name) =>
  call(u, `insert into storage.objects (bucket_id, name, owner) values ('delivery-proofs', $1, $2)`, [name, u]);
const order = async (id) => (await rows(db, `select * from orders where id = $1`, [id]))[0];

/** Order picked up by [driver], ready to be delivered. */
async function onTheWay(driver = D1) {
  const [o] = await asU(C, () =>
    rows(db, `select * from place_order($1, $2::jsonb, $3, '0550123456')`, [
      PIZZA, JSON.stringify([{ id: margherita, qty: 2 }]), addr,
    ]));
  await call(O, `select owner_set_order_status($1, 'accepted')`, [o.id]);
  await call(driver, `select driver_claim_order($1)`, [o.id]);
  await call(O, `select owner_set_order_status($1, 'ready')`, [o.id]);
  await call(driver, `select driver_set_order_status($1, 'picked_up')`, [o.id]);
  return o.id;
}

async function delivered(driver = D1) {
  const id = await onTheWay(driver);
  await upload(driver, `${id}/proof.jpg`);
  await call(driver, `select driver_complete_delivery($1, $2)`, [id, `${id}/proof.jpg`]);
  return id;
}

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [C, 'c@test.dz', 'Amina'],
    [C2, 'c2@test.dz', 'Other'],
    [O, 'o@test.dz', 'Omar'],
    [O2, 'o2@test.dz', 'Other owner'],
    [D1, 'd1@test.dz', 'Rachid'],
    [D2, 'd2@test.dz', 'Sofiane'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  await call(O2, `select register_restaurant('Chez Other', '0550999888', 'Rue Y', 'Oran')`);
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  addr = (await asU(C, () =>
    rows(db, `insert into addresses (label, address_text) values ('home', 'Rue Didouche 12') returning id`)))[0].id;
  for (const [d, phone] of [[D1, '0661000001'], [D2, '0661000002']]) {
    await call(d, `select register_driver($1, 'moto')`, [phone]);
    await call(ADMIN, `select admin_set_driver_approved($1, true)`, [d]);
    await call(d, `select driver_set_online(true)`);
  }
});

test.beforeEach(async () => {
  await db.query(`delete from orders`);
  await db.query(`delete from storage.objects`);
});

// ---------- photo ----------
test('delivering needs the photo, uploaded under the order folder', async () => {
  const id = await onTheWay();
  await asU(D1, () => assert.rejects(db.query(`select driver_complete_delivery($1, null)`, [id]), /photo_required/));
  // Path given but nothing uploaded.
  await asU(D1, () => assert.rejects(db.query(`select driver_complete_delivery($1, $2)`, [id, `${id}/x.jpg`]), /photo_required/));
  // A photo of another order doesn't count.
  const other = await onTheWay(D2);
  await upload(D2, `${other}/p.jpg`);
  await asU(D1, () => assert.rejects(db.query(`select driver_complete_delivery($1, $2)`, [id, `${other}/p.jpg`]), /photo_required/));

  await upload(D1, `${id}/proof.jpg`);
  await call(D1, `select driver_complete_delivery($1, $2)`, [id, `${id}/proof.jpg`]);
  const o = await order(id);
  assert.equal(o.status, 'delivered');
  assert.equal(o.delivery_photo_path, `${id}/proof.jpg`);
  assert.equal(o.commission_amount, 112); // 1400 × 8 %
});

test('only the assigned driver uploads, only while on the way', async () => {
  const id = await onTheWay();
  await asU(D2, () => denied(db.query(`insert into storage.objects (bucket_id, name) values ('delivery-proofs', $1)`, [`${id}/x.jpg`])));
  await asU(C, () => denied(db.query(`insert into storage.objects (bucket_id, name) values ('delivery-proofs', $1)`, [`${id}/x.jpg`])));
  await asU(D1, () => denied(db.query(`insert into storage.objects (bucket_id, name) values ('delivery-proofs', 'not-an-order/x.jpg')`)));
  // Before pickup: not yet.
  const [early] = await asU(C, () =>
    rows(db, `select * from place_order($1, $2::jsonb, $3, '0550123456')`, [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr]));
  await call(O, `select owner_set_order_status($1, 'accepted')`, [early.id]);
  await call(D2, `select driver_claim_order($1)`, [early.id]);
  await asU(D2, () => denied(db.query(`insert into storage.objects (bucket_id, name) values ('delivery-proofs', $1)`, [`${early.id}/x.jpg`])));
});

test('photo visible to the customer, the driver and the admin only', async () => {
  const id = await delivered();
  const see = async (u) => (await asU(u, () => rows(db, `select name from storage.objects where bucket_id = 'delivery-proofs'`))).length;
  assert.equal(await see(C), 1);
  assert.equal(await see(D1), 1);
  assert.equal(await see(ADMIN), 1);
  assert.equal(await see(C2), 0);
  assert.equal(await see(D2), 0);
  assert.equal(await see(O2), 0);
  await as(db, 'anon', null, async () => {
    assert.equal((await rows(db, `select name from storage.objects where bucket_id = 'delivery-proofs'`)).length, 0);
  });
  const [mine] = await asU(C, () => rows(db, `select delivery_photo_path from my_orders($1)`, [id]));
  assert.equal(mine.delivery_photo_path, `${id}/proof.jpg`);
  const [adm] = await asU(ADMIN, () => rows(db, `select * from admin_order_delivery($1)`, [id]));
  assert.equal(adm.driver_name, 'Rachid');
  assert.equal(adm.delivery_photo_path, `${id}/proof.jpg`);
  await asU(C, () => assert.rejects(db.query(`select * from admin_order_delivery($1)`, [id]), /admin only/));
});

// ---------- cash ----------
test('driver hands, restaurant confirms; both lists follow', async () => {
  const id = await delivered();
  let [dp] = await asU(D1, () => rows(db, `select * from driver_cash_pending()`));
  assert.equal(dp.food_total, 1400);
  assert.equal(dp.restaurant_name, 'Pizzeria El Bahdja');
  assert.equal(dp.cash_handed_at, null);
  assert.equal(dp.overdue, false);
  let [op] = await asU(O, () => rows(db, `select * from owner_cash_pending()`));
  assert.equal(op.driver_name, 'Rachid');
  assert.equal(op.food_total, 1400);
  const [me] = await asU(D1, () => rows(db, `select cash_owed, cash_blocked from my_driver()`));
  assert.deepEqual([me.cash_owed, me.cash_blocked], [1400, false]);

  await call(D1, `select driver_mark_cash_handed($1)`, [id]);
  [op] = await asU(O, () => rows(db, `select cash_handed_at from owner_cash_pending()`));
  assert.ok(op.cash_handed_at);
  await asU(D1, () => assert.rejects(db.query(`select driver_mark_cash_handed($1)`, [id]), /not_allowed/)); // twice

  await call(O, `select owner_confirm_cash($1)`, [id]);
  assert.equal((await asU(D1, () => rows(db, `select id from driver_cash_pending()`))).length, 0);
  assert.equal((await asU(O, () => rows(db, `select id from owner_cash_pending()`))).length, 0);
  assert.ok((await order(id)).cash_confirmed_at);
  await asU(O, () => assert.rejects(db.query(`select owner_confirm_cash($1)`, [id]), /not_allowed/)); // twice
});

test('restaurant can confirm even if the driver forgot to tap', async () => {
  const id = await delivered();
  await call(O, `select owner_confirm_cash($1)`, [id]);
  const o = await order(id);
  assert.ok(o.cash_handed_at && o.cash_confirmed_at);
});

test('cash actions: only the right driver / owner, only delivered orders', async () => {
  const id = await onTheWay();
  await asU(D1, () => assert.rejects(db.query(`select driver_mark_cash_handed($1)`, [id]), /not_allowed/));
  await asU(O, () => assert.rejects(db.query(`select owner_confirm_cash($1)`, [id]), /not_allowed/));
  await upload(D1, `${id}/p.jpg`);
  await call(D1, `select driver_complete_delivery($1, $2)`, [id, `${id}/p.jpg`]);
  await asU(D2, () => assert.rejects(db.query(`select driver_mark_cash_handed($1)`, [id]), /order_not_found/));
  await asU(O2, () => assert.rejects(db.query(`select owner_confirm_cash($1)`, [id]), /order_not_found/));
  await asU(C, () => assert.rejects(db.query(`select owner_confirm_cash($1)`, [id]), /order_not_found/));
  await as(db, 'anon', null, () => denied(db.query(`select owner_confirm_cash($1)`, [id])));
  // Never by writing the table.
  await asU(O, () => denied(db.query(`update orders set cash_confirmed_at = now() where id = $1`, [id])));
  await asU(D1, () => denied(db.query(`update orders set cash_handed_at = now() where id = $1`, [id])));
  assert.equal((await asU(O2, () => rows(db, `select id from owner_cash_pending()`))).length, 0);
});

test('money unconfirmed for 24 h blocks new orders until confirmed', async () => {
  const id = await delivered();
  const next = async () => {
    const [o] = await asU(C, () =>
      rows(db, `select * from place_order($1, $2::jsonb, $3, '0550123456')`, [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr]));
    await call(O, `select owner_set_order_status($1, 'accepted')`, [o.id]);
    return o.id;
  };
  // 23 h: still fine.
  await db.query(`update orders set delivered_at = now() - interval '23 hours' where id = $1`, [id]);
  const a = await next();
  await call(D1, `select driver_claim_order($1)`, [a]);
  await call(D1, `select driver_release_order($1)`, [a]);

  // 25 h: blocked, even after tapping "handed" (the restaurant must confirm).
  await db.query(`update orders set delivered_at = now() - interval '25 hours' where id = $1`, [id]);
  await call(D1, `select driver_mark_cash_handed($1)`, [id]);
  await asU(D1, () => assert.rejects(db.query(`select driver_claim_order($1)`, [a]), /cash_overdue/));
  const [me] = await asU(D1, () => rows(db, `select cash_blocked from my_driver()`));
  assert.equal(me.cash_blocked, true);
  const [dp] = await asU(D1, () => rows(db, `select overdue from driver_cash_pending()`));
  assert.equal(dp.overdue, true);
  const [adm] = await asU(ADMIN, () => rows(db, `select cash_owed, cash_owed_count, cash_blocked from admin_list_drivers() where email = 'd1@test.dz'`));
  assert.deepEqual([adm.cash_owed, adm.cash_owed_count, adm.cash_blocked], [1400, 1, true]);
  // Other drivers aren't affected.
  await call(D2, `select driver_claim_order($1)`, [a]);
  await call(D2, `select driver_release_order($1)`, [a]);

  await call(O, `select owner_confirm_cash($1)`, [id]);
  await call(D1, `select driver_claim_order($1)`, [a]);
});

test('the hours come from app_config', async () => {
  const id = await delivered();
  await db.query(`update orders set delivered_at = now() - interval '3 hours' where id = $1`, [id]);
  await db.query(`update app_config set cash_handover_hours = 2`);
  try {
    const [me] = await asU(D1, () => rows(db, `select cash_blocked from my_driver()`));
    assert.equal(me.cash_blocked, true);
  } finally {
    await db.query(`update app_config set cash_handover_hours = 24`);
  }
});
