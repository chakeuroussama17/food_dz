// Checkout: 1% tax, promo codes (rules, limits, who pays), cash amounts,
// statements and the admin page functions.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a';
const C2 = 'abababab-0000-4000-8000-0000000000ab';
const O = 'cccccccc-0000-4000-8000-00000000000c';
const D = 'd1d1d1d1-0000-4000-8000-0000000000d1';
const PIZZA = '11111111-1111-4111-8111-111111111111';
const BURGER = '22222222-2222-4222-8222-222222222222';

let db;
let margherita; // 700 DA
const addr = {};
const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));
const q = (u, sql, params) => asU(u, () => rows(db, sql, params));
const rejects = (u, sql, params, re) => asU(u, () => assert.rejects(db.query(sql, params), re));

/** Places 2 × Margherita (1400 DA) for [c], with [code]. */
const place = async (c = C, code = null, extra = {}) => (await q(c,
  `select * from place_order($1, $2::jsonb, $3, '0550123456', '', $4, null, $5, $6)`,
  [PIZZA, JSON.stringify([{ id: margherita, qty: 2 }]), addr[c],
   extra.expected ?? null, code, extra.payment ?? 'cash']))[0];

async function saveCode(fields) {
  const f = {
    id: null, code: 'TEST', kind: 'percent', value: 10, max_discount: null,
    min_order: 0, max_uses: null, per_customer: null, starts_at: null, ends_at: null,
    restaurant_id: null, funded_by: 'platform', note: '', ...fields,
  };
  return (await q(ADMIN, `select admin_save_promo_code($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) id`,
    [f.id, f.code, f.kind, f.value, f.max_discount, f.min_order, f.max_uses,
     f.per_customer, f.starts_at, f.ends_at, f.restaurant_id, f.funded_by, f.note]))[0].id;
}

