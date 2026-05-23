{ pkgs, ... }:

pkgs.writeShellScriptBin "check-flake" ''
  set -euo pipefail

  if [[ -f "./flake.nix" ]]; then
    FLAKE_DIR="$(pwd)"
  else
    FLAKE_DIR="/home/dan/Projects/nix-home"
  fi

  echo "--> Running flake check..."
  nix flake check "path:$FLAKE_DIR" "$@"
''
