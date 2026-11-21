# Releasing foodfennec on Google Play and the App Store

App ID (both stores, permanent): `com.foodfennec.app`. Version: `app/pubspec.yaml`
(`1.0.0+6` = version name + build number; raise the build number for every upload).

## Done in the code

- Name, icons (Android adaptive + iOS), splash, app ID `com.foodfennec.app`.
- In-app account deletion (customers, riders, restaurants), required by both stores.
- Public privacy policy and terms: `<website>/legal/privacy`, `/legal/terms`,
  `/legal/partner`, `/legal/rider` (FR / AR / EN). Consent recorded per version.
- Permission texts (iOS `Info.plist`); location only while the app is open (no
  background location); `ITSAppUsesNonExemptEncryption = false`.
- Login with email, Google; Sign in with Apple on iPhone (Apple rule 4.8).
  Facebook is coded but hidden (`kFacebookLogin` in
  `app/lib/features/auth/widgets/social_buttons.dart`); turn it on after section 4.
- CI: `android.yml` builds the APK + the Play bundle (`.aab`), signed with your key
  when the secrets below exist; `ios.yml` checks the iPhone build on a Mac.

## 1. Supabase (before anything else)

1. SQL Editor, in order: `supabase/dashboard/2026-11-21` … `2026-11-27_legal_consent.sql`.
2. Authentication → URL configuration: Site URL = the website address; Redirect
   URLs: `foodfennec://login-callback` and the website address.
3. Authentication → Providers: enable Google, Facebook, Apple (see 4).
4. Redeploy the `push` Edge Function (after the SQL).
5. Before launch: delete the demo accounts and demo data.

## 2. Firebase (push notifications)

The app ID changed, so push needs the new app:
1. Firebase console → Add app → Android → package `com.foodfennec.app`. Put its
   App ID in the GitHub secret `FIREBASE_APP_ID`.
2. Add an iOS app `com.foodfennec.app`; upload an APNs key (Apple Developer →
   Keys) in Firebase → Cloud Messaging. Needed for iPhone notifications.
3. Rotate the service-account key used by the push function.

## 3. Google Play

1. Play Console developer account (25 USD, once).
2. Create the upload key on a PC with Java (Android Studio includes it):
   ```
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Keep the file and passwords safe (outside the repository).
3. GitHub → Settings → Secrets → Actions:
   `ANDROID_KEYSTORE_BASE64` (PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))`),
   `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (= `upload`), `ANDROID_KEY_PASSWORD`.
4. Push → download `foodfennec-N.aab` from the GitHub release → upload in Play Console.
5. Store listing: icon 512×512, feature graphic 1024×500, phone screenshots,
   short and full description (FR / AR / EN), privacy policy URL.
6. App content: Data safety (collected: name, email, phone, location, photos,
   app activity, device IDs; shared with restaurants and riders for the order;
   encrypted in transit; users can delete their account), content rating,
   target audience 13+, app access (give a test customer account).
7. New personal developer accounts must run a closed test (at least 12 testers
   for 14 days) before production.

## 4. Login providers

- Google: Google Cloud → OAuth client (Web) with redirect
  `https://<project>.supabase.co/auth/v1/callback` → client ID/secret in Supabase.
- Facebook: Meta for Developers → app → Facebook Login → valid OAuth redirect =
  the same Supabase callback. Privacy policy URL = `<website>/legal/privacy`; data
  deletion = the "Delete my account" instructions (`/legal/privacy`, section 7).
  App ID/secret in Supabase. Switch the Meta app to "Live".
- Apple: Apple Developer → Identifiers → Services ID + Sign in with Apple key →
  in Supabase (Apple provider).

## 5. App Store (iPhone)

1. Apple Developer Program (99 USD / year).
2. A Mac (or a cloud Mac such as Codemagic) to sign and upload; this Windows PC
   cannot. Xcode → Signing: team, bundle ID `com.foodfennec.app`, capabilities
   Push Notifications and Sign in with Apple.
3. App Store Connect: listing, 6.7" and 6.5" screenshots, privacy policy URL,
   App Privacy answers (same as Data safety), demo account for the reviewer.

## 6. Before going live in Algeria (check with a lawyer)

- Have the legal texts (`app/lib/features/legal/legal_texts.dart`) reviewed.
- Law 18-07 (personal data): declaration / authorisation with the ANPDP, and
  authorisation for transfers abroad (Supabase and Firebase servers are outside
  Algeria).
- Law 18-05 (e-commerce): registration of the activity, and the rules on the
  website's hosting and domain.
- Map tiles: the free OpenStreetMap servers are not for production apps; use a
  tile provider with a key (e.g. MapTiler, Stadia) before launch.
- Domain: buy it, set it in Admin → Settings (QR codes) and in Supabase URLs.
