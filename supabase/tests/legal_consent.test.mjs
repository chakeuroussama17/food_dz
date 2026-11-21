// Legal consent: sign-up box, accepting later, checks.
import test from 'node:test';
import assert from 'node:assert/strict';
import { freshDb, as, rows } from './helpers.mjs';

const C = 'aaaaaaaa-0000-4000-8000-00000000000a';
const S = 'abababab-0000-4000-8000-0000000000ab';
let db;
const q = (u, sql, params) => as(db, 'authenticated', u, () => rows(db, sql, params));
const rejects = (u, sql, params, re) =>
  as(db, 'authenticated', u, () => assert.rejects(db.query(sql, params), re));

test.before(async () => {
  db = await freshDb([[C, 'c@test.dz', 'Amina']]);
});

test('sign-up with the box ticked records terms + privacy', async () => {
  await db.query(
    `insert into auth.users (id, email, raw_user_meta_data) values ($1, 's@test.dz', $2)`,
    [S, JSON.stringify({ name: 'Social Sami', accepted_terms: '2026-11-20', platform: 'android' })]);
  const mine = await q(S, `select document, version from my_consents() order by document`);
  assert.deepEqual(mine.map((r) => `${r.document}@${r.version}`), ['privacy@2026-11-20', 'terms@2026-11-20']);
  // Social logins give "name": kept as the full name.
  assert.equal((await rows(db, `select full_name from profiles where id = $1`, [S]))[0].full_name, 'Social Sami');
});

test('accepting later; checks; only my own', async () => {
  assert.equal((await q(C, `select * from my_consents()`)).length, 0);
  await q(C, `select accept_documents(array['terms','privacy','rider'], '2026-11-20', 'ios')`);
  await q(C, `select accept_documents(array['terms'], '2026-11-20')`); // again: no error
  const mine = await q(C, `select document from my_consents() order by document`);
  assert.deepEqual(mine.map((r) => r.document), ['privacy', 'rider', 'terms']);
  await rejects(C, `select accept_documents(array['cookies'], '2026-11-20')`, [], /invalid_document/);
  await rejects(C, `select accept_documents(array['terms'], 'v2')`, [], /invalid_version/);
  assert.deepEqual(await q(C, `select * from user_consents`).catch(() => []), []);
  await as(db, 'anon', null, () =>
    assert.rejects(db.query(`select accept_documents(array['terms'], '2026-11-20')`), /denied/));
});
