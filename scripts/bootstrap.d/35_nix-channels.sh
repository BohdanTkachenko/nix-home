#!/usr/bin/env bash
set -euo pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../_common.sh"

add_channel() {
  local url="$1"; shift
  local name="$1"; shift

  log item "$name ($url)"

  nix-channel --add "$url" "$name" 2>&1 | tee -a "$LOG_FILE" > "$LAST_COMMAND_LOG_FILE"
  nix-channel --update 2>&1 | tee -a "$LOG_FILE" > "$LAST_COMMAND_LOG_FILE"

  log success "Done"
}

main() {
  log section "Setting up Nix channels..."


  add_channel https://nixos.org/channels/nixos-25.05 nixpkgs
}

main
