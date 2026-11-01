#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
BASE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
TARGET_DIR="$HOME/.local/bin"
mkdir -p "$TARGET_DIR"
install -m 700 "$BASE/hub.sh" "$TARGET_DIR/bri-hub"
install -m 700 "$BASE/mini-toqi.sh" "$TARGET_DIR/mini-toqi"
printf 'Installed: %s\n' "$TARGET_DIR/bri-hub"
printf 'Installed: %s\n' "$TARGET_DIR/mini-toqi"
printf 'Run: %s init\n' "$TARGET_DIR/bri-hub"
printf 'Then: %s install\n' "$TARGET_DIR/mini-toqi"
