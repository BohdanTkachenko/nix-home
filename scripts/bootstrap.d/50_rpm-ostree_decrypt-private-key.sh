#!/usr/bin/env bash
set -euo pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../_common.sh"

IDENTITY_ENCRYPTED="$HOME_MANAGER_DIR/key.txt.age"
IDENTITY_DECRYPTED="$HOME/.config/sops/age/keys.txt"

decrypt_key() {
  log section "Decrypting age key..."

  log item "$IDENTITY_DECRYPTED"
  if [ -f "$IDENTITY_DECRYPTED" ]; then
    log ok "Already decrypted."
    exit 0
  fi

  log mismatch "Decrypting..."

  mkdir -p $(dirname "$IDENTITY_DECRYPTED")
  chezmoi age decrypt \
    --output "$IDENTITY_DECRYPTED" \
    --passphrase \
    "$IDENTITY_ENCRYPTED"
  chmod 600 "$IDENTITY_DECRYPTED"
  
  log success "Decrypted"
}

decrypt_key
