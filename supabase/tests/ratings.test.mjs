// Ratings: food + delivery, windows, reviews, replies, flags, reports, blocks.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a'; // Amina Benali
const C2 = 'abababab-0000-4000-8000-0000000000ab'; // Bilal
const C3 = 'acacacac-0000-4000-8000-0000000000ac'; // Chakib (deletes account)
const O = 'cccccccc-0000-4000-8000-00000000000c'; // pizzeria owner
const M = 'bbbbbbbb-0000-4000-8000-00000000000b'; // manager
const S = '99999999-0000-4000-8000-000000000009'; // staff
const X = 'dddddddd-0000-4000-8000-00000000000d'; // other owner
const D = 'd1d1d1d1-0000-4000-8000-0000000000d1'; // driver
const D2 = 'd2d2d2d2-0000-4000-8000-0000000000d2'; // other driver
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let margherita;
const addr = {};

const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));
const q = (u, sql, params) => asU(u, () => rows(db, sql, params));
const anon = (sql, params) => as(db, 'anon', null, () => rows(db, sql, params));
const rejects = (u, sql, params, re) => asU(u, () => assert.rejects(db.query(sql, params), re));

/** A delivered order of [customer] (driver [driver]). */
async function delivered(customer = C, driver = D) {
  const [o] = await q(customer, `select * from place_order($1, $2::jsonb, $3, '0550123456')`,
    [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr[customer]]);
  await call(O, `select owner_set_order_status($1, 'accepted')`, [o.id]);
  await call(driver, `select driver_claim_order($1)`, [o.id]);
  await call(O, `select owner_set_order_status($1, 'ready')`, [o.id]);
  await call(driver, `select driver_set_order_status($1, 'picked_up')`, [o.id]);
  await call(driver, `insert into storage.objects (bucket_id, name, owner) values ('delivery-proofs', $1, $2)`, [`${o.id}/p.jpg`, driver]);
  await call(driver, `select driver_complete_delivery($1, $2)`, [o.id, `${o.id}/p.jpg`]);
  return o.id;
}
const rate = (u, id, part, stars, reasons = [], comment = '') =>
  call(u, `select rate_order($1, $2, $3, $4::text[], $5)`, [id, part, stars, reasons, comment]);
const ratingRow = async (id) => (await rows(db, `select * from order_ratings where order_id = $1`, [id]))[0];

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [C, 'c@test.dz', 'Amina Benali'],
    [C2, 'c2@test.dz', 'Bilal'],
    [C3, 'c3@test.dz', 'Chakib Haddad'],
    [O, 'o@test.dz', 'Omar'],
    [M, 'm@test.dz', 'Mounir'],
    [S, 's@test.dz', 'Samia'],
    [X, 'x@test.dz', 'Xavier'],
    [D, 'd@test.dz', 'Rachid'],
    [D2, 'd2@test.dz', 'Sofiane'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  await call(O, `select owner_add_member($1, 'm@test.dz', 'manager')`, [PIZZA]);
  await call(O, `select owner_add_member($1, 's@test.dz', 'staff')`, [PIZZA]);
  await call(X, `select register_restaurant('Chez X', '0550999888', 'Rue Y', 'Oran')`);
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  for (const c of [C, C2, C3]) {
    addr[c] = (await q(c, `insert into addresses (label, address_text, area) values ('home', 'Rue 1', 'Kouba') returning id`))[0].id;
  }
  for (const [d, phone] of [[D, '0661000001'], [D2, '0661000002']]) {
    await call(d, `select register_driver($1, 'moto')`, [phone]);
    await call(ADMIN, `select admin_set_driver_approved($1, true)`, [d]);
    await call(d, `select driver_set_online(true)`);
  }
});

let first; // the first delivered order

test('rate the food and the delivery: stars, reasons only when poor, name label', async () => {
  first = await delivered();
  await rate(C, first, 'driver', 5, ['late'], 'Très aimable');
  await rate(C, first, 'food', 2, ['cold', 'small_portion'], 'Froide, petite');
  const r = await ratingRow(first);
  assert.equal(r.customer_label, 'Amina B.');
  assert.equal(r.driver_stars, 5);
  assert.deepEqual(r.driver_reasons, []); // good rating: no reasons kept
  assert.equal(r.food_stars, 2);
  assert.deepEqual(r.food_reasons, ['cold', 'small_portion']);
  assert.equal(r.driver_id, D);
  assert.equal(r.restaurant_id, PIZZA);

  const [mine] = await q(C, `select * from my_order_ratings($1)`, [first]);
  assert.equal(mine.food_stars, 2);
  assert.equal(mine.driver_stars, 5);
  assert.equal(mine.has_driver, true);
});

