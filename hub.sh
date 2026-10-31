#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'
ROOT="${TOQI_HUB_ROOT:-$HOME/ToqiHub}"
DRAFTS="$ROOT/drafts"
GENERATED="$ROOT/generated"
QUARANTINE="$ROOT/quarantine"
AUDIT="$ROOT/audit"
LOG="$AUDIT/actions.tsv"
say() { printf '%s\n' "$*"; }
fail() { say "Refused: $*" >&2; exit 1; }
valid_name() { [[ "${1:-}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] && [[ "$1" != .* ]] && [[ "$1" != *..* ]]; }
log() { printf '%s\t%s\t%s\n' "$(date -Is)" "$1" "$2" >> "$LOG"; }
need() { [[ -f "$LOG" ]] || fail "Run init first."; }
init() { mkdir -p "$DRAFTS" "$GENERATED" "$QUARANTINE" "$AUDIT"; [[ -f "$LOG" ]] || { printf 'timestamp\taction\tdetail\n' > "$LOG"; chmod 600 "$LOG"; }; say "Ready: $ROOT"; log init workspace-ready; }
status() { need; say "Workspace: $ROOT"; say "Drafts: $(find "$DRAFTS" -maxdepth 1 -type f | wc -l)"; say "Generated: $(find "$GENERATED" -maxdepth 1 -type f | wc -l)"; say "Quarantined: $(find "$QUARANTINE" -maxdepth 1 -type f | wc -l)"; log status local-counts; }
new_draft() { need; valid_name "${1:-}" || fail "Use a simple draft name, not a path."; local f="$DRAFTS/$1.txt"; [[ ! -e "$f" ]] || fail "Draft already exists."; umask 077; printf 'Title: %s\nStatus: draft\n\nPurpose:\n\nAudience:\n\nKey points:\n\nCall to action:\n' "$1" > "$f"; say "Created: $f"; log new-draft "$1.txt"; }
whatsapp_draft() { need; valid_name "${1:-}" || fail "Use a simple post name, not a path."; local f="$DRAFTS/whatsapp-$1.txt"; [[ ! -e "$f" ]] || fail "Post draft already exists."; umask 077; printf 'WHATSAPP DRAFT, NOT SENT\n\nCaption:\n\nMedia to attach from ToqiHub/generated:\n\nChoose recipient and tap Send yourself.\n' > "$f"; say "Prepared: $f"; log prepare-whatsapp "whatsapp-$1.txt"; }
list_generated() { need; find "$GENERATED" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort; log list-generated listed; }
move_file() { need; valid_name "${3:-}" || fail "Filename must be a plain name, not a path."; local src="$1/$3" dst="$2/$3"; [[ -f "$src" && ! -L "$src" ]] || fail "Only regular workspace files allowed."; [[ ! -e "$dst" ]] || fail "Destination already has that filename."; mv -- "$src" "$dst"; say "$4 complete: $3"; log "$4" "$3"; }
root_status() { need; command -v su >/dev/null || fail "No root provider found."; say "Requesting read-only root status."; local out; if ! out=$(su -c 'id; getenforce 2>/dev/null || true; uname -r' 2>&1); then say "Root check denied or failed."; log root-status denied; return 1; fi; say "$out"; log root-status read-only; }
case "${1:-help}" in
init) init ;; status) status ;; new-draft) new_draft "${2:-}" ;; prepare-whatsapp) whatsapp_draft "${2:-}" ;; list-generated) list_generated ;; quarantine) move_file "$GENERATED" "$QUARANTINE" "${2:-}" quarantine ;; restore) move_file "$QUARANTINE" "$GENERATED" "${2:-}" restore ;; root-status) root_status ;; *) say "Actions: init, status, new-draft, prepare-whatsapp, list-generated, quarantine, restore, root-status" ;; esac