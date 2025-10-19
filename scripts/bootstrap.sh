#!/usr/bin/env bash
set -eu

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/_common.sh"

for script in $HOME_MANAGER_DIR/scripts/_bootstrap_*.sh; do
  "$script"
done