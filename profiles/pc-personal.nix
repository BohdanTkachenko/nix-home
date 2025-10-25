{ pkgs, ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    "mbedtls-2.28.10"
  ];

  home.packages = with pkgs; [
    openrgb
  ];
}
