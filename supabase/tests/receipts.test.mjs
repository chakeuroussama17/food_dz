// Receipts: business info, restaurant statements, driver statement, setting.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows, denied } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a';
const O = 'cccccccc-0000-4000-8000-00000000000c';
const O2 = 'dddddddd-0000-4000-8000-00000000000d';
const D1 = 'd1d1d1d1-0000-4000-8000-0000000000d1';
const D2 = 'd2d2d2d2-0000-4000-8000-0000000000d2';
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let addr;
let margherita;
const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, p) => asU(u, () => db.query(sql, p));
const today = () => new Date().toISOString().slice(0, 10);
const daysAgo = (n) => new Date(Date.now() - n * 864e5).toISOString().slice(0, 10);

async function delivered(driver = D1) {
  const [o] = await asU(C, () =>
    rows(db, `select * from place_order($1, $2::jsonb, $3, '0550123456')`, [PIZZA, JSON.stringify([{ id: margherita, qty: 2 }]), addr]));
  await call(O, `select owner_set_order_status($1, 'accepted')`, [o.id]);
  await call(driver, `select driver_claim_order($1)`, [o.id]);
  await call(O, `select owner_set_order_status($1, 'ready')`, [o.id]);
  await call(driver, `select driver_set_order_status($1, 'picked_up')`, [o.id]);
  await call(driver, `insert into storage.objects (bucket_id, name, owner) values ('delivery-proofs', $1, $2)`, [`${o.id}/p.jpg`, driver]);
  await call(driver, `select driver_complete_delivery($1, $2)`, [o.id, `${o.id}/p.jpg`]);
  return o.id;
}

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'], [C, 'c@test.dz', 'Amina'],
    [O, 'o@test.dz', 'Omar'], [O2, 'o2@test.dz', 'Other'],
    [D1, 'd1@test.dz', 'Rachid'], [D2, 'd2@test.dz', 'Sofiane'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  await call(O2, `select register_restaurant('Chez Other', '0550999888', 'Rue Y', 'Oran')`);
  await db.query(`update app_config set business_name = 'Food DZ', business_tax_id = 'NIF123'`);
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  addr = (await asU(C, () => rows(db, `insert into addresses (label, address_text) values ('home', 'Rue 1') returning id`)))[0].id;
  for (const [d, ph] of [[D1, '0661000001'], [D2, '0661000002']]) {
    await call(d, `select register_driver($1, 'moto')`, [ph]);
    await call(ADMIN, `select admin_set_driver_approved($1, true)`, [d]);
    await call(d, `select driver_set_online(true)`);
  }
});

test('business info for receipts: any signed-in user, not visitors', async () => {
  const [{ b }] = await asU(C, () => rows(db, `select business_info() as b`));
  assert.equal(b.business_name, 'Food DZ');
  assert.equal(b.business_tax_id, 'NIF123');
  assert.ok(!('default_commission_rate' in b));
  await as(db, 'anon', null, () => denied(db.query(`select business_info()`)));
});

test('driver statement: own deliveries of the period only', async () => {
  const a = await delivered(D1);
  await delivered(D2);
  await call(O, `select owner_confirm_cash($1)`, [a]);
  const list = await asU(D1, () => rows(db, `select * from driver_statement($1, $2)`, [daysAgo(7), today()]));
  assert.equal(list.length, 1);
  assert.equal(list[0].restaurant_name, 'Pizzeria El Bahdja');
  assert.deepEqual([list[0].total, list[0].food_total, list[0].delivery_fee], [1600, 1400, 200]);
  assert.ok(list[0].cash_confirmed_at);
  assert.equal((await asU(D1, () => rows(db, `select * from driver_statement($1, $2)`, [daysAgo(30), daysAgo(10)]))).length, 0);
  await asU(D1, () => assert.rejects(db.query(`select * from driver_statement($1, $2)`, [today(), daysAgo(1)]), /invalid_period/));
  await asU(D1, () => assert.rejects(db.query(`select * from driver_statement($1, $2)`, [daysAgo(100), today()]), /invalid_period/));
  assert.equal((await asU(C, () => rows(db, `select * from driver_statement($1, $2)`, [daysAgo(7), today()]))).length, 0);
});

test('restaurant sees and downloads only its own commission statements', async () => {
  await delivered(D1);
  // Bill everything up to today (the period must be finished, so move the delivery back).
  await db.query(`update orders set delivered_at = now() - interval '3 days' where status = 'delivered'`);
  const [{ id }] = await asU(ADMIN, () => rows(db, `select admin_generate_statement($1, $2, $3) as id`, [PIZZA, daysAgo(10), daysAgo(1)]));
  const list = await asU(O, () => rows(db, `select * from owner_statements()`));
  assert.equal(list.length, 1);
  assert.match(list[0].number, /^FD-\d{4}-\d{4}$/);
  const [{ d }] = await asU(O, () => rows(db, `select owner_statement_detail($1) as d`, [id]));
  assert.equal(d.restaurant.name, 'Pizzeria El Bahdja');
  assert.equal(d.business.business_name, 'Food DZ');
  assert.ok(d.orders.length >= 1);
  assert.equal((await asU(O2, () => rows(db, `select * from owner_statements()`))).length, 0);
  await asU(O2, () => assert.rejects(db.query(`select owner_statement_detail($1)`, [id]), /statement not found/));
  await asU(C, () => assert.rejects(db.query(`select owner_statement_detail($1)`, [id]), /statement not found/));
});

test('admin sets the cash block hours; nobody else', async () => {
  await call(ADMIN, `select admin_set_cash_hours(12)`);
  const [c] = await rows(db, `select cash_handover_hours from app_config`);
  assert.equal(c.cash_handover_hours, 12);
  const [{ cfg }] = await asU(ADMIN, () => rows(db, `select admin_get_config() as cfg`));
  assert.equal(cfg.cash_handover_hours, 12);
  await asU(ADMIN, () => assert.rejects(db.query(`select admin_set_cash_hours(0)`), /invalid hours/));
  await asU(ADMIN, () => assert.rejects(db.query(`select admin_set_cash_hours(500)`), /invalid hours/));
  await asU(O, () => assert.rejects(db.query(`select admin_set_cash_hours(48)`), /admin only/));
  await call(ADMIN, `select admin_set_cash_hours(24)`);
});
