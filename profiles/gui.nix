{ pkgs, ... }:
{
  programs.chromium-pwa-wmclass-sync.service.enable = true;

  home.packages = with pkgs; [
    beeper
    obsidian
    cameractrls-gtk4
    mission-center
    nerd-fonts.hack
    nerd-fonts.droid-sans-mono
    nerd-fonts.roboto-mono
  ];

  imports = [
    ../modules/1password
    ../modules/gnome
    ../modules/ptyxis
    ../modules/vscode/vscode.nix
  ];
}
