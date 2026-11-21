-- =====================================================================
-- Legal consent: who accepted which document, which version, when.
--
-- Documents: terms (terms of use), privacy (privacy policy), partner
-- (restaurant partner terms), rider (rider terms). The app shows the
-- current version; a new version is accepted again on the next start.
-- Sign-up sends the accepted version in its metadata (email form);
-- social logins (Google, Facebook, Apple) accept on the first start.
-- =====================================================================

create table if not exists public.user_consents (
  user_id     uuid not null references public.profiles (id) on delete cascade,
  document    text not null check (document in ('terms', 'privacy', 'partner', 'rider')),
  version     text not null check (version ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'),
  accepted_at timestamptz not null default now(),
  platform    text not null default '' check (char_length(platform) <= 20),
  primary key (user_id, document, version)
);
alter table public.user_consents enable row level security;
-- No policies: written and read through the functions below.

-- The documents (and versions) I accepted.
create or replace function public.my_consents()
returns table (document text, version text, accepted_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select c.document, c.version, c.accepted_at
    from public.user_consents c
   where c.user_id = auth.uid()
   order by c.accepted_at;
$$;
revoke all on function public.my_consents() from public, anon;
grant execute on function public.my_consents() to authenticated;

-- Errors: invalid_document, invalid_version
create or replace function public.accept_documents(
  p_documents text[], p_version text, p_platform text default '')
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  d text;
begin
  if auth.uid() is null then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if coalesce(p_version, '') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then
    raise exception 'invalid_version' using errcode = 'P0001';
  end if;
  foreach d in array coalesce(p_documents, '{}') loop
    if d not in ('terms', 'privacy', 'partner', 'rider') then
      raise exception 'invalid_document' using errcode = 'P0001';
    end if;
    insert into public.user_consents (user_id, document, version, platform)
    values (auth.uid(), d, p_version,
            case when p_platform in ('android', 'ios', 'web') then p_platform else '' end)
    on conflict do nothing;
  end loop;
end $$;
revoke all on function public.accept_documents(text[], text, text) from public, anon;
grant execute on function public.accept_documents(text[], text, text) to authenticated;

-- ---------- sign-up: the box ticked on the form ---------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  m        jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_phone  text := btrim(coalesce(m ->> 'phone', ''));
  v_wilaya text := btrim(coalesce(m ->> 'wilaya', ''));
  v_lang   text := btrim(coalesce(m ->> 'lang', ''));
  v_plat   text := btrim(coalesce(m ->> 'platform', ''));
  v_terms  text := btrim(coalesce(m ->> 'accepted_terms', ''));
begin
  insert into public.profiles (id, full_name, phone, wilaya, commune,
                               signup_platform, signup_lang)
  values (
    new.id,
    -- Social logins give "name" (Google: also "full_name").
    left(coalesce(nullif(btrim(m ->> 'full_name'), ''), btrim(m ->> 'name'), ''), 80),
    case when v_phone ~ '^0[567][0-9]{8}$' then v_phone end,
    case when v_wilaya ~ '^[0-9]{1,2}$' and v_wilaya::int between 1 and 58
         then v_wilaya::smallint end,
    nullif(left(regexp_replace(btrim(coalesce(m ->> 'commune', '')), '\s+', ' ', 'g'), 80), ''),
    case when v_plat in ('android', 'ios', 'web') then v_plat end,
    case when v_lang in ('ar', 'fr', 'en') then v_lang end
  )
  on conflict (id) do nothing;
  if v_terms ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then
    insert into public.user_consents (user_id, document, version, platform)
    values (new.id, 'terms', v_terms,
            case when v_plat in ('android', 'ios', 'web') then v_plat else '' end),
           (new.id, 'privacy', v_terms,
            case when v_plat in ('android', 'ios', 'web') then v_plat else '' end)
    on conflict do nothing;
  end if;
  return new;
end $$;
