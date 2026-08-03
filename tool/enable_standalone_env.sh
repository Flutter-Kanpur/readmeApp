#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC="$ROOT/pubspec.yaml"
ENV_FILE="$ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env in project root." >&2
  echo "Copy .env.example and fill in your values:" >&2
  echo "  cp .env.example .env" >&2
  exit 1
fi

if grep -qE '^[[:space:]]*- \.env[[:space:]]*$' "$PUBSPEC"; then
  echo ".env asset already enabled in pubspec.yaml"
else
  sed -i '' '/assets\/lottie\/empty\.json/a\
    # Standalone only — added by tool/enable_standalone_env.sh (gitignored .env)\
    - .env
' "$PUBSPEC"
  echo "Added .env asset to pubspec.yaml"
fi

cd "$ROOT"
if command -v flutter >/dev/null 2>&1; then
  flutter pub get
else
  echo "flutter not in PATH; skipped flutter pub get"
fi
echo "Standalone env ready. Run: flutter run"
