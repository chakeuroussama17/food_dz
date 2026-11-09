// Orders, status rules, commission, admin API and commission statements.
import test from 'node:test';
import assert from 'node:assert/strict';
import { join } from 'node:path';
import { freshDb, as, rows, denied, read, root } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const A = 'aaaaaaaa-0000-4000-8000-00000000000a'; // customer
const B = 'bbbbbbbb-0000-4000-8000-00000000000b'; // other customer
const O = 'cccccccc-0000-4000-8000-00000000000c'; // owner
const PIZZA = '11111111-1111-4111-8111-111111111111';
const BURGER = '22222222-2222-4222-8222-222222222222';

let db;
let ownRestaurant;

/** Inserts an order directly (as the database owner, like place_order will). */
async function order({
  restaurant = PIZZA,
  customer = A,
  food = 1000,
  status = 'placed',
  deliveredDaysAgo = null,
  rate = 0.08,
}) {
  const [o] = await rows(
    db,
    `insert into orders (restaurant_id, customer_id, status, customer_name,
       customer_phone, address_text, food_total, delivery_fee, commission_rate,
       delivered_at)
     values ($1, $2, $3, 'Client', '0550123456', 'Rue 1', $4, 200, $5,
       case when $6::int is null then null else now() - make_interval(days => $6::int) end)
     returning id, code, total, commission_amount`,
    [restaurant, customer, status, food, rate, deliveredDaysAgo],
  );
  return o;
}

const today = () => new Date().toISOString().slice(0, 10);
const daysAgo = (n) => new Date(Date.now() - n * 864e5).toISOString().slice(0, 10);

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [A, 'a@test.dz', 'Amina'],
    [B, 'b@test.dz', 'Bilal'],
    [O, 'o@test.dz', 'Omar'],
  ]);
  // The admin role is only ever given by SQL in the dashboard.
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await as(db, 'authenticated', O, async () => {
    const [r] = await rows(
      db,
      `select register_restaurant('Chez Omar', '0550111222', 'Rue Didouche', 'Alger') as id`,
    );
    ownRestaurant = r.id;
  });
});

// ---------- access ----------
test('admin API: refused to customers, owners and anonymous visitors', async () => {
  for (const uid of [A, O]) {
    await as(db, 'authenticated', uid, async () => {
      await assert.rejects(db.query('select * from admin_list_restaurants()'), /admin only/);
      await assert.rejects(db.query(`select admin_set_restaurant_active($1, true)`, [ownRestaurant]), /admin only/);
      await assert.rejects(db.query(`select admin_stats($1, $2)`, [daysAgo(30), today()]), /admin only/);
      await assert.rejects(db.query(`select admin_generate_statement($1, $2, $3)`, [PIZZA, daysAgo(30), today()]), /admin only/);
    });
  }
  await as(db, 'anon', null, async () => {
    await denied(db.query('select * from admin_list_restaurants()'));
  });
});

test('nobody can make themselves admin', async () => {
  await as(db, 'authenticated', A, async () => {
    await denied(db.query(`update profiles set role = 'admin' where id = $1`, [A]));
  });
});

test('admin sees pending restaurants with owner details and approves them', async () => {
  await as(db, 'authenticated', ADMIN, async () => {
    const list = await rows(db, 'select * from admin_list_restaurants()');
    const mine = list.find((r) => r.id === ownRestaurant);
    assert.equal(mine.is_active, false);
    assert.equal(mine.owner_email, 'o@test.dz');
    assert.equal(mine.owner_name, 'Omar');
    assert.equal(Number(mine.effective_rate), 0.08);
    await db.query(`select admin_set_restaurant_active($1, true)`, [ownRestaurant]);
    await db.query(`select admin_set_commission($1, 0.10)`, [ownRestaurant]);
    await assert.rejects(db.query(`select admin_set_commission($1, 0.9)`, [ownRestaurant]), /invalid rate/);
  });
  const [r] = await rows(db, 'select is_active, commission_rate from restaurants where id = $1', [ownRestaurant]);
  assert.equal(r.is_active, true);
  assert.equal(Number(r.commission_rate), 0.1);
});

test('deactivating a restaurant also closes it', async () => {
  await db.query(`update restaurants set is_open = true where id = $1`, [ownRestaurant]);
  await as(db, 'authenticated', ADMIN, async () => {
    await db.query(`select admin_set_restaurant_active($1, false)`, [ownRestaurant]);
  });
  const [r] = await rows(db, 'select is_active, is_open from restaurants where id = $1', [ownRestaurant]);
  assert.deepEqual(r, { is_active: false, is_open: false });
  await db.query(`update restaurants set is_active = true where id = $1`, [ownRestaurant]);
});

