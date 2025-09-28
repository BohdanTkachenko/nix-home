{ pkgs, ... }:

{
  home.stateVersion = "25.05";

  home.username = "dan";
  home.homeDirectory = "/var/home/dan";

  programs.home-manager = {
    enable = true;
  };

  home.packages = [
    pkgs.chezmoi
  ];

  imports = [
    ./modules/bash.nix
    ./modules/fish.nix
    ./modules/flatpak.nix
    ./modules/gnome.nix
    ./modules/vscode.nix
    ./modules/xremap.nix
  ];
}
