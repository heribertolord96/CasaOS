#!/usr/bin/env bash
# 1) Install upstream CasaOS (official script) if you want a clean base.
# 2) Apply this fork's UI from a built www directory.
# Usage on target: sudo bash install-official-then-apply-ui.sh [path-to-www]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

if ! command -v casaos >/dev/null 2>&1; then
  echo "==> Installing official CasaOS (get.casaos.io) ..."
  curl -fsSL https://get.casaos.io | bash
else
  echo "==> casaos already installed, skipping official install."
fi

exec bash "$SCRIPT_DIR/apply-ui-build.sh" "${1:-}"