test('rules: own delivered order, valid stars / reasons / comment / part', async () => {
  await rejects(C2, `select rate_order($1, 'food', 5)`, [first], /order_not_found/);
  await rejects(C, `select rate_order($1, 'food', 6)`, [first], /invalid_stars/);
  await rejects(C, `select rate_order($1, 'food', 0)`, [first], /invalid_stars/);
  await rejects(C, `select rate_order($1, 'chef', 3)`, [first], /invalid_part/);
  await rejects(C, `select rate_order($1, 'food', 2, array['late'])`, [first], /invalid_reasons/);
  await rejects(C, `select rate_order($1, 'driver', 2, array['cold'])`, [first], /invalid_reasons/);
  await rejects(C, `select rate_order($1, 'food', 2, '{}', $2)`, [first, 'x'.repeat(301)], /invalid_comment/);
  await as(db, 'anon', null, () => assert.rejects(
    db.query(`select rate_order($1, 'food', 5)`, [first]), /permission denied/));

  // Not delivered yet.
  const [o] = await q(C2, `select * from place_order($1, $2::jsonb, $3, '0550123456')`,
    [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr[C2]]);
  await rejects(C2, `select rate_order($1, 'food', 5)`, [o.id], /not_delivered/);
  await call(O, `select owner_set_order_status($1, 'rejected', 'Test')`, [o.id]);
  await rejects(C2, `select rate_order($1, 'food', 5)`, [o.id], /not_delivered/);

  // Nobody can read the table directly.
  await asU(C, () => assert.rejects(db.query(`select * from order_ratings`), /permission denied/));
});

test('windows: 7 days to rate, 24 hours to change it', async () => {
  // Change within 24 h: fine, the first date is kept.
  await rate(C, first, 'food', 4);
  assert.equal((await ratingRow(first)).food_stars, 4);

  // 25 h later: locked (food), the other part is still open.
  await db.query(`update order_ratings set food_rated_at = now() - interval '25 hours' where order_id = $1`, [first]);
  await rejects(C, `select rate_order($1, 'food', 1)`, [first], /rating_locked/);
  await rate(C, first, 'driver', 4);

  // Older than 7 days and never rated: closed.
  const old = await delivered(C2);
  // (cash settled, so the driver isn't blocked by the 24 h cash rule)
  await db.query(`update orders set delivered_at = now() - interval '8 days',
                    cash_handed_at = now(), cash_confirmed_at = now() where id = $1`, [old]);
  await rejects(C2, `select rate_order($1, 'food', 5)`, [old], /window_closed/);

  // A delivered order without a driver can't rate one.
  const nd = await delivered(C2);
  await db.query(`update orders set driver_id = null where id = $1`, [nd]);
  await rejects(C2, `select rate_order($1, 'driver', 5)`, [nd], /no_driver/);
  await rate(C2, nd, 'food', 5);
});

test('averages show from 5 ratings; cards, page and public reviews follow', async () => {
  // So far food ratings: first (4) + nd (5) = 2.
  const [card0] = await anon(`select rating_avg, rating_count from list_restaurants() where id = $1`, [PIZZA]);
  assert.equal(card0.rating_avg, null);
  assert.equal(card0.rating_count, 2);

  const ids = [];
  for (const [c, stars] of [[C2, 5], [C, 3], [C2, 5]]) {
    const id = await delivered(c);
    await rate(c, id, 'food', stars, stars <= 3 ? ['bad_taste'] : [], stars === 5 ? 'Excellent !' : '');
    ids.push(id);
  }
  // (4 + 5 + 5 + 3 + 5) / 5 = 4.4
  const [card] = await anon(`select rating_avg, rating_count from list_restaurants() where id = $1`, [PIZZA]);
  assert.equal(Number(card.rating_avg), 4.4);
  assert.equal(card.rating_count, 5);
  const [st] = await anon(`select * from restaurant_status($1)`, [PIZZA]);
  assert.equal(Number(st.rating_avg), 4.4);

  const pub = await anon(`select * from restaurant_reviews('pizzeria-el-bahdja')`);
  assert.equal(pub.length, 5);
  assert.equal(pub[0].customer_label, 'Bilal');
  assert.ok(pub.every((p) => p.stars >= 3));
  assert.deepEqual(await anon(`select * from restaurant_reviews('chez-x')`), []);
  assert.equal((await anon(`select * from restaurant_reviews('pizzeria-el-bahdja', 2, 3)`)).length, 2);
  test.ids = ids;
});

