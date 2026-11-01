#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
ROOT="${TOQI_HUB_ROOT:-$HOME/ToqiHub}"
DRAFTS="$ROOT/drafts"
GENERATED="$ROOT/generated"
QUARANTINE="$ROOT/quarantine"
AUDIT="$ROOT/audit"
LOG="$AUDIT/actions.tsv"
say() { printf "%s\n" "$*"; }
fail() { say "Refused: $*" >&2; exit 1; }
valid_name() { [[ "${1:-}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] && [[ "$1" != .* ]] && [[ "$1" != *..* ]]; }
log() { printf "%s\t%s\t%s\n" "$(date -Is)" "$1" "$2" >> "$LOG"; }
need() { [[ -f "$LOG" ]] || fail "Run init first."; }
init() { mkdir -p "$DRAFTS" "$GENERATED" "$QUARANTINE" "$AUDIT"; [[ -f "$LOG" ]] || { printf "timestamp\taction\tdetail\n" > "$LOG"; chmod 600 "$LOG"; }; say "Ready: $ROOT"; log init workspace-ready; }
status() { need; say "Workspace: $ROOT"; say "Drafts: $(find "$DRAFTS" -maxdepth 1 -type f | wc -l)"; say "Generated: $(find "$GENERATED" -maxdepth 1 -type f | wc -l)"; say "Quarantined: $(find "$QUARANTINE" -maxdepth 1 -type f | wc -l)"; log status local-counts; }
help_menu() { cat <<HELP
Bri Command Hub
Your local workbench. Toqi stays in WhatsApp.

START HERE
  bri-hub status
  bri-hub new-draft guide-name
  bri-hub prepare-whatsapp post-name

CREATE
  bri-hub create-first-build-card
  bri-hub list-generated

KEEP FILES TIDY
  bri-hub quarantine filename
  bri-hub restore filename

CAREFUL LANE
  bri-hub root-status
  Read-only diagnostic. Android asks first.

Nothing here sends messages or posts Status updates.
You review and tap Send in WhatsApp yourself.
HELP
}
new_draft() { need; valid_name "${1:-}" || fail "Use a simple draft name, not a path."; local f="$DRAFTS/$1.txt"; [[ ! -e "$f" ]] || fail "Draft already exists."; umask 077; printf "Title: %s\nStatus: draft\n\nPurpose:\n\nAudience:\n\nKey points:\n\nCall to action:\n" "$1" > "$f"; say "Created: $f"; log new-draft "$1.txt"; }
whatsapp_draft() { need; valid_name "${1:-}" || fail "Use a simple post name, not a path."; local f="$DRAFTS/whatsapp-$1.txt"; [[ ! -e "$f" ]] || fail "Post draft already exists."; umask 077; printf "WHATSAPP DRAFT, NOT SENT\n\nCaption:\n\nMedia to attach from ToqiHub/generated:\n\nChoose recipient and tap Send yourself.\n" > "$f"; say "Prepared: $f"; log prepare-whatsapp "whatsapp-$1.txt"; }
first_build_card() { need; local f="$GENERATED/first-build-card.svg"; [[ ! -e "$f" ]] || fail "Card already exists. It was not replaced."; umask 077; cat > "$f" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920"><rect width="1080" height="1920" fill="#08110f"/><g stroke="#12563d" stroke-width="1" opacity=".55"><path d="M0 160H1080M0 400H1080M0 640H1080M0 880H1080M0 1120H1080M0 1360H1080M0 1600H1080M0 1840H1080"/><path d="M90 0V1920M270 0V1920M450 0V1920M630 0V1920M810 0V1920M990 0V1920"/></g><rect x="325" y="440" width="430" height="275" rx="32" fill="none" stroke="#65f77c" stroke-width="14"/><path d="M325 505h135l55-65h155" fill="none" stroke="#65f77c" stroke-width="14"/><text x="540" y="970" text-anchor="middle" font-family="sans-serif" font-size="136" font-weight="bold" fill="#ffffff">FIRST BUILD</text><text x="540" y="1080" text-anchor="middle" font-family="sans-serif" font-size="54" letter-spacing="9" fill="#ffffff">Bri Command Hub</text><circle cx="540" cy="1270" r="58" fill="none" stroke="#65f77c" stroke-width="10"/><path d="M510 1270l22 22 42-48" fill="none" stroke="#65f77c" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/><text x="540" y="1530" text-anchor="middle" font-family="monospace" font-size="31" fill="#ffffff">Local. Practical. Under my control.</text></svg>
SVG
chmod 600 "$f"; say "Created card: $f"; say "Preview it first. WhatsApp publishing still needs your final tap."; log create-status-card first-build-card.svg; }
list_generated() { need; find "$GENERATED" -maxdepth 1 -type f -printf "%f\n" | LC_ALL=C sort; log list-generated listed; }
move_file() { need; valid_name "${3:-}" || fail "Filename must be a plain name, not a path."; local src="$1/$3" dst="$2/$3"; [[ -f "$src" && ! -L "$src" ]] || fail "Only regular workspace files allowed."; [[ ! -e "$dst" ]] || fail "Destination already has that filename."; mv -- "$src" "$dst"; say "$4 complete: $3"; log "$4" "$3"; }
root_status() { need; command -v su >/dev/null || fail "No root provider found."; say "Requesting read-only root status."; local out; if ! out=$(su -c "id; getenforce 2>/dev/null || true; uname -r" 2>&1); then say "Root check denied or failed."; log root-status denied; return 1; fi; say "$out"; log root-status read-only; }
case "${1:-help}" in
help|-h|--help) help_menu ;; init) init ;; status) status ;; new-draft) new_draft "${2:-}" ;; prepare-whatsapp) whatsapp_draft "${2:-}" ;; create-first-build-card) first_build_card ;; list-generated) list_generated ;; quarantine) move_file "$GENERATED" "$QUARANTINE" "${2:-}" quarantine ;; restore) move_file "$QUARANTINE" "$GENERATED" "${2:-}" restore ;; root-status) root_status ;; *) say "Unknown action: ${1:-}"; say; help_menu ;; esac
