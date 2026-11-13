// Restaurant owners: registration, approval gate, own restaurant & menu.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows, denied } from './helpers.mjs';

const A = 'aaaaaaaa-0000-4000-8000-00000000000a'; // customer
const O = 'cccccccc-0000-4000-8000-00000000000c'; // owner 1
const O2 = 'dddddddd-0000-4000-8000-00000000000d'; // owner 2
const DEMO = '11111111-1111-4111-8111-111111111111'; // seeded restaurant

let db;
let mine; // Omar's restaurant id
let other; // Ouarda's restaurant id

test.before(async () => {
  db = await freshDb([
    [A, 'a@test.dz', 'Amina'],
    [O, 'o@test.dz', 'Omar'],
    [O2, 'o2@test.dz', 'Ouarda'],
  ]);
});

test('register: inactive + closed restaurant, owner role, unique slug', async () => {
  await as(db, 'authenticated', O, async () => {
    const [r] = await rows(
      db,
      `select register_restaurant('Chez Omar', '0550111222', 'Rue Didouche Mourad', 'Alger Centre', 36.77, 3.06, 30) as id`,
    );
    mine = r.id;
    const [me] = await rows(db, 'select * from my_restaurant()');
    assert.equal(me.name, 'Chez Omar');
    assert.equal(me.slug, 'chez-omar');
    assert.equal(me.is_active, false);
    assert.equal(me.is_open, false);
    assert.equal(me.prep_minutes, 30);
    const [p] = await rows(db, 'select role from profiles');
    assert.equal(p.role, 'restaurant');
  });
  await as(db, 'authenticated', O2, async () => {
    const [r] = await rows(
      db,
      `select register_restaurant('Chez Omar', '0661111222', 'Kouba centre', 'Kouba') as id`,
    );
    other = r.id;
    const [me] = await rows(db, 'select slug from my_restaurant()');
    assert.equal(me.slug, 'chez-omar-2');
  });
});

// A second registration by an owner adds an outlet: see outlets.test.mjs.
test('register: signed in only, inputs validated', async () => {
  await as(db, 'authenticated', A, async () => {
    await assert.rejects(
      db.query(`select register_restaurant('X', '0550111222', 'Somewhere', 'X')`),
      /invalid name/,
    );
    await assert.rejects(
      db.query(`select register_restaurant('Bon Resto', '12345', 'Somewhere', 'X')`),
      /invalid phone/,
    );
    await assert.rejects(
      db.query(`select register_restaurant('Bon Resto', '0550111222', 'ab', 'X')`),
      /invalid address/,
    );
  });
  await as(db, 'anon', null, async () => {
    await denied(
      db.query(`select register_restaurant('Anon Resto', '0550111222', 'Somewhere', 'X')`),
    );
  });
});

test('Arabic-only names get a generic slug', async () => {
  const [r] = await rows(db, `select make_restaurant_slug('مطعم الأمير') as s`);
  assert.equal(r.s, 'restaurant');
  const [r2] = await rows(db, `select make_restaurant_slug('Café Été') as s`);
  assert.equal(r2.s, 'cafe-ete');
});

test('before approval: hidden from customers and anonymous visitors', async () => {
  for (const [role, uid] of [['authenticated', A], ['anon', null]]) {
    await as(db, role, uid, async () => {
      assert.equal((await rows(db, 'select id from restaurants where id = $1', [mine])).length, 0);
      assert.equal((await rows(db, 'select * from list_restaurants() where id = $1', [mine])).length, 0);
    });
  }
  await as(db, 'authenticated', A, async () => {
    assert.equal((await rows(db, 'select * from my_restaurant()')).length, 0);
  });
});

test('owner edits own restaurant; cannot approve it, change commission or owner', async () => {
  await as(db, 'authenticated', O, async () => {
    const ok = await db.query(
      `update restaurants set description = 'Cuisine maison', is_open = true where id = $1`,
      [mine],
    );
    assert.equal(ok.affectedRows, 1);
    await denied(db.query(`update restaurants set is_active = true where id = $1`, [mine]));
    await denied(db.query(`update restaurants set commission_rate = 0 where id = $1`, [mine]));
    await denied(db.query(`update restaurants set owner_id = $1 where id = $2`, [A, mine]));
    await denied(db.query(`update restaurants set slug = 'new' where id = $1`, [mine]));
    const notMine = await db.query(`update restaurants set description = 'x' where id = $1`, [other]);
    assert.equal(notMine.affectedRows, 0);
  });
  await as(db, 'authenticated', A, async () => {
    const res = await db.query(`update restaurants set name = 'hacked' where id = $1`, [mine]);
    assert.equal(res.affectedRows, 0);
  });
});

test('owner manages own menu; nobody else can', async () => {
  const [burger] = await rows(db, `select id from categories where slug = 'burger'`);
  let item;
  await as(db, 'authenticated', O, async () => {
    const [it] = await rows(
      db,
      `insert into menu_items (restaurant_id, category_id, name, price) values ($1, $2, 'Burger maison', 800) returning id`,
      [mine, burger.id],
    );
    item = it.id;
    // Visible to the owner although the restaurant is not approved yet.
    assert.equal((await rows(db, 'select id from menu_items where restaurant_id = $1', [mine])).length, 1);
    await db.query(`update menu_items set price = 850, is_available = false where id = $1`, [item]);
    await denied(db.query(`insert into menu_items (restaurant_id, name, price) values ($1, 'x', 100)`, [other]));
    await denied(db.query(`update menu_items set restaurant_id = $1 where id = $2`, [other, item]));
    const demo = await db.query(`update menu_items set price = 10 where restaurant_id = $1`, [DEMO]);
    assert.equal(demo.affectedRows, 0);
    await assert.rejects(
      db.query(`insert into menu_items (restaurant_id, name, price) values ($1, 'Free', 0)`, [mine]),
      /check constraint/,
    );
  });
  await as(db, 'authenticated', A, async () => {
    await denied(db.query(`insert into menu_items (restaurant_id, name, price) values ($1, 'x', 100)`, [mine]));
    const del = await db.query(`delete from menu_items where id = $1`, [item]);
    assert.equal(del.affectedRows, 0);
  });
  await as(db, 'authenticated', O2, async () => {
    assert.equal((await rows(db, 'select id from menu_items where id = $1', [item])).length, 0);
  });
  await as(db, 'authenticated', O, async () => {
    const del = await db.query(`delete from menu_items where id = $1`, [item]);
    assert.equal(del.affectedRows, 1);
  });
});

test('restaurant photos: owner uploads only into own folder', async () => {
  await as(db, 'authenticated', O, async () => {
    await db.query(
      `insert into storage.objects (bucket_id, name) values ('restaurant-media', $1)`,
      [`${mine}/cover.jpg`],
    );
    await denied(
      db.query(`insert into storage.objects (bucket_id, name) values ('restaurant-media', $1)`, [
        `${other}/cover.jpg`,
      ]),
    );
  });
  await as(db, 'authenticated', A, async () => {
    await denied(
      db.query(`insert into storage.objects (bucket_id, name) values ('restaurant-media', $1)`, [
        `${mine}/x.jpg`,
      ]),
    );
  });
});

test('after the admin approves, customers see it', async () => {
  await db.exec(`update restaurants set is_active = true where id = '${mine}'`);
  await as(db, 'anon', null, async () => {
    const r = await rows(db, 'select name, is_open from restaurants where id = $1', [mine]);
    assert.deepEqual(r, [{ name: 'Chez Omar', is_open: true }]);
  });
});
