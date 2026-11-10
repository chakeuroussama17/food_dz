// Accounts: phone at sign-up, avatar read rule, delete my account.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows, denied } from './helpers.mjs';

const A = 'aaaaaaaa-0000-4000-8000-00000000000a'; // customer with a past order
const B = 'bbbbbbbb-0000-4000-8000-00000000000b'; // other customer
const O = 'cccccccc-0000-4000-8000-00000000000c'; // restaurant owner
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let item;
const asU = (u, fn) => as(db, 'authenticated', u, fn);

async function order(customer) {
  const addr = (await asU(customer, () =>
    rows(db, `insert into addresses (label, address_text, area) values ('home', 'Rue Didouche 12', 'Alger') returning id`)))[0].id;
  const [o] = await asU(customer, () =>
    rows(db, `select * from place_order($1, $2::jsonb, $3, '0550123456', 'code porte 12')`, [PIZZA, JSON.stringify([{ id: item, qty: 1 }]), addr]));
  return o.id;
}

test.before(async () => {
  db = await freshDb([[A, 'a@test.dz', 'Amina'], [B, 'b@test.dz', 'Bilal'], [O, 'o@test.dz', 'Omar']]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  item = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
});

test('phone from sign-up is kept when valid', async () => {
  const ok = 'eeeeeeee-1111-4000-8000-000000000001';
  const bad = 'eeeeeeee-1111-4000-8000-000000000002';
  await db.query(`insert into auth.users (id, email, raw_user_meta_data) values ($1, 'p1@test.dz', '{"full_name":"Yacine","phone":"0661234567"}')`, [ok]);
  await db.query(`insert into auth.users (id, email, raw_user_meta_data) values ($1, 'p2@test.dz', '{"full_name":"X","phone":"12345"}')`, [bad]);
  const [p1] = await rows(db, `select full_name, phone from profiles where id = $1`, [ok]);
  const [p2] = await rows(db, `select phone from profiles where id = $1`, [bad]);
  assert.deepEqual([p1.full_name, p1.phone], ['Yacine', '0661234567']);
  assert.equal(p2.phone, null);
});

test('avatars: each user reads only their own files', async () => {
  await asU(A, () => db.query(`insert into storage.objects (bucket_id, name) values ('avatars', $1)`, [`${A}/me.jpg`]));
  assert.equal((await asU(A, () => rows(db, `select name from storage.objects where bucket_id = 'avatars'`))).length, 1);
  assert.equal((await asU(B, () => rows(db, `select name from storage.objects where bucket_id = 'avatars'`))).length, 0);
});

test('delete my account: refused with an order in progress', async () => {
  const id = await order(A);
  await asU(A, () => assert.rejects(db.query(`select delete_my_account()`), /active_orders/));
  await asU(O, () => db.query(`select owner_set_order_status($1, 'rejected', 'Fermé')`, [id]));
});

test('delete my account: user gone, orders kept without personal details', async () => {
  const [before] = await rows(db, `select id, total from orders where customer_id = $1`, [A]);
  await asU(A, () => db.query(`select delete_my_account()`));

  assert.equal((await rows(db, `select 1 from auth.users where id = $1`, [A])).length, 0);
  assert.equal((await rows(db, `select 1 from profiles where id = $1`, [A])).length, 0);
  assert.equal((await rows(db, `select 1 from addresses where user_id = $1`, [A])).length, 0);
  const [o] = await rows(db, `select * from orders where id = $1`, [before.id]);
  assert.equal(o.customer_id, null);
  assert.equal(o.total, before.total); // amounts untouched
  assert.equal(o.customer_name, 'Client supprimé');
  assert.equal(o.address_text, 'Adresse supprimée');
  assert.equal(o.notes, '');
  assert.equal(o.lat, null);
  // B is untouched.
  assert.equal((await rows(db, `select 1 from profiles where id = $1`, [B])).length, 1);
});

test('restaurant owners and visitors cannot use it; amounts stay locked', async () => {
  await asU(O, () => assert.rejects(db.query(`select delete_my_account()`), /not_a_customer/));
  await as(db, 'anon', null, () => denied(db.query(`select delete_my_account()`)));
  // The order rule still refuses changing an order's customer to someone else.
  const id = await order(B);
  await assert.rejects(db.query(`update orders set customer_id = $2 where id = $1`, [id, O]), /order amounts cannot change/);
});
