#!/usr/bin/env bash
set -euo pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/_common.sh"

source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

home-manager switch -v --flake "$HOME_MANAGER_DIR#$HOME_MANAGER_HOST"
