// Outlets (several restaurants per owner) and team roles.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows } from './helpers.mjs';

const C = 'aaaaaaaa-0000-4000-8000-00000000000a'; // customer
const O = 'cccccccc-0000-4000-8000-00000000000c'; // owner of the pizzeria
const M = 'bbbbbbbb-0000-4000-8000-00000000000b'; // manager
const S = '99999999-0000-4000-8000-000000000009'; // staff
const X = 'dddddddd-0000-4000-8000-00000000000d'; // outsider owner
const D = 'd1d1d1d1-0000-4000-8000-0000000000d1'; // driver
const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const PIZZA = '11111111-1111-4111-8111-111111111111';

let db;
let addr;
let margherita;
let outlet2;

const asU = (u, fn) => as(db, 'authenticated', u, fn);
const call = (u, sql, params) => asU(u, () => db.query(sql, params));
const q = (u, sql, params) => asU(u, () => rows(db, sql, params));

async function placeOrder(restaurant = PIZZA, item = margherita) {
  const [o] = await q(C, `select * from place_order($1, $2::jsonb, $3, '0550123456')`, [
    restaurant, JSON.stringify([{ id: item, qty: 1 }]), addr,
  ]);
  return o.id;
}

test.before(async () => {
  db = await freshDb([
    [C, 'c@test.dz', 'Amina'],
    [O, 'o@test.dz', 'Omar'],
    [M, 'm@test.dz', 'Mounir'],
    [S, 's@test.dz', 'Samia'],
    [X, 'x@test.dz', 'Xavier'],
    [D, 'd@test.dz', 'Rachid'],
    [ADMIN, 'admin@test.dz', 'Admin'],
  ]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update profiles set role = 'restaurant' where id = $1`, [O]);
  // Set directly, like the demo SQL: the trigger makes Omar an owner member.
  await db.query(`update restaurants set owner_id = $1, is_active = true, is_open = true where id = $2`, [O, PIZZA]);
  await call(X, `select register_restaurant('Chez Xavier', '0550999888', 'Rue Y', 'Oran')`);
  margherita = (await rows(db, `select id from menu_items where name = 'Pizza Margherita'`))[0].id;
  addr = (await q(C, `insert into addresses (label, address_text) values ('home', 'Rue Didouche 12') returning id`))[0].id;
  await call(D, `select register_driver('0661000001', 'moto')`);
  await call(ADMIN, `select admin_set_driver_approved($1, true)`, [D]);
});

test('owner adds a second outlet; both are listed with the role', async () => {
  const [{ id }] = await q(O, `select register_restaurant('Pizzeria Hydra', '0550111333', 'Rue Hydra', 'Hydra') as id`);
  outlet2 = id;
  const mine = await q(O, `select name, my_role, is_active from my_restaurants()`);
  assert.deepEqual(
    mine.map((r) => `${r.name}:${r.my_role}`).sort(),
    ['Pizzeria El Bahdja:owner', 'Pizzeria Hydra:owner'],
  );
  assert.equal(mine.find((r) => r.name === 'Pizzeria Hydra').is_active, false);
  // Old app versions still get one restaurant.
  assert.equal((await q(O, `select * from my_restaurant()`)).length, 1);
});

test('team: only owners add members, by email, existing accounts only', async () => {
  await call(O, `select owner_add_member($1, 'M@TEST.dz', 'manager')`, [PIZZA]);
  await call(O, `select owner_add_member($1, 's@test.dz', 'staff')`, [PIZZA]);
  assert.equal((await rows(db, `select role from profiles where id = $1`, [S]))[0].role, 'restaurant');

  await asU(O, () => assert.rejects(db.query(`select owner_add_member($1, 'nobody@test.dz', 'staff')`, [PIZZA]), /user_not_found/));
  await asU(O, () => assert.rejects(db.query(`select owner_add_member($1, 's@test.dz', 'staff')`, [PIZZA]), /already_member/));
  await asU(O, () => assert.rejects(db.query(`select owner_add_member($1, 'd@test.dz', 'staff')`, [PIZZA]), /user_has_other_role/));
  await asU(O, () => assert.rejects(db.query(`select owner_add_member($1, 'c@test.dz', 'chef')`, [PIZZA]), /bad_role/));
  await asU(M, () => assert.rejects(db.query(`select owner_add_member($1, 'c@test.dz', 'staff')`, [PIZZA]), /not_allowed/));
  await asU(X, () => assert.rejects(db.query(`select owner_add_member($1, 'c@test.dz', 'staff')`, [PIZZA]), /not_allowed/));

  const team = await q(M, `select full_name, role from restaurant_team($1)`, [PIZZA]);
  assert.deepEqual(team.map((t) => t.role), ['owner', 'manager', 'staff']);
  await asU(S, () => assert.rejects(db.query(`select * from restaurant_team($1)`, [PIZZA]), /not_allowed/));
  // Staff and managers see only the outlet they were added to.
  assert.deepEqual((await q(S, `select name, my_role from my_restaurants()`)).map((r) => r.my_role), ['staff']);
});

test('staff: handle orders and cash, but no menu, details, reports or statements', async () => {
  const id = await placeOrder();
  const list = await q(S, `select id, restaurant_name from owner_orders(true)`);
  assert.deepEqual(list.map((o) => o.id), [id]);
  assert.equal(list[0].restaurant_name, 'Pizzeria El Bahdja');
  await call(S, `select owner_set_order_status($1, 'accepted')`, [id]);

  // Menu writes are refused (no row changed under RLS).
  await call(S, `update menu_items set price = 1 where id = $1`, [margherita]);
  assert.notEqual((await rows(db, `select price from menu_items where id = $1`, [margherita]))[0].price, 1);
  await call(S, `update restaurants set is_open = false where id = $1`, [PIZZA]);
  assert.equal((await rows(db, `select is_open from restaurants where id = $1`, [PIZZA]))[0].is_open, true);

  const day = `now() - interval '1 day', now() + interval '1 day'`;
  assert.equal((await q(S, `select * from owner_report(${day})`)).length, 0);
  assert.equal((await q(S, `select * from owner_statements()`)).length, 0);

  // Outsiders see nothing and can't touch it.
  assert.equal((await q(X, `select * from owner_orders(true)`)).length, 0);
  await asU(X, () => assert.rejects(db.query(`select owner_set_order_status($1, 'ready')`, [id]), /order_not_found/));
  await call(S, `select owner_set_order_status($1, 'cancelled', 'Test')`, [id]);
});

test('manager: menu, open switch and reports; not the team', async () => {
  await call(M, `update menu_items set price = 750 where id = $1`, [margherita]);
  assert.equal((await rows(db, `select price from menu_items where id = $1`, [margherita]))[0].price, 750);
  await call(M, `update restaurants set is_open = false where id = $1`, [PIZZA]);
  assert.equal((await rows(db, `select is_open from restaurants where id = $1`, [PIZZA]))[0].is_open, false);
  await call(M, `update restaurants set is_open = true where id = $1`, [PIZZA]);
  const day = `now() - interval '1 day', now() + interval '1 day'`;
  const rep = await q(M, `select restaurant_name, customer_key from owner_report(${day})`);
  assert.ok(rep.length >= 1);
  assert.equal(rep[0].restaurant_name, 'Pizzeria El Bahdja');
  assert.match(rep[0].customer_key, /^[0-9a-f]{32}$/);
  // Not a member of the second outlet.
  await asU(M, () => assert.rejects(db.query(`select * from restaurant_team($1)`, [outlet2]), /not_allowed/));
});

test('owner: orders and reports of all outlets, filterable', async () => {
  // The second outlet needs to be live with a dish to take an order.
  await call(ADMIN, `select admin_set_restaurant_active($1, true)`, [outlet2]);
  await call(O, `update restaurants set is_open = true where id = $1`, [outlet2]);
  const [{ id: dish }] = await q(O, `insert into menu_items (restaurant_id, name, price) values ($1, 'Pizza Hydra', 900) returning id`, [outlet2]);
  const o2 = await placeOrder(outlet2, dish);
  const o1 = await placeOrder();

  const all = await q(O, `select id, restaurant_id from owner_orders(true)`);
  assert.deepEqual(new Set(all.map((o) => o.id)), new Set([o1, o2]));
  const only2 = await q(O, `select id from owner_orders(true, 100, $1)`, [outlet2]);
  assert.deepEqual(only2.map((o) => o.id), [o2]);
  // The pizzeria's manager and staff don't see the other outlet's order.
  assert.deepEqual((await q(S, `select id from owner_orders(true)`)).map((o) => o.id), [o1]);

  const day = `now() - interval '1 day', now() + interval '1 day'`;
  const rep = await q(O, `select distinct restaurant_id from owner_report(${day}, $1::uuid[])`, [[outlet2]]);
  assert.deepEqual(rep.map((r) => r.restaurant_id), [outlet2]);

  for (const id of [o1, o2]) await call(O, `select owner_set_order_status($1, 'rejected', 'Test')`, [id]);
});

test('roles change; the last owner stays; leaving makes you a customer again', async () => {
  await asU(O, () => assert.rejects(db.query(`select owner_set_member_role($1, $2, 'manager')`, [PIZZA, O]), /last_owner/));
  await asU(O, () => assert.rejects(db.query(`select owner_remove_member($1, $2)`, [PIZZA, O]), /last_owner/));
  await call(O, `select owner_set_member_role($1, $2, 'manager')`, [PIZZA, S]);
  assert.equal((await q(S, `select my_role from my_restaurants()`))[0].my_role, 'manager');

  // Staff can't add an outlet (only owners can).
  await asU(S, () => assert.rejects(db.query(`select register_restaurant('Mine', '0550111444', 'Rue Z', 'Z')`), /already has a role/));

  // The member leaves by themself.
  await call(S, `select owner_remove_member($1, $2)`, [PIZZA, S]);
  assert.equal((await rows(db, `select role from profiles where id = $1`, [S]))[0].role, 'customer');
  assert.equal((await q(S, `select * from my_restaurants()`)).length, 0);
  // Others can't remove people.
  await asU(M, () => assert.rejects(db.query(`select owner_remove_member($1, $2)`, [PIZZA, O]), /not_allowed/));
});

test('closing the account archives sole-owned outlets; the team goes back to customer', async () => {
  // Nothing open on the outlets (orders were rejected above).
  await call(O, `select delete_my_restaurant_account()`);
  const r = await rows(db, `select id, deleted_at, owner_id from restaurants where id = any($1::uuid[])`, [[PIZZA, outlet2]]);
  assert.ok(r.every((x) => x.deleted_at && x.owner_id === null));
  assert.equal((await rows(db, `select role from profiles where id = $1`, [M]))[0].role, 'customer');
  assert.equal((await rows(db, `select count(*)::int n from restaurant_members where restaurant_id = any($1::uuid[])`, [[PIZZA, outlet2]]))[0].n, 0);
  // Xavier's restaurant is untouched.
  assert.equal((await q(X, `select * from my_restaurants()`)).length, 1);
});
