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

## Getting Started

- [Flutter documentation](https://docs.flutter.dev/)
