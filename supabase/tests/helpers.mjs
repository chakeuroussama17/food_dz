// Shared helpers for the database tests (PGlite = real Postgres in WASM).
import { PGlite } from '@electric-sql/pglite';
import { readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const here = dirname(fileURLToPath(import.meta.url));
export const root = join(here, '..');
export const read = (p) => readFileSync(p, 'utf8');

/** New database with the Supabase stand-in, all migrations and the seed. */
export async function freshDb(users = []) {
  const db = new PGlite();
  await db.exec(read(join(here, 'supabase_stub.sql')));
  const migrations = readdirSync(join(root, 'migrations'))
    .filter((f) => f.endsWith('.sql'))
    .sort();
  for (const m of migrations) await db.exec(read(join(root, 'migrations', m)));
  await db.exec(read(join(root, 'seed.sql')));
  for (const [id, email, name] of users) {
    await db.query(
      `insert into auth.users (id, email, raw_user_meta_data) values ($1, $2, $3)`,
      [id, email, JSON.stringify({ full_name: name })],
    );
  }
  return db;
}

/** Runs [fn] as [role] ('anon' | 'authenticated'), with [userId] as auth.uid(). */
export async function as(db, role, userId, fn) {
  await db.exec(
    `reset role; select set_config('request.jwt.claim.sub', '${userId ?? ''}', false); set role ${role};`,
  );
  try {
    return await fn();
  } finally {
    await db.exec('reset role;');
  }
}

export const rows = async (db, sql, params) => (await db.query(sql, params)).rows;

export async function denied(
  promise,
  pattern = /permission denied|violates row-level security/,
) {
  await assert.rejects(promise, pattern);
}