test('reviews for the restaurant: managers see them, staff and others do not', async () => {
  const day = `now() - interval '2 days', now() + interval '1 day'`;
  const list = await q(M, `select * from owner_reviews(null, ${day})`);
  assert.equal(list.length, 5);
  assert.equal(list.find((r) => r.order_id === first).items, 'Pizza Margherita');
  assert.equal((await q(O, `select * from owner_reviews(array[$1]::uuid[])`, [PIZZA])).length, 5);
  assert.equal((await q(S, `select * from owner_reviews()`)).length, 0);
  assert.equal((await q(X, `select * from owner_reviews()`)).length, 0);
  assert.equal((await q(C, `select * from owner_reviews()`)).length, 0);
  assert.equal((await q(O, `select * from owner_reviews(null, now() + interval '1 day', now() + interval '2 days')`)).length, 0);
});

test('reply once, flag once; staff, outsiders and customers can do neither', async () => {
  const [target] = test.ids;
  await call(M, `select owner_reply_review($1, 'Merci beaucoup !')`, [target]);
  await rejects(O, `select owner_reply_review($1, 'Encore')`, [target], /already_replied/);
  await rejects(S, `select owner_reply_review($1, 'Hi')`, [target], /not_found/);
  await rejects(X, `select owner_reply_review($1, 'Hi')`, [target], /not_found/);
  await rejects(C, `select owner_reply_review($1, 'Hi')`, [target], /not_found/);
  const lowOne = test.ids[1];
  await rejects(O, `select owner_reply_review($1, '')`, [lowOne], /invalid_reply/);
  await rejects(O, `select owner_reply_review($1, $2)`, [lowOne, 'x'.repeat(301)], /invalid_reply/);

  // The reply is public and the customer sees it too.
  const pub = await anon(`select reply from restaurant_reviews('pizzeria-el-bahdja') where reply is not null`);
  assert.deepEqual(pub.map((p) => p.reply), ['Merci beaucoup !']);
  assert.equal((await q(C2, `select reply from my_order_ratings($1)`, [target]))[0].reply, 'Merci beaucoup !');

  await call(M, `select owner_flag_review($1, 'Commentaire sur la livraison, pas sur la cuisine')`, [lowOne]);
  await rejects(O, `select owner_flag_review($1, 'Encore une fois')`, [lowOne], /already_flagged/);
  await rejects(O, `select owner_flag_review($1, 'x')`, [first], /invalid_reason/);
  await rejects(S, `select owner_flag_review($1, 'Pas permis')`, [first], /not_found/);
});

