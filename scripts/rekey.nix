{ pkgs, ... }:

pkgs.writeShellScriptBin "rekey" ''
  set -euo pipefail

  if [[ -f "./flake.nix" ]]; then
    FLAKE_DIR="$(pwd)"
  else
    FLAKE_DIR="/home/dan/Projects/nix-home"
  fi

  export SOPS_AGE_KEY
  SOPS_AGE_KEY=$(${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$HOME/.ssh/id_ed25519")

  DEFAULT_FILES=(
    "nixos/secrets/wireguard.yaml"
    "home/programs/ssh/private-ssh-config"
    "home/services/secrets/winapps.yaml"
    "home/programs/ai/secrets/claude-code.yaml"
    "home/programs/secrets/cargo.yaml"
  )

  if [[ $# -gt 0 ]]; then
    FILES=("$@")
  else
    FILES=("''${DEFAULT_FILES[@]}")
  fi

  for f in "''${FILES[@]}"; do
    if [[ -f "$FLAKE_DIR/$f" ]]; then
      target="$FLAKE_DIR/$f"
    elif [[ -f "$f" ]]; then
      target="$f"
    else
      echo "Warning: file $f not found"
      continue
    fi
    echo "--> Updating keys for $target..."
    ${pkgs.sops}/bin/sops updatekeys -y "$target"
  done
''
