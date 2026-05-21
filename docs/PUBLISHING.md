# Publishing Brolly to the Google Play Store

This is the one-time setup you do before your first Play Store release, plus the
recurring steps for every subsequent release.

## 1. Pre-flight: keys + accounts

You need accounts and keys from three places.

### a. Google Play Console
- Sign up at https://play.google.com/console (one-time $25 USD).
- Create an app entry. The package name must match `applicationId` in
  [android/app/build.gradle.kts](../android/app/build.gradle.kts) (currently
  `com.brolly.brolly`).

### b. AdMob (https://admob.google.com)
- Create an AdMob account if you don't have one.
- Add a new app of type "Android". Once approved, AdMob hands you an **App
  ID** and you can create **Ad Unit IDs** under it.
- Replace the placeholder values in:
  - [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) — the
    `com.google.android.gms.ads.APPLICATION_ID` meta-data tag currently uses
    Google's *sample* App ID. Swap it for your real one before publishing.
  - [lib/core/ads/ad_config.dart](../lib/core/ads/ad_config.dart) — replace
    `_prodBannerAndroid` (and `_prodBannerIos` if you ship iOS) with your real
    ad unit IDs.
- **Important:** debug builds always use Google's test ad unit IDs. Don't ever
  click your own ads on a release build with your real IDs — AdMob will close
  your account.

### c. Maps + radar data — already free

No account or key needed. Brolly uses:

- **OpenFreeMap** (https://openfreemap.org) — vector tiles for the base map.
  Free, no key, CC0-licensed, explicitly permits commercial use at scale.
- **RainViewer** (https://www.rainviewer.com) — animated radar tiles. Free
  personal-use tier covers small-scale ad-supported apps; if Brolly grows
  large, consult their commercial license.
- **Open-Meteo** (https://open-meteo.com) — forecast + geocoding. Free, no
  key, ~10k calls/day per user IP.

## 2. One-time: generate the upload keystore

You need a release keystore to sign Play Store builds. Without one your APKs
are debug-signed and the Play Store will reject them.

```powershell
cd C:\development\Brolly\android
keytool -genkey -v -keystore brolly-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias brolly
```

`keytool` will prompt for a keystore password, a key password, and your name /
organisation. **Write the passwords down somewhere safe** — if you lose them
you can never publish another update to the same app on Play Store.

Then create `android/key.properties` (gitignored):

```properties
storePassword=<the keystore password you set>
keyPassword=<the key password you set>
keyAlias=brolly
storeFile=brolly-release.jks
```

The build.gradle.kts is already wired to pick this up automatically. If
`key.properties` is missing the build falls back to debug signing so local
`flutter run --release` still works.

**Back up `brolly-release.jks` and `key.properties` somewhere not in this
repo.** A password manager, encrypted USB, anything. Losing them means losing
the ability to update your app.

## 3. Privacy policy

Play Store requires a public privacy policy URL for any app that accesses
location, even if you don't transmit it. A minimal version that matches what
Brolly actually does:

```markdown
# Brolly Privacy Policy

Brolly does not collect, store, transmit, or sell any personal information.

## Location
Brolly requests your device location only to show local weather and radar. The
coordinates are sent to weather data providers (Open-Meteo, MapTiler,
RainViewer) as part of the request URL. No location history is retained on our
servers — we don't run any servers.

## Saved places
Place names and coordinates you pin are stored locally on your device and
never leave it.

## Advertising
Brolly displays banner ads served by Google AdMob. AdMob may collect device
identifiers (advertising ID) and approximate location to serve relevant ads.
See Google's privacy policy at https://policies.google.com/privacy for
details. You can reset your advertising ID at any time in your device's
settings.

## Contact
[your email here]
```

Host this somewhere publicly accessible. The easiest options:

- A GitHub Pages site for this repo: turn on Pages in repo settings, save the
  text above as `docs/privacy.md`, get a URL like
  `https://<your-github>.github.io/Brolly/privacy`
- A Gist on github.com made public
- Your own domain if you have one

Paste the URL into the Play Console "App content" → "Privacy policy" section.

## 4. App icon

Replace the default Flutter icon before publishing. The pubspec is already
wired up with `flutter_launcher_icons`. Drop your icon files into
`assets/branding/` (see that folder's README) and run:

```powershell
flutter pub run flutter_launcher_icons
```

Adaptive icons (Android 12+) need a foreground PNG with transparent
background — see the pubspec's `flutter_launcher_icons` section.

## 5. Build the release AAB

Play Store wants an Android App Bundle (`.aab`), not an APK.

```powershell
cd C:\development\Brolly
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

That's the file you upload to Play Console under "Production" → "Create new
release".

For your personal ad-free build (sideload onto your own phone):

```powershell
flutter build apk --release --dart-define=ADS_ENABLED=false
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Install via
`adb install`.

## 6. Play Console checklist (first release)

Inside Play Console, you'll be required to fill in:

- App name, description, category (Weather)
- Screenshots (phone + 7-inch + 10-inch tablet)
- Feature graphic (1024×500 PNG)
- Content rating questionnaire
- Target audience (probably 13+)
- Data safety form — declare you collect location for "App functionality" only
- Ads declaration — yes, your app contains ads
- Privacy policy URL (from step 3)

After upload Google reviews the bundle, typically within a few days.

## 7. Subsequent releases

For every update:

```powershell
# Bump version in pubspec.yaml — e.g. 0.1.0+1 -> 0.2.0+2
flutter build appbundle --release
```

Upload the new AAB, write release notes, roll out.
