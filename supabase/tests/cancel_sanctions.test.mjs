// Cancelling (instant or a request the restaurant answers) and sanctions
// (warning, suspension, ban) for customers and riders.
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
const one = async (u, sql, params) => (await q(u, sql, params))[0];
const rejects = (u, sql, params, re) => asU(u, () => assert.rejects(db.query(sql, params), re));
const order = async (id) => (await rows(db, `select * from orders where id = $1`, [id]))[0];

async function place() {
  // Keep under the active-orders limit: older test orders are closed.
  await db.query(`update orders set status = 'cancelled', cancelled_by = 'system'
                   where customer_id = $1 and status in ('placed', 'accepted', 'ready')
                     and cancel_request_status is distinct from 'pending'
                     and placed_at < now() - interval '0 seconds'`, [C]).catch(() => {});
  const [o] = await q(C, `select * from place_order($1, $2::jsonb, $3, '0550123456')`,
    [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr]);
  return o.id;
}
const accept = (id) => call(O, `select owner_set_order_status($1, 'accepted')`, [id]);

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [C, 'c@test.dz', 'Amina'],
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
});

test('before acceptance: cancelled at once, with the reason, by the customer', async () => {
  const id = await place();
  await rejects(C, `select cancel_my_order($1, 'bored')`, [id], /invalid_reason/);
  const r = await one(C, `select cancel_my_order($1, 'too_long') r`, [id]);
  assert.equal(r.r, 'cancelled');
  const o = await order(id);
  assert.equal(o.status, 'cancelled');
  assert.equal(o.cancelled_by, 'customer');
  assert.equal(o.cancel_reason, 'too_long');
  assert.ok(o.cancelled_at);
  // The old call (no reason) still works.
  const id2 = await place();
  await call(C, `select cancel_my_order($1)`, [id2]);
  assert.equal((await order(id2)).cancel_reason, 'other');
});

test('after acceptance: a request; the restaurant accepts it', async () => {
  const id = await place();
  await accept(id);
  const r = await one(C, `select cancel_my_order($1, 'wrong_address', 'Wrong building') r`, [id]);
  assert.equal(r.r, 'requested');
  let o = await order(id);
  assert.equal(o.status, 'accepted'); // goes on until the restaurant answers
  assert.equal(o.cancel_request_status, 'pending');
  assert.equal(o.cancel_request_note, 'Wrong building');
  await rejects(C, `select cancel_my_order($1, 'other')`, [id], /already_requested/);

  const [mine] = await q(C, `select * from my_orders($1)`, [id]);
  assert.equal(mine.cancel_request_status, 'pending');
  const [theirs] = await q(O, `select * from owner_orders(true) where id = $1`, [id]);
  assert.equal(theirs.cancel_request_reason, 'wrong_address');
  assert.equal(theirs.cancel_request_note, 'Wrong building');

  await rejects(C, `select owner_answer_cancel_request($1, true)`, [id], /order_not_found/);
  await call(O, `select owner_answer_cancel_request($1, true)`, [id]);
  o = await order(id);
  assert.equal(o.status, 'cancelled');
  assert.equal(o.cancel_request_status, 'accepted');
  assert.equal(o.cancelled_by, 'customer');
  assert.equal(o.cancel_reason, 'wrong_address');
  await rejects(O, `select owner_answer_cancel_request($1, true)`, [id], /no_request/);
});

