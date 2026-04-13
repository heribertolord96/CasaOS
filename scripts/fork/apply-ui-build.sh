#!/usr/bin/env bash
# Apply a pre-built CasaOS-UI (static www) to a standard CasaOS install.
# Typical: pnpm build in CasaOS-UI, then run this on the target host (with sudo).
set -euo pipefail

CASA_OS_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEFAULT_SRC="${CASA_UI_BUILD:-$CASA_OS_ROOT/../CasaOS-UI/build/sysroot/var/lib/casaos/www}"
SRC="${1:-$DEFAULT_SRC}"
DST="/var/lib/casaos/www"

if [[ ! -f "$SRC/index.html" ]]; then
  echo "ERROR: No index.html in: $SRC" >&2
  echo "Set CASA_UI_BUILD or pass path to built www (e.g. CasaOS-UI/build/sysroot/var/lib/casaos/www)." >&2
  exit 1
fi

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

BK="www.bak.$(date +%Y%m%d%H%M%S)"
if [[ -d "$DST" ]] && [[ -f "$DST/index.html" ]]; then
  cp -a "$DST" "${DST%/}.$BK"
  echo "Backup: ${DST}.$BK"
fi

rsync -a --delete "$SRC/" "$DST/"
echo "OK: UI applied from $SRC -> $DST"
echo "Restart gateway if needed: sudo systemctl restart casaos-gateway"
