#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
BASE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
TARGET="$HOME/.local/bin/bri-hub"
mkdir -p "$(dirname "$TARGET")"
install -m 700 "$BASE/hub.sh" "$TARGET"
printf 'Installed: %s\n' "$TARGET"
printf 'Run: %s init\n' "$TARGET"