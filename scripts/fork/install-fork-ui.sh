#!/usr/bin/env bash
# Build CasaOS-UI from a local clone and apply static files to the running CasaOS host.
# Expects: official CasaOS already installed (see: which casaos).
# Layout: CasaOS/ and CasaOS-UI/ as sibling directories, or set CASA_UI_ROOT.
#
# Usage:
#   bash scripts/fork/install-fork-ui.sh           # build + sudo apply
#   bash scripts/fork/install-fork-ui.sh --build-only
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CASA_OS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CASA_UI="${CASA_UI_ROOT:-$CASA_OS_ROOT/../CasaOS-UI}"
BUILD_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --build-only) BUILD_ONLY=true ;;
    -h|--help)
      sed -n '1,20p' "$0"
      exit 0
      ;;
  esac
done

if [[ ! -f "$CASA_UI/package.json" ]]; then
  echo "ERROR: CasaOS-UI not found at: $CASA_UI" >&2
  echo "Clone your fork next to CasaOS (../CasaOS-UI) or set CASA_UI_ROOT=/path/to/CasaOS-UI" >&2
  exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "ERROR: pnpm not found. Install Node + pnpm (see CasaOS-UI/README)." >&2
  exit 1
fi

if ! command -v casaos >/dev/null 2>&1; then
  echo "WARNING: 'casaos' not in PATH (which casaos → empty)." >&2
  echo "Install official CasaOS first: curl -fsSL https://get.casaos.io | sudo bash" >&2
  if [[ "$BUILD_ONLY" != true ]]; then
    echo "Refusing to apply UI without a detected install. Use --build-only to only compile." >&2
    exit 1
  fi
fi

cd "$CASA_UI"
pnpm install
pnpm run build

WWW="$CASA_UI/build/sysroot/var/lib/casaos/www"
if [[ ! -f "$WWW/index.html" ]]; then
  echo "ERROR: Build did not produce: $WWW/index.html" >&2
  exit 1
fi

if [[ "$BUILD_ONLY" == true ]]; then
  echo "OK: build only. Apply manually:"
  echo "  sudo bash $SCRIPT_DIR/apply-ui-build.sh $WWW"
  exit 0
fi

exec sudo bash "$SCRIPT_DIR/apply-ui-build.sh" "$WWW"
