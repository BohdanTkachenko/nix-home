{
  features,
  homeDirectory,
  pkgs,
  username,
  lib,
  ...
}:
{
  home.stateVersion = "25.05";
  home.username = username;
  home.homeDirectory = homeDirectory;

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;

  programs.chromium-pwa-wmclass-sync.service.enable = true;

  home.packages = with pkgs; [
    _1password-gui
    chezmoi
    beeper
    nerd-fonts.hack
    nerd-fonts.droid-sans-mono
    nerd-fonts.roboto-mono
  ];

  imports = [
    ./modules/bash.nix
    ./modules/fish.nix
    ./modules/flatpak.nix
    ./modules/git.nix
    ./modules/gnome.nix
    ./modules/micro.nix
    ./modules/ssh-private.nix
    ./modules/ssh.nix
    ./modules/systemd.nix
    ./modules/tealdeer.nix
    ./modules/tools.nix
    ./modules/vscode/vscode.nix
  ]
  ++ (lib.optional features.xremap ./modules/xremap.nix);
}
