{ pkgs, ... }:

{
  home.stateVersion = "25.05";

  home.username = "dan";
  home.homeDirectory = "/var/home/dan";

  programs.home-manager = {
    enable = true;
  };

  imports = [
    ./modules/packages.nix
    ./modules/bash.nix
  ];
}
