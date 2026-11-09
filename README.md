# Food App (Algeria): MVP

Food delivery for one restaurant, one driver and one customer, end to end.
Flutter (web + Android/iOS) on Supabase. Arabic (RTL), French and English.
Prices are in DZD, whole numbers. Cash on delivery only.

```
/app        Flutter app
/design     Screenshots from the Figma design (source of the look)
/supabase   SQL migrations, tests, Edge Functions  (from step 1)
```

## Prerequisites

- Flutter 3.44+ (`flutter --version`)
- Docker Desktop (running), for the local database
- Supabase CLI 2.x (`supabase --version`)

## Run the app

```bash
cd app
flutter pub get
cp env.example.json env.json      # then paste your Supabase URL + publishable key
flutter run -d chrome --dart-define-from-file=env.json
```

Without `env.json` the app still starts. Only screens that need data won't work.

The component gallery is at `/dev/gallery`. Use it to compare the shared
widgets with the Figma screens and to check Arabic RTL with the
language switch at the top right.

## Local backend (Supabase)

```bash
# Docker Desktop must be running
supabase start                    # from the repo root; prints the API URL and keys
```

Put the printed `API URL` and `Publishable key` (or `anon key`) into `app/env.json`:

```json
{ "SUPABASE_URL": "http://127.0.0.1:54321", "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..." }
```

Emails aren't really sent locally. Open **Mailpit at http://127.0.0.1:54324**
to read the 6-digit sign-up and password-reset codes.

Auth settings are in `supabase/config.toml`:
- email confirmation is required
- 6-digit codes, valid for 15 minutes
- passwords need at least 8 characters
- email templates (FR/AR/EN) are in `supabase/templates/`

## Customer start flow

`/` splash → `/welcome` onboarding (first launch only) → `/login`,
`/signup` → `/verify` (code) → `/home`. Forgot password:
`/forgot-password` → `/verify` → `/reset-password`. The router sends
signed-out users to `/login` and signed-in users away from the auth pages.

Onboarding illustrations: drop `onboarding_1.png`, `onboarding_2.png` and
`onboarding_3.png` into `app/assets/images/`. They replace the grey
placeholders automatically.

## Database

- Schema: `supabase/migrations/`. Demo data: `supabase/seed.sql`.
- **Applying to the hosted project:** this network blocks the Postgres port,
  so `supabase db push` doesn't work. Open Dashboard → **SQL Editor**, paste
  the generated file from `supabase/dashboard/`, and press Run.
- **Database tests** (RLS, triggers, functions) run in Node with PGlite, a
  real Postgres in WebAssembly. No Docker needed:
  ```bash
  cd supabase/tests && npm install && npm test
  ```

## Customer browsing & account

| Route | Page |
|---|---|
| `/home` | Deliver-to, greeting, search, categories, restaurants |
| `/search` | Recent keywords, suggested restaurants, live results |
| `/category/:slug` | Popular dishes of a category + restaurants |
| `/r/:slug` | Restaurant (the QR link) with category chips |
| `/r/:slug/item/:id` | Dish details, quantity, add to cart |
| `/cart` | Basic cart (checkout comes with ordering) |
| `/location` | "Access location" (shown once after login) |
| `/account`, `/account/personal`, `/account/edit` | Profile, info, edit + photo |
| `/account/addresses`, `.../new`, `.../:id` | Delivery addresses with map pin |

Signed-out visitors opening `/r/<slug>` are sent to login and then back to
that restaurant.

## Checkout & customer orders

| Route | Page |
|---|---|
| `/cart` | "My Cart" design: dishes, delivery address + phone (EDIT), total with Breakdown, PLACE ORDER |
| `/orders/:id/placed` | Order placed: code and amount to pay in cash |
| `/orders` | My orders: Ongoing / History, cancel while not accepted |
| `/orders/:id` | Live status steps, items, amounts, address; updates by itself |

**Rules (in the database, `place_order`):**
- The app sends dish ids and quantities only. Prices, the delivery fee and the
  commission rate are read from the database.
- The total the customer saw is checked; if a price changed the order is
  refused and the cart refreshes itself with the new prices.
- One restaurant per order, restaurant approved and open, dishes available,
  1–20 of each, at most 30 lines; the address must be the customer's own.
