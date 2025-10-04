{ pkgs, ... }:

{
  home.stateVersion = "25.05";

  home.username = "dan";
  home.homeDirectory = "/var/home/dan";

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
  xdg.enable = true;
  xdg.mime.enable = true;
  home.sessionVariables.NIXOS_OZONE_WL = "1";

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
    ./modules/tools.nix
    ./modules/ssh.nix
    ./modules/ssh-private.nix
    ./modules/vscode.nix
    ./modules/xremap.nix
  ];
}
