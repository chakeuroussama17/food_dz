// Home banners: admin manages, everybody sees the active ones.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows, denied } from './helpers.mjs';

const ADMIN = 'eeeeeeee-0000-4000-8000-00000000000e';
const C = 'aaaaaaaa-0000-4000-8000-00000000000a';
const PIZZA = '11111111-1111-4111-8111-111111111111';
const img = (n) => `https://x.supabase.co/storage/v1/object/public/banners/${n}.jpg`;

let db;
const asAdmin = (fn) => as(db, 'authenticated', ADMIN, fn);
const add = (n, title = '', rid = null) =>
  asAdmin(() => rows(db, `select admin_add_banner($1, $2, $3) as id`, [img(n), title, rid])).then((r) => r[0].id);

test.before(async () => {
  db = await freshDb([[ADMIN, 'admin@food.dz', 'Admin'], [C, 'c@test.dz', 'Amina']]);
  await db.query(`update profiles set role = 'admin' where id = $1`, [ADMIN]);
  await db.query(`update restaurants set is_active = true where id = $1`, [PIZZA]);
});

test('admin adds banners; customers and visitors see the active ones in order', async () => {
  const a = await add('a', 'Ramadan -10%', PIZZA);
  const b = await add('b');
  const c = await add('c');
  await asAdmin(() => db.query(`select admin_update_banner($1, '', null, false)`, [c]));

  for (const role of [['authenticated', C], ['anon', null]]) {
    const list = await as(db, role[0], role[1], () => rows(db, `select * from home_banners()`));
    assert.deepEqual(list.map((x) => x.id), [a, b]);
    assert.equal(list[0].restaurant_slug, 'pizzeria-el-bahdja');
    assert.equal(list[0].title, 'Ramadan -10%');
  }
  // Admin list shows everything, with the restaurant name.
  const all = await asAdmin(() => rows(db, `select * from admin_list_banners()`));
  assert.equal(all.length, 3);
  assert.equal(all[0].restaurant_name, 'Pizzeria El Bahdja');
});

test('reorder and delete', async () => {
  const all = await asAdmin(() => rows(db, `select id from admin_list_banners()`));
  const [a, b, c] = all.map((x) => x.id);
  await asAdmin(() => db.query(`select admin_move_banner($1, 1)`, [a])); // a down
  let order = (await asAdmin(() => rows(db, `select id from admin_list_banners()`))).map((x) => x.id);
  assert.deepEqual(order, [b, a, c]);
  await asAdmin(() => db.query(`select admin_move_banner($1, -1)`, [b])); // already first
  await asAdmin(() => db.query(`select admin_move_banner($1, -1)`, [c]));
  order = (await asAdmin(() => rows(db, `select id from admin_list_banners()`))).map((x) => x.id);
  assert.deepEqual(order, [b, c, a]);
  const [{ url }] = await asAdmin(() => rows(db, `select admin_delete_banner($1) as url`, [c]));
  assert.equal(url, img('c'));
  assert.equal((await asAdmin(() => rows(db, `select id from admin_list_banners()`))).length, 2);
});

test('a deactivated restaurant is not linked any more', async () => {
  await db.query(`update restaurants set is_active = false where id = $1`, [PIZZA]);
  const list = await as(db, 'authenticated', C, () => rows(db, `select * from home_banners()`));
  assert.ok(list.every((x) => x.restaurant_slug === null));
  await db.query(`update restaurants set is_active = true where id = $1`, [PIZZA]);
});

test('only the admin manages banners and their pictures', async () => {
  await as(db, 'authenticated', C, async () => {
    await assert.rejects(db.query(`select admin_add_banner($1)`, [img('x')]), /admin only/);
    await assert.rejects(db.query(`select * from admin_list_banners()`), /admin only/);
    await denied(db.query(`insert into banners (image_url) values ($1)`, [img('x')]));
    await denied(db.query(`insert into storage.objects (bucket_id, name) values ('banners', 'x.jpg')`));
  });
  await asAdmin(() => assert.rejects(db.query(`select admin_add_banner('http://not-https.jpg')`), /invalid image/));
  await asAdmin(() => db.query(`insert into storage.objects (bucket_id, name) values ('banners', 'ok.jpg')`));
});
