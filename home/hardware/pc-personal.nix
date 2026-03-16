{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.openrgb
  ];
}
