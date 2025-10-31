#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/../_common.sh"

UINPUT_MODULE="uinput"
MODULES_FILE="/etc/modules"

RULE_FILE="/etc/udev/rules.d/input.rules"
RULE_LINE='KERNEL=="uinput", GROUP="input", TAG+="uaccess"'

install_kernel_module() {
  local module="$1"

  log item "Kernel module $module"

  if grep -qFx "$module" "$MODULES_FILE" >/dev/null 2>&1; then
    log ok "Module already registered in $MODULES_FILE"
  else
    warn_once_elevated
    echo "$module" | sudo tee -a "$MODULES_FILE" >/dev/null 2>&1
    log success "Registered module in $MODULES_FILE"
  fi

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
  log section "udev Rules"

  install_kernel_module "$UINPUT_MODULE"
  install_udev_rule "$RULE_LINE"
}

main
