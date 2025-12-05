{ config, pkgs, ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    "mbedtls-2.28.10"
  ];

  home.packages = [
    (config.lib.nixGL.wrap pkgs.openrgb)
  ];
}
