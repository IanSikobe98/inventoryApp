# Stockroom: Flutter app for the shoe inventory API

A Flutter front end (Android, iOS, web, desktop) for the Spring Boot
`inventoryService` API. Screens: Dashboard, Inventory (add / edit / restock /
delete), Record Sale, Sales Log, Payment Modes. Admin / Employee view switch.

## 1. Prerequisites

- Flutter 3.24 or newer (`flutter --version`, `flutter doctor`)
- The Spring Boot API running (see "Run the backend" below)
- For phones/emulators: Android Studio (Android) or Xcode (iOS/macOS)

## 2. Create the platform folders (one time)

This zip contains only the Dart code (`lib/`, `test/`, `pubspec.yaml`). Flutter
generates `android/`, `ios/`, `web/` etc. for you:

```bash
unzip stockroom-flutter-app.zip -d stockroom_app
cd stockroom_app
flutter create --org com.shoe --project-name stockroom_app .
flutter pub get
```

`flutter create .` keeps the existing `lib/` and `pubspec.yaml`. If it ever
overwrites `lib/main.dart` with the counter demo, just restore `lib/main.dart`
from the zip.

## 3. Run the backend

In your Spring Boot project (with the `CorsConfig` from the API zip):

```bash
./mvnw spring-boot:run        # or ./gradlew bootRun
```

Check it: open http://localhost:8080/swagger-ui.html. Make sure you have at
least one payment mode (the app can add them for you on the Payment modes screen).

## 4. Run the app

The app finds the API automatically in the common cases:

| You run on                     | API address used by default   |
|--------------------------------|-------------------------------|
| Chrome / Edge (web)            | http://localhost:8080         |
| iOS simulator, macOS, Windows, Linux | http://localhost:8080   |
| Android emulator               | http://10.0.2.2:8080          |

```bash
flutter run -d chrome          # easiest first run (needs the CorsConfig on the API)
flutter run -d emulator-5554   # an Android emulator; see `flutter devices`
flutter run -d macos           # or windows / linux
```

A **real phone** must reach your computer over Wi-Fi. Use your computer's LAN IP
and make sure your firewall allows port 8080:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080
```

### Platform settings you may need

- **Android (plain http)**: Android 9+ blocks `http://` by default. In
  `android/app/src/main/AndroidManifest.xml` add to the `<application ...>` tag
  `android:usesCleartextTraffic="true"`, and above it add
  `<uses-permission android:name="android.permission.INTERNET"/>`.
  (Debug builds already include INTERNET; release builds do not.)
- **iOS (plain http)**: in `ios/Runner/Info.plist` add
  `NSAppTransportSecurity` -> `NSAllowsLocalNetworking` = true (or
  `NSAllowsArbitraryLoads` = true for a dev-only LAN IP).
- **macOS**: add `com.apple.security.network.client` = true to
  `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.
- **Web**: the API must allow the browser origin (CORS). `CorsConfig.java`
  in the API zip allows `http://localhost:*`. Change it to your real
  origin before you deploy.
- Use HTTPS in production, and remove the cleartext / ATS exceptions.

## 5. Automated tests

```bash
flutter analyze        # static checks: run this first
flutter test           # all tests (no server needed; HTTP is faked)
flutter test test/api_client_test.dart      # one file
flutter test --coverage                     # writes coverage/lcov.info
```

What's covered:

| File | Checks |
|---|---|
| `models_test.dart` | JSON -> models (batches, sales, dashboard, Spring pages) |
| `format_test.dart` | money / date formatting |
| `api_client_test.dart` | request URLs & bodies (e.g. `shoeSize`, dates), 409/400/502 errors, unreachable server |
| `widget_test.dart` | inventory list + error state, add-batch form (validation and POST body), sale form (total, inactive modes hidden, stock limit, server error), dashboard numbers |

The tests use `MockClient`, so they run without the backend or internet
(`AppText.useGoogleFonts = false` stops the font package downloading fonts).

## 6. Manual test script (with the real API)

Start the API and the app, then:

1. **Payment modes** (Admin): add "Airtel Money", it appears as Active. Switch it
   off, then on. Adding "Airtel Money" again shows a "already exists" error.
2. **Inventory -> Add batch**: code `SB-2201`, size `42`, type `Sneaker`, colour
   `Black`, pairs `24`, cost `1800`, wholesale `2500`, retail `3200`. The card shows
   **24 / 24 left, In stock**. Add the same code again and you get a duplicate-code error.
3. **Record sale**: pick SB-2201, quantity `2`, price `3000`, pay with M-Pesa.
   Total shows **KSh 6,000**. Confirm. A toast appears.
4. **Check the effects**:
   - Inventory: **22 / 24 left**.
   - Sales log: the new sale, with the M-Pesa pill.
   - Dashboard: Today's sales **KSh 6,000**, est. profit **KSh 2,400**
     ((3000 - 1800) x 2), the 7-day bar for today, SB-2201 in Top sellers.
5. **Stock guard**: try quantity `23` (only 22 left): the form blocks it. Then try
   to sell the last pair from two browser tabs at once: one succeeds, the other
   shows "Only N pair(s) ... remain".
6. **Restock**: Restock +12 on SB-2201: **34 / 36 left**.
7. **Low stock**: sell until 5 or fewer remain: the card turns **Low stock**, the
   dashboard "Needs restocking" count goes up, and "Low stock only" filters to it.
8. **Sales log filters**: search "sneaker", pick a date range, pick a payment mode,
   then "Clear filters".
9. **Employee view**: switch to Employee: only Record sale + Sales log show.
10. **Offline**: stop the API and pull to refresh: a friendly "Cannot reach the
    server" message with **Try again**.

You can also test the API on its own in Swagger UI (`/swagger-ui.html`).

## 7. Project layout

```
lib/
  main.dart, app.dart         entry point, providers + theme wiring
  config/env.dart             API base URL (override with --dart-define)
  theme/app_theme.dart        colours + fonts (Fraunces / IBM Plex)
  models/                     ShoeBatch, Sale, PaymentMode, DashboardData, PageResult
  services/api_client.dart    every HTTP call + error handling
  providers/                  state (Provider/ChangeNotifier), one per feature
  widgets/                    cards, forms, dialogs, shared bits
  screens/                    Dashboard, Inventory, Sell, Sales log, Payment modes, shell
test/                         unit + widget tests
```

## 8. Known limits / next steps

- **No login yet.** The Admin/Employee switch only decides which screens show;
  it is not security. The API's `CurrentUserProvider` currently stamps user id 1.
  Add real auth (e.g. JWT) on the API, then send the token from `ApiClient`.
- **Photos are links** (`pictureUrl`): the API has no upload endpoint yet.
- Inventory and sell lists load the first 100 batches; the sales log pages 25 at a
  time with "Load more". Add paging to Inventory if you have more batches.
- Light theme only.
- Fonts come from Google Fonts at run time. To work offline, bundle the font files
  under `assets/fonts` and switch `AppText` to `fontFamily`.
