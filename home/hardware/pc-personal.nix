{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.openrgb
  ];

  imports = [
    ./common.nix
  ];
}
