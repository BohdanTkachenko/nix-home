{ pkgs, rebuild, ... }:

pkgs.writeShellScriptBin "update" ''
  set -euo pipefail

  if [[ -f "./flake.nix" ]]; then
    FLAKE_DIR="$(pwd)"
  else
    FLAKE_DIR="/home/dan/.config/nix"
  fi

  echo "--> Updating flake inputs..."
  nix flake update --flake "path:$FLAKE_DIR"

  echo "--> Rebuilding system..."
  ${rebuild}/bin/rebuild "$@"
''
