#!/data/data/com.termux/files/usr/bin/bash
# Mini-Toqi is an optional, local-only drafting helper for Bri Command Hub.
# Model output is text for Bri to review. It never becomes a shell command.
set -Eeuo pipefail

HUB_ROOT="${TOQI_HUB_ROOT:-$HOME/ToqiHub}"
AI_ROOT="$HUB_ROOT/mini-toqi"
MODEL_DIR="$AI_ROOT/models"
MODEL_NAME="SmolLM2-360M-Instruct-Q4_0_4_4.gguf"
MODEL_PATH="$MODEL_DIR/$MODEL_NAME"
MODEL_URL="https://huggingface.co/bartowski/SmolLM2-360M-Instruct-GGUF/resolve/main/$MODEL_NAME?download=true"
AUDIT_DIR="$HUB_ROOT/audit"
AUDIT_LOG="$AUDIT_DIR/actions.tsv"
MAX_INPUT=700

say() { printf '%s\n' "$*"; }
fail() { say "Refused: $*" >&2; exit 1; }
need_hub() { [[ -f "$AUDIT_LOG" ]] || fail "Run bri-hub init first."; }
log() { printf '%s\t%s\t%s\n' "$(date -Is)" "$1" "$2" >> "$AUDIT_LOG"; }
runner() {
  local candidate
  for candidate in llama-cli llama-run; do
    command -v "$candidate" >/dev/null 2>&1 && { printf '%s' "$candidate"; return 0; }
  done
  return 1
}
check_free_space() {
  local available_kb
  available_kb="$(df -Pk "$HOME" | awk 'NR==2 {print $4}')"
  [[ "$available_kb" =~ ^[0-9]+$ ]] || fail "Could not check free storage."
  (( available_kb >= 850000 )) || fail "Need about 850 MB free before installing the local model."
}
help_menu() { cat <<'HELP'
MINI-TOQI
Optional offline drafting helper for Bri Command Hub.

USE THESE
  mini-toqi install       Install local runner and download the 230 MB model
  mini-toqi check         Check the local setup
  mini-toqi ask "TEXT"    Get a private local drafting response
  mini-toqi remove-model  Remove only the downloaded model, after confirmation

BOUNDARIES
  • It works locally after model download, with no account or server.
  • It does not read chats, email, or phone data.
  • It never runs a command, sends a message, posts a Status, or uses root.
  • Treat its answer as a draft. Review it before doing anything.
  • Do not paste passwords, codes, banking details, private chats or legal records.
HELP
}
install_model() {
  need_hub
  command -v pkg >/dev/null 2>&1 || fail "Run this inside Termux."
  check_free_space
  mkdir -p "$MODEL_DIR"
  if [[ -s "$MODEL_PATH" ]]; then
    say "Model already exists: $MODEL_PATH"
    log mini-toqi-install existing-model
    return 0
  fi
  say "Installing the local model runner. This does not use root."
  pkg install -y llama-cpp curl
  command -v curl >/dev/null 2>&1 || fail "curl installation did not finish."
  say "Downloading the small offline model, about 230 MB. Keep Termux open until it finishes."
  local partial="$MODEL_PATH.part"
  curl --fail --location --proto '=https' --tlsv1.2 --continue-at - --output "$partial" "$MODEL_URL"
  local bytes
  bytes="$(wc -c < "$partial")"
  (( bytes >= 180000000 )) || { rm -f -- "$partial"; fail "Model download was too small, so it was discarded."; }
  mv -- "$partial" "$MODEL_PATH"
  chmod 600 "$MODEL_PATH"
  say "Mini-Toqi is ready. Try: mini-toqi ask \"Draft a short encouragement for my customers\""
  log mini-toqi-install "$(basename "$MODEL_PATH")"
}
check_setup() {
  need_hub
  local binary=""
  binary="$(runner || true)"
  say "Workspace: $AI_ROOT"
  [[ -n "$binary" ]] && say "Runner: $binary" || say "Runner: not installed"
  if [[ -s "$MODEL_PATH" ]]; then
    say "Model: ready ($(du -h "$MODEL_PATH" | awk '{print $1}'))"
  else
    say "Model: not downloaded"
  fi
  say "Mode: local-only, draft-only"
  log mini-toqi-check setup-status
}
ask() {
  need_hub
  local request="${1:-}"
  [[ -n "$request" ]] || fail "Give Mini-Toqi a short request in quotes."
  (( ${#request} <= MAX_INPUT )) || fail "Keep one request under $MAX_INPUT characters."
  [[ -s "$MODEL_PATH" ]] || fail "No local model yet. Run: mini-toqi install"
  local binary
  binary="$(runner || true)"
  [[ -n "$binary" ]] || fail "Local runner missing. Run: mini-toqi install"
  local prompt
  prompt="<|im_start|>system
You are Mini-Toqi, a small offline drafting helper inside Bri Command Hub. Give concise, practical plain-text help. You are not allowed to claim access to apps, chats, email, contacts, files, accounts, the internet, location, or the phone. Never request or repeat passwords, codes, banking details, recovery phrases or private messages. Never provide shell commands, root actions, security bypasses, or instructions to send, post, buy, pay, book, change settings, or contact anyone. You can draft text and suggest that Bri uses Bri Command Hub's visible fixed actions, but you cannot execute them. State uncertainty honestly.\n<|im_end|>\n<|im_start|>user\n$request\n<|im_end|>\n<|im_start|>assistant\n"
  say "Mini-Toqi, local draft only:"
  "$binary" -m "$MODEL_PATH" -c 1024 -n 220 --temp 0.4 --no-warmup -p "$prompt"
  printf '\n'
  log mini-toqi-ask local-draft
}
remove_model() {
  need_hub
  [[ "${2:-}" == "CONFIRM" ]] || fail "This deletes only the downloaded model. Re-run: mini-toqi remove-model CONFIRM"
  [[ -f "$MODEL_PATH" && ! -L "$MODEL_PATH" ]] || fail "No regular model file found to remove."
  rm -- "$MODEL_PATH"
  say "Removed the downloaded local model. The Hub and your drafts are untouched."
  log mini-toqi-remove-model "$(basename "$MODEL_PATH")"
}

case "${1:-help}" in
  help|-h|--help) help_menu ;;
  install) install_model ;;
  check) check_setup ;;
  ask) ask "${2:-}" ;;
  remove-model) remove_model "$@" ;;
  *) say "Unknown action: ${1:-}"; say; help_menu; exit 1 ;;
esac
