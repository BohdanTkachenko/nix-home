#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/../_common.sh"

UINPUT_MODULE_FILE_SRC="$HOME_MANAGER_DIR/scripts/bootstrap.d/resources/uinput.conf"
UINPUT_MODULE_FILE_DST="/etc/modules-load.d/uinput.conf"

RULE_FILE="/etc/udev/rules.d/input.rules"
RULE_LINE='KERNEL=="uinput", GROUP="input", TAG+="uaccess"'

install_uinput_kernel_module() {
  log section "Kernel module uinput"

  local file_changed
  maybe_copy_file \
    "$UINPUT_MODULE_FILE_SRC" \
    "$UINPUT_MODULE_FILE_DST" \
    "sudo" ||
    file_changed=$?

  log item "modprobe uinput"

  if lsmod | ug uinput >/dev/null 2>&1; then
    log ok "Module is already loaded"
  else
    warn_once_elevated
    sudo modprobe uinput
    log success "Loaded module"
  fi

  return 0
}

install_udev_rule() {
  log item "udev rule: $RULE_LINE"

  if grep -qFx "$RULE_LINE" "$RULE_FILE" >/dev/null 2>&1; then
    log ok "Already exists"
    return 0
  fi

  warn_once_elevated
  echo "$RULE_LINE" | sudo tee -a "$RULE_FILE" >/dev/null 2>&1
  sudo udevadm control --reload-rules >/dev/null 2>&1 &&
    sudo udevadm trigger >/dev/null 2>&1
}

main() {
  install_uinput_kernel_module
  install_udev_rule "$RULE_LINE"
}

main
