#!/usr/bin/env bash
# Push an over-the-air Shorebird patch for an existing release.
# Usage: ./tool/shorebird_patch.sh [android|ios|both]
#
# Requires a prior `shorebird release` for the same pubspec version.
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

VERSION="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -1 | tr -d ' ')"
echo "Patching for pubspec version: $VERSION"
echo "(Users must have installed a Shorebird release matching this version.)"
echo ""

run_flutter_pub_get || true

patch_one() {
  local target="$1"
  echo "==> Shorebird patch: $target"
  if ! "$SHOREBIRD_BIN" patch "$target"; then
    echo "" >&2
    echo "Patch failed. Common causes:" >&2
    echo "  • No release yet — run: ./tool/shorebird_release.sh $target" >&2
    echo "  • pubspec version changed since last release" >&2
    echo "  • Native/plugin changes (need a new store release, not a patch)" >&2
    exit 1
  fi
}

case "$PLATFORM" in
  android) patch_one android ;;
  ios) patch_one ios ;;
  both)
    patch_one android
    patch_one ios
    ;;
  *)
    echo "Usage: $0 [android|ios|both]" >&2
    exit 1
    ;;
esac

echo ""
echo "Patch published. Users on version $VERSION receive it on next app launch."
