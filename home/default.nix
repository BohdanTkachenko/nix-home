{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./profiles/common.nix
    ./profiles/personal.nix
    ./hardware
    ./services/winapps.nix
  ];

  config = {
    home.username = lib.mkDefault "dan";
    home.homeDirectory = lib.mkDefault "/var/home/dan";
  };
}