test('admin decides on flagged reviews; hidden ones count nowhere', async () => {
  const lowOne = test.ids[1];
  const pending = await q(ADMIN, `select * from admin_flagged_reviews()`);
  assert.equal(pending.length, 1);
  assert.equal(pending[0].flag_decision, null);
  assert.equal(pending[0].restaurant_name, 'Pizzeria El Bahdja');
  await asU(O, () => assert.rejects(db.query(`select * from admin_flagged_reviews()`), /admin only/));
  await asU(O, () => assert.rejects(db.query(`select admin_review_decision($1, true)`, [lowOne]), /admin only/));

  const rest = (await q(ADMIN, `select * from admin_restaurant_ratings()`)).find((r) => r.restaurant_id === PIZZA);
  assert.equal(rest.flagged_pending, 1);

  // Hide it: gone from public, owner list and the average (now 4 ratings: no average).
  await call(ADMIN, `select admin_review_decision($1, true)`, [lowOne]);
  assert.equal((await anon(`select * from restaurant_reviews('pizzeria-el-bahdja')`)).length, 4);
  assert.equal((await q(O, `select * from owner_reviews()`)).length, 4);
  const [card] = await anon(`select rating_avg, rating_count from list_restaurants() where id = $1`, [PIZZA]);
  assert.equal(card.rating_avg, null);
  assert.equal(card.rating_count, 4);
  await rejects(O, `select owner_reply_review($1, 'Trop tard')`, [lowOne], /not_found/);
  // The customer still sees their own review.
  assert.equal((await q(C, `select food_stars from my_order_ratings($1)`, [lowOne]))[0].food_stars, 3);
  assert.equal((await q(ADMIN, `select * from admin_flagged_reviews()`))[0].flag_decision, 'hidden');

  // Keep it: back everywhere.
  await call(ADMIN, `select admin_review_decision($1, false)`, [lowOne]);
  assert.equal((await anon(`select * from restaurant_reviews('pizzeria-el-bahdja')`)).length, 5);
  assert.equal((await q(ADMIN, `select * from admin_flagged_reviews()`))[0].flag_decision, 'kept');
  await asU(ADMIN, () => assert.rejects(
    db.query(`select admin_review_decision($1, true)`, ['00000000-0000-4000-8000-000000000000']), /not_found/));
});

test('driver sees an average from 5 ratings and the reasons, never who', async () => {
  // Rate the driver on a few more deliveries.
  for (const [c, stars, reasons] of [[C, 2, ['late']], [C2, 1, ['late', 'rude']]]) {
    const id = await delivered(c);
    await rate(c, id, 'driver', stars, reasons);
  }
  const mine = (await q(D, `select * from driver_rating_summary()`))[0];
  // first (4) + the 2 above; other deliveries had no driver rating yet.
  assert.equal(mine.rating_count, 3);
  assert.equal(mine.rating_avg, null);
  assert.deepEqual(mine.reasons, { late: 2, rude: 1 });

  for (const c of [C2, C]) {
    const id = await delivered(c);
    await rate(c, id, 'driver', 5);
  }
  const after = (await q(D, `select * from driver_rating_summary()`))[0];
  assert.equal(after.rating_count, 5);
  assert.equal(Number(after.rating_avg), 3.4);

  await rejects(C, `select * from driver_rating_summary()`, [], /not_a_driver/);
  assert.equal((await q(D2, `select * from driver_rating_summary()`))[0].rating_count, 0);
});

test('admin sees every driver with averages and warnings', async () => {
  const list = await q(ADMIN, `select * from admin_driver_ratings()`);
  const d = list.find((x) => x.driver_id === D);
  assert.equal(d.name, 'Rachid');
  assert.equal(d.rated_count, 5);
  assert.equal(Number(d.rating_avg), 3.4);
  assert.equal(d.low_30d, 2);
  assert.equal(d.reasons.late, 2);
  assert.equal(list.find((x) => x.driver_id === D2).rated_count, 0);
  assert.equal(list[0].driver_id, D); // worst first
  await asU(D, () => assert.rejects(db.query(`select * from admin_driver_ratings()`), /admin only/));
});

test('reports about customers: driver or restaurant team, once, private', async () => {
  const id = await delivered(C3);
  await call(D, `select report_customer($1, 'no_answer', 'Ne répond pas')`, [id]);
  await call(S, `select report_customer($1, 'rude')`, [id]);
  await rejects(D, `select report_customer($1, 'rude')`, [id], /already_reported/);
  await rejects(D2, `select report_customer($1, 'rude')`, [id], /order_not_found/);
  await rejects(X, `select report_customer($1, 'rude')`, [id], /order_not_found/);
  await rejects(C3, `select report_customer($1, 'rude')`, [id], /order_not_found/);
  await rejects(O, `select report_customer($1, 'swearing')`, [id], /invalid_reason/);
  await rejects(O, `select report_customer($1, 'rude', $2)`, [id, 'x'.repeat(301)], /invalid_note/);
  await as(db, 'anon', null, () => assert.rejects(
    db.query(`select report_customer($1, 'rude')`, [id]), /permission denied/));

  assert.deepEqual((await q(D, `select * from my_reported_orders()`)).map((r) => r.order_id), [id]);
  assert.equal((await q(D2, `select * from my_reported_orders()`)).length, 0);
  await asU(C3, () => assert.rejects(db.query(`select * from customer_reports`), /permission denied/));
  await asU(D, () => assert.rejects(db.query(`select * from admin_customer_reports()`), /admin only/));

  const list = await q(ADMIN, `select * from admin_customer_reports()`);
  assert.equal(list.length, 2);
  assert.deepEqual(new Set(list.map((r) => r.reporter_role)), new Set(['driver', 'restaurant']));
  assert.equal(list[0].customer_name, 'Chakib Haddad');
  assert.equal(list[0].customer_reports_total, 2);
  assert.equal(list[0].customer_blocked, false);
  test.reportId = list.find((r) => r.reporter_role === 'driver').id;
  test.chakibOrder = id;
});