test('admin edits settings and business details', async () => {
  await as(db, 'authenticated', ADMIN, async () => {
    await db.query(
      `select admin_update_config(250, 0.07, 'Food DZ', '0550000000', 'billing@food.dz', 'Alger', 'NIF123')`,
    );
    const [{ admin_get_config: c }] = await rows(db, 'select admin_get_config()');
    assert.equal(c.delivery_fee, 250);
    assert.equal(Number(c.default_commission_rate), 0.07);
    assert.equal(c.business_name, 'Food DZ');
  });
  await db.query(`update app_config set delivery_fee = 200, default_commission_rate = 0.08`);
});

// ---------- order rules ----------
test('total and commission are computed by the database', async () => {
  const o = await order({ food: 1234, status: 'delivered', deliveredDaysAgo: 1 });
  assert.equal(o.total, 1434);
  assert.equal(o.commission_amount, 99); // round(1234 * 0.08)
});

test('only allowed status changes; timestamps and commission set', async () => {
  const o = await order({ food: 2000 });
  await assert.rejects(db.query(`update orders set status = 'delivered' where id = $1`, [o.id]), /invalid status change/);
  await db.query(`update orders set status = 'accepted' where id = $1`, [o.id]);
  await db.query(`update orders set status = 'ready' where id = $1`, [o.id]);
  await db.query(`update orders set status = 'picked_up' where id = $1`, [o.id]);
  await db.query(`update orders set status = 'delivered' where id = $1`, [o.id]);
  const [r] = await rows(db, 'select accepted_at, ready_at, picked_up_at, delivered_at, commission_amount from orders where id = $1', [o.id]);
  assert.ok(r.accepted_at && r.ready_at && r.picked_up_at && r.delivered_at);
  assert.equal(r.commission_amount, 160);
  await assert.rejects(db.query(`update orders set status = 'cancelled' where id = $1`, [o.id]), /invalid status change/);
  const ev = await rows(db, 'select to_status from order_events where order_id = $1 order by id', [o.id]);
  assert.deepEqual(ev.map((e) => e.to_status), ['placed', 'accepted', 'ready', 'picked_up', 'delivered']);
});

test('amounts can never change after the order is placed', async () => {
  const o = await order({});
  await assert.rejects(db.query(`update orders set food_total = 1 where id = $1`, [o.id]), /cannot change/);
  await assert.rejects(db.query(`update orders set commission_rate = 0 where id = $1`, [o.id]), /cannot change/);
});

test('order visibility: own orders for customers, own restaurant for owners', async () => {
  const mine = await order({ customer: A, restaurant: ownRestaurant });
  const other = await order({ customer: B, restaurant: PIZZA });
  await as(db, 'authenticated', A, async () => {
    const ids = (await rows(db, 'select id from orders')).map((r) => r.id);
    assert.ok(ids.includes(mine.id));
    assert.ok(!ids.includes(other.id));
    assert.equal((await rows(db, 'select * from order_items where order_id = $1', [other.id])).length, 0);
    await denied(db.query(`update orders set status = 'cancelled' where id = $1`, [mine.id]));
    await denied(db.query(`insert into orders (restaurant_id, customer_name, customer_phone, address_text, food_total, delivery_fee, commission_rate) values ($1, 'x', '0550123456', 'abc', 10, 0, 0)`, [PIZZA]));
  });
  await as(db, 'authenticated', O, async () => {
    const ids = (await rows(db, 'select id from orders')).map((r) => r.id);
    assert.ok(ids.includes(mine.id));
    assert.ok(!ids.includes(other.id));
  });
  await as(db, 'anon', null, async () => {
    await denied(db.query('select id from orders'));
  });
});

