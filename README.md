# ReadMe

Flutter blog app for ReadMe. Runs standalone or embedded inside the Flutter Kanpur main app.

## Environment setup

ReadMe uses a gitignored `.env` for Supabase and OAuth keys. The committed `pubspec.yaml` does **not** bundle `.env` so the package builds cleanly when Flutter Kanpur pulls ReadMe from Git.

### Standalone dev / Play Store build

1. Copy the template and fill in values:

   ```bash
   cp .env.example .env
   ```

2. Enable the local `.env` asset (patches `pubspec.yaml` on your machine only):

   ```bash
   ./tool/enable_standalone_env.sh
   ```

3. Run or build:

   ```bash
   flutter run
   # or
   ./tool/run_standalone.sh
   ```

### Before commit or Kanpur release tag

Remove the local `.env` asset line so the committed pubspec stays package-safe:

```bash
./tool/disable_standalone_env.sh
```

### Flutter Kanpur (embedded)

No ReadMe `.env` is required in the package. The host app loads its own `.env` and binds ReadMe Supabase via `ReadmeSupabase.bind`. Ensure the host `.env` includes `README_SUPABASE_URL`, `README_SUPABASE_ANON_KEY`, and `README_SYNC_SESSION_URL`.

## Deep links (open articles in the app)

Shared article URLs use this format:

```text
https://readme.flutterkanpur.in/blogs/articles/{blog_id}
```

When the app is installed and domain verification is configured, tapping such a link (e.g. from WhatsApp) opens the article inside ReadMe instead of the browser.

### Production setup

1. **Android** — In Play Console → Setup → App integrity, copy the **App signing key certificate** SHA-256 fingerprint into [`readme_website/public/.well-known/assetlinks.json`](../readme_website/public/.well-known/assetlinks.json) (replace `REPLACE_WITH_PLAY_APP_SIGNING_SHA256`).

2. **iOS** — Replace `REPLACE_TEAM_ID` in [`readme_website/public/.well-known/apple-app-site-association`](../readme_website/public/.well-known/apple-app-site-association) with your Apple Developer Team ID. Enable **Associated Domains** for `com.drishtant.readme` in the Apple Developer portal.

3. **Deploy** the website so both files are live at:
   - `https://readme.flutterkanpur.in/.well-known/assetlinks.json`
   - `https://readme.flutterkanpur.in/.well-known/apple-app-site-association`

### Test on Android

```bash
# Simulate opening an article link
adb shell am start -a android.intent.action.VIEW \
  -d "https://readme.flutterkanpur.in/blogs/articles/YOUR_BLOG_UUID"

# Check App Links verification status
adb shell pm get-app-links com.drishtant.readme
```

App Links verification usually requires a **release/signed** build whose certificate matches `assetlinks.json`.

## Shorebird (OTA code push)

ReadMe uses [Shorebird](https://shorebird.dev) to ship **Dart code fixes** without waiting for Play Store review. Native/plugin changes still require a full store release.

Shorebird applies only to the **standalone** ReadMe app (`com.drishtant.readme`). It is skipped when embedded in Flutter Kanpur.

### One-time setup

1. Install the CLI: [Shorebird Quick Start](https://docs.shorebird.dev/getting-started/)
2. From the project root:

   ```bash
   chmod +x tool/shorebird_*.sh
   ./tool/shorebird_setup.sh
   ```

   This runs `shorebird login` and `shorebird init`, which assigns your real `app_id` in `shorebird.yaml`.

3. Commit `shorebird.yaml` (app id is not secret).

**Flutter not in PATH?** This project uses FVM (`3.38.7`). Either:

```bash
fvm flutter pub get
# or add FVM to PATH, then re-run the scripts
export PATH="$PATH:$HOME/fvm/default/bin"   # if you use fvm global
```

The tool scripts auto-detect `fvm flutter` and `~/fvm/versions/<version>/bin/flutter`.

### Release to stores (base binary) — do this FIRST

You **must** create a Shorebird release before any patch will work.

```bash
./tool/enable_standalone_env.sh   # if not already enabled
./tool/shorebird_release.sh android
# ./tool/shorebird_release.sh ios
```

Upload the generated `.aab` / `.ipa` to Play Console / App Store Connect.

### Push an OTA patch — only AFTER a release exists

```bash
./tool/shorebird_patch.sh android
```

If you see `No Android releases found`, run `shorebird_release.sh` first (not `flutter build`).

Patches update **Dart code only** (UI, logic, bug fixes). Users get the patch on the next app launch (background download). A snackbar may prompt them to reopen the app.

### Store updates vs patches

- **Shorebird patch** — quick Dart-only fixes (no store review)
- **Play Store update** (`upgrader` in app) — new native version, plugins, or when patch is not enough

### Verify locally

```bash
shorebird preview --release-version 1.1.0+8
shorebird doctor
```

## Getting Started

- [Flutter documentation](https://docs.flutter.dev/)