- Max 3 orders in progress and 10 orders per hour per customer.
- A double tap or network retry never creates two orders (`client_ref`).
- Customers can cancel only until the restaurant accepts (`cancel_my_order`).
- Status changes are pushed live (Supabase Realtime on `orders`, filtered by
  RLS), with a 30-second refresh as a fallback.

## Restaurant owners

1. Login page → **"Own a restaurant? REGISTER IT"** (`/restaurant/register`):
   enter the owner account and restaurant details.
2. The restaurant is created **inactive and closed**. The owner sees
   "Waiting for approval" and can already build the menu.
3. **Approve it:** Supabase Dashboard → Table Editor → `restaurants` → set
   `is_active` to `true`. The owner can then switch "Open for orders" on, and
   customers see the restaurant.

| Route | Page |
|---|---|
| `/restaurant` | Dashboard: approval banner, open/closed switch, counters, menu summary |
| `/restaurant/menu` | My menu: category chips, availability switches |
| `/restaurant/menu/new`, `/restaurant/menu/:id` | Add / edit dish (photo, price, category) |
| `/restaurant/profile` | Cover, logo, details, map pin, language, log out |
| `/restaurant/orders` | Live orders: New / In progress / History, Accept, Reject, Ready, Cancel |

After login, owners always land in `/restaurant/...` and customers can never
open it. The database enforces this as well, not only the app.

**Live orders:** new orders appear instantly (Supabase Realtime, plus a
20-second refresh as a fallback), with a red count on the orders icon and a
chime that repeats every 20 seconds until the order is accepted or rejected.
Browsers only allow sound after a tap, so on the web the page shows a one-tap
"turn on the sound alert" banner. The speaker icon mutes it.

What a restaurant may do (`owner_set_order_status`, checked in the database):
new → accepted, new → rejected (reason required), accepted → ready,
accepted/ready → cancelled (reason required). Pickup and delivery belong to
the driver. The reason is shown to the customer.

## Drivers

1. Login page → **"Deliver with us? JOIN"** (`/driver/register`): account,
   mobile phone, vehicle (moto / car / bike).
