{ pkgs, ... }:
{
  imports = [
    ./workstation.nix

    ../modules/xremap.nix
  ];
}