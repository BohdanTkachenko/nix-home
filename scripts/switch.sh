#!/usr/bin/env bash
set -euo pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/_common.sh"

if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

home-manager switch -b backup -v --flake "path:$HOME_MANAGER_DIR#$HOME_MANAGER_HOST"