// ---------- statements ----------
test('statement: bills only delivered, unbilled orders of that restaurant and period', async () => {
  // Fresh restaurant data for a clean count.
  await db.query(`delete from orders where restaurant_id = $1`, [BURGER]);
  const inPeriod = [
    await order({ restaurant: BURGER, food: 1000, status: 'delivered', deliveredDaysAgo: 3 }),
    await order({ restaurant: BURGER, food: 2500, status: 'delivered', deliveredDaysAgo: 5 }),
  ];
  await order({ restaurant: BURGER, food: 9999, status: 'delivered', deliveredDaysAgo: 40 }); // outside
  await order({ restaurant: BURGER, food: 7777, status: 'placed' }); // not delivered
  await order({ restaurant: PIZZA, food: 5555, status: 'delivered', deliveredDaysAgo: 3 }); // other restaurant

  await as(db, 'authenticated', ADMIN, async () => {
    const [{ admin_preview_statement: p }] = await rows(db, 'select admin_preview_statement($1, $2, $3)', [BURGER, daysAgo(14), today()]);
    assert.deepEqual(p, { orders_count: 2, food_total: 3500, commission_total: 280 });

    const [{ admin_generate_statement: sid }] = await rows(db, 'select admin_generate_statement($1, $2, $3)', [BURGER, daysAgo(14), today()]);
    const [{ admin_statement_detail: d }] = await rows(db, 'select admin_statement_detail($1)', [sid]);
    assert.match(d.statement.number, /^FD-\d{4}-0001$/);
    assert.equal(d.statement.commission_total, 280);
    assert.equal(d.orders.length, 2);
    assert.deepEqual(d.orders.map((o) => o.code).sort(), inPeriod.map((o) => o.code).sort());
    assert.equal(d.restaurant.name, 'Burger House');

    // Never billed twice.
    await assert.rejects(db.query('select admin_generate_statement($1, $2, $3)', [BURGER, daysAgo(14), today()]), /no orders to bill/);
    // Unfinished period refused.
    await assert.rejects(db.query('select admin_generate_statement($1, $2, $3)', [BURGER, today(), daysAgo(-3)]), /period not finished/);

    // Second statement gets the next number.
    const [{ admin_generate_statement: sid2 }] = await rows(db, 'select admin_generate_statement($1, $2, $3)', [BURGER, daysAgo(60), daysAgo(30)]);
    const [{ admin_statement_detail: d2 }] = await rows(db, 'select admin_statement_detail($1)', [sid2]);
    assert.match(d2.statement.number, /^FD-\d{4}-0002$/);

    // Paid statements can't be cancelled; issued ones free their orders.
    await db.query('select admin_set_statement_paid($1, true)', [sid]);
    await assert.rejects(db.query('select admin_cancel_statement($1)', [sid]), /already paid/);
    await db.query('select admin_cancel_statement($1)', [sid2]);
    const [{ admin_preview_statement: again }] = await rows(db, 'select admin_preview_statement($1, $2, $3)', [BURGER, daysAgo(60), daysAgo(30)]);
    assert.equal(again.orders_count, 1);

    const list = await rows(db, 'select number, status from admin_list_statements($1)', [BURGER]);
    assert.deepEqual(list.map((s) => s.status), ['paid']);
  });
});

test('owners can read their own statements only', async () => {
  await as(db, 'authenticated', O, async () => {
    assert.equal((await rows(db, 'select id from statements where restaurant_id = $1', [BURGER])).length, 0);
  });
});

test('stats add up', async () => {
  await as(db, 'authenticated', ADMIN, async () => {
    const [{ admin_stats: s }] = await rows(db, 'select admin_stats($1, $2)', [daysAgo(90), today()]);
    const [chk] = await rows(db, `select count(*)::int n, coalesce(sum(commission_amount),0)::int c from orders where status = 'delivered'`);
    assert.equal(s.delivered_orders, chk.n);
    assert.equal(s.commission, chk.c);
    assert.equal(s.customers, 2);
    const by = await rows(db, 'select * from admin_stats_by_restaurant($1, $2)', [daysAgo(90), today()]);
    assert.equal(by.reduce((t, r) => t + r.commission, 0), chk.c);
    const orders = await rows(db, 'select * from admin_list_orders($1, $2, $3)', [daysAgo(90), today(), BURGER]);
    assert.ok(orders.every((o) => o.restaurant_name === 'Burger House'));
    const cust = await rows(db, `select * from admin_list_customers('amina')`);
    assert.equal(cust.length, 1);
  });
});

test('demo orders script runs and is idempotent', async () => {
  const demo = read(join(root, 'demo_orders.sql'));
  await db.exec(demo);
  await db.exec(demo);
  const [r] = await rows(db, `select count(*)::int n, bool_and(food_total = (select sum(line_total) from order_items i where i.order_id = o.id)) ok from orders o where notes = 'DEMO'`);
  assert.ok(r.n > 20);
  assert.equal(r.ok, true);
  const [c] = await rows(db, `select bool_and(commission_amount = round(food_total * commission_rate)) ok from orders where notes = 'DEMO' and status = 'delivered'`);
  assert.equal(c.ok, true);
});
