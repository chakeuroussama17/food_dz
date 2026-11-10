-- =====================================================================
-- Customer accounts: phone given at sign-up, profile photo fix,
-- "Delete my account".
-- =====================================================================

-- ---------- profile photos --------------------------------------------
-- Uploading and replacing a file needs a read rule on your own files
-- (Storage checks if the file exists). Also lets the app delete them.
create policy "avatars: owner can read own"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

-- ---------- phone given at sign-up ------------------------------------
-- The app sends the phone in the sign-up metadata; it is kept when it is a
-- valid Algerian mobile (05/06/07 + 8 digits).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_phone text := btrim(coalesce(new.raw_user_meta_data ->> 'phone', ''));
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    left(coalesce(trim(new.raw_user_meta_data ->> 'full_name'), ''), 80),
    case when v_phone ~ '^0[567][0-9]{8}$' then v_phone end
  )
  on conflict (id) do nothing;
  return new;
end $$;

-- ---------- orders: let a deleted account leave its orders --------------
-- Same rules as before; the customer may only change to null (the
-- customer's account was deleted).
create or replace function public.orders_before_write()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    new.total := new.food_total + new.delivery_fee;
    if new.status = 'delivered' then
      new.delivered_at := coalesce(new.delivered_at, now());
      new.commission_amount := round(new.food_total * new.commission_rate);
    end if;
    return new;
  end if;

  -- Money and identity never change after the order is placed.
  if new.food_total <> old.food_total or new.delivery_fee <> old.delivery_fee
     or new.commission_rate <> old.commission_rate
     or new.restaurant_id <> old.restaurant_id
     or (new.customer_id is distinct from old.customer_id
         and new.customer_id is not null) -- null: account deleted
     or new.code <> old.code then
    raise exception 'order amounts cannot change' using errcode = 'P0001';
  end if;
  new.total := new.food_total + new.delivery_fee;

  if new.status <> old.status then
    if not public.order_status_allowed(old.status, new.status) then
      raise exception 'invalid status change % -> %', old.status, new.status
        using errcode = 'P0001';
    end if;
    case new.status
      when 'accepted'  then new.accepted_at  := now();
      when 'ready'     then new.ready_at     := now();
      when 'picked_up' then new.picked_up_at := now();
      when 'delivered' then
        new.delivered_at := now();
        new.commission_amount := round(new.food_total * new.commission_rate);
      when 'rejected', 'cancelled' then new.cancelled_at := now();
      else null;
    end case;
  end if;

  -- A billed order stays billed (only cancelling the statement frees it).
  if old.statement_id is not null and new.statement_id is not null
     and new.statement_id <> old.statement_id then
    raise exception 'order already billed' using errcode = 'P0001';
  end if;
  return new;
end $$;

-- ---------- delete my account -----------------------------------------
-- Customers only (restaurant and driver accounts carry money and history:
-- the admin closes them). Refused while an order is in progress.
-- Past orders stay for the accounts but lose the personal details.
-- Errors: not_signed_in, not_a_customer, active_orders
create or replace function public.delete_my_account()
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  v_role public.app_role;
begin
  if uid is null then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  select role into v_role from public.profiles where id = uid for update;
  if v_role is distinct from 'customer' then
    raise exception 'not_a_customer' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.orders o
              where o.customer_id = uid
                and o.status in ('placed', 'accepted', 'ready', 'picked_up')) then
    raise exception 'active_orders' using errcode = 'P0001';
  end if;

  update public.orders
     set customer_name = 'Client supprimé',
         customer_phone = '0500000000',
         address_text = 'Adresse supprimée',
         address_details = '',
         area = '',
         lat = null,
         lng = null,
         notes = ''
   where customer_id = uid;

  -- Cascades to profiles, addresses, push tokens; orders keep a null
  -- customer. The app removes the profile photo files first.
  delete from auth.users where id = uid;
end $$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
