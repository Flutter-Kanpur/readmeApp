#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT/tool/enable_standalone_env.sh"
cd "$ROOT"
flutter run "$@"