test('blocking a customer stops new orders; unblocking restores them', async () => {
  const place = () => q(C3, `select * from place_order($1, $2::jsonb, $3, '0550123456')`,
    [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr[C3]]);
  await call(ADMIN, `select admin_handle_report($1, 'warned', 'Avertissement')`, [test.reportId]);
  const [w] = (await q(ADMIN, `select * from admin_customer_reports('warned')`));
  assert.equal(w.admin_note, 'Avertissement');
  const o = await place(); // a warning does not block
  await call(O, `select owner_set_order_status($1, 'rejected', 'Test')`, [o[0].id]);

  await call(ADMIN, `select admin_handle_report($1, 'blocked')`, [test.reportId]);
  await rejects(C3, `select * from place_order($1, $2::jsonb, $3, '0550123456')`,
    [PIZZA, JSON.stringify([{ id: margherita, qty: 1 }]), addr[C3]], /account_blocked/);
  assert.equal((await q(ADMIN, `select customer_blocked from admin_customer_reports('blocked')`))[0].customer_blocked, true);

  await rejects(C3, `select admin_set_customer_blocked($1, false)`, [C3], /admin only/);
  await call(ADMIN, `select admin_set_customer_blocked($1, false)`, [C3]);
  const again = await place();
  await call(O, `select owner_set_order_status($1, 'rejected', 'Test')`, [again[0].id]);
  await rejects(ADMIN, `select admin_handle_report($1, 'banned')`, [test.reportId], /invalid_status/);
});

test('a deleted account no longer shows its name on its review', async () => {
  const id = test.chakibOrder;
  await rate(C3, id, 'food', 5, [], 'Top');
  assert.equal((await ratingRow(id)).customer_label, 'Chakib H.');
  await call(C3, `select delete_my_account()`);
  const r = await ratingRow(id);
  assert.equal(r.customer_id, null);
  assert.equal(r.customer_label, 'Client');
  assert.equal(r.food_stars, 5); // the review stays
  // Reports keep the snapshot for the admin.
  assert.equal((await q(ADMIN, `select customer_name from admin_customer_reports() limit 1`))[0].customer_name, 'Chakib Haddad');
});

test('reminders: delivered 40 min to 3 h ago, unrated, once', async () => {
  // (the hourly order limit looks at placed_at)
  await db.query(`update orders set placed_at = now() - interval '2 hours' where placed_at > now() - interval '2 hours'`);
  const fresh = await delivered(C2); // just delivered: too early
  const due = await delivered(C2);
  const rated = await delivered(C2);
  const tooOld = await delivered(C2);
  await db.query(`update orders set delivered_at = now() - interval '1 hour' where id = any($1::uuid[])`, [[due, rated]]);
  await db.query(`update orders set delivered_at = now() - interval '5 hours' where id = $1`, [tooOld]);
  await rate(C2, rated, 'food', 5);
  await db.query(`delete from rating_reminders`);

  assert.equal((await rows(db, `select send_rating_reminders() n`))[0].n, 1);
  assert.deepEqual((await rows(db, `select order_id from rating_reminders`)).map((r) => r.order_id), [due]);
  assert.equal((await rows(db, `select send_rating_reminders() n`))[0].n, 0);
  assert.ok(fresh);

  // Not callable by apps.
  await asU(C2, () => assert.rejects(db.query(`select send_rating_reminders()`), /permission denied/));
});
