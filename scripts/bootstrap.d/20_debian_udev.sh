#!/usr/bin/env bash
set -euo pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../_common.sh"

RULE_FILE="/etc/udev/rules.d/input.rules"
RULE_LINE='KERNEL=="uinput", GROUP="input", TAG+="uaccess"'

main() {
  log section "udev Rules"

  log item "$RULE_LINE"

  if grep -qFx "$RULE_LINE" "$RULE_FILE" 2>/dev/null; then
    log ok "Already exists"
    return 0
  fi

  warn_once_elevated
  
  echo "$RULE_LINE" | sudo tee -a "$RULE_FILE" > /dev/null
  sudo modprobe uinput
  sudo udevadm control --reload-rules && sudo udevadm trigger
}

main
