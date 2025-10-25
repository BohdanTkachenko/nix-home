#!/usr/bin/env bash
set -euo pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../_common.sh"

add_user_to_group() {
  local group="$1"; shift
  
  log item "Add user $USER to group $group"

  if groups "$USER" | grep -q "\b$group\b"; then
    log ok "User is already in group."
    return 0
  fi

  warn_once_elevated
  
  if ! sudo usermod -a -G "$group" $USER; then
    log error "Failed to add user to group."
    return 1
  fi

  log success "User added to group."
  log warning "A re-login or reboot is required for this to take effect."
  
  return 2
}

add_user_to_groups() {
  local needs_reboot=""
  for group in "$@"; do
    local group_status=0
    add_user_to_group "$group" || group_status=$?

    if [[ "$group_status" -eq 1 ]]; then
      return 1
    fi

    if [[ "$group_status" -eq 2 ]]; then
      needs_reboot="1"
    fi
  done

  if [[ -n "$needs_reboot" ]]; then
    return 2
  fi

  return 0
}

install_nix() {
  log item "Nix"

  if [ -f "/usr/bin/nix" ]; then
    log ok "Nix is already installed."
    return 0
  fi
  
  log mismatch "Not installed. Installing Debian nix package..."
  {
     DEBIAN_FRONTEND=noninteractive sudo apt install -y nix
  } 2>&1 | tee -a "$LOG_FILE"
  exit_codes=("${PIPESTATUS[@]}")

  if ! ([ "${exit_codes[0]}" -eq 0 ] && [ "${exit_codes[1]}" -eq 0 ]); then
    log error "Nix installation failed. Check '$LOG_FILE' for details."
    return 1
  fi

  log success "Nix installation completed successfully."
  log warning "A reboot is required for this to take effect."

  return 2
}

install() {
  log section "Installing Nix..."

  local needs_reboot=""

  local nix_status=0
  install_nix || nix_status=$?

  if [[ "$nix_status" -eq 1 ]]; then
    return 1
  fi

  if [[ "$nix_status" -eq 2 ]]; then
    needs_reboot="1"
  fi

  local group_status=0
  add_user_to_groups "nix-users" "input" || group_status=$?

  if [[ "$group_status" -eq 1 ]]; then
    return 1
  fi

  if [[ "$group_status" -eq 2 ]]; then
    needs_reboot="1"
  fi
  
  if [[ -n "$needs_reboot" ]]; then
    ask_before_reboot
  fi
}

install
