#!/usr/bin/env bash
# Build a Shorebird release (Play Store / App Store base binary).
# Usage: ./tool/shorebird_release.sh [android|ios|both]
#
# You MUST create a release before `shorebird patch` will work.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
RESOLVE_TOOLCHAIN_ROOT="$ROOT"
# shellcheck source=resolve_toolchain.sh
source "$ROOT/tool/resolve_toolchain.sh"

PLATFORM="${1:-android}"

require_shorebird

if [[ ! -f shorebird.yaml ]]; then
  echo "Missing shorebird.yaml. Run ./tool/shorebird_setup.sh first." >&2
  exit 1
fi

if [[ -f tool/enable_standalone_env.sh ]]; then
  ./tool/enable_standalone_env.sh
fi

run_flutter_pub_get || true

release_one() {
  local target="$1"
  echo "==> Shorebird release: $target"
  "$SHOREBIRD_BIN" release "$target"
}

case "$PLATFORM" in
  android) release_one android ;;
  ios) release_one ios ;;
  both)
    release_one android
    release_one ios
    ;;
  *)
    echo "Usage: $0 [android|ios|both]" >&2
    exit 1
    ;;
esac

echo ""
echo "Release complete. Upload the generated artifact to the store."
echo "After users install this build, push patches with:"
echo "  ./tool/shorebird_patch.sh $PLATFORM"
