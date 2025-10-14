#!/usr/bin/env bash
set -eu

source $HOME_MANAGER_DIR/scripts/_common.sh

CONFIG_FILE="$HOME_MANAGER_DIR/bootstrap.nix"

function write_config() {
  log section "Config"

  log item "$CONFIG_FILE"

  cat > "$CONFIG_FILE" << EOF
{
  # Edit in scripts/_bootstrap_05_config.sh
  username = "$USER";
  homeDirectory = "$HOME";
  sourceDir = "$HOME/.local/share/chezmoi/dot_config/home-manager";
  hosttypes = ["desktop" "lenovo-z16"];
}
EOF

  log ok "Updated"
}

write_config