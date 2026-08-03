#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC="$ROOT/pubspec.yaml"

if ! grep -qE '^[[:space:]]*- \.env[[:space:]]*$' "$PUBSPEC"; then
  echo ".env asset not present in pubspec.yaml (already disabled)"
else
  sed -i '' \
    -e '/Standalone only.*enable_standalone_env\.sh/d' \
    -e '/^[[:space:]]*- \.env[[:space:]]*$/d' \
    "$PUBSPEC"
  echo "Removed .env asset from pubspec.yaml"
fi

cd "$ROOT"
if command -v flutter >/dev/null 2>&1; then
  flutter pub get
else
  echo "flutter not in PATH; skipped flutter pub get"
fi
echo "Package-safe pubspec restored (safe for Flutter Kanpur Git dependency)"
