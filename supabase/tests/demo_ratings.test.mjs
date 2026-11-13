// The optional demo ratings file runs on a real database, creates what it
// promises for every role, can be run twice, and can be removed.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { freshDb, as, rows, root } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const CLIENT = 'aaaaaaaa-0000-4000-8000-00000000000a';
const OWNER = 'cccccccc-0000-4000-8000-00000000000c';
const DRIVER = 'd1d1d1d1-0000-4000-8000-0000000000d1';
const R1 = '11111111-1111-4111-8111-111111111111';

const demo = readFileSync(join(root, 'dashboard', '2026-11-20b_demo_ratings_OPTIONAL.sql'), 'utf8');
const remove = readFileSync(join(root, 'dashboard', '2026-11-20c_remove_demo_ratings.sql'), 'utf8');

let db;
const asU = (u, fn) => as(db, 'authenticated', u, fn);
const q = (u, sql, params) => asU(u, () => rows(db, sql, params));

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@gmail.com', 'Admin'],
    [CLIENT, 'client@gmail.com', 'Amina Benali'],
    [OWNER, 'restaurant@gmail.com', 'Omar'],
    [DRIVER, 'driver@gmail.com', 'Rachid'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [OWNER]);
  await db.query(`update profiles set role = 'driver' where id = $1`, [DRIVER]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [OWNER, R1]);
  await db.query(`insert into drivers (id, phone, vehicle, is_approved) values ($1, '0661000001', 'moto', true)`, [DRIVER]);
  await db.exec(demo);
});

test('restaurants: reviews with replies, averages, complaints', async () => {
  for (const slug of ['pizzeria-el-bahdja', 'burger-house-hydra', 'dar-lgharbi']) {
    const list = await as(db, 'anon', null, () => rows(db, `select * from restaurant_reviews($1, 50)`, [slug]));
    assert.ok(list.length >= 9, `${slug}: ${list.length} reviews`);
    assert.ok(list.some((r) => r.reply), `${slug}: some replies`);
    assert.ok(list.some((r) => r.comment), `${slug}: some comments`);
  }
  const [card] = await as(db, 'anon', null, () => rows(db, `select rating_avg, rating_count from list_restaurants() where id = $1`, [R1]));
  assert.ok(Number(card.rating_avg) >= 3 && Number(card.rating_avg) <= 5, `average ${card.rating_avg}`);
  assert.ok(card.rating_count >= 15);

  const day = `now() - interval '40 days', now() + interval '1 day'`;
  const mine = await q(OWNER, `select * from owner_reviews(null, ${day})`);
  assert.ok(mine.length >= 15);
  assert.ok(mine.some((r) => r.stars <= 2 && r.reasons.length > 0), 'poor reviews carry reasons');
  assert.ok(mine.some((r) => r.flag_decision === 'kept'));
  assert.ok(mine.some((r) => r.flagged_at && !r.flag_decision), 'one flag waits for the admin');
});

test('driver: delivery ratings with an average and reasons', async () => {
  const s = (await q(DRIVER, `select * from driver_rating_summary()`))[0];
  assert.ok(s.rating_count >= 25);
  assert.ok(s.rating_avg !== null);
  assert.ok(Object.keys(s.reasons).length > 0);
  const list = await q(ADMIN, `select * from admin_driver_ratings()`);
  assert.equal(list.length, 1);
  assert.ok(list[0].rated_count >= 25);
});

test('customer: four orders to try the screens', async () => {
  const ratings = await q(CLIENT, `select * from my_order_ratings()`);
  const now = Date.now();
  const hours = (r) => (now - new Date(r.delivered_at).getTime()) / 3.6e6;
  const a = ratings.find((r) => hours(r) > 1.5 && hours(r) < 2.5 && r.food_stars === null && r.driver_stars === null);
  assert.ok(a, 'delivered 2 h ago, unrated: the pop-up case');
  const b = ratings.find((r) => hours(r) > 60 && hours(r) < 80 && r.driver_stars === 5 && r.food_stars === null);
  assert.ok(b, 'delivered 3 days ago, driver rated, food open');
  const c = ratings.find((r) => hours(r) > 1 && hours(r) < 1.4 && r.food_stars === 5 && r.reply);
  assert.ok(c, 'rated and answered, still editable');
  // The customer can really rate the open ones (rules from the database).
  await asU(CLIENT, () => db.query(`select rate_order($1, 'driver', 5)`, [a.order_id]));
  await asU(CLIENT, () => db.query(`select rate_order($1, 'food', 4)`, [b.order_id]));
  await asU(CLIENT, () => db.query(`select rate_order($1, 'food', 5)`, [c.order_id]));
  // The 8-day-old order is too late.
  const d = ratings.find((r) => hours(r) > 7 * 24 && hours(r) < 9 * 24);
  await asU(CLIENT, () => assert.rejects(db.query(`select rate_order($1, 'food', 5)`, [d.order_id]), /window_closed/));
});

test('admin: flagged reviews and reports about the demo customer', async () => {
  const flagged = await q(ADMIN, `select * from admin_flagged_reviews()`);
  assert.equal(flagged.length, 2);
  assert.equal(flagged.filter((f) => !f.flag_decision).length, 1);
  const reports = await q(ADMIN, `select * from admin_customer_reports()`);
  assert.equal(reports.length, 4);
  assert.deepEqual(reports.map((r) => r.status).sort(), ['dismissed', 'open', 'open', 'warned']);
  assert.ok(reports.every((r) => r.customer_reports_total === 4));
  // Blocking works, and unblocking undoes it.
  const open = reports.find((r) => r.status === 'open');
  await asU(ADMIN, () => db.query(`select admin_handle_report($1, 'blocked')`, [open.id]));
  assert.equal((await q(ADMIN, `select customer_blocked from admin_customer_reports() limit 1`))[0].customer_blocked, true);
  await asU(ADMIN, () => db.query(`select admin_set_customer_blocked($1, false)`, [CLIENT]));
});

test('no money left open, nobody blocked, and the file can run again', async () => {
  assert.equal((await q(OWNER, `select * from owner_cash_pending()`)).length, 0);
  assert.equal((await q(DRIVER, `select * from driver_cash_pending()`)).length, 0);
  const before = (await rows(db, `select count(*)::int n from orders where notes = 'DEMO-RATINGS'`))[0].n;
  assert.ok(before >= 50);
  await db.exec(demo);
  assert.equal((await rows(db, `select count(*)::int n from orders where notes = 'DEMO-RATINGS'`))[0].n, before);
  // Triggers are back on.
  const t = await rows(db, `select tgname, tgenabled from pg_trigger where tgrelid = 'public.orders'::regclass and tgname in ('orders_before_write', 'orders_push')`);
  assert.ok(t.length >= 1 && t.every((x) => x.tgenabled === 'O'));
});

test('the removal file deletes everything it created', async () => {
  await db.exec(remove);
  for (const table of ['orders', 'order_ratings', 'customer_reports', 'order_items']) {
    assert.equal((await rows(db, `select count(*)::int n from ${table}`))[0].n, 0, table);
  }
  assert.equal((await rows(db, `select blocked_at from profiles where id = $1`, [CLIENT]))[0].blocked_at, null);
});
