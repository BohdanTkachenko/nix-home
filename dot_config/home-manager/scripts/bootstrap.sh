#!/usr/bin/env bash
set -eu

for script in $CHEZMOI_SOURCE_DIR/dot_config/home-manager/scripts/_bootstrap_*.sh; do
  "$script"
done