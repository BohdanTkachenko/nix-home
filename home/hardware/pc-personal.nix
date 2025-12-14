{ config, pkgs, ... }:
{
  home.packages = [
    (config.lib.nixGL.wrap pkgs.openrgb)
  ];

  imports = [
    ./common.nix
  ];
}
