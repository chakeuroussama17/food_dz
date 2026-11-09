// Push tokens + the order trigger (without pg_net: must never break orders).
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows, denied } from './helpers.mjs';

const A = 'aaaaaaaa-0000-4000-8000-00000000000a';
const B = 'bbbbbbbb-0000-4000-8000-00000000000b';
const O = 'cccccccc-0000-4000-8000-00000000000c';
const PIZZA = '11111111-1111-4111-8111-111111111111';
const TOKEN = 'fcm-token-' + 'x'.repeat(40);

let db;
const asU = (u, fn) => as(db, 'authenticated', u, fn);

test.before(async () => {
  db = await freshDb([[A, 'a@test.dz', 'Amina'], [B, 'b@test.dz', 'Bilal'], [O, 'o@test.dz', 'Omar']]);
});

test('register: own token, moves to whoever signs in on that phone', async () => {
  await asU(A, () => db.query(`select register_push_token($1, 'android', 'ar')`, [TOKEN]));
  let [t] = await rows(db, `select user_id, lang from push_tokens where token = $1`, [TOKEN]);
  assert.deepEqual([t.user_id, t.lang], [A, 'ar']);
  await asU(B, () => db.query(`select register_push_token($1, 'android', 'xx')`, [TOKEN]));
  [t] = await rows(db, `select user_id, lang from push_tokens where token = $1`, [TOKEN]);
  assert.deepEqual([t.user_id, t.lang], [B, 'fr']);
  // B logs out from that phone.
  await asU(A, () => db.query(`select unregister_push_token($1)`, [TOKEN])); // not A's: no effect
  assert.equal((await rows(db, `select 1 from push_tokens`)).length, 1);
  await asU(B, () => db.query(`select unregister_push_token($1)`, [TOKEN]));
  assert.equal((await rows(db, `select 1 from push_tokens`)).length, 0);
});

test('at most 10 phones per user; input checked; no direct access', async () => {
  for (let i = 0; i < 12; i++) {
    await asU(A, () => db.query(`select register_push_token($1, 'android')`, [`${TOKEN}-${i}`]));
  }
  assert.equal((await rows(db, `select 1 from push_tokens where user_id = $1`, [A])).length, 10);
  await asU(A, () => assert.rejects(db.query(`select register_push_token('short', 'android')`), /invalid_token/));
  await asU(A, () => assert.rejects(db.query(`select register_push_token($1, 'fax')`, [TOKEN]), /invalid_token/));
  await as(db, 'anon', null, () => denied(db.query(`select register_push_token($1, 'android')`, [TOKEN])));
  await asU(A, () => denied(db.query(`select * from push_tokens`)));
  await asU(A, () => denied(db.query(`select * from private.push_config`)));
});

test('orders keep working with push configured but no pg_net', async () => {
  await db.query(`insert into private.push_config (function_url, secret) values ('https://x/functions/v1/push', $1)`, ['s'.repeat(40)]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  const item = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  const addr = (await asU(A, () => rows(db, `insert into addresses (label, address_text) values ('home', 'Rue 1') returning id`)))[0].id;
  const [o] = await asU(A, () => rows(db, `select * from place_order($1, $2::jsonb, $3, '0550123456')`, [PIZZA, JSON.stringify([{ id: item, qty: 1 }]), addr]));
  await asU(O, () => db.query(`select owner_set_order_status($1, 'accepted')`, [o.id]));
  const [row] = await rows(db, `select status from orders where id = $1`, [o.id]);
  assert.equal(row.status, 'accepted');
});
