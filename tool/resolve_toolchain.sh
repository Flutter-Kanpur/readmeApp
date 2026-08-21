#!/usr/bin/env bash
# Resolve Shorebird + Flutter binaries for tool/*.sh scripts.
# Source this file:  source "$(dirname "$0")/resolve_toolchain.sh"

_resolve_toolchain_root() {
  if [[ -n "${RESOLVE_TOOLCHAIN_ROOT:-}" ]]; then
    echo "$RESOLVE_TOOLCHAIN_ROOT"
    return
  fi
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
  echo "$(cd "$script_dir/.." && pwd)"
}

resolve_shorebird() {
  if [[ -n "${SHOREBIRD_BIN:-}" && -x "${SHOREBIRD_BIN}" ]]; then
    echo "$SHOREBIRD_BIN"
    return 0
  fi
  if command -v shorebird >/dev/null 2>&1; then
    echo "shorebird"
    return 0
  fi
  if [[ -x "$HOME/.shorebird/bin/shorebird" ]]; then
    echo "$HOME/.shorebird/bin/shorebird"
    return 0
  fi
  return 1
}

resolve_flutter() {
  local root
  root="$(_resolve_toolchain_root)"

  if [[ -n "${FLUTTER_BIN:-}" && -x "${FLUTTER_BIN}" ]]; then
    echo "$FLUTTER_BIN"
    return 0
  fi
  if command -v flutter >/dev/null 2>&1; then
    echo "flutter"
    return 0
  fi
  if [[ -x "$root/.fvm/flutter_sdk/bin/flutter" ]]; then
    echo "$root/.fvm/flutter_sdk/bin/flutter"
    return 0
  fi
  if command -v fvm >/dev/null 2>&1 && [[ -f "$root/.fvm/fvm_config.json" ]]; then
    echo "fvm flutter"
    return 0
  fi
  local version
  version="$(sed -n 's/.*"flutterSdkVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$root/.fvm/fvm_config.json" 2>/dev/null | head -1)"
  if [[ -n "$version" && -x "$HOME/fvm/versions/$version/bin/flutter" ]]; then
    echo "$HOME/fvm/versions/$version/bin/flutter"
    return 0
  fi
  return 1
}

require_shorebird() {
  local bin
  if ! bin="$(resolve_shorebird)"; then
    echo "Shorebird CLI not found. Install: https://docs.shorebird.dev/getting-started/" >&2
    exit 1
  fi
  SHOREBIRD_BIN="$bin"
  export SHOREBIRD_BIN
}

run_flutter_pub_get() {
  local root flutter_bin
  root="$(_resolve_toolchain_root)"
  if ! flutter_bin="$(resolve_flutter)"; then
    echo "flutter not found (install Flutter, add to PATH, or use FVM)." >&2
    echo "  fvm install && fvm flutter pub get" >&2
    echo "Shorebird release may still work — it bundles its own Flutter SDK." >&2
    return 1
  fi
  echo "Using Flutter: $flutter_bin"
  (cd "$root" && $flutter_bin pub get)
}
