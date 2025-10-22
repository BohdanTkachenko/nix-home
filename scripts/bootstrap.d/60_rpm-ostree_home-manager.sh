#!/usr/bin/env bash
set -euo pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../_common.sh"

source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

home_manager() {
  log section "(Re)building home configuration using Home-Manager"

  log item "Home-Manager"

  local home_manager_command
  if command -v home-manager &> /dev/null; then
    home_manager_command=(home-manager)
    log mismatch "Rebuilding home configuration..."
  else
    home_manager_command=(nix run home-manager --)
    log mismatch "Installing Home-Manager and building home configuration..."
  fi

  home_manager_command+=(switch -v -b backup --show-trace --flake "$HOME_MANAGER_DIR#$HOME_MANAGER_HOST")

  if "${home_manager_command[@]}" 2>&1 | tee -a "$LOG_FILE" > "$LAST_COMMAND_LOG_FILE"; then
    log success "Installed Home Manager and built home configuration."
  else
    log error "Failed to install Home Manager and build home configuration."
    cat "$LAST_COMMAND_LOG_FILE"
    return 1
  fi

  return 0
}

home_manager
