// Database tests: schema, seed, RLS and helper functions.
// Runs real Postgres (PGlite, WebAssembly) in Node: no Docker needed.
//   cd supabase/tests && npm install && npm test
import { PGlite } from '@electric-sql/pglite';
import { readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import assert from 'node:assert/strict';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');
const read = (p) => readFileSync(p, 'utf8');

const A = 'aaaaaaaa-0000-4000-8000-00000000000a';
const B = 'bbbbbbbb-0000-4000-8000-00000000000b';

async function freshDb() {
  const db = new PGlite();
  await db.exec(read(join(here, 'supabase_stub.sql')));
  const migrations = readdirSync(join(root, 'migrations')).filter((f) => f.endsWith('.sql')).sort();
  for (const m of migrations) await db.exec(read(join(root, 'migrations', m)));
  await db.exec(read(join(root, 'seed.sql')));
  await db.exec(`
    insert into auth.users (id, email, raw_user_meta_data) values
      ('${A}', 'a@test.dz', '{"full_name":"Amina"}'),
      ('${B}', 'b@test.dz', '{"full_name":"Bilal"}');`);
  return db;
}

/** Runs [fn] as the given role (and user id for authenticated). */
async function as(db, role, userId, fn) {
  await db.exec(`reset role; select set_config('request.jwt.claim.sub', '${userId ?? ''}', false); set role ${role};`);
  try {
    return await fn();
  } finally {
    await db.exec('reset role;');
  }
}
const rows = async (db, sql, params) => (await db.query(sql, params)).rows;
async function denied(promise, pattern = /permission denied|violates row-level security/) {
  await assert.rejects(promise, pattern);
}

let db;
test.before(async () => {
  db = await freshDb();
});

test('migration + seed: 8 categories, 3 restaurants, 16 items', async () => {
  const [c] = await rows(db, 'select (select count(*)::int from categories) c, (select count(*)::int from restaurants) r, (select count(*)::int from menu_items) m');
  assert.deepEqual(c, { c: 8, r: 3, m: 16 });
});

test('seed is safe to re-run', async () => {
  await db.exec(read(join(root, 'seed.sql')));
  const [c] = await rows(db, 'select count(*)::int n from menu_items');
  assert.equal(c.n, 16);
});

test('a profile is created for each new user, with the sign-up name', async () => {
  const r = await rows(db, 'select id, full_name, role from profiles order by full_name');
  assert.deepEqual(r.map((x) => [x.full_name, x.role]), [['Amina', 'customer'], ['Bilal', 'customer']]);
});

// ---------- anonymous visitor ----------
test('anon can read the public catalogue', async () => {
  await as(db, 'anon', null, async () => {
    assert.equal((await rows(db, 'select id from categories')).length, 8);
    assert.equal((await rows(db, 'select id, name, is_open from restaurants')).length, 3);
    assert.equal((await rows(db, 'select id, price from menu_items')).length, 16);
    const [cfg] = await rows(db, 'select delivery_fee from app_config');
    assert.equal(cfg.delivery_fee, 200);
  });
});

test('anon cannot read private columns or customer data', async () => {
  await as(db, 'anon', null, async () => {
    await denied(db.query('select commission_rate from restaurants'));
    await denied(db.query('select owner_id from restaurants'));
    await denied(db.query('select email from restaurants'));
    await denied(db.query('select default_commission_rate from app_config'));
    await denied(db.query('select * from profiles'));
    await denied(db.query('select * from addresses'));
  });
});

test('anon cannot write the catalogue', async () => {
  await as(db, 'anon', null, async () => {
    await denied(db.query(`insert into categories (slug, name_ar, name_fr, name_en) values ('x1','x','x','x')`));
    await denied(db.query(`update menu_items set price = 10`));
    await denied(db.query(`delete from restaurants`));
  });
});

test('inactive restaurants and their dishes are hidden', async () => {
  await db.exec(`update restaurants set is_active = false where slug = 'dar-lgharbi'`);
  try {
    await as(db, 'anon', null, async () => {
      assert.equal((await rows(db, 'select id from restaurants')).length, 2);
      assert.equal((await rows(db, `select id from menu_items where restaurant_id = '33333333-3333-4333-8333-333333333333'`)).length, 0);
      assert.equal((await rows(db, 'select * from list_restaurants()')).length, 2);
    });
  } finally {
    await db.exec(`update restaurants set is_active = true where slug = 'dar-lgharbi'`);
  }
});

// ---------- customers ----------
test('a customer sees and edits only their own profile', async () => {
  await as(db, 'authenticated', A, async () => {
    const r = await rows(db, 'select full_name from profiles');
    assert.deepEqual(r, [{ full_name: 'Amina' }]);
    await db.query(`update profiles set full_name = 'Amina B', phone = '0550123456' where id = $1`, [A]);
    // Updating someone else silently touches 0 rows.
    const res = await db.query(`update profiles set full_name = 'hacked' where id = $1`, [B]);
    assert.equal(res.affectedRows, 0);
  });
  const [b] = await rows(db, 'select full_name from profiles where id = $1', [B]);
  assert.equal(b.full_name, 'Bilal');
});

test('a customer cannot change their role', async () => {
  await as(db, 'authenticated', A, async () => {
    await denied(db.query(`update profiles set role = 'admin' where id = $1`, [A]));
  });
});

test('phone numbers are validated', async () => {
  await as(db, 'authenticated', A, async () => {
    await assert.rejects(db.query(`update profiles set phone = '021123456' where id = $1`, [A]), /check constraint/);
  });
});

test('addresses are private to their owner', async () => {
  await as(db, 'authenticated', A, async () => {
    await db.query(`insert into addresses (label, address_text, area) values ('home', 'Cité 200 logements', 'Kouba')`);
  });
  await as(db, 'authenticated', B, async () => {
    assert.equal((await rows(db, 'select * from addresses')).length, 0);
    await denied(db.query(`insert into addresses (user_id, address_text) values ($1, 'spoofed')`, [A]));
  });
  await as(db, 'authenticated', A, async () => {
    assert.equal((await rows(db, 'select * from addresses')).length, 1);
  });
});

test('only one default address per customer', async () => {
  await as(db, 'authenticated', A, async () => {
    const [w] = await rows(db, `insert into addresses (label, address_text) values ('work', 'Hydra, rue 5') returning id`);
    const [h] = await rows(db, `select id from addresses where label = 'home'`);
    await db.query('select set_default_address($1)', [h.id]);
    await db.query('select set_default_address($1)', [w.id]);
    const defs = await rows(db, 'select label from addresses where is_default');
    assert.deepEqual(defs, [{ label: 'work' }]);
  });
  await as(db, 'authenticated', B, async () => {
    const [h] = await (async () => { await db.exec('reset role'); return rows(db, `select id from addresses where label = 'home'`); })();
    await db.exec(`set role authenticated`);
    await assert.rejects(db.query('select set_default_address($1)', [h.id]), /address not found/);
  });
});

test('max 10 addresses per customer', async () => {
  await as(db, 'authenticated', B, async () => {
    for (let i = 0; i < 10; i++) {
      await db.query(`insert into addresses (address_text) values ($1)`, [`Adresse ${i}`]);
    }
    await assert.rejects(db.query(`insert into addresses (address_text) values ('one too many')`), /address limit reached/);
  });
});

// ---------- read helpers ----------
test('list_restaurants: categories, min price, open first', async () => {
  await as(db, 'anon', null, async () => {
    const all = await rows(db, 'select name, is_open, category_slugs, min_price from list_restaurants()');
    assert.equal(all.length, 3);
    assert.equal(all[2].name, 'Dar Lgharbi'); // closed → last
    const bh = all.find((r) => r.name === 'Burger House');
    assert.deepEqual([...bh.category_slugs].sort(), ['burger', 'dessert', 'sandwich']);
    assert.equal(bh.min_price, 250);
    const burgers = await rows(db, `select name from list_restaurants('burger')`);
    assert.deepEqual(burgers, [{ name: 'Burger House' }]);
  });
});

test('search_catalog finds dishes and restaurants, ignores wildcards', async () => {
  await as(db, 'anon', null, async () => {
    const byName = await rows(db, `select kind, title from search_catalog('bahdja')`);
    assert.deepEqual(byName, [{ kind: 'restaurant', title: 'Pizzeria El Bahdja' }]);
    const r = await rows(db, `select kind, title, subtitle from search_catalog('PIZZA')`);
    assert.equal(r.filter((x) => x.kind === 'item').length, 3); // case-insensitive
    assert.ok(r.every((x) => x.subtitle === 'Pizzeria El Bahdja'));
    assert.equal((await rows(db, `select * from search_catalog('%')`)).length, 0);
    assert.equal((await rows(db, `select * from search_catalog('a')`)).length, 0); // too short
  });
});

// ---------- storage ----------
test('avatars: customers upload only into their own folder', async () => {
  await as(db, 'authenticated', A, async () => {
    await db.query(`insert into storage.objects (bucket_id, name) values ('avatars', $1)`, [`${A}/me.jpg`]);
    await denied(db.query(`insert into storage.objects (bucket_id, name) values ('avatars', $1)`, [`${B}/me.jpg`]));
  });
});
