{ pkgs, ... }:

pkgs.writeShellScriptBin "check-flake" ''
  set -euo pipefail

  if [[ -f "./flake.nix" ]]; then
    FLAKE_DIR="$(pwd)"
  else
    FLAKE_DIR="/home/dan/.config/nix"
  fi

  echo "--> Running flake check..."
  nix flake check "path:$FLAKE_DIR" "$@"
''
