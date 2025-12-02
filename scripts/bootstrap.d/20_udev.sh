#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/../_common.sh"

UINPUT_MODULE_FILE="/etc/modules-load.d/uinput.conf"
UINPUT_MODULE_LINE="uinput"

RULE_FILE="/etc/udev/rules.d/input.rules"
RULE_LINE='KERNEL=="uinput", GROUP="input", TAG+="uaccess"'

maybe_add_line() {
  local file="$1"
  local line="$2"

  log item "${line} --> ${file}"

  if grep -qFx "$line" "$file" >/dev/null 2>&1; then
    log ok "Already exists"
    return 1
  fi

  warn_once_elevated
  echo "$line" | sudo tee -a "$file" >/dev/null 2>&1
  return 0
}

main() {
  log section "udev rules"

  maybe_add_line "$UINPUT_MODULE_FILE" "$UINPUT_MODULE_LINE" || true
  if lsmod | ug uinput >/dev/null 2>&1; then
    log ok "Module is already loaded"
  else
    warn_once_elevated
    sudo modprobe uinput
    log success "Loaded module"
  fi
  
  if maybe_add_line "$RULE_FILE" "$RULE_LINE"; then
    sudo udevadm control --reload-rules >/dev/null 2>&1
    sudo udevadm trigger >/dev/null 2>&1
  fi
}

main