async function deliver(id) {
  await call(O, `select owner_set_order_status($1, 'accepted')`, [id]);
  await call(D, `select driver_claim_order($1)`, [id]);
  await call(O, `select owner_set_order_status($1, 'ready')`, [id]);
  await call(D, `select driver_set_order_status($1, 'picked_up')`, [id]);
  await call(D, `insert into storage.objects (bucket_id, name, owner) values ('delivery-proofs', $1, $2)`, [`${id}/p.jpg`, D]);
  await call(D, `select driver_complete_delivery($1, $2)`, [id, `${id}/p.jpg`]);
}

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [C, 'c@test.dz', 'Amina'],
    [C2, 'c2@test.dz', 'Bilal'],
    [O, 'o@test.dz', 'Omar'],
    [D, 'd@test.dz', 'Rachid'],
  ], { taxRate: 0.01 });
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true, commission_rate = 0.1 where id = $2`, [O, PIZZA]);
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  for (const c of [C, C2]) {
    addr[c] = (await q(c, `insert into addresses (label, address_text, area) values ('home', 'Rue 1', 'Kouba') returning id`))[0].id;
  }
  await call(D, `select register_driver('0661000001', 'moto')`);
  await call(ADMIN, `select admin_set_driver_approved($1, true)`, [D]);
  await call(D, `select driver_set_online(true)`);
});

test('tax: 1% of the food, in the total; only cash accepted', async () => {
  const o = await place();
  assert.equal(o.food_total, 1400);
  assert.equal(o.tax_amount, 14);
  assert.equal(o.discount_amount, 0);
  assert.equal(o.total, 1400 + 14 + 200);
  // The app sends the total it showed: an old total is refused.
  await asU(C, () => assert.rejects(place(C, null, { expected: 1600 }), /prices_changed/));
  await asU(C, () => assert.rejects(place(C, null, { payment: 'card' }), /payment_unavailable/));
  await call(C, `select cancel_my_order($1)`, [o.id]);
});

test('promo: percent with cap, amount, minimum, dates, restaurant', async () => {
  await saveCode({ code: 'bienvenue', kind: 'percent', value: 20, max_discount: 250 });
  const [p] = await q(C, `select * from check_promo($1, ' Bienvenue ', 1400)`, [PIZZA]);
  assert.equal(p.code, 'BIENVENUE');
  assert.equal(p.discount, 250); // 20% = 280, capped at 250

  await saveCode({ code: 'MOINS300', kind: 'amount', value: 300, min_order: 1500 });
  await rejects(C, `select * from check_promo($1, 'MOINS300', 1400)`, [PIZZA], /promo_min_order/);
  assert.equal((await q(C, `select * from check_promo($1, 'MOINS300', 2000)`, [PIZZA]))[0].discount, 300);

  await rejects(C, `select * from check_promo($1, 'NOPE', 1400)`, [PIZZA], /promo_invalid/);
  await saveCode({ code: 'BURGERONLY', restaurant_id: BURGER });
  await rejects(C, `select * from check_promo($1, 'BURGERONLY', 1400)`, [PIZZA], /promo_not_here/);
  await saveCode({ code: 'SOON', starts_at: new Date(Date.now() + 864e5).toISOString() });
  await rejects(C, `select * from check_promo($1, 'SOON', 1400)`, [PIZZA], /promo_not_started/);
  await saveCode({ code: 'OLD', starts_at: '2020-01-01', ends_at: '2020-02-01' });
  await rejects(C, `select * from check_promo($1, 'OLD', 1400)`, [PIZZA], /promo_expired/);
  const off = await saveCode({ code: 'OFF' });
  await call(ADMIN, `select admin_set_promo_active($1, false)`, [off]);
  await rejects(C, `select * from check_promo($1, 'OFF', 1400)`, [PIZZA], /promo_invalid/);
});

test('order with a code: discount, tax after discount, cash, limits', async () => {
  const o = await place(C, 'BIENVENUE');
  assert.equal(o.discount_amount, 250);
  assert.equal(o.tax_amount, Math.round((1400 - 250) * 0.01)); // 12 (11.5 → 12)
  assert.equal(o.total, 1400 - 250 + 12 + 200);
  const [mine] = await q(C, `select * from my_orders($1)`, [o.id]);
  assert.equal(mine.promo_code, 'BIENVENUE');
  assert.equal(mine.payment_method, 'cash');
  assert.equal(mine.discount_amount, 250);

  // Limits: 1 per customer, 2 in total.
  await saveCode({ code: 'ONCE', kind: 'amount', value: 100, per_customer: 1, max_uses: 2 });
  const once = await place(C, 'ONCE');
  await asU(C, () => assert.rejects(place(C, 'ONCE'), /promo_already_used/));
  // A cancelled order gives the use back.
  await call(C, `select cancel_my_order($1)`, [once.id]);
  await call(C, `select cancel_my_order($1)`, [o.id]);
  const again = await place(C, 'ONCE');
  assert.equal(again.discount_amount, 100);
  await place(C2, 'ONCE');
  // Two uses in total: nobody else can use it now.
  await rejects(C2, `select * from check_promo($1, 'ONCE', 1400)`, [PIZZA], /promo_used_up/);
  await db.query(`update orders set status = 'cancelled', cancelled_at = now() where promo_code_id is not null`);
});

test('who pays: the cash, the commission and the statement add up', async () => {
  await db.query(`update orders set status = 'cancelled', cancelled_at = now() where status in ('placed')`);
  await saveCode({ code: 'APP200', kind: 'amount', value: 200, funded_by: 'platform' });
  await saveCode({ code: 'RESTO200', kind: 'amount', value: 200, funded_by: 'restaurant' });
  const a = await place(C, 'APP200');   // food 1400, −200, tax 12, fee 200 → 1412
  await deliver(a.id);
  await db.query(`update orders set cash_handed_at = now(), cash_confirmed_at = now() where id = $1`, [a.id]);
  const b = await place(C2, 'RESTO200'); // same amounts
  await deliver(b.id);

  // The rider hands the restaurant: food − discount + tax.
  const cash = await q(D, `select * from driver_cash_pending()`);
  assert.equal(cash.length, 1);
  assert.equal(cash[0].food_total, 1400 - 200 + 12);
  assert.equal((await q(D, `select * from my_driver()`))[0].cash_owed, 1212);
  assert.equal((await q(O, `select * from owner_cash_pending()`))[0].food_total, 1212);

  const [ra] = await rows(db, `select commission_amount, total from orders where id = $1`, [a.id]);
  const [rb] = await rows(db, `select commission_amount from orders where id = $1`, [b.id]);
  assert.equal(ra.total, 1412);
  assert.equal(ra.commission_amount, 140); // platform pays: commission on the full food
  assert.equal(rb.commission_amount, 120); // restaurant pays: on food after discount

  await db.query(`update orders set delivered_at = now() - interval '2 days' where id in ($1, $2)`, [a.id, b.id]);
  const day = new Date(Date.now() - 2 * 864e5).toISOString().slice(0, 10);
  const sid = (await q(ADMIN, `select admin_generate_statement($1, $2, $2) id`, [PIZZA, day]))[0].id;
  const [s] = await q(ADMIN, `select * from admin_list_statements($1)`, [PIZZA]);
  assert.equal(s.id, sid);
  assert.equal(s.commission_total, 260);
  assert.equal(s.tax_total, 24);
  assert.equal(s.discount_total, 200); // only the platform-paid one
  assert.equal(s.amount_due, 260 + 24 - 200);
  const det = (await q(O, `select owner_statement_detail($1) d`, [sid]))[0].d;
  assert.equal(det.orders.length, 2);
  assert.deepEqual(det.orders.map((x) => x.amount_due).sort((x, y) => x - y), [-48, 132]);
  assert.equal((await q(O, `select * from owner_statements()`))[0].amount_due, 84);
});

test('admin page: list with uses; codes checked; others refused', async () => {
  const list = await q(ADMIN, `select * from admin_promo_codes()`);
  const app = list.find((x) => x.code === 'APP200');
  assert.equal(app.uses, 1);
  assert.equal(Number(app.discount_given), 200);
  await asU(ADMIN, () => assert.rejects(saveCode({ code: 'APP200' }), /code_taken/));
  await asU(ADMIN, () => assert.rejects(saveCode({ code: 'a b' }), /invalid_code/));
  await asU(ADMIN, () => assert.rejects(saveCode({ code: 'BIG', value: 95 }), /invalid_value/));
  // Editing keeps the code's id.
  await saveCode({ id: app.id, code: 'APP250', kind: 'amount', value: 250 });
  assert.ok((await q(ADMIN, `select * from admin_promo_codes()`)).some((x) => x.id === app.id && x.code === 'APP250'));
  await rejects(C, `select * from admin_promo_codes()`, [], /./);
  await rejects(C, `select admin_set_promo_active($1, false)`, [app.id], /./);
  // Customers can't read the table.
  await rejects(C, `select * from promo_codes`, [], /permission denied/);
});
