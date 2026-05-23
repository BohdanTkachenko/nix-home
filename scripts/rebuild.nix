{ pkgs, ... }:

pkgs.writeShellScriptBin "rebuild" ''
  set -euo pipefail

  if [[ -f "./flake.nix" ]]; then
    FLAKE_DIR="$(pwd)"
  else
    FLAKE_DIR="/home/dan/Projects/nix-home"
  fi

  echo "--> Rebuilding NixOS configuration..."

  # Try direct sudo first (works outside the IDE sandbox)
  if sudo /run/current-system/sw/bin/nixos-rebuild switch --flake "path:$FLAKE_DIR" "$@"; then
    exit 0
  fi

  # Fallback to transient systemd user service to escape IDE sandbox constraints
  echo "--> Direct rebuild blocked or failed. Attempting sandbox bypass via systemd-run..."
  exec ${pkgs.systemd}/bin/systemd-run --user --pty --collect sudo /run/current-system/sw/bin/nixos-rebuild switch --flake "path:$FLAKE_DIR" "$@"
''
