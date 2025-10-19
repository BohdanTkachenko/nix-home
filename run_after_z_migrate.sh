#!/usr/bin/env bash
set -eu

rm -rf ~/.config/home-manager
rm -rf ~/.config/nix

chezmoi purge

bash -c "bash <(curl -sSL https://raw.githubusercontent.com/BohdanTkachenko/dotfiles/refs/heads/main/scripts/install.sh)"