test('refused: the order goes on, no second request; pickup closes a waiting one', async () => {
  const id = await place();
  await accept(id);
  await call(C, `select cancel_my_order($1, 'changed_mind')`, [id]);
  await call(O, `select owner_answer_cancel_request($1, false)`, [id]);
  let o = await order(id);
  assert.equal(o.status, 'accepted');
  assert.equal(o.cancel_request_status, 'refused');
  await rejects(C, `select cancel_my_order($1, 'changed_mind')`, [id], /request_refused/);

  // A request still waiting when the rider picks up: expired.
  const id2 = await place();
  await accept(id2);
  await call(D, `select driver_set_online(true)`);
  await call(D, `select driver_claim_order($1)`, [id2]);
  await call(O, `select owner_set_order_status($1, 'ready')`, [id2]);
  await call(C, `select cancel_my_order($1, 'too_long')`, [id2]);
  await call(D, `select driver_set_order_status($1, 'picked_up')`, [id2]);
  o = await order(id2);
  assert.equal(o.cancel_request_status, 'expired');
  await rejects(C, `select cancel_my_order($1, 'too_long')`, [id2], /cannot_cancel/);

  // The restaurant cancelling on its own: by the restaurant.
  const id3 = await place();
  await accept(id3);
  await call(O, `select owner_set_order_status($1, 'cancelled', 'Out of dough')`, [id3]);
  assert.equal((await order(id3)).cancelled_by, 'restaurant');
});

test('watchlist: 3+ cancellations in 30 days', async () => {
  // So far: 2 instant cancels, 1 accepted request, 1 refused, 1 expired.
  const list = await q(ADMIN, `select * from admin_watchlist()`);
  assert.equal(list.length, 1);
  assert.equal(list[0].user_id, C);
  assert.equal(list[0].cancels_30d, 5);
  assert.equal(list[0].restricted, false);
  const [c] = await q(ADMIN, `select * from admin_list_customers('amina')`);
  assert.equal(c.cancels_30d, 5);
  await rejects(C, `select * from admin_watchlist()`, [], /admin|denied|not/i);
});

test('warning: shown once, then gone; the customer can still order', async () => {
  await rejects(ADMIN, `select admin_sanction_user($1, 'warning', 'bad')`, [C], /invalid_reason/);
  await rejects(ADMIN, `select admin_sanction_user($1, 'jail', 'other')`, [C], /invalid_kind/);
  await rejects(ADMIN, `select admin_sanction_user($1, 'warning', 'other')`, [ADMIN], /not_found/);
  await rejects(C, `select admin_sanction_user($1, 'ban', 'other')`, [C], /admin|denied|not/i);
  await call(ADMIN, `select admin_sanction_user($1, 'warning', 'too_many_cancellations', 'Please only order when you are sure.', null, 'cancels a lot')`, [C]);
  const w = await one(C, `select * from my_restriction()`);
  assert.equal(w.kind, 'warning');
  assert.equal(w.message, 'Please only order when you are sure.');
  assert.equal(w.admin_note, undefined); // never shown to the person
  await call(C, `select acknowledge_warning($1)`, [w.id]);
  assert.equal((await q(C, `select * from my_restriction()`)).length, 0);
  await place(); // still allowed
});

test('suspension: no orders until it ends or is lifted', async () => {
  await rejects(ADMIN, `select admin_sanction_user($1, 'suspension', 'fake_orders')`, [C], /invalid_days/);
  await rejects(ADMIN, `select admin_sanction_user($1, 'suspension', 'fake_orders', '', 400)`, [C], /invalid_days/);
  const { id } = await one(ADMIN, `select admin_sanction_user($1, 'suspension', 'fake_orders', 'Fake orders', 7) id`, [C]);
  const r = await one(C, `select * from my_restriction()`);
  assert.equal(r.kind, 'suspension');
  assert.ok(new Date(r.ends_at) > new Date(Date.now() + 6 * 864e5));
  await rejects(C, `select * from place_order($1, $2::jsonb, $3, '0550123456')`,
    [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr], /account_blocked/);
  const [c] = await q(ADMIN, `select * from admin_list_customers('amina')`);
  assert.equal(c.restriction_kind, 'suspension');
  assert.equal(c.warnings, 1);

  // Ended (time passed): can order again.
  await db.query(`update user_sanctions set ends_at = now() - interval '1 minute' where id = $1`, [id]);
  assert.equal((await q(C, `select * from my_restriction()`)).length, 0);
  await place();
});

