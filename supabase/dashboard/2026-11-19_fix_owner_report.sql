-- FIX: paste into Supabase Dashboard → SQL Editor → Run.
-- The restaurant report was defined twice (the 2026-11-16 file was run
-- again after 2026-11-17), so the app couldn't load it ("Last 7 days"
-- and Insights kept loading). This removes the old version and keeps the
-- new one (with outlets).
drop function if exists public.owner_report(timestamptz, timestamptz);
notify pgrst, 'reload schema';
