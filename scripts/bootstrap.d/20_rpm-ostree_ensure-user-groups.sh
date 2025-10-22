#!/usr/bin/env bash
set -euo pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../_common.sh"

ostree_make_group_available_sudo() {
  local group="$1"; shift

  warn_once_elevated

  if grep -q "^${group}:" /etc/group; then
    log ok "/etc/group already contains group '$group'"
    return 0
  fi

  log mismatch "/etc/group does not contain group '$group'. Adding..."

  if ! grep -q "^${group}:" /usr/lib/group; then
    log error "/usr/lib/group does not contain group '$group'"
    exit 1
  fi

  if ! (grep -E "^${group}:" /usr/lib/group | sudo tee -a /etc/group > /dev/null); then
    log error "Failed to append group '$group' to /etc/group. Please check permissions."
    exit 1
  fi

  log success "Added group '$group' to /etc/group"

  return 1
}

add_user_to_group_sudo() {
  local user="$1"; shift
  local group="$1"; shift

  warn_once_elevated

  ostree_make_group_available_sudo "$group"

  if ! sudo usermod -aG "$group" "$user"; then
    log error "Failed to add user '$user' to group '$group'. Please check permissions."
    exit 1
  fi
}

ensure_user_in_group() {
  local group="$1"; shift
  log item "Checking group membership for '${group}'"

  if groups "$USER" | grep -q "\b${group}\b"; then
    log ok "User '$USER' is already a member of group '${group}'."
    return 0
  fi

  log mismatch "User '$USER' is not in group '${group}'. Adding..."
  add_user_to_group_sudo "$USER" "$group"
  log success "Successfully added '$USER' to '${group}'."
  return 1
}

main() {
  log section "Configuring User Groups..."
  
  local change_made=false

  ensure_user_in_group "input" || change_made=true

  if [ "$change_made" = true ]; then
    log warning "A log out and log back in is required for group changes to take full effect."
  fi
}

main
