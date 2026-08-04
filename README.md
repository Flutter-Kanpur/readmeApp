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

## Getting Started

- [Flutter documentation](https://docs.flutter.dev/)