2. The admin approves the driver in **Admin → Drivers**.
3. The driver switches **Online** and sees orders the restaurant accepted that
   no driver took yet (restaurant, customer's area, distance, fee, cash).
   The list refreshes every 10 s and chimes when a new order appears.
4. **Take it**: first tap wins (the database refuses the second driver with
   "Another driver took it first"). One delivery at a time per driver.
5. The driver sees the customer's name, phone, address and notes, with Call
   and Google Maps directions for both stops. **Picked up** once the
   restaurant marked it Ready, then **Delivered & paid** (confirms the cash).
   Before pickup the driver can give the order back.

| Route | Page |
|---|---|
| `/driver` | Online switch, current delivery, available orders, today's total |
| `/driver/orders/:id` | Pickup / drop-off, call, directions, cash, actions |
| `/driver/deliveries` | Finished deliveries with fees |
| `/driver/account` | Phone, vehicle, language, log out |

### Proof of delivery and cash

- **Photo:** "Delivered & paid" opens the camera. The database refuses the
  delivery without a photo uploaded to the private `delivery-proofs` bucket
  under the order's folder, by the assigned driver, while the order is on its
  way. The customer, the driver and the admin can see it (customer order page,
  Admin → Orders); nobody else.
- **Cash:** the driver collects the total, keeps the delivery fee and owes the
  food total to the restaurant.
  1. Driver home: "Money to give to restaurants" → **I gave the money**.
  2. Restaurant dashboard: "Money to receive from drivers" → **Received**
     (works even if the driver forgot to tap).
  3. Admin → Drivers: amount owed per driver, **Blocked** when overdue.
- **Block:** money unconfirmed for more than `app_config.cash_handover_hours`
  (24 h) → the driver can't take new orders until the restaurant confirms.

## Admin

**Create the admin account (once):**
1. In the app, sign up normally with the email you'll use for admin.
2. In Supabase → SQL Editor, run:
   ```sql
   update public.profiles set role = 'admin'
   where id = (select id from auth.users where email = 'YOUR-ADMIN-EMAIL');
   ```
3. Log out and log in again. You land on `/admin`.

Only this SQL can grant the admin role. Users can never change their own
role, and every admin function in the database checks it.

| Route | Page |
|---|---|
| `/admin` | Dashboard for a period: commission, sales, delivered, fees, cancelled, in progress, to approve, not billed yet; per-restaurant table |
| `/admin/restaurants` | Approve / deactivate / reactivate, commission rate per restaurant, owner contact, amount to bill |
| `/admin/drivers` | Approve / deactivate drivers, online now, current order, deliveries |
| `/admin/orders` | All orders, filtered by period / restaurant / status, with items |
| `/admin/receipts` | Commission receipts: generate (previous half-month, last month, custom), PDF download/print, mark paid, cancel |
| `/admin/settings` | Delivery fee, default commission, hours before a driver with unconfirmed cash is blocked, your details printed on the receipts, customers list |

**Commission rules (in the database):**
- On every delivered order: `commission = round(food total × rate)`. The rate
  is frozen when the order is placed, and delivery fees are excluded.
- A receipt bills the delivered, not-yet-billed orders of one restaurant in a
  finished period. Receipts are numbered `FD-YYYY-0001`. An order can never be
  billed twice. Cancelling an unpaid receipt frees its orders.

**Demo orders:** `supabase/dashboard/2026-11-07b_demo_orders_OPTIONAL_after_orders.sql`
adds about 120 orders for testing. Remove them before launch; the SQL is at
the top of that file.

## Receipts (in the app, no email)

| Who | Where | Document |
|---|---|---|
| Customer | Order page of a delivered order → Download receipt / Print | Order receipt: dishes, delivery fee, total paid in cash, driver |
| Restaurant | Profile → My commission statements | The commission statements the admin issued (same PDF) |
| Driver | My deliveries → PDF icon → this/last week, this/last month | Earnings statement: deliveries, cash collected, given to restaurants, fees earned |
| Admin | Receipts | Commission statements (generate, PDF, paid, cancel) |

All PDFs carry the business details from Admin → Settings, in the app's
language (Arabic laid out right-to-left; amounts in "DA").

## Phone app (Android APK)

GitHub Actions (`.github/workflows/android.yml`) builds the APK on every push
to `main` that touches `app/`, or by hand: Actions → Android APK → Run
workflow. The APK is attached to a GitHub Release (`build-N`): open the
release on the phone, download the `.apk`, allow installing from the browser.

Repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `SUPABASE_URL` | `https://<project>.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | the publishable key (public, same as `env.json`) |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID` | optional: push notifications (from `google-services.json`) |

## Push notifications

Alerts while the app is closed (Android/iOS; web later):
new order → restaurant; accepted / ready / on the way / delivered / rejected
→ customer; new delivery available / ready for pickup → drivers.

How it works: the phone registers its Firebase token (`register_push_token`);
the `orders_push` trigger calls the `push` Edge Function through `pg_net`;
the function picks the recipients and sends through Firebase Cloud Messaging.

Setup (once):
1. Firebase console → new project → add an Android app with package
   `dz.foodapp.food_app` → download `google-services.json` (keep it out of
   git). Copy its api key, app id, sender id and project id into `env.json`
   and the GitHub secrets above.
2. Firebase → Project settings → Service accounts → Generate new private key.
   Then: `supabase secrets set FCM_SERVICE_ACCOUNT="$(cat key.json)"`.
3. `supabase secrets set PUSH_SECRET=<the value in supabase/.env>` and run
   `supabase/dashboard/private/push_config_PRIVATE.sql` (not in git) in the
   SQL Editor.
4. Deploy: `supabase functions deploy push --no-verify-jwt --use-api`.

Without these the app works normally, just without push.

## Auto-reject

An order the restaurant doesn't answer within `app_config.auto_reject_minutes`
(10, Admin → Settings) is rejected by `auto_reject_stale_orders()`, run every
minute by pg_cron. The customer sees "The restaurant didn't answer in time".

## Tests

```bash
cd app
flutter analyze
flutter test                                  # unit + widget tests
# Render the gallery to PNGs (test/screenshots/gallery_ar.png, gallery_fr.png):
flutter test test/screenshots --update-goldens --tags screenshot --run-skipped
```

## Design tokens

Colours, radii and spacing come from the Figma kit and live in
`app/lib/core/theme/app_colors.dart`. Fonts: **Sen** (Latin, from the design)
and **Noto Kufi Arabic** (Arabic). Both are bundled in `app/assets/fonts`, so
there is no network request for fonts.

## Secrets

- `app/env.json` holds only the public Supabase URL and publishable key. It's
  git-ignored anyway.
- Server secrets (Resend API key, service role key) only go in Supabase:
  `supabase secrets set RESEND_API_KEY=...`. Never put them in the Flutter app.
