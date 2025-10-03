{ pkgs, ... }:

{
  home.stateVersion = "25.05";

  home.username = "dan";
  home.homeDirectory = "/var/home/dan";

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
  xdg.enable = true;
  xdg.mime.enable = true;

  home.packages = [
    pkgs.chezmoi
    pkgs._1password-gui
  ];

  imports = [
    ./modules/bash.nix
    ./modules/fish.nix
    ./modules/flatpak.nix
    ./modules/git.nix
    ./modules/gnome.nix
    ./modules/vscode.nix
    ./modules/xremap.nix
  ];
}
