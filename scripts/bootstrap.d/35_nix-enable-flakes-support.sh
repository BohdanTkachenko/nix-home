#!/usr/bin/env bash
set -euo pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../_common.sh"

NIX_CONF_FILE=$HOME/.config/nix/nix.conf
BOOTSTRAP_NIX_CONF_FILE=$HOME_MANAGER_DIR/scripts/bootstrap.d/resources/nix.conf


main() {
  log section "Enabling Nix flakes support"

  local status=0
  maybe_copy_file \
    "$BOOTSTRAP_NIX_CONF_FILE" \
    "$NIX_CONF_FILE" \
    "" || status=$?
  
  if [ $status -gt 0 && $status -lte 10 ]; then
    return $status
  fi
  
  return 0
}

main
