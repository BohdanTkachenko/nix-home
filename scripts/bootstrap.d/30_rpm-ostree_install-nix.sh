#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/../_common.sh"

OSTREE_PREPARE_ROOT_CONFIG_FILE=/etc/ostree/prepare-root.conf
BOOTSTRAP_OSTREE_PREPARE_ROOT_CONFIG_FILE=$HOME_MANAGER_DIR/scripts/bootstrap.d/resources/prepare-root.conf

update_initramfs_etc_sudo() {
  warn_once_elevated
  sudo rpm-ostree initramfs-etc --force-sync --track=$OSTREE_PREPARE_ROOT_CONFIG_FILE
  ask_before_reboot
}

configure_ostree() {
  log section "Configuring ostree..."

  local file_changed=0
  maybe_copy_file \
    "$BOOTSTRAP_OSTREE_PREPARE_ROOT_CONFIG_FILE" \
    "$OSTREE_PREPARE_ROOT_CONFIG_FILE" \
    "sudo" ||
    file_changed=$?

  log item "InitramfsEtc"
  if [ $file_changed -gt 10 ]; then
    log mismatch "$OSTREE_PREPARE_ROOT_CONFIG_FILE has changed, running rpm-ostree initramfs-etc..."
    update_initramfs_etc_sudo
    return 10
  else
    log ok "$OSTREE_PREPARE_ROOT_CONFIG_FILE is correct."
  fi

  local ostree_status=$(rpm-ostree status --json | jq -r --arg file "$OSTREE_PREPARE_ROOT_CONFIG_FILE" '
    def has_config(d):
      ((d | ."initramfs-etc"?) // []) | any(. == $file);

    if has_config((.deployments[] | select(.booted == true))) then
      "BOOTED"
    elif has_config((.deployments[] | select(.staged == true))) then
      "STAGED"
    else
      "NONE"
    end
  ')
  case "$ostree_status" in
  STAGED)
    log mismatch "Staged ostree deployment is already configured correctly."
    ask_before_reboot
    return 11
    ;;
  NONE)
    log mismatch "Neither currently booted nor staged ostree deployment is configured correctly. Running rpm-ostree initramfs-etc..."
    update_initramfs_etc_sudo
    return 12
    ;;
  esac

  log ok "Currently booted ostree deployment is already configured correctly."
  return 0
}

install_nix() {
  log section "Installing Nix..."

  log item "Nix"

  if [ -f "/nix/receipt.json" ]; then
    log ok "Nix is already installed."
  else
    log mismatch "Not installed. Installing using Determinate Systems installer..."
    {
      curl -fsSL https://install.determinate.systems/nix 2> >(tee -a "$LOG_FILE") |
        sh -s -- install --no-confirm
    } 2>&1 | tee -a "$LOG_FILE"
    exit_codes=("${PIPESTATUS[@]}")

    if ! ([ "${exit_codes[0]}" -eq 0 ] && [ "${exit_codes[1]}" -eq 0 ]); then
      log error "Nix installation failed. Check '$LOG_FILE' for details."
      return 1
    fi

    log success "Nix installation completed successfully."
  fi
}

install() {
  configure_ostree
  install_nix
}

install
