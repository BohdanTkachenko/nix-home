# Waydroid — Android in a container on Wayland
# https://wiki.nixos.org/wiki/Waydroid
#
# After rebuild, initialize with:
#   sudo waydroid init
# Or with Google Play Services:
#   sudo waydroid init -s GAPPS -f
{ pkgs, ... }:

{
  virtualisation.waydroid.enable = true;

  # Clipboard sharing between host and Waydroid
  environment.systemPackages = with pkgs; [
    wl-clipboard
  ];
}
