#!/usr/bin/env bash
set -eu

source $CHEZMOI_SOURCE_DIR/common.sh
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

home_manager() {
  log section "(Re)building home configuration using Home-Manager"

  log item "OS Check"
  log info "Detected OS: $(get_os)"
  if is_os_supports_nix; then
    log ok "OS supports Nix."
  else
    log skip "OS does not support Nix. Skipping Nix installation."
    return 0
  fi

  log item "Home-Manager"

  local home_manager_command
  if command -v home-manager &> /dev/null; then
    home_manager_command=(home-manager switch -b backup)
    log ok "Home-Manager is already installed."
    log mismatch "Rebuilding home configuration..."
  else
    home_manager_command=(nix run home-manager -- switch -b backup)
    log mismatch "Installing Home-Manager and building home configuration..."
  fi

  "${home_manager_command[@]}" 2>&1 | tee -a "$LOG_FILE" > "$LAST_COMMAND_LOG_FILE"
  status=${PIPESTATUS[0]}
  if [ $status -eq 0 ]; then
    log success "Installed Home Manager and built home configuration."
  else
    log error "Failed to install Home Manager and build home configuration."
    cat "$LAST_COMMAND_LOG_FILE"
    return 1
  fi

  return 0
}

home_manager