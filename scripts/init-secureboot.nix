# Secure Boot Initialization Script
# Usage: nix run .#init-secureboot
{ pkgs, ... }:

pkgs.writeShellScriptBin "init-secureboot" ''
  set -euo pipefail

  if [[ $EUID -ne 0 ]]; then
     echo "This script must be run as root (use sudo)"
     exit 1
  fi

  echo "--> Reinitializing Secure Boot (Lanzaboote)..."
  
  echo "--> Creating secure boot directory..."
  mkdir -p /etc/secureboot

  echo "--> Creating new keys..."
  sbctl create-keys

  echo "--> Priming EFI partition..."
  bootctl install

  echo "--> Signing bootloader and kernel..."
  sbctl sign-all

  echo "--> Enrolling keys (Best Effort)..."
  if sbctl enroll-keys --microsoft; then
      echo "SUCCESS: Keys enrolled."
  else
      echo "WARNING: Could not enroll keys (BIOS likely not in Setup Mode)."
      echo "To complete setup:"
      echo "1. Reboot and enter BIOS/UEFI settings"
      echo "2. Clear existing keys and enter Setup Mode"
      echo "3. Run 'sudo sbctl enroll-keys --microsoft' manually"
  fi

  echo "--> Registering Bootloader..."
  /nix/var/nix/profiles/system/bin/switch-to-configuration boot

  echo "--> Secure Boot reinitialization complete!"
''