test('ban: permanent until lifted; history kept', async () => {
  const { id } = await one(ADMIN, `select admin_sanction_user($1, 'ban', 'refused_to_pay', 'Refused to pay twice') id`, [C]);
  assert.equal((await one(C, `select * from my_restriction()`)).kind, 'ban');
  await rejects(C, `select * from place_order($1, $2::jsonb, $3, '0550123456')`,
    [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr], /account_blocked/);
  const restr = await q(ADMIN, `select * from admin_restrictions()`);
  assert.deepEqual(restr.map((x) => [x.user_id, x.kind]), [[C, 'ban']]);

  await call(ADMIN, `select admin_lift_sanction($1)`, [id]);
  await rejects(ADMIN, `select admin_lift_sanction($1)`, [id], /not_found/);
  assert.equal((await q(C, `select * from my_restriction()`)).length, 0);
  assert.equal((await rows(db, `select blocked_at from profiles where id = $1`, [C]))[0].blocked_at, null);
  await place();

  const h = await q(ADMIN, `select * from admin_user_sanctions($1)`, [C]);
  assert.deepEqual(h.map((x) => x.kind), ['ban', 'suspension', 'warning']);
  assert.equal(h[0].created_by_name, 'Admin');
  assert.equal(h[0].active, false);
  assert.equal(h[2].admin_note, 'cancels a lot');
});

test('rider: suspended means offline, no going online, no new deliveries', async () => {
  // Finish the rider's earlier delivery; recent orders don't count for the
  // customer's hourly limit.
  await db.query(`alter table orders disable trigger user`);
  await db.query(`update orders set status = 'delivered', delivered_at = now() where driver_id = $1 and status = 'picked_up'`, [D]);
  await db.query(`alter table orders enable trigger user`);
  await db.query(`update orders set placed_at = placed_at - interval '2 hours'`);
  await call(D, `select driver_set_online(true)`).catch(() => {});
  const id = await place();
  await accept(id);
  const { id: sid } = await one(ADMIN, `select admin_sanction_user($1, 'suspension', 'cash_not_returned', 'Hand the cash back first', 3) id`, [D]);
  assert.equal((await rows(db, `select is_online from drivers where id = $1`, [D]))[0].is_online, false);
  await rejects(D, `select driver_set_online(true)`, [], /account_suspended/);
  await db.query(`update drivers set is_online = true where id = $1`, [D]).catch(() => {});
  await rejects(D, `select driver_claim_order($1)`, [id], /account_suspended|not_online|offline/);
  assert.equal((await one(D, `select * from my_restriction()`)).reason, 'cash_not_returned');
  await call(ADMIN, `select admin_lift_sanction($1)`, [sid]);
  await call(D, `select driver_set_online(true)`);
  await call(D, `select driver_claim_order($1)`, [id]);
});

test('reports: warned sends a warning, blocked bans (linked to the report)', async () => {
  const [{ id }] = await rows(db, `select id from orders where customer_id = $1 limit 1`, [C]);
  await call(O, `insert into customer_reports (order_id, reporter_id, reporter_role, customer_id, reason)
                 values ($1, $2, 'restaurant', $3, 'rude')`, [id, O, C]).catch(async () => {
    await db.query(`insert into customer_reports (order_id, reporter_id, reporter_role, customer_id, reason)
                    values ($1, $2, 'restaurant', $3, 'rude')`, [id, O, C]);
  });
  const [{ rid }] = await rows(db, `select id rid from customer_reports order by id desc limit 1`);
  await call(ADMIN, `select admin_handle_report($1, 'warned', 'Be polite')`, [rid]);
  const w = await one(C, `select * from my_restriction()`);
  assert.equal(w.kind, 'warning');
  assert.equal(w.reason, 'abuse');
  await call(ADMIN, `select admin_handle_report($1, 'blocked', 'Again')`, [rid]);
  assert.equal((await one(C, `select * from my_restriction()`)).kind, 'ban');
  const links = await rows(db, `select kind from user_sanctions where report_id = $1 order by id`, [rid]);
  assert.deepEqual(links.map((x) => x.kind), ['warning', 'ban']);
  // The old switch lifts it.
  await call(ADMIN, `select admin_set_customer_blocked($1, false)`, [C]);
  assert.equal((await q(C, `select * from my_restriction()`)).filter((x) => x.kind !== 'warning').length, 0);
});
