#!/usr/bin/env bash
# One-time Shorebird setup for ReadMe standalone app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
RESOLVE_TOOLCHAIN_ROOT="$ROOT"
# shellcheck source=resolve_toolchain.sh
source "$ROOT/tool/resolve_toolchain.sh"

require_shorebird

echo "Using: $($SHOREBIRD_BIN --version | head -1)"
echo ""
echo "Step 1: Log in to Shorebird (opens browser)..."
"$SHOREBIRD_BIN" login

echo ""
echo "Step 2: Initialize ReadMe in Shorebird console..."
"$SHOREBIRD_BIN" init --force --display-name "ReadMe"

echo ""
echo "Step 3: Fetch Dart dependencies..."
run_flutter_pub_get || true

echo ""
echo "Done. Next steps (release BEFORE patch):"
echo "  ./tool/shorebird_release.sh android   # first — creates store binary"
echo "  ./tool/shorebird_patch.sh android     # later — OTA Dart-only update"
