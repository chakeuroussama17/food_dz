// More about each customer: sign-up wilaya/commune, "complete your
// profile", app sessions and the admin's list and summary.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a';
const C2 = 'abababab-0000-4000-8000-0000000000ab';

let db;
const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));
const q = (u, sql, params) => asU(u, () => rows(db, sql, params));
const rejects = (u, sql, params, re) => asU(u, () => assert.rejects(db.query(sql, params), re));
const me = async (u) => (await q(u, `select * from profiles where id = $1`, [u]))[0];

test.before(async () => {
  db = await freshDb([
    [ADMIN, 'admin@food.dz', 'Admin'],
    [C, 'c@test.dz', 'Amina'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
});

test('sign-up keeps a valid wilaya, commune, platform and language', async () => {
  await db.query(
    `insert into auth.users (id, email, raw_user_meta_data) values ($1, 'k@test.dz', $2)`,
    [C2, JSON.stringify({
      full_name: 'Karim', phone: '0661000002', wilaya: '16', commune: '  Bab   Ezzouar ',
      platform: 'android', lang: 'ar',
    })]);
  const p = await me(C2);
  assert.equal(p.wilaya, 16);
  assert.equal(p.commune, 'Bab Ezzouar');
  assert.equal(p.signup_platform, 'android');
  assert.equal(p.signup_lang, 'ar');

  // Bad values are dropped, the account is still created.
  const X = 'cdcdcdcd-0000-4000-8000-0000000000cd';
  await db.query(
    `insert into auth.users (id, email, raw_user_meta_data) values ($1, 'x@test.dz', $2)`,
    [X, JSON.stringify({ full_name: 'X', wilaya: '99', platform: 'windows', lang: 'de' })]);
  const x = (await rows(db, `select * from profiles where id = $1`, [X]))[0];
  assert.equal(x.wilaya, null);
  assert.equal(x.signup_platform, null);
  assert.equal(x.signup_lang, null);
});

test('complete my profile: checks, partial updates, the card stops showing', async () => {
  const adult = new Date(Date.now() - 25 * 365.25 * 864e5).toISOString().slice(0, 10);
  const child = new Date(Date.now() - 10 * 365.25 * 864e5).toISOString().slice(0, 10);
  await rejects(C, `select update_my_details(p_birth_date => $1::date)`, [child], /invalid_birth_date/);
  await rejects(C, `select update_my_details(p_birth_date => '1900-01-01')`, [], /invalid_birth_date/);
  await rejects(C, `select update_my_details(p_gender => 'x')`, [], /invalid_gender/);
  await rejects(C, `select update_my_details(p_wilaya => 59)`, [], /invalid_wilaya/);
  await rejects(C, `select update_my_details(p_commune => '   ')`, [], /invalid_commune/);
  await rejects(C, `select update_my_details(p_referral => 'tv')`, [], /invalid_referral/);

  await call(C, `select update_my_details(p_wilaya => 31, p_commune => 'Oran')`);
  let p = await me(C);
  assert.equal(p.wilaya, 31);
  assert.equal(p.profile_prompt_at, null); // not answered yet

  await call(C, `select update_my_details($1::date, 'female', null, null, 'social', true)`, [adult]);
  p = await me(C);
  assert.equal(p.gender, 'female');
  assert.equal(p.referral_source, 'social');
  assert.equal(p.wilaya, 31); // kept
  assert.ok(p.profile_prompt_at);

  // Users can't write the columns directly.
  await rejects(C, `update profiles set gender = 'male', last_seen_at = now() where id = $1`, [C], /denied/);

  await call(C2, `select skip_profile_prompt()`);
  assert.ok((await me(C2)).profile_prompt_at);
});

test('app start: last seen, device, one row per active day', async () => {
  await call(C, `select touch_session('android', '0.3.0+12', 'Android 14', 'Samsung SM-A155F', 'fr')`);
  await call(C, `select touch_session('android', '0.3.0+12', 'Android 14', 'Samsung SM-A155F', 'fr')`);
  await call(C2, `select touch_session('hack', '<script>', '', '', 'xx')`);
  const p = await me(C);
  assert.equal(p.last_platform, 'android');
  assert.equal(p.last_app_version, '0.3.0+12');
  assert.equal(p.last_device, 'Samsung SM-A155F');
  assert.equal(p.last_lang, 'fr');
  assert.equal(p.signup_platform, 'android'); // first time seen
  assert.ok(p.last_seen_at);
  const k = await me(C2);
  assert.equal(k.last_platform, null);
  assert.equal(k.last_app_version, 'script');
  assert.equal(k.signup_platform, 'android'); // from sign-up, kept
  const days = await rows(db, `select * from user_activity_days order by user_id`);
  assert.equal(days.length, 2);
  // Nobody reads the activity table directly.
  assert.deepEqual(await q(C, `select * from user_activity_days`).catch(() => []), []);
});

test('admin: customers with everything, and a summary', async () => {
  const list = await q(ADMIN, `select * from admin_list_customers('')`);
  const a = list.find((r) => r.id === C);
  assert.equal(a.gender, 'female');
  assert.equal(a.wilaya, 31);
  assert.equal(a.last_device, 'Samsung SM-A155F');
  assert.equal(a.active_days_30, 1);
  assert.equal(a.orders_count, 0);
  assert.equal((await q(ADMIN, `select * from admin_list_customers('ezzouar')`)).length, 1);

  const [{ s }] = await q(ADMIN, `select admin_customer_insights() s`);
  assert.equal(s.customers, 3);
  assert.equal(s.active_1d, 2);
  assert.equal(s.profile_done, 1);
  assert.equal(s.gender.female, 1);
  assert.equal(s.age['25-34'], 1);
  assert.equal(s.wilaya['16'], 1);
  assert.equal(s.wilaya['31'], 1);
  assert.equal(s.referral.social, 1);
  assert.equal(s.platform.android, 2);
  await rejects(C, `select admin_customer_insights()`, [], /admin|denied|not/i);
});
