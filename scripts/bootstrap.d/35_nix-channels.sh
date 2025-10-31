#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/../_common.sh"

update_channel() {
  local name="$1"

  log mismatch "Update channel"

  if ! nix-channel --update "$name" 2>&1 | tee -a "$LOG_FILE" >"$LAST_COMMAND_LOG_FILE"; then
    log error "Failed to update channels."
    cat "$LAST_COMMAND_LOG_FILE"
    return 1
  fi

  log success "Channels update."
}

add_channel() {
  local url="$1"
  local name="$2"

  local success_msg="Added channel."

  log item "$name ($url)"

  existing=$(nix-channel --list | grep -e "^$name " || true)
  if [[ ! -z "$existing" ]]; then
    existing_url=$(echo "$existing" | cut -d ' ' -f2)
    if [[ "$existing_url" == "$url" ]]; then
      log ok "Already added."
      return 0
    fi

    log mismatch "Found an existing channel with a different url: $existing_url"
    success_msg="Replaced channel."
  fi

  if ! nix-channel --add "$url" "$name" 2>&1 | tee -a "$LOG_FILE" >"$LAST_COMMAND_LOG_FILE"; then
    log error "Failed to install."
    cat "$LAST_COMMAND_LOG_FILE"
    return 1
  fi

  log success "$success_msg"

  update_channel "$name"
}

add_and_update_channel() {
  local url="$1"
  local name="$2"

  add_channel "$url" "$name"
  update_channel "$name"
}

main() {
  log section "Setting up Nix channels..."

  add_and_update_channel https://nixos.org/channels/nixos-25.05 nixpkgs
}

main
