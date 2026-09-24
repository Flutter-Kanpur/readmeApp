# Contributing to ReadME App

ReadME App is the Flutter mobile app for the ReadME community blogging platform. It runs standalone on Android and iOS, and can also be embedded inside the Flutter Kanpur main app.

## Before you start

- **Stack**: Flutter (FVM `3.38.7`), Supabase (auth + database), Shorebird (OTA updates)
- **Flutter setup**: This project uses [FVM](https://fvm.app/). Install FVM, then run `fvm use` in the project root.
- **IDE**: Android Studio or VS Code with the Flutter extension

## Set up locally

```bash
git clone https://github.com/Flutter-Kanpur/readmeApp.git
cd readmeApp

# Install dependencies
fvm flutter pub get

# Set up environment
cp .env.example .env
# Fill in SUPABASE_URL and SUPABASE_ANON_KEY
# (Ask in the Flutter Kanpur WhatsApp group if you need test credentials)

# Enable the .env for standalone dev
./tool/enable_standalone_env.sh

# Run the app
fvm flutter run
```

> If you don't have FVM, you can use `flutter` directly if your version matches `3.38.7`.

## Project structure

```
lib/
  core/           → app config, theme, routing, Supabase client
  features/       → feature modules (articles, communities, auth, profile)
  shared/         → reusable widgets and utilities
assets/           → images, fonts, icons
supabase/         → database migration SQL
tool/             → shell scripts for env, Shorebird, builds
```

Each feature in `lib/features/` follows the same structure:
```
features/articles/
  data/           → Supabase queries
  domain/         → models
  presentation/   → screens and widgets
```

## What to pick up

Look for issues labelled **`good first issue`** on GitHub. Good areas to start:

- **UI polish** — spacing, animations, loading states, empty states
- **New screens** — notifications, bookmarks, writer profile
- **Bug fixes** — reported crashes or layout issues on specific devices
- **Accessibility** — semantic labels, font scaling, contrast
- **Deep link improvements** — article sharing, community invites

## How to contribute

1. **Pick an issue** — comment on it so others know you're working on it
2. **Fork and branch** — branch name: `fix/issue-title` or `feat/feature-name`
3. **Make your change** — keep it focused; one issue per PR
4. **Test on both platforms** if possible — at minimum run on Android emulator
5. **Open a PR** — describe what you changed and why, link the issue

```bash
git checkout -b fix/your-issue-title
# make changes
git commit -m "fix: short description"
git push origin fix/your-issue-title
# open PR on GitHub
```

## Before committing

Always run this before pushing — it removes the local `.env` asset line so the pubspec stays clean for other contributors:

```bash
./tool/disable_standalone_env.sh
```

## Code style

- Follow the existing feature folder structure
- Use `const` constructors wherever possible
- Keep widgets small — extract to `shared/` if used in more than one feature
- No `print()` statements in PRs — use proper logging if needed

## Need help?

Drop a message in the Flutter Kanpur WhatsApp group or comment on the issue. Maintainers are active and happy to guide first-time Flutter contributors.
