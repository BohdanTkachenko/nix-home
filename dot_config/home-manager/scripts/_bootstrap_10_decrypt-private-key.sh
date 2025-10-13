#!/bin/sh
set -eu -o pipefail

source $CHEZMOI_SOURCE_DIR/dot_config/home-manager/scripts/_common.sh

decrypt_key() {
  log section "Decrypting age key..."

  log item "$IDENTITY_DECRYPTED"
  if [ ! -f "$IDENTITY_DECRYPTED" ]; then
    log mismatch "Decrypting..."
    mkdir -p $(dirname "$IDENTITY_DECRYPTED")
    chezmoi age decrypt \
      --output "$IDENTITY_DECRYPTED" \
      --passphrase \
      "$IDENTITY_ENCRYPTED"
    chmod 600 "$IDENTITY_DECRYPTED"
    log success "Decrypted"
  else
    log ok "Already decrypted."
  fi
}

decrypt_key
