{ pkgs, ... }:

pkgs.writeShellScriptBin "show-age-pubkey" ''
  set -euo pipefail

  ${pkgs.ssh-to-age}/bin/ssh-to-age -i "$HOME/.ssh/id_ed25519.pub"
''
