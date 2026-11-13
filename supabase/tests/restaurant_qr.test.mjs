// Restaurant QR codes: the public address setting and the scan counts.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a';
const C2 = 'abababab-0000-4000-8000-0000000000ab';
const O = 'cccccccc-0000-4000-8000-00000000000c';
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let slug;
const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));
const q = (u, sql, params) => asU(u, () => rows(db, sql, params));
const rejects = (u, sql, params, re) => asU(u, () => assert.rejects(db.query(sql, params), re));

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [C, 'c@test.dz', 'Amina'],
    [C2, 'c2@test.dz', 'Karim'],
    [O, 'o@test.dz', 'Omar'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  slug = (await rows(db, `select slug from restaurants where id = $1`, [PIZZA]))[0].slug;
});

test('everyone reads the public address; only the admin changes it', async () => {
  const [c] = await q(C, `select public_base_url from app_config`);
  assert.equal(c.public_base_url, 'https://foodfennec.com');
  await as(db, 'anon', null, async () => {
    const [a] = await rows(db, `select public_base_url from app_config`);
    assert.equal(a.public_base_url, 'https://foodfennec.com');
  });
  const [r] = await q(ADMIN, `select admin_set_public_url(' https://FoodFennec.dz/ ') as u`);
  assert.equal(r.u, 'https://foodfennec.dz');
  await rejects(ADMIN, `select admin_set_public_url('foodfennec')`, [], /invalid_url/);
  await rejects(ADMIN, `select admin_set_public_url('https://x.dz/r/abc')`, [], /invalid_url/);
  await rejects(ADMIN, `select admin_set_public_url('javascript:alert(1)')`, [], /invalid_url/);
  await rejects(C, `select admin_set_public_url('https://evil.dz')`, [], /not|admin|denied/i);
  // The receipts use the new brand name.
  const [n] = await rows(db, `select business_name from app_config`);
  assert.equal(n.business_name, 'foodfennec');
});

test('scans are counted once per 10 minutes per person; stats for the team and the admin', async () => {
  await call(C, `select log_restaurant_visit($1, 'qr_app')`, [slug]);
  await call(C, `select log_restaurant_visit($1, 'qr_app')`, [slug]); // reload: ignored
  await call(C, `select log_restaurant_visit($1, 'qr_web')`, [slug.toUpperCase()]);
  await call(C2, `select log_restaurant_visit($1, 'qr_web')`, [slug]);
  await call(C2, `select log_restaurant_visit($1, 'link')`, [slug]); // not a scan
  await call(C2, `select log_restaurant_visit('nope', 'qr_app')`); // unknown: ignored
  await call(C2, `select log_restaurant_visit($1, 'hack')`, [slug]); // bad source: ignored
  // An older visit (more than 10 minutes ago) counts again.
  await db.query(`update restaurant_visits set created_at = now() - interval '40 days' where user_id = $1 and source = 'qr_app'`, [C]);
  await call(C, `select log_restaurant_visit($1, 'qr_app')`, [slug]);

  const [s] = await q(O, `select * from restaurant_qr_stats($1)`, [PIZZA]);
  assert.deepEqual(
    { ...s },
    { scans_total: 4, scans_30d: 3, scans_7d: 3, app_scans: 2, web_scans: 2, people: 2, orders_after: 0 });
  const [a] = await q(ADMIN, `select * from restaurant_qr_stats($1)`, [PIZZA]);
  assert.equal(a.scans_total, 4);
  await rejects(C, `select * from restaurant_qr_stats($1)`, [PIZZA], /not_allowed/);
  // Nobody reads the raw table.
  assert.deepEqual(await q(C, `select * from restaurant_visits`).catch(() => []), []);
});

test('an inactive restaurant is not counted; anon cannot log', async () => {
  await db.query(`update restaurants set is_active = false where id = $1`, [PIZZA]);
  const before = (await rows(db, `select count(*)::int n from restaurant_visits`))[0].n;
  await call(C2, `select log_restaurant_visit($1, 'qr_app')`, [slug]);
  const after = (await rows(db, `select count(*)::int n from restaurant_visits`))[0].n;
  assert.equal(after, before);
  await as(db, 'anon', null, () =>
    assert.rejects(db.query(`select log_restaurant_visit($1, 'qr_app')`, [slug]), /denied/));
  await db.query(`update restaurants set is_active = true where id = $1`, [PIZZA]);
});
