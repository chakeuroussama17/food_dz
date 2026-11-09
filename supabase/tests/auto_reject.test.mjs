// Auto-reject of orders the restaurant doesn't answer.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows, denied } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a';
const O = 'cccccccc-0000-4000-8000-00000000000c';
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let addr;
let margherita;
const asU = (u, fn) => as(db, 'authenticated', u, fn);

async function place(minutesAgo) {
  const [o] = await asU(C, () =>
    rows(db, `select * from place_order($1, $2::jsonb, $3, '0550123456')`, [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr]));
  await db.query(`update orders set placed_at = now() - make_interval(mins => $2) where id = $1`, [o.id, minutesAgo]);
  return o.id;
}
const status = async (id) => (await rows(db, `select status, reject_reason from orders where id = $1`, [id]))[0];

test.before(async () => {
  db = await freshDb([[ADMIN, 'admin@food.dz', 'Admin'], [C, 'c@test.dz', 'Amina'], [O, 'o@test.dz', 'Omar']]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  addr = (await asU(C, () => rows(db, `insert into addresses (label, address_text) values ('home', 'Rue 1') returning id`)))[0].id;
});

test('unanswered after 10 min: rejected with the no_answer reason', async () => {
  const old = await place(11);
  const recent = await place(5);
  const accepted = await place(30);
  await as(db, 'authenticated', O, () => db.query(`select owner_set_order_status($1, 'accepted')`, [accepted]));

  const [{ n }] = await rows(db, `select auto_reject_stale_orders() as n`);
  assert.equal(n, 1);
  assert.deepEqual(await status(old), { status: 'rejected', reject_reason: 'no_answer' });
  assert.equal((await status(recent)).status, 'placed');
  assert.equal((await status(accepted)).status, 'accepted');
  // The customer sees it as rejected; logged like any status change.
  const [mine] = await asU(C, () => rows(db, `select status, reject_reason from my_orders($1)`, [old]));
  assert.equal(mine.reject_reason, 'no_answer');
  const ev = await rows(db, `select to_status from order_events where order_id = $1 order by id`, [old]);
  assert.deepEqual(ev.map((e) => e.to_status), ['placed', 'rejected']);
  await db.query(`delete from orders`);
});

test('the delay comes from the admin setting', async () => {
  const id = await place(5);
  await as(db, 'authenticated', ADMIN, () => db.query(`select admin_set_auto_reject_minutes(4)`));
  await rows(db, `select auto_reject_stale_orders()`);
  assert.equal((await status(id)).status, 'rejected');
  await as(db, 'authenticated', ADMIN, () => assert.rejects(db.query(`select admin_set_auto_reject_minutes(1)`), /invalid minutes/));
  await as(db, 'authenticated', O, () => assert.rejects(db.query(`select admin_set_auto_reject_minutes(20)`), /admin only/));
  await as(db, 'authenticated', ADMIN, () => db.query(`select admin_set_auto_reject_minutes(10)`));
  await db.query(`delete from orders`);
});

test('nobody can run the auto-reject from the app', async () => {
  await asU(C, () => denied(db.query(`select auto_reject_stale_orders()`)));
  await as(db, 'authenticated', O, () => denied(db.query(`select auto_reject_stale_orders()`)));
